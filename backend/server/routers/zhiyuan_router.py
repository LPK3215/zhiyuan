"""智愿 - 志愿填报 API 路由

用户端：/api/zhiyuan/*  （查询、推荐、方案生成）
管理端：/api/zhiyuan/admin/*  （数据增删改查）
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from server.utils.auth_middleware import get_db, get_required_user, get_admin_user
from yuxi.repositories.zhiyuan_models import (
    AdmissionScore,
    EnrollmentPlan,
    Major,
    ProvinceRule,
    University,
)
from yuxi.repositories.zhiyuan_repository import ZhiyuanRepository, _escape_like, _LIKE_ESCAPE_CHAR
from sqlalchemy import func, select

zhiyuan = APIRouter(prefix="/zhiyuan", tags=["zhiyuan"])

# 管理端列表统一分页上限，避免无界返回
_ADMIN_LIST_CAP = 500


async def _paginate(db: AsyncSession, model, conditions: list, page: int, size: int) -> dict:
    """通用分页列表辅助：统计 total + 按 offset/limit 取页。

    用于去重多个结构相同的管理端列表接口（院校/专业/分数），
    集中维护分页逻辑与上限。
    """
    base = select(model)
    if conditions:
        base = base.where(*conditions)
    total = (await db.execute(select(func.count()).select_from(base.subquery()))).scalar() or 0
    rows = (
        await db.execute(base.offset((page - 1) * size).limit(size))
    ).scalars().all()
    return {"total": total, "page": page, "size": size, "items": [r.to_dict() for r in rows]}


async def _enrich_with_university_names(db: AsyncSession, items: list[dict]) -> None:
    """批量补全 items 中每条记录的 university_name 字段。

    用于管理端分数/计划列表，避免前端只拿到 university_id 无法直观识别院校。
    单条 IN 查询，O(1) DB 调用。
    """
    ids = {item.get("university_id") for item in items if item.get("university_id")}
    if not ids:
        return
    rows = (
        await db.execute(select(University.id, University.name).where(University.id.in_(ids)))
    ).all()
    name_map = {r[0]: r[1] for r in rows}
    for item in items:
        uid = item.get("university_id")
        item["university_name"] = name_map.get(uid, "") if uid else ""


async def _ensure_university_exists(db: AsyncSession, university_id: int) -> None:
    """外键存在性校验：确保 university_id 指向真实存在的院校。

    用于单条创建端点（分数/招生计划/专业），避免写入指向不存在院校的孤立记录。
    不存在时抛 422，与批量导入端点行为一致。
    """
    if not university_id:
        raise HTTPException(status_code=422, detail="university_id 不能为空")
    exists = (
        await db.execute(select(University.id).where(University.id == university_id))
    ).scalar_one_or_none()
    if exists is None:
        raise HTTPException(status_code=422, detail=f"university_id={university_id} 不存在")


# ========== 用户端接口 ==========


@zhiyuan.get("/universities")
async def search_universities(
    keyword: str = Query(default="", description="搜索关键词"),
    province: str = Query(default="", description="省份"),
    level: str = Query(default="", description="层次：985/211/双一流/普通"),
    type: str = Query(default="", description="类型：综合/理工/师范"),
    limit: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """搜索院校"""
    repo = ZhiyuanRepository(db)
    results = await repo.search_universities(
        province=province, level=level, type_=type, keyword=keyword, limit=limit
    )
    return {"message": "ok", "data": results}


@zhiyuan.get("/universities/{university_id}")
async def get_university_detail(
    university_id: int,
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """获取院校详情（含专业列表）"""
    result = await db.execute(select(University).where(University.id == university_id))
    uni = result.scalar_one_or_none()
    if not uni:
        raise HTTPException(status_code=404, detail="院校不存在")

    repo = ZhiyuanRepository(db)
    majors = await repo.get_majors_by_university(university_id)
    data = uni.to_dict()
    data["majors"] = majors
    return {"message": "ok", "data": data}


@zhiyuan.get("/scores")
async def query_scores(
    university_name: str = Query(default="", description="院校名称"),
    province: str = Query(default="", description="省份"),
    year: int = Query(default=0, description="年份"),
    subject_type: str = Query(default="", description="科类"),
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """查询历年录取分数"""
    repo = ZhiyuanRepository(db)
    uni_id = 0
    if university_name:
        uni = await repo.get_university_by_name(university_name)
        if not uni:
            return {"message": "ok", "data": []}
        uni_id = uni["id"]
    results = await repo.query_admission_scores(
        university_id=uni_id, province=province, year=year, subject_type=subject_type
    )
    return {"message": "ok", "data": results}


@zhiyuan.get("/rank")
async def get_score_rank(
    score: int = Query(..., description="分数"),
    province: str = Query(..., description="省份"),
    year: int = Query(default=0, description="年份，0 表示查最近年份"),
    subject_type: str = Query(default="", description="科类"),
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """查询一分一段（分数→位次），year=0 时自动取最近可用年份"""
    repo = ZhiyuanRepository(db)
    if year <= 0:
        year = await repo.get_latest_rank_year(province) or 0
    result = await repo.get_rank_by_score(score, province, year, subject_type)
    if not result:
        result = await repo.get_nearest_rank(score, province, year, subject_type)
    if not result:
        raise HTTPException(status_code=404, detail="未找到位次数据")
    return {"message": "ok", "data": result}


class RecommendRequest(BaseModel):
    """冲稳保推荐请求体"""

    rank: int = Field(..., gt=0, description="用户位次（全省排名），必须为正")
    province: str = Field(..., min_length=1, description="省份")
    subject_type: str = Field(default="", description="科类")
    strategy: str = Field(default="all", description="策略：all/rush/stable/safe")


@zhiyuan.post("/recommend")
async def recommend_schools(
    body: RecommendRequest,
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """冲稳保推荐"""
    repo = ZhiyuanRepository(db)
    result = await repo.recommend_by_rank(
        rank=body.rank,
        province=body.province,
        subject_type=body.subject_type,
        strategy=body.strategy,
    )

    # 补全院校名称/层次/省份（单条 IN 查询，与 /plan 对齐，避免前端仅拿到 university_id）
    all_ids = {
        item["university_id"] for group in result.values() for item in group
    }
    uni_map = await repo.get_university_maps(all_ids, fields=("name", "level", "province"))
    for category in result:
        for item in result[category]:
            uni = uni_map.get(item["university_id"], {})
            item["university_name"] = uni.get("name", f"ID:{item['university_id']}")
            item["level"] = uni.get("level", "")
            item["province"] = uni.get("province", "")
    return {"message": "ok", "data": result}


class GeneratePlanRequest(BaseModel):
    """生成志愿方案请求体"""

    rank: int = Field(..., gt=0, description="用户位次（全省排名），必须为正")
    province: str = Field(..., min_length=1, description="省份")
    subject_type: str = Field(default="", description="科类")
    subject_combination: str = Field(default="", description="选科组合，如'物理+化学+生物'")
    score: int = Field(default=0, ge=0, le=750, description="高考分数")


@zhiyuan.post("/plan")
async def generate_plan(
    body: GeneratePlanRequest,
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """生成志愿方案（含冲稳保三档 + 每所院校的推荐专业）"""
    repo = ZhiyuanRepository(db)
    recommendation = await repo.recommend_by_rank(
        rank=body.rank,
        province=body.province,
        subject_type=body.subject_type,
        strategy="all",
    )

    # 批量补充院校名称（单条 IN 查询，复用当前会话）
    all_ids = {
        item["university_id"]
        for group in recommendation.values()
        for item in group
    }
    uni_map = await repo.get_university_maps(all_ids, fields=("name", "level", "province"))

    subject_combination = body.subject_combination
    # 批量补全所有院校的专业维度（单条 IN 查询，消除逐校 N+1）
    majors_map = await repo.get_university_majors_batch(
        all_ids, body.province, subject_combination, top_n=3
    )

    plan = {"profile": body.model_dump(), "rush": [], "stable": [], "safe": []}
    for category in ("rush", "stable", "safe"):
        for item in recommendation.get(category, []):
            uni = uni_map.get(item["university_id"], {})
            plan[category].append({
                "university_name": uni.get("name", f"ID:{item['university_id']}"),
                "level": uni.get("level", ""),
                "province": uni.get("province", ""),
                "avg_rank": item["avg_rank"],
                "rank_ratio": item["ratio"],
                "majors": majors_map.get(item["university_id"], []),
            })

    plan["summary"] = {
        "total": len(plan["rush"]) + len(plan["stable"]) + len(plan["safe"]),
        "rush_count": len(plan["rush"]),
        "stable_count": len(plan["stable"]),
        "safe_count": len(plan["safe"]),
    }
    return {"message": "ok", "data": plan}


# 图谱关系类型白名单（防止 relation_type 被注入到 Cypher 模式）
# 同时包含英文（知识库图谱）和中文（智愿种子图谱）关系名
_GRAPH_RELATION_WHITELIST = {
    "belongs_to",
    "has_major",
    "located_in",
    "employed_by",
    "requires",
    "offers",
    "adjacent_to",
    # 智愿种子图谱使用的中文关系名
    "开设",
    "属于",
    "对应职业",
    "前置学科",
}


@zhiyuan.get("/graph")
async def query_graph(
    start_entity: str = Query(..., description="起始实体"),
    relation_type: str = Query(default="", description="关系类型"),
    depth: int = Query(default=2, ge=1, le=4),
    _user=Depends(get_required_user),
):
    """知识图谱查询（需要Neo4j）

    安全：
    - relation_type 仅允许白名单内的值直接拼入 Cypher 关系模式，非法值一律回退为任意关系（避免 Cypher 注入）。
    - start_entity 做空/超长校验；depth 再次显式钳制到 [1,4]，避免拼入越界数值。
    """
    clean_entity = (start_entity or "").strip()
    if not clean_entity:
        raise HTTPException(status_code=400, detail="实体名称不能为空")
    if len(clean_entity) > 100:
        raise HTTPException(status_code=400, detail="实体名称过长（最多100字符）")

    try:
        from yuxi.storage.neo4j import get_shared_neo4j_connection, neo4j_read

        conn = get_shared_neo4j_connection()
        if not conn.is_running():
            return {"message": "图谱服务未启用", "data": []}

        safe_rel = relation_type if relation_type in _GRAPH_RELATION_WHITELIST else ""
        safe_depth = max(1, min(int(depth), 4))
        if safe_depth == 1:
            # depth=1: direct relationships, r is a single relationship
            # 使用 startNode/endNode 确保关系方向正确
            rel_pattern = f"-[r:{safe_rel}]-" if safe_rel else "-[r]-"
            cypher = (
                f"MATCH (n {{name: $entity}}){rel_pattern}(m) "
                f"RETURN startNode(r).name AS start, type(r) AS relation, endNode(r).name AS target LIMIT 50"
            )
        else:
            # depth>1: variable-length path, UNWIND 展开每条关系
            # 必须使用 startNode(rel)/endNode(rel) 获取每条关系的实际端点，
            # 不能用 n.name/m.name（它们是路径的起止点，不是每条关系的端点）
            rel_pattern = f"*1..{safe_depth}"
            rel_type_filter = f":{safe_rel}" if safe_rel else ""
            cypher = (
                f"MATCH path = (n {{name: $entity}})-[r{rel_type_filter}{rel_pattern}]-(m) "
                f"UNWIND relationships(path) AS rel "
                f"WITH DISTINCT startNode(rel).name AS start, type(rel) AS relation, endNode(rel).name AS target "
                f"RETURN start, relation, target LIMIT 50"
            )
        # 使用同步 Neo4j 驱动在线程中执行查询，避免阻塞事件循环
        import asyncio

        results = await asyncio.to_thread(
            neo4j_read, conn.driver, cypher, entity=clean_entity
        )
        # 统一返回 {message, data} envelope，使成功/未启用/失败三种状态结构一致，
        # 前端 resolveGraph 通过 res?.data 透明消费，无需区分裸 list 与降级包。
        return {"message": "ok", "data": results or []}
    except HTTPException:
        raise
    except Exception as e:
        return {"message": f"图谱查询失败: {str(e)}", "data": []}


@zhiyuan.get("/rules/{province}")
async def get_province_rule(
    province: str,
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """获取省份填报规则"""
    repo = ZhiyuanRepository(db)
    rule = await repo.get_province_rule(province)
    if not rule:
        raise HTTPException(status_code=404, detail=f"暂无 {province} 的规则数据")
    return {"message": "ok", "data": rule}


class CompareMajorsRequest(BaseModel):
    """专业对比请求体"""

    major_names: list[str] = Field(..., min_length=2, description="要对比的专业名称列表")
    university_name: str = Field(default="", description="限定在某校内对比（可选）")


@zhiyuan.post("/majors/compare")
async def compare_majors(
    body: CompareMajorsRequest,
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """专业对比"""
    repo = ZhiyuanRepository(db)
    results = await repo.compare_majors(body.major_names, body.university_name)
    return {"message": "ok", "data": results}


@zhiyuan.get("/subject-check")
async def check_subject(
    combination: str = Query(..., description="选科组合，如'物理+化学+生物'"),
    province: str = Query(default=""),
    db: AsyncSession = Depends(get_db),
    _user=Depends(get_required_user),
):
    """选科兼容性检查"""
    repo = ZhiyuanRepository(db)
    results = await repo.check_subject_requirement(combination, province)
    return {"message": "ok", "data": results}


# ========== 管理端 CRUD 接口 ==========

admin = APIRouter(prefix="/zhiyuan/admin", tags=["zhiyuan-admin"])


# --- 院校管理 ---


class UniversityCreate(BaseModel):
    name: str = Field(..., min_length=2)
    province: str = Field(..., min_length=1)
    city: str = ""
    level: str = ""
    type: str = ""
    nature: str = "公办"
    website: str = ""
    intro: str = ""
    master_points: int = Field(default=0, ge=0)
    doctor_points: int = Field(default=0, ge=0)
    key_disciplines: str = ""


@admin.get("/universities")
async def admin_list_universities(
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
    keyword: str = Query(default=""),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：院校列表（分页）"""
    conditions = []
    if keyword:
        conditions.append(University.name.ilike(f"%{_escape_like(keyword)}%", escape=_LIKE_ESCAPE_CHAR))
    return await _paginate(db, University, conditions, page, size)


@admin.post("/universities")
async def admin_create_university(
    body: UniversityCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：新增院校"""
    existing = (
        await db.execute(select(University).where(University.name == body.name))
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=409, detail=f"院校『{body.name}』已存在")
    uni = University(**body.model_dump())
    db.add(uni)
    await db.commit()
    await db.refresh(uni)
    return uni.to_dict()


@admin.put("/universities/{university_id}")
async def admin_update_university(
    university_id: int,
    body: UniversityCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：更新院校"""
    result = await db.execute(select(University).where(University.id == university_id))
    uni = result.scalar_one_or_none()
    if not uni:
        raise HTTPException(status_code=404, detail="院校不存在")

    for key, value in body.model_dump().items():
        setattr(uni, key, value)
    await db.commit()
    await db.refresh(uni)
    return uni.to_dict()


@admin.delete("/universities/{university_id}")
async def admin_delete_university(
    university_id: int,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：删除院校"""
    result = await db.execute(select(University).where(University.id == university_id))
    uni = result.scalar_one_or_none()
    if not uni:
        raise HTTPException(status_code=404, detail="院校不存在")

    await db.delete(uni)
    await db.commit()
    return {"status": "ok", "deleted": university_id}


# --- 专业管理 ---


class MajorCreate(BaseModel):
    university_id: int = Field(..., gt=0, description="所属院校 ID，必须为正")
    name: str = Field(..., min_length=2)
    code: str = ""
    degree: str = ""
    duration: str = "4年"
    subject_category: str = ""
    subject_requirement: str = ""
    intro: str = ""
    employment_rate: float = Field(default=0.0, ge=0.0, le=100.0, description="就业率百分比")
    avg_salary: float = Field(default=0.0, ge=0.0)
    career_directions: str = ""
    is_key: bool = False


@admin.get("/majors")
async def admin_list_majors(
    university_id: int = Query(default=0),
    keyword: str = Query(default=""),
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：专业列表"""
    conditions = []
    if university_id:
        conditions.append(Major.university_id == university_id)
    if keyword:
        conditions.append(Major.name.ilike(f"%{_escape_like(keyword)}%", escape=_LIKE_ESCAPE_CHAR))
    result = await _paginate(db, Major, conditions, page, size)
    await _enrich_with_university_names(db, result["items"])
    return result


@admin.post("/majors")
async def admin_create_major(
    body: MajorCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：新增专业"""
    await _ensure_university_exists(db, body.university_id)
    major = Major(**body.model_dump())
    db.add(major)
    await db.commit()
    await db.refresh(major)
    return major.to_dict()


@admin.delete("/majors/{major_id}")
async def admin_delete_major(
    major_id: int,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：删除专业"""
    result = await db.execute(select(Major).where(Major.id == major_id))
    major = result.scalar_one_or_none()
    if not major:
        raise HTTPException(status_code=404, detail="专业不存在")

    await db.delete(major)
    await db.commit()
    return {"status": "ok", "deleted": major_id}


# --- 录取分数管理 ---


class AdmissionScoreCreate(BaseModel):
    university_id: int = Field(..., gt=0, description="所属院校 ID，必须为正")
    major_id: int = Field(default=0, ge=0)
    province: str = Field(..., min_length=1)
    year: int = Field(..., gt=0, description="年份，必须为正")
    subject_type: str = ""
    batch: str = "本科一批"
    min_score: int = Field(default=0, ge=0, le=750)
    max_score: int = Field(default=0, ge=0, le=750)
    avg_score: int = Field(default=0, ge=0, le=750)
    min_rank: int = Field(default=0, ge=0)
    plan_count: int = Field(default=0, ge=0)


@admin.get("/scores")
async def admin_list_scores(
    university_id: int = Query(default=0),
    province: str = Query(default=""),
    year: int = Query(default=0),
    page: int = Query(default=1, ge=1),
    size: int = Query(default=50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：录取分数列表"""
    conditions = []
    if university_id:
        conditions.append(AdmissionScore.university_id == university_id)
    if province:
        conditions.append(AdmissionScore.province == province)
    if year:
        conditions.append(AdmissionScore.year == year)
    result = await _paginate(db, AdmissionScore, conditions, page, size)
    await _enrich_with_university_names(db, result["items"])
    return result


@admin.post("/scores")
async def admin_create_score(
    body: AdmissionScoreCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：新增录取分数"""
    await _ensure_university_exists(db, body.university_id)
    score = AdmissionScore(**body.model_dump())
    db.add(score)
    await db.commit()
    await db.refresh(score)
    return score.to_dict()


@admin.post("/scores/batch")
async def admin_batch_create_scores(
    body: list[AdmissionScoreCreate],
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：批量导入录取分数（单次上限 1000 条，防止内存/DB 过载）"""
    if len(body) > 1000:
        raise HTTPException(status_code=413, detail="单次批量导入不得超过 1000 条")
    if not body:
        return {"status": "ok", "count": 0}

    # 外键存在性预校验：一次性查出所有涉及的 university_id 是否真实存在，
    # 避免写入指向不存在院校的孤立分数（脏数据）。
    wanted_ids = {item.university_id for item in body}
    existing_rows = (
        await db.execute(select(University.id).where(University.id.in_(wanted_ids)))
    ).all()
    existing_ids = {r[0] for r in existing_rows}
    missing_ids = sorted(wanted_ids - existing_ids)
    if missing_ids:
        raise HTTPException(
            status_code=422,
            detail=f"以下 university_id 不存在，已拒绝整批写入：{missing_ids}",
        )

    for item in body:
        db.add(AdmissionScore(**item.model_dump()))
    await db.commit()
    return {"status": "ok", "count": len(body)}


@admin.delete("/scores/{score_id}")
async def admin_delete_score(
    score_id: int,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：删除录取分数"""
    result = await db.execute(select(AdmissionScore).where(AdmissionScore.id == score_id))
    score = result.scalar_one_or_none()
    if not score:
        raise HTTPException(status_code=404, detail="记录不存在")

    await db.delete(score)
    await db.commit()
    return {"status": "ok", "deleted": score_id}


# --- 省份规则管理 ---


class ProvinceRuleCreate(BaseModel):
    province: str = Field(..., min_length=1)
    year: int = Field(..., gt=0, description="年份，必须为正")
    mode: str = ""
    batch_count: int = Field(default=0, ge=0)
    max_per_batch: int = Field(default=0, ge=0)
    subject_mode: str = ""
    description: str = ""
    tips: str = ""


@admin.get("/rules")
async def admin_list_rules(
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：所有省份规则（上限分页，避免无界返回）"""
    rows = (await db.execute(select(ProvinceRule).limit(_ADMIN_LIST_CAP))).scalars().all()
    return {"total": len(rows), "items": [r.to_dict() for r in rows]}


@admin.post("/rules")
async def admin_upsert_rule(
    body: ProvinceRuleCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：新增或更新省份规则"""
    if not body.province.strip():
        raise HTTPException(status_code=422, detail="province 不能为空")
    if body.year <= 0:
        raise HTTPException(status_code=422, detail="year 必须为正整数")

    result = await db.execute(select(ProvinceRule).where(ProvinceRule.province == body.province))
    existing = result.scalar_one_or_none()

    if existing:
        for key, value in body.model_dump().items():
            setattr(existing, key, value)
        await db.commit()
        await db.refresh(existing)
        return existing.to_dict()
    else:
        rule = ProvinceRule(**body.model_dump())
        db.add(rule)
        await db.commit()
        await db.refresh(rule)
        return rule.to_dict()


# --- 招生计划管理 ---


class EnrollmentPlanCreate(BaseModel):
    university_id: int = Field(..., gt=0, description="所属院校 ID，必须为正")
    major_id: int = Field(default=0, ge=0)
    province: str = Field(..., min_length=1)
    year: int = Field(..., gt=0, description="年份，必须为正")
    subject_type: str = ""
    batch: str = ""
    plan_count: int = Field(default=0, ge=0)
    duration: str = "4年"
    tuition: str = ""
    remark: str = ""


@admin.get("/plans")
async def admin_list_plans(
    university_id: int = Query(default=0),
    province: str = Query(default=""),
    year: int = Query(default=0),
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：招生计划列表（分页）"""
    conditions = []
    if university_id:
        conditions.append(EnrollmentPlan.university_id == university_id)
    if province:
        conditions.append(EnrollmentPlan.province == province)
    if year:
        conditions.append(EnrollmentPlan.year == year)
    result = await _paginate(db, EnrollmentPlan, conditions, page, size)
    await _enrich_with_university_names(db, result["items"])
    return result


@admin.post("/plans")
async def admin_create_plan(
    body: EnrollmentPlanCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：新增招生计划"""
    await _ensure_university_exists(db, body.university_id)
    plan = EnrollmentPlan(**body.model_dump())
    db.add(plan)
    await db.commit()
    await db.refresh(plan)
    return plan.to_dict()


@admin.put("/majors/{major_id}")
async def admin_update_major(
    major_id: int,
    body: MajorCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：更新专业"""
    result = await db.execute(select(Major).where(Major.id == major_id))
    major = result.scalar_one_or_none()
    if not major:
        raise HTTPException(status_code=404, detail="专业不存在")
    await _ensure_university_exists(db, body.university_id)
    for key, value in body.model_dump().items():
        setattr(major, key, value)
    await db.commit()
    await db.refresh(major)
    return major.to_dict()


@admin.put("/scores/{score_id}")
async def admin_update_score(
    score_id: int,
    body: AdmissionScoreCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：更新录取分数"""
    result = await db.execute(select(AdmissionScore).where(AdmissionScore.id == score_id))
    score = result.scalar_one_or_none()
    if not score:
        raise HTTPException(status_code=404, detail="记录不存在")
    await _ensure_university_exists(db, body.university_id)
    for key, value in body.model_dump().items():
        setattr(score, key, value)
    await db.commit()
    await db.refresh(score)
    return score.to_dict()


@admin.put("/plans/{plan_id}")
async def admin_update_plan(
    plan_id: int,
    body: EnrollmentPlanCreate,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：更新招生计划"""
    result = await db.execute(select(EnrollmentPlan).where(EnrollmentPlan.id == plan_id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="招生计划不存在")
    await _ensure_university_exists(db, body.university_id)
    for key, value in body.model_dump().items():
        setattr(plan, key, value)
    await db.commit()
    await db.refresh(plan)
    return plan.to_dict()


@admin.delete("/plans/{plan_id}")
async def admin_delete_plan(
    plan_id: int,
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：删除招生计划"""
    result = await db.execute(select(EnrollmentPlan).where(EnrollmentPlan.id == plan_id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="招生计划不存在")
    await db.delete(plan)
    await db.commit()
    return {"status": "ok", "deleted": plan_id}
