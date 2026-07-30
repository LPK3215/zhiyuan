"""智愿 - 高考志愿填报工具集（13个工具）"""

import json

from pydantic import BaseModel, Field

from yuxi.agents.toolkits.registry import tool
from yuxi.utils import logger


# ========== 共享 helper ==========

import time as _time

# 轻量 TTL 缓存（院校名称→ID映射，避免同一轮对话重复查库）
_uni_cache: dict[str, tuple[dict | None, float]] = {}
_CACHE_TTL = 120  # 秒
_CACHE_MAX_SIZE = 500  # 容量上限：防止长期运行时缓存键无限增长


def _prune_uni_cache(now: float) -> None:
    """缓存维护：先清过期项；仍超限则按最旧时间戳淘汰（近似 LRU）。"""
    expired = [k for k, (_, ts) in _uni_cache.items() if (now - ts) >= _CACHE_TTL]
    for k in expired:
        _uni_cache.pop(k, None)
    if len(_uni_cache) >= _CACHE_MAX_SIZE:
        # 按写入时间升序淘汰最旧的 20%，摊薄单次清理成本
        oldest = sorted(_uni_cache.items(), key=lambda kv: kv[1][1])
        for k, _ in oldest[: max(1, _CACHE_MAX_SIZE // 5)]:
            _uni_cache.pop(k, None)


async def _resolve_university(repo, name: str) -> dict | None:
    """带缓存的院校名称解析"""
    now = _time.time()
    cached = _uni_cache.get(name)
    if cached and (now - cached[1]) < _CACHE_TTL:
        return cached[0]
    result = await repo.get_university_by_name(name)
    if len(_uni_cache) >= _CACHE_MAX_SIZE:
        _prune_uni_cache(now)
    _uni_cache[name] = (result, now)
    return result


async def _with_repo(coro_factory):
    """统一session管理 + 异常兜底（工具层不抛异常，返回错误文本）"""
    try:
        from yuxi.storage.postgres.manager import pg_manager

        async with pg_manager.get_async_session_context() as session:
            from yuxi.repositories.zhiyuan_repository import ZhiyuanRepository

            repo = ZhiyuanRepository(session)
            return await coro_factory(repo)
    except Exception as e:
        logger.error(f"[zhiyuan_tool] 执行失败: {type(e).__name__}: {e}")
        return f"工具执行异常：{type(e).__name__}，请稍后重试"


# ========== 查询类工具（6个） ==========


class QueryAdmissionScoresInput(BaseModel):
    """查历年录取分输入"""

    university_name: str = Field(description="院校名称，如'清华大学'、'浙江大学'")
    province: str = Field(default="", description="省份，如'河南'、'山东'")
    year: int = Field(default=0, description="查询年份，0表示查最近3年")
    subject_type: str = Field(default="", description="科类：理科/文科/物理类/历史类/综合改革")


@tool(category="buildin", tags=["志愿填报"], display_name="查历年录取分", args_schema=QueryAdmissionScoresInput)
async def query_admission_scores(
    university_name: str, province: str = "", year: int = 0, subject_type: str = ""
) -> str:
    """查询院校/专业的历年录取分数线和位次。

    当用户想了解某所学校往年录取情况时使用。返回近几年的最低分、最高分、平均分和最低位次。
    必须提供院校名称，省份和科类可选但建议提供以精确匹配。
    """
    async def _query(repo):
        uni = await _resolve_university(repo, university_name)
        if not uni:
            return f"未找到院校：{university_name}"
        scores = await repo.query_admission_scores(
            university_id=uni["id"],
            province=province,
            year=year,
            subject_type=subject_type,
        )
        if not scores:
            return f"{uni['name']} 在 {province or '全国'} 暂无录取数据"
        # 附带院校名
        for s in scores:
            s["university_name"] = uni["name"]
        return json.dumps(scores, ensure_ascii=False, indent=2)

    return await _with_repo(_query)


class GetScoreRankInput(BaseModel):
    """查位次输入"""

    score: int = Field(description="高考分数")
    province: str = Field(description="省份，如'河南'")
    year: int = Field(description="年份，如2025")
    subject_type: str = Field(default="", description="科类：理科/文科/物理类/历史类")


@tool(category="buildin", tags=["志愿填报"], display_name="查位次", args_schema=GetScoreRankInput)
async def get_score_rank(score: int, province: str, year: int, subject_type: str = "") -> str:
    """根据高考分数查询一分一段表，获取对应位次（全省排名）。

    位次是志愿填报最核心的参考指标，比分数更稳定。当用户告知分数后，必须调用此工具获取位次。
    """
    async def _query(repo):
        result = await repo.get_rank_by_score(score, province, year, subject_type)
        if not result:
            # 尝试找最近的
            result = await repo.get_nearest_rank(score, province, year, subject_type)
        if not result:
            return f"未找到 {province} {year}年 {score}分的位次数据"
        return json.dumps(result, ensure_ascii=False)

    return await _with_repo(_query)


class GetUniversityDetailInput(BaseModel):
    """院校详情输入"""

    university_name: str = Field(description="院校名称")


@tool(category="buildin", tags=["志愿填报"], display_name="院校详情", args_schema=GetUniversityDetailInput)
async def get_university_detail(university_name: str) -> str:
    """查询院校的详细信息，包括层次(985/211/双一流)、类型、所在城市、硕博点数量、重点学科等。

    当用户想了解某所学校的基本情况时使用。
    """
    async def _query(repo):
        uni = await _resolve_university(repo, university_name)
        if not uni:
            return f"未找到院校：{university_name}"
        # 附带专业列表概要
        majors = await repo.get_majors_by_university(uni["id"])
        uni["major_count"] = len(majors)
        uni["major_names"] = [m["name"] for m in majors[:30]]
        return json.dumps(uni, ensure_ascii=False, indent=2)

    return await _with_repo(_query)


class GetProvincePlanInput(BaseModel):
    """招生计划输入"""

    university_name: str = Field(description="院校名称")
    province: str = Field(description="招生省份")
    year: int = Field(default=0, description="年份，0表示最新")


@tool(category="buildin", tags=["志愿填报"], display_name="招生计划", args_schema=GetProvincePlanInput)
async def get_province_plan(university_name: str, province: str, year: int = 0) -> str:
    """查询某院校在指定省份的招生计划（各专业招生人数、学费、批次等）。

    当用户想知道某校在某省招多少人、哪些专业招生时使用。
    """
    async def _query(repo):
        uni = await _resolve_university(repo, university_name)
        if not uni:
            return f"未找到院校：{university_name}"
        plans = await repo.get_enrollment_plan(uni["id"], province, year)
        if not plans:
            return f"{uni['name']} 在 {province} 暂无招生计划数据"
        for p in plans:
            p["university_name"] = uni["name"]
        return json.dumps(plans, ensure_ascii=False, indent=2)

    return await _with_repo(_query)


class GetEmploymentDataInput(BaseModel):
    """就业数据输入"""

    university_name: str = Field(default="", description="院校名称")
    major_name: str = Field(default="", description="专业名称")


@tool(category="buildin", tags=["志愿填报"], display_name="就业数据", args_schema=GetEmploymentDataInput)
async def get_employment_data(university_name: str = "", major_name: str = "") -> str:
    """查询专业的就业率、平均薪资和就业方向。

    当用户关心某个专业毕业后好不好找工作、薪资如何时使用。
    至少提供院校名称或专业名称之一。
    """
    if not university_name and not major_name:
        return "请提供院校名称或专业名称"

    async def _query(repo):
        if university_name and not major_name:
            uni = await _resolve_university(repo, university_name)
            if not uni:
                return f"未找到院校：{university_name}"
            majors = await repo.get_majors_by_university(uni["id"])
        else:
            majors = await repo.search_majors(name=major_name, limit=20)

        if not majors:
            return "未找到相关专业数据"

        # 只返回有就业数据的
        data = [
            {
                "name": m["name"],
                "employment_rate": m["employment_rate"],
                "avg_salary": m["avg_salary"],
                "career_directions": m["career_directions"],
            }
            for m in majors
            if m["employment_rate"] > 0 or m["avg_salary"] > 0
        ]
        if not data:
            return "暂无就业统计数据"
        return json.dumps(data, ensure_ascii=False, indent=2)

    return await _with_repo(_query)


class QueryGraphInput(BaseModel):
    """知识图谱查询输入"""

    start_entity: str = Field(description="起始实体名称，如'计算机科学与技术'、'清华大学'")
    relation_type: str = Field(default="", description="关系类型：开设/属于/对应职业/前置学科，空表示所有关系")
    depth: int = Field(default=2, ge=1, le=4, description="探索深度，默认2层，最大4层")


# 图谱关系类型白名单（防止 relation_type 被注入到 Cypher 模式）
_GRAPH_RELATION_WHITELIST = {
    "belongs_to",
    "has_major",
    "located_in",
    "employed_by",
    "requires",
    "offers",
    "adjacent_to",
}


@tool(category="buildin", tags=["志愿填报"], display_name="知识图谱查询", args_schema=QueryGraphInput)
async def query_graph(start_entity: str, relation_type: str = "", depth: int = 2) -> str:
    """在知识图谱中查询实体关系（院校-专业-学科-职业之间的关联）。

    当用户想了解某个专业对应什么职业、某校开了哪些专业、某学科的前置知识等关系时使用。
    """
    try:
        from yuxi.knowledge.runtime import knowledge_base

        # 使用Yuxi已有的Neo4j图谱查询能力
        retrievers = knowledge_base.get_retrievers()
        if not retrievers:
            return "知识图谱服务未就绪"

        # 输入校验：实体名必须非空且长度受限，避免空串/超大串爆破图库
        clean_entity = (start_entity or "").strip()
        if not clean_entity:
            return "实体名称不能为空"
        if len(clean_entity) > 100:
            return "实体名称过长（上限 100 字符）"

        # 资源防护：depth 钳制在 [1, 4]，避免 LLM 传入极大 depth 触发 Neo4j
        # 可变长度路径（*1..N）在匹配阶段的资源耗尽（LIMIT 不阻止匹配探索）。
        # 默认 2，向后兼容；超出范围静默钳制而非报错，保证工具始终可返回结果。
        safe_depth = max(1, min(int(depth), 4))

        # 安全：relation_type 仅在白名单内才拼入 Cypher 关系模式，避免 Cypher 注入。
        # start_entity 通过参数化 $start_entity 传入，杜绝字符串插值注入。
        safe_rel = relation_type if relation_type in _GRAPH_RELATION_WHITELIST else ""
        rel_filter = f"-[r:{safe_rel}]-" if safe_rel else "-[r]-"
        cypher = (
            f"MATCH path = (n {{name: $start_entity}}){rel_filter}*1..{safe_depth}(m) "
            f"RETURN n.name AS start, type(r) AS relation, m.name AS target LIMIT 50"
        )

        # 通过Yuxi图谱接口执行
        graph_db = getattr(knowledge_base, "graph", None)
        if graph_db is None:
            return "图谱模块未启用（需要Neo4j服务）"

        results = await graph_db.query(cypher, {"start_entity": clean_entity})
        if not results:
            return f"未找到与 '{clean_entity}' 相关的图谱关系"
        return json.dumps(results, ensure_ascii=False, indent=2)

    except Exception as e:
        logger.error(f"图谱查询失败: {e}")
        return f"图谱查询失败: {str(e)}"


# ========== 计算类工具（5个） ==========


class RecommendSchoolsInput(BaseModel):
    """冲稳保推荐输入"""

    rank: int = Field(description="用户位次（全省排名），通过get_score_rank获取")
    province: str = Field(description="省份")
    subject_type: str = Field(default="", description="科类")
    strategy: str = Field(default="all", description="策略：all/rush/stable/safe")


@tool(category="buildin", tags=["志愿填报"], display_name="冲稳保推荐", args_schema=RecommendSchoolsInput)
async def recommend_schools(rank: int, province: str, subject_type: str = "", strategy: str = "all") -> str:
    """基于用户位次，推荐冲/稳/保三档院校。

    这是志愿填报的核心工具。必须先通过get_score_rank获取位次后再调用。
    冲：录取位次高于用户（有难度）；稳：匹配度高；保：录取位次低于用户（兜底）。
    """
    async def _query(repo):
        result = await repo.recommend_by_rank(rank, province, subject_type, strategy)

        # 补充院校名称（复用当前会话，避免嵌套开启新 session；单条 IN 查询避免 N+1）
        all_ids = set()
        for group in result.values():
            for item in group:
                all_ids.add(item["university_id"])

        if all_ids:
            name_map = await repo.get_university_maps(all_ids)
            for group in result.values():
                for item in group:
                    info = name_map.get(item["university_id"], {})
                    item["university_name"] = info.get("name", f"ID:{item['university_id']}")
                    item["level"] = info.get("level", "")

        total = sum(len(v) for v in result.values())
        if total == 0:
            return f"位次 {rank} 在 {province} 暂无匹配推荐（可能数据不足）"

        return json.dumps(result, ensure_ascii=False, indent=2)

    return await _with_repo(_query)


class CalculateProbabilityInput(BaseModel):
    """录取概率输入"""

    rank: int = Field(description="用户位次")
    university_name: str = Field(description="目标院校名称")
    province: str = Field(description="省份")
    years: int = Field(default=3, ge=1, le=5, description="参考年数")


@tool(category="buildin", tags=["志愿填报"], display_name="录取概率", args_schema=CalculateProbabilityInput)
async def calculate_probability(rank: int, university_name: str, province: str, years: int = 3) -> str:
    """估算用户被某院校录取的概率（基于历年位次波动）。

    当用户问"我能不能上XX大学"时使用。返回概率值、历年位次区间和波动情况。
    """
    async def _query(repo):
        uni = await _resolve_university(repo, university_name)
        if not uni:
            return f"未找到院校：{university_name}"
        result = await repo.calculate_probability(rank, uni["id"], province, years)
        result["university_name"] = uni["name"]
        return json.dumps(result, ensure_ascii=False, indent=2)

    return await _with_repo(_query)


class CheckSubjectRequirementInput(BaseModel):
    """选科检查输入"""

    subject_combination: str = Field(description="选科组合，如'物理+化学+生物'或'历史+政治+地理'")
    province: str = Field(default="", description="省份（不同省份选科模式不同）")


@tool(category="buildin", tags=["志愿填报"], display_name="选科检查", args_schema=CheckSubjectRequirementInput)
async def check_subject_requirement(subject_combination: str, province: str = "") -> str:
    """检查给定选科组合能报考哪些专业（过滤选科不符的专业）。

    新高考省份（3+1+2或3+3）有选科限制。当用户告知选科后，推荐前应先检查。
    """
    async def _query(repo):
        compatible = await repo.check_subject_requirement(subject_combination, province)
        if not compatible:
            return f"选科组合 '{subject_combination}' 未匹配到专业数据（可能数据不全）"
        # 精简输出
        summary = [
            {"name": m["name"], "requirement": m["subject_requirement"], "category": m["subject_category"]}
            for m in compatible
        ]
        return json.dumps(
            {"total": len(summary), "majors": summary},
            ensure_ascii=False,
            indent=2,
        )

    return await _with_repo(_query)


class CompareMajorsInput(BaseModel):
    """专业对比输入"""

    major_names: list[str] = Field(description="要对比的专业名称列表，如['计算机科学与技术','软件工程']")
    university_name: str = Field(default="", description="限定在某校内对比（可选）")


@tool(category="buildin", tags=["志愿填报"], display_name="专业对比", args_schema=CompareMajorsInput)
async def compare_majors(major_names: list[str], university_name: str = "") -> str:
    """对比多个专业的学制、学位、就业率、薪资、就业方向等维度。

    当用户在几个专业之间犹豫不决时使用，帮助横向比较。
    """
    if len(major_names) < 2:
        return "请提供至少2个专业名称进行对比"

    async def _query(repo):
        results = await repo.compare_majors(major_names, university_name)
        if not results:
            return f"未找到专业数据：{', '.join(major_names)}"
        return json.dumps(results, ensure_ascii=False, indent=2)

    return await _with_repo(_query)


class RankTrendAnalysisInput(BaseModel):
    """位次趋势输入"""

    university_name: str = Field(description="院校名称")
    province: str = Field(description="省份")
    years: int = Field(default=5, ge=2, le=10, description="分析年数")


@tool(category="buildin", tags=["志愿填报"], display_name="位次趋势", args_schema=RankTrendAnalysisInput)
async def rank_trend_analysis(university_name: str, province: str, years: int = 5) -> str:
    """分析某院校录取位次的历年变化趋势（是在涨还是在跌）。

    当用户想判断某校是否"大小年"、录取难度是否逐年上升时使用。
    """
    async def _query(repo):
        uni = await _resolve_university(repo, university_name)
        if not uni:
            return f"未找到院校：{university_name}"
        trend = await repo.rank_trend(uni["id"], province, years)
        if not trend:
            return f"{uni['name']} 在 {province} 暂无足够年份的位次数据"

        # 计算趋势方向
        ranks = [t["min_rank"] for t in trend]
        if len(ranks) >= 2:
            if ranks[-1] > ranks[0] * 1.1:
                direction = "位次上升（竞争加剧）"
            elif ranks[-1] < ranks[0] * 0.9:
                direction = "位次下降（竞争减缓）"
            else:
                direction = "基本稳定"
        else:
            direction = "数据不足，无法判断趋势"

        return json.dumps(
            {"university_name": uni["name"], "trend": trend, "direction": direction},
            ensure_ascii=False,
            indent=2,
        )

    return await _with_repo(_query)


# ========== 生成类工具（2个） ==========


class GenerateApplicationPlanInput(BaseModel):
    """生成志愿方案输入"""

    profile_json: str = Field(
        description=(
            "用户画像JSON字符串，包含：score(分数), rank(位次), province(省份), "
            "subject_type(科类), subject_combination(选科组合,可选), "
            "preferences(偏好,如城市/专业方向,可选)"
        )
    )


@tool(category="buildin", tags=["志愿填报"], display_name="生成志愿方案", args_schema=GenerateApplicationPlanInput)
async def generate_application_plan(profile_json: str) -> str:
    """汇总用户画像，生成完整的冲稳保志愿方案表。

    这是最终交付物工具。当用户明确要求"帮我出方案"/"生成志愿表"时调用。
    输入用户画像JSON，输出结构化的志愿方案（含院校+专业+批次+概率）。
    调用前必须确保已获取：分数、位次、省份、科类。
    """
    try:
        profile = json.loads(profile_json)
    except json.JSONDecodeError:
        return "profile_json 格式错误，请提供合法JSON"

    required = ["rank", "province"]
    missing = [k for k in required if not profile.get(k)]
    if missing:
        return f"缺少必要字段：{', '.join(missing)}"

    # rank 类型/正数校验：LLM 可能传入字符串或非法值，统一在此转换拦截
    try:
        rank = int(profile["rank"])
    except (TypeError, ValueError):
        return "rank 必须为整数"
    if rank <= 0:
        return "rank 必须为正整数"

    province = profile["province"]
    subject_type = profile.get("subject_type", "")

    async def _generate(repo):
        # 1. 获取冲稳保推荐
        recommendation = await repo.recommend_by_rank(rank, province, subject_type, "all")

        # 2. 补充院校详情（复用当前会话，单条 IN 查询，避免嵌套 session + N+1）
        all_ids = set()
        for group in recommendation.values():
            for item in group:
                all_ids.add(item["university_id"])

        uni_map = await repo.get_university_maps(
            all_ids, fields=("name", "level", "province")
        )

        # 3. 批量取各院校推荐专业（单条 IN 查询，消除逐校 N+1）
        subject_combination = profile.get("subject_combination", "")
        majors_map = await repo.get_university_majors_batch(
            all_ids, province, subject_combination, top_n=3
        ) if all_ids else {}

        # 4. 组装方案（含专业维度，循环内仅查表）
        plan = {"profile": profile, "rush": [], "stable": [], "safe": []}
        for category in ("rush", "stable", "safe"):
            for item in recommendation.get(category, []):
                uni = uni_map.get(item["university_id"], {})
                majors = majors_map.get(item["university_id"], [])
                plan[category].append({
                    "university_name": uni.get("name", f"ID:{item['university_id']}"),
                    "level": uni.get("level", ""),
                    "province": uni.get("province", ""),
                    "avg_rank": item["avg_rank"],
                    "rank_ratio": item["ratio"],
                    "majors": majors,
                })

        plan["summary"] = {
            "total": len(plan["rush"]) + len(plan["stable"]) + len(plan["safe"]),
            "rush_count": len(plan["rush"]),
            "stable_count": len(plan["stable"]),
            "safe_count": len(plan["safe"]),
        }
        return json.dumps(plan, ensure_ascii=False, indent=2)

    return await _with_repo(_generate)


class ExportPlanInput(BaseModel):
    """导出方案输入"""

    plan_json: str = Field(description="generate_application_plan 输出的方案JSON")
    format: str = Field(default="table", description="输出格式：table(文本表格)/json")


@tool(category="buildin", tags=["志愿填报"], display_name="导出方案", args_schema=ExportPlanInput)
async def export_plan(plan_json: str, format: str = "table") -> str:
    """将志愿方案格式化为可读的文本表格或结构化输出。

    在generate_application_plan之后调用，将JSON方案转为用户友好的表格形式。
    """
    try:
        plan = json.loads(plan_json)
    except json.JSONDecodeError:
        return "plan_json 格式错误"

    if format == "json":
        return json.dumps(plan, ensure_ascii=False, indent=2)

    # 文本表格格式
    lines = []
    profile = plan.get("profile", {})
    lines.append(f"【志愿方案】{profile.get('province', '')} | 分数:{profile.get('score', '-')} | 位次:{profile.get('rank', '-')}")
    lines.append("=" * 60)

    for category, label in [("rush", "冲"), ("stable", "稳"), ("safe", "保")]:
        items = plan.get(category, [])
        lines.append(f"\n【{label}】共{len(items)}所")
        for i, item in enumerate(items, 1):
            name = item.get("university_name", "?")
            level = item.get("level", "")
            ratio = item.get("rank_ratio", "")
            level_tag = f"[{level}]" if level else ""
            lines.append(f"  {i:2d}. {name} {level_tag} 位次比:{ratio}")
            for j, m in enumerate(item.get("majors", []), 1):
                req = m.get("subject_requirement")
                req_tag = f" (选科:{req})" if req else ""
                lines.append(
                    f"       · {m.get('major_name', '?')}"
                    f" 计划{m.get('plan_count', '-')}人"
                    f"{req_tag}"
                )

    summary = plan.get("summary", {})
    lines.append(f"\n合计: {summary.get('total', 0)}所 (冲{summary.get('rush_count', 0)}/稳{summary.get('stable_count', 0)}/保{summary.get('safe_count', 0)})")

    return "\n".join(lines)
