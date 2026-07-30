"""智愿 - 志愿填报 API 路由

用户端：/api/zhiyuan/*  （查询、推荐、方案生成）
管理端：/api/zhiyuan/admin/*  （数据增删改查）
"""

import time
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Request, UploadFile, File
from pydantic import BaseModel, Field, field_validator, model_validator
from sqlalchemy.ext.asyncio import AsyncSession

from server.utils.auth_middleware import get_db, get_required_user, get_admin_user
from yuxi.repositories.zhiyuan_models import (
    AdmissionScore,
    EnrollmentPlan,
    Major,
    ProvinceRule,
    ScoreRank,
    University,
)
from yuxi.repositories.zhiyuan_repository import ZhiyuanRepository, _escape_like, _LIKE_ESCAPE_CHAR
from sqlalchemy import func, select

zhiyuan = APIRouter(prefix="/zhiyuan", tags=["zhiyuan"])

# 管理端列表统一分页上限，避免无界返回
_ADMIN_LIST_CAP = 500

# 公开统计端点内存缓存：避免高频首页刷新打 DB（TTL 秒数）
_STATS_CACHE_TTL = 30
_stats_cache: dict[str, tuple[float, Any]] = {}


def _get_cached(key: str):
    """读取缓存。命中且未过期则返回值，否则返回 None。"""
    entry = _stats_cache.get(key)
    if not entry:
        return None
    ts, value = entry
    if time.monotonic() - ts > _STATS_CACHE_TTL:
        return None
    return value


def _set_cached(key: str, value: Any) -> None:
    """写入缓存（带时间戳）。"""
    _stats_cache[key] = (time.monotonic(), value)


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


@zhiyuan.get("/stats")
async def get_public_stats(
    db: AsyncSession = Depends(get_db),
):
    """公开统计端点（首页展示用，无需认证）

    返回各业务表的数据量，用于首页展示平台数据规模。
    使用 30 秒内存缓存，避免高频首页刷新打 DB。
    """
    cached = _get_cached("stats")
    if cached is not None:
        return cached

    uni_count = (await db.execute(select(func.count()).select_from(University))).scalar() or 0
    major_count = (await db.execute(select(func.count()).select_from(Major))).scalar() or 0
    score_count = (await db.execute(select(func.count()).select_from(AdmissionScore))).scalar() or 0
    rank_count = (await db.execute(select(func.count()).select_from(ScoreRank))).scalar() or 0
    plan_count = (await db.execute(select(func.count()).select_from(EnrollmentPlan))).scalar() or 0
    province_count = (
        await db.execute(select(func.count(func.distinct(University.province))))
    ).scalar() or 0
    level_985 = (
        await db.execute(
            select(func.count()).select_from(
                select(University).where(University.level == "985").subquery()
            )
        )
    ).scalar() or 0
    level_211 = (
        await db.execute(
            select(func.count()).select_from(
                select(University).where(University.level == "211").subquery()
            )
        )
    ).scalar() or 0

    payload = {
        "message": "ok",
        "data": {
            "universities": uni_count,
            "majors": major_count,
            "admission_scores": score_count,
            "score_ranks": rank_count,
            "enrollment_plans": plan_count,
            "provinces_covered": province_count,
            "level_985": level_985,
            "level_211": level_211,
        },
    }
    _set_cached("stats", payload)
    return payload


@zhiyuan.get("/stats/health")
async def get_data_health(
    db: AsyncSession = Depends(get_db),
):
    """数据完整度健康检查（管理端展示用，无需认证）。

    返回各业务维度的数据缺失情况，用于评估数据完整度：
    - 缺失重点学科的院校数
    - 缺失硕士点/博士点的院校数
    - 缺失网站链接的院校数
    - 无专业的院校数
    - 无录取分数的院校数
    - 无招生计划的院校数

    使用 30 秒内存缓存，避免管理端频繁刷新打 DB。
    """
    cached = _get_cached("health")
    if cached is not None:
        return cached

    # 缺失重点学科
    no_disciplines = (
        await db.execute(
            select(func.count()).select_from(
                select(University)
                .where(
                    (University.key_disciplines.is_(None))
                    | (University.key_disciplines == "")
                )
                .subquery()
            )
        )
    ).scalar() or 0

    # 缺失硕士点/博士点
    no_master = (
        await db.execute(
            select(func.count()).select_from(
                select(University)
                .where((University.master_points.is_(None)) | (University.master_points == 0))
                .subquery()
            )
        )
    ).scalar() or 0
    no_doctor = (
        await db.execute(
            select(func.count()).select_from(
                select(University)
                .where((University.doctor_points.is_(None)) | (University.doctor_points == 0))
                .subquery()
            )
        )
    ).scalar() or 0

    # 缺失网站
    no_website = (
        await db.execute(
            select(func.count()).select_from(
                select(University)
                .where((University.website.is_(None)) | (University.website == ""))
                .subquery()
            )
        )
    ).scalar() or 0

    # 无专业的院校数
    uni_with_majors = (
        await db.execute(select(func.distinct(Major.university_id)))
    ).scalars().all()
    uni_with_majors_set = set(uni_with_majors)
    uni_total = (
        await db.execute(select(func.count()).select_from(University))
    ).scalar() or 0
    no_majors = max(0, uni_total - len(uni_with_majors_set))

    # 无录取分数的院校数
    uni_with_scores = (
        await db.execute(select(func.distinct(AdmissionScore.university_id)))
    ).scalars().all()
    uni_with_scores_set = set(uni_with_scores)
    no_scores = max(0, uni_total - len(uni_with_scores_set))

    # 无招生计划的院校数
    uni_with_plans = (
        await db.execute(select(func.distinct(EnrollmentPlan.university_id)))
    ).scalars().all()
    uni_with_plans_set = set(uni_with_plans)
    no_plans = max(0, uni_total - len(uni_with_plans_set))

    # 综合健康分（0-100）：每个维度权重相同
    total_checks = 6
    passed = 0
    if uni_total == 0:
        return {
            "message": "ok",
            "data": {
                "total_universities": 0,
                "health_score": 0,
                "issues": {"empty_data": "院校库为空"},
            },
        }
    weights = {
        "no_disciplines": 0.10,
        "no_master": 0.10,
        "no_doctor": 0.10,
        "no_website": 0.10,
        "no_majors": 0.25,
        "no_scores": 0.20,
        "no_plans": 0.15,
    }
    score_loss = 0.0
    issues = {}
    for key, missing in {
        "no_disciplines": no_disciplines,
        "no_master": no_master,
        "no_doctor": no_doctor,
        "no_website": no_website,
        "no_majors": no_majors,
        "no_scores": no_scores,
        "no_plans": no_plans,
    }.items():
        if missing > 0:
            ratio = missing / uni_total
            score_loss += ratio * weights[key] * 100
            issues[key] = missing
    health_score = max(0, round(100 - score_loss))

    payload = {
        "message": "ok",
        "data": {
            "total_universities": uni_total,
            "health_score": health_score,
            "issues": issues,
            "details": {
                "no_disciplines": no_disciplines,
                "no_master": no_master,
                "no_doctor": no_doctor,
                "no_website": no_website,
                "no_majors": no_majors,
                "no_scores": no_scores,
                "no_plans": no_plans,
            },
        },
    }
    _set_cached("health", payload)
    return payload


def _invalidate_stats_cache() -> None:
    """管理端写入数据后清除统计缓存，确保下次查询拿到最新数据。"""
    _stats_cache.pop("stats", None)
    _stats_cache.pop("health", None)


# ========== 管理端 CRUD 接口 ==========


async def _invalidate_cache_after_write(request: Request):
    """管理端写操作（POST/PUT/DELETE）完成后清除统计缓存。

    GET 请求不清缓存，避免读操作导致缓存频繁失效。
    使用 yield 依赖：在响应返回后执行清除。
    """
    yield
    if request.method != "GET":
        _invalidate_stats_cache()


admin = APIRouter(
    prefix="/zhiyuan/admin",
    tags=["zhiyuan-admin"],
    dependencies=[Depends(_invalidate_cache_after_write)],
)


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

    @field_validator("website")
    @classmethod
    def _validate_website(cls, v: str) -> str:
        """website 非空时必须以 http:// 或 https:// 开头，防止脏数据。"""
        if v and not v.startswith(("http://", "https://")):
            raise ValueError("website 必须以 http:// 或 https:// 开头")
        return v

    @field_validator("level")
    @classmethod
    def _validate_level(cls, v: str) -> str:
        """level 限定为已知层次枚举，空字符串表示未设置。"""
        if v and v not in ("985", "211", "双一流", "普通"):
            raise ValueError("level 必须为 985/211/双一流/普通 之一")
        return v

    @field_validator("nature")
    @classmethod
    def _validate_nature(cls, v: str) -> str:
        """nature 限定为公办/民办/中外合作，空字符串表示未设置。"""
        if v and v not in ("公办", "民办", "中外合作"):
            raise ValueError("nature 必须为 公办/民办/中外合作 之一")
        return v


@admin.get("/universities")
async def admin_list_universities(
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=500),
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
    size: int = Query(default=20, ge=1, le=500),
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

    @field_validator("year")
    @classmethod
    def _validate_year(cls, v: int) -> int:
        """年份合理性校验：不能早于 1990，不能晚于当前年份 + 1（允许提前录入下一年计划）。"""
        from datetime import datetime
        current_year = datetime.now().year
        if v < 1990 or v > current_year + 1:
            raise ValueError(f"年份必须在 1990 ~ {current_year + 1} 之间")
        return v

    @model_validator(mode="after")
    def _validate_score_range(self):
        """分数逻辑校验：max >= avg >= min（0 表示未录入，跳过比较）。"""
        if (
            self.max_score > 0
            and self.min_score > 0
            and self.max_score < self.min_score
        ):
            raise ValueError("max_score 不能小于 min_score")
        if (
            self.avg_score > 0
            and self.min_score > 0
            and self.avg_score < self.min_score
        ):
            raise ValueError("avg_score 不能小于 min_score")
        if (
            self.max_score > 0
            and self.avg_score > 0
            and self.avg_score > self.max_score
        ):
            raise ValueError("avg_score 不能大于 max_score")
        return self


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


# --- 补充：规则删除 / 专业批量导入 / 计划批量导入 ---


@admin.delete("/rules/{province}")
async def admin_delete_rule(
    province: str,
    year: int = Query(default=0, description="年份，0 表示删除该省份所有年份的规则"),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：删除省份规则

    year=0 时删除该省份的所有规则；否则只删除指定年份的规则。
    """
    stmt = select(ProvinceRule).where(ProvinceRule.province == province)
    if year > 0:
        stmt = stmt.where(ProvinceRule.year == year)
    rows = (await db.execute(stmt)).scalars().all()
    if not rows:
        raise HTTPException(status_code=404, detail=f"未找到 {province} 的规则数据")
    for row in rows:
        await db.delete(row)
    await db.commit()
    return {"status": "ok", "deleted": len(rows)}


@admin.post("/majors/batch")
async def admin_batch_create_majors(
    body: list[MajorCreate],
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：批量导入专业（单次上限 500 条）"""
    if len(body) > 500:
        raise HTTPException(status_code=413, detail="单次批量导入不得超过 500 条")
    if not body:
        return {"status": "ok", "count": 0}

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
        db.add(Major(**item.model_dump()))
    await db.commit()
    return {"status": "ok", "count": len(body)}


@admin.post("/plans/batch")
async def admin_batch_create_plans(
    body: list[EnrollmentPlanCreate],
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：批量导入招生计划（单次上限 500 条）"""
    if len(body) > 500:
        raise HTTPException(status_code=413, detail="单次批量导入不得超过 500 条")
    if not body:
        return {"status": "ok", "count": 0}

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
        db.add(EnrollmentPlan(**item.model_dump()))
    await db.commit()
    return {"status": "ok", "count": len(body)}


# --- Excel/CSV 文件上传导入 ---


def _parse_upload_file(content: bytes, filename: str):
    """解析上传的 Excel/CSV 文件，返回 pandas DataFrame。

    支持 .xlsx/.xls（openpyxl 引擎）和 .csv（utf-8/gbk 自动探测编码）。
    """
    import io
    import pandas as pd

    lower = (filename or "").lower()
    if lower.endswith(".csv"):
        # CSV 编码自动探测：先试 utf-8，失败回退 gbk
        try:
            return pd.read_csv(io.BytesIO(content), dtype=str)
        except UnicodeDecodeError:
            return pd.read_csv(io.BytesIO(content), dtype=str, encoding="gbk")
    elif lower.endswith((".xlsx", ".xls")):
        return pd.read_excel(io.BytesIO(content), dtype=str, engine="openpyxl")
    else:
        raise HTTPException(
            status_code=415,
            detail=f"不支持的文件格式：{filename}，仅支持 .xlsx/.xls/.csv",
        )


def _safe_int(val, default=0):
    """安全转 int：空值/NaN/非数字 → default。"""
    if val is None:
        return default
    s = str(val).strip()
    if not s or s.lower() in ("nan", "none", ""):
        return default
    try:
        return int(float(s))
    except (ValueError, TypeError):
        return default


def _safe_float(val, default=0.0):
    """安全转 float：空值/NaN/非数字 → default。"""
    if val is None:
        return default
    s = str(val).strip()
    if not s or s.lower() in ("nan", "none", ""):
        return default
    try:
        return float(s)
    except (ValueError, TypeError):
        return default


@admin.post("/scores/import")
async def admin_import_scores_file(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：通过 Excel/CSV 文件导入录取分数

    要求列名（不区分大小写，支持中英文）：
    院校名称/院校/university_name, 院校ID/university_id, 专业ID/major_id,
    省份/province, 年份/year, 科类/subject_type, 批次/batch,
    最低分/min_score, 最高分/max_score, 平均分/avg_score,
    最低位次/min_rank, 计划数/plan_count

    优先使用 university_id；若仅有 university_name，则按名称查找院校 ID。
    """
    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="文件大小不得超过 10MB")

    df = _parse_upload_file(content, file.filename or "")

    # 列名归一化：去空格、转小写
    df.columns = [str(c).strip().lower() for c in df.columns]

    # 列名映射（中文 -> 英文标准字段）
    col_map = {
        "院校名称": "university_name", "院校": "university_name", "university_name": "university_name",
        "院校id": "university_id", "university_id": "university_id",
        "专业id": "major_id", "major_id": "major_id",
        "省份": "province", "province": "province",
        "年份": "year", "year": "year",
        "科类": "subject_type", "subject_type": "subject_type",
        "批次": "batch", "batch": "batch",
        "最低分": "min_score", "min_score": "min_score",
        "最高分": "max_score", "max_score": "max_score",
        "平均分": "avg_score", "avg_score": "avg_score",
        "最低位次": "min_rank", "min_rank": "min_rank",
        "计划数": "plan_count", "plan_count": "plan_count",
    }
    rename_dict = {}
    for col in df.columns:
        if col in col_map:
            rename_dict[col] = col_map[col]
    df = df.rename(columns=rename_dict)

    # 必须有 university_id 或 university_name
    if "university_id" not in df.columns and "university_name" not in df.columns:
        raise HTTPException(
            status_code=422,
            detail="文件必须包含「院校ID」或「院校名称」列",
        )
    if "province" not in df.columns:
        raise HTTPException(status_code=422, detail="文件必须包含「省份」列")
    if "year" not in df.columns:
        raise HTTPException(status_code=422, detail="文件必须包含「年份」列")

    # 如果只有 university_name，批量查找 university_id
    if "university_id" not in df.columns:
        names = df["university_name"].dropna().unique().tolist()
        rows = (
            await db.execute(select(University.id, University.name).where(University.name.in_(names)))
        ).all()
        name_map = {r[1]: r[0] for r in rows}
        df["university_id"] = df["university_name"].map(lambda n: name_map.get(str(n).strip(), 0))
        unmatched = df[df["university_id"] == 0]
        if len(unmatched) > 0:
            missing_names = unmatched["university_name"].unique().tolist()[:10]
            raise HTTPException(
                status_code=422,
                detail=f"以下院校名称未匹配到记录：{missing_names}，请先在院校管理中添加",
            )

    records = []
    for _, row in df.iterrows():
        uid = _safe_int(row.get("university_id"))
        if uid <= 0:
            continue
        records.append(AdmissionScore(
            university_id=uid,
            major_id=_safe_int(row.get("major_id")),
            province=str(row.get("province", "")).strip(),
            year=_safe_int(row.get("year")) or 2025,
            subject_type=str(row.get("subject_type", "")).strip(),
            batch=str(row.get("batch", "本科一批")).strip() or "本科一批",
            min_score=_safe_int(row.get("min_score")),
            max_score=_safe_int(row.get("max_score")),
            avg_score=_safe_int(row.get("avg_score")),
            min_rank=_safe_int(row.get("min_rank")),
            plan_count=_safe_int(row.get("plan_count")),
        ))

    if not records:
        raise HTTPException(status_code=422, detail="文件中没有有效数据行")

    if len(records) > 1000:
        raise HTTPException(status_code=413, detail=f"单次导入不得超过 1000 条，当前 {len(records)} 条")

    for rec in records:
        db.add(rec)
    await db.commit()
    return {"status": "ok", "count": len(records), "file": file.filename}


@admin.post("/majors/import")
async def admin_import_majors_file(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(get_admin_user),
):
    """管理端：通过 Excel/CSV 文件导入专业

    要求列名：院校名称/院校ID, 专业名称/name, 专业代码/code, 学位类型/degree,
    学制/duration, 学科门类/subject_category, 选科要求/subject_requirement,
    就业率/employment_rate, 平均薪资/avg_salary, 就业方向/career_directions,
    是否重点/is_key, 专业简介/intro
    """
    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="文件大小不得超过 10MB")

    df = _parse_upload_file(content, file.filename or "")
    df.columns = [str(c).strip().lower() for c in df.columns]

    col_map = {
        "院校名称": "university_name", "院校": "university_name", "university_name": "university_name",
        "院校id": "university_id", "university_id": "university_id",
        "专业名称": "name", "name": "name",
        "专业代码": "code", "code": "code",
        "学位类型": "degree", "degree": "degree",
        "学制": "duration", "duration": "duration",
        "学科门类": "subject_category", "subject_category": "subject_category",
        "选科要求": "subject_requirement", "subject_requirement": "subject_requirement",
        "就业率": "employment_rate", "employment_rate": "employment_rate",
        "平均薪资": "avg_salary", "avg_salary": "avg_salary",
        "就业方向": "career_directions", "career_directions": "career_directions",
        "是否重点": "is_key", "is_key": "is_key",
        "专业简介": "intro", "intro": "intro",
    }
    rename_dict = {col: col_map[col] for col in df.columns if col in col_map}
    df = df.rename(columns=rename_dict)

    if "university_id" not in df.columns and "university_name" not in df.columns:
        raise HTTPException(status_code=422, detail="文件必须包含「院校ID」或「院校名称」列")
    if "name" not in df.columns:
        raise HTTPException(status_code=422, detail="文件必须包含「专业名称」列")

    if "university_id" not in df.columns:
        names = df["university_name"].dropna().unique().tolist()
        rows = (
            await db.execute(select(University.id, University.name).where(University.name.in_(names)))
        ).all()
        name_map = {r[1]: r[0] for r in rows}
        df["university_id"] = df["university_name"].map(lambda n: name_map.get(str(n).strip(), 0))
        unmatched = df[df["university_id"] == 0]
        if len(unmatched) > 0:
            missing_names = unmatched["university_name"].unique().tolist()[:10]
            raise HTTPException(
                status_code=422,
                detail=f"以下院校名称未匹配到记录：{missing_names}，请先在院校管理中添加",
            )

    records = []
    for _, row in df.iterrows():
        uid = _safe_int(row.get("university_id"))
        if uid <= 0:
            continue
        is_key_val = str(row.get("is_key", "")).strip().lower()
        records.append(Major(
            university_id=uid,
            name=str(row.get("name", "")).strip(),
            code=str(row.get("code", "")).strip(),
            degree=str(row.get("degree", "")).strip(),
            duration=str(row.get("duration", "4年")).strip() or "4年",
            subject_category=str(row.get("subject_category", "")).strip(),
            subject_requirement=str(row.get("subject_requirement", "")).strip(),
            intro=str(row.get("intro", "")).strip(),
            employment_rate=_safe_float(row.get("employment_rate")),
            avg_salary=_safe_float(row.get("avg_salary")),
            career_directions=str(row.get("career_directions", "")).strip(),
            is_key=is_key_val in ("true", "1", "yes", "是", "重点"),
        ))

    if not records:
        raise HTTPException(status_code=422, detail="文件中没有有效数据行")

    if len(records) > 500:
        raise HTTPException(status_code=413, detail=f"单次导入不得超过 500 条，当前 {len(records)} 条")

    for rec in records:
        db.add(rec)
    await db.commit()
    return {"status": "ok", "count": len(records), "file": file.filename}
