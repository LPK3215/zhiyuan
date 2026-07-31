"""
智愿（Zhiyuan）AI Agent 工具层 —— 将数据访问能力封装为 LLM 可调用的 Function Tools。

设计原则：
  1. 每个工具函数签名与 OpenAI function calling 规范对齐（name + description + parameters schema）
  2. 工具内部不直接操作数据库，全部委托给 ZhiyuanRepository
  3. 参数校验在工具入口完成（白名单/范围检查），避免无效查询穿透到数据库层
  4. 返回统一的 {"success": bool, "data": ..., "error": str|None} 结构
  5. 所有异常在工具内部捕获，绝不向 LLM 泄露调用栈

优化记录：
  - 2026-07-31：概率公式统一引用 estimate_admission_probability、类型注解全覆盖、
    边界条件完善（空结果、空参数、非法值）、异常细分捕获
"""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any

from yuxi.agents.toolkits.registry import tool
from yuxi.storage.postgres.manager import pg_manager  # 数据库会话管理器
from yuxi.repositories.zhiyuan_repository import (
    DatabaseError,
    DataNotFoundError,
    InvalidParameterError,
    RepositoryError,
    estimate_admission_probability,
    zhiyuan_repository,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# 工具实现
# ---------------------------------------------------------------------------


def _success(data: Any) -> dict[str, Any]:
    """构造成功响应。"""
    return {"success": True, "data": data, "error": None}


def _error(msg: str) -> dict[str, Any]:
    """构造错误响应。"""
    return {"success": False, "data": None, "error": msg}


# ---- 院校查询工具 -----------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="搜索院校")
async def search_universities(
    keyword: str = "",
    province: str = "",
    level: str = "",
    school_type: str = "",
    limit: int = 20,
    offset: int = 0,
) -> dict[str, Any]:
    """
    搜索院校列表，支持按关键词、省份、层次、类型筛选。

    Args:
        keyword: 院校名称关键词（模糊搜索）
        province: 省份名称（如"北京"、"广东"）
        level: 院校层次（985/211/双一流/普通）
        school_type: 院校类型（综合/理工/师范/农林/医药/语言/财经/政法/体育/艺术/民族/军事）
        limit: 返回数量上限（默认20，最大50）
        offset: 分页偏移量

    Returns:
        包含院校列表和总数的响应
    """
    try:
        # 参数校验
        limit = min(max(1, limit), 50)

        async with pg_manager.get_async_session_context() as session:
            result = await zhiyuan_repository.list_universities(
                session,
                keyword=keyword or None,
                province=province or None,
                level=level or None,
                school_type=school_type or None,
                limit=limit,
                offset=offset,
            )
        return _success(result)
    except InvalidParameterError as e:
        logger.warning(f"search_universities 参数错误: {e}")
        return _error(str(e))
    except (DatabaseError, RepositoryError) as e:
        logger.error(f"search_universities 数据库错误: {e}")
        return _error("院校查询服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"search_universities 未知错误: {e}")
        return _error(f"院校查询失败: {e}")


@tool(category="zhiyuan", tags=["志愿填报"], display_name="院校详情")
async def get_university_detail(
    university_name: str,
) -> dict[str, Any]:
    """
    获取指定院校的详细信息，包括基本信息、开设专业列表。

    Args:
        university_name: 院校全名（如"北京大学"）

    Returns:
        院校详情（含专业列表）
    """
    if not university_name or not university_name.strip():
        return _error("院校名称不能为空")

    try:
        async with pg_manager.get_async_session_context() as session:
            detail = await zhiyuan_repository.get_university_detail(
                session, university_name.strip()
            )
        if detail is None:
            return _error(f"未找到院校: {university_name}")
        return _success(detail)
    except DatabaseError as e:
        logger.error(f"get_university_detail 数据库错误: {e}")
        return _error("院校详情查询服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"get_university_detail 未知错误: {e}")
        return _error(f"院校详情查询失败: {e}")


# ---- 录取分数查询工具 -------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="查历年录取分")
async def query_admission_scores(
    university_name: str,
    province: str,
    subject_type: str,
    years: int = 3,
) -> dict[str, Any]:
    """
    查询指定院校在特定省份的历年录取分数和位次。

    Args:
        university_name: 院校全名
        province: 省份
        subject_type: 科类（理科/文科/物理类/历史类）
        years: 查询近N年数据（默认3年）

    Returns:
        历年录取分数和位次列表
    """
    if not university_name or not university_name.strip():
        return _error("院校名称不能为空")
    if not province:
        return _error("省份不能为空")
    if not subject_type:
        return _error("科类不能为空")

    try:
        async with pg_manager.get_async_session_context() as session:
            scores = await zhiyuan_repository.query_admission_scores(
                session,
                university_name=university_name.strip(),
                province=province.strip(),
                subject_type=subject_type.strip(),
                years=min(max(1, years), 5),
            )
        return _success(scores)
    except InvalidParameterError as e:
        return _error(str(e))
    except DatabaseError as e:
        logger.error(f"query_admission_scores 数据库错误: {e}")
        return _error("录取分数查询服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"query_admission_scores 未知错误: {e}")
        return _error(f"录取分数查询失败: {e}")


# ---- 位次估算工具 -----------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="分数转位次")
async def estimate_rank(
    score: int,
    province: str,
    subject_type: str,
) -> dict[str, Any]:
    """
    根据高考分数估算省位次。

    Args:
        score: 高考分数（200-750）
        province: 省份
        subject_type: 科类（理科/文科/物理类/历史类）

    Returns:
        估算的省位次
    """
    try:
        async with pg_manager.get_async_session_context() as session:
            rank = await zhiyuan_repository.get_score_rank(
                session,
                score=score,
                province=province,
                subject_type=subject_type,
            )
        if rank is None:
            return _error(
                f"未能根据 {province} {subject_type} {score}分 估算位次，请手动提供位次"
            )
        return _success({"rank": rank["rank"], "same_score_count": rank["same_score_count"], "score": score})
    except InvalidParameterError as e:
        return _error(str(e))
    except DatabaseError as e:
        logger.error(f"estimate_rank 数据库错误: {e}")
        return _error("位次估算服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"estimate_rank 未知错误: {e}")
        return _error(f"位次估算失败: {e}")


# ---- 志愿方案生成工具 -------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="生成志愿方案")
async def generate_plan(
    score: int,
    rank: int,
    province: str,
    subject_type: str,
    subject_combination: str = "",
) -> dict[str, Any]:
    """
    生成冲稳保三档志愿方案。

    Args:
        score: 高考分数（200-750）
        rank: 省位次
        province: 省份
        subject_type: 科类（理科/文科/物理类/历史类）
        subject_combination: 选科组合（如"物理+化学+生物"，可选）

    Returns:
        冲稳保三档院校方案及概率分析
    """
    try:
        async with pg_manager.get_async_session_context() as session:
            plan = await zhiyuan_repository.generate_plan(
                session,
                score=score,
                rank=rank,
                province=province,
                subject_type=subject_type,
                subject_combination=subject_combination,
            )

        # 为 AI 生成友好的文本摘要
        summary_text = _build_plan_summary(plan)

        return _success({
            "plan": plan,
            "summary_text": summary_text,
        })
    except InvalidParameterError as e:
        return _error(str(e))
    except DatabaseError as e:
        logger.error(f"generate_plan 数据库错误: {e}")
        return _error("志愿方案生成服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"generate_plan 未知错误: {e}")
        return _error(f"志愿方案生成失败: {e}")


def _build_plan_summary(plan: dict[str, Any] | None) -> str:
    """为 AI 构建人类可读的方案摘要文本。"""
    if plan is None:
        return "暂无可用的志愿方案数据"
    s = plan.get("summary", {})
    parts = [
        f"志愿方案共 {s.get('total', 0)} 所院校：",
        f"冲一冲 {s.get('rush_count', 0)} 所（录取概率 15%-70%）",
        f"稳一稳 {s.get('stable_count', 0)} 所（录取概率 70%-95%）",
        f"保一保 {s.get('safe_count', 0)} 所（录取概率 95%+）",
    ]

    # 每个档位前 3 所
    for category, label in [("rush", "冲"), ("stable", "稳"), ("safe", "保")]:
        items = plan.get(category) or []
        if items:
            top3 = items[:3]
            names = [
                f"{u['university_name']}({int(u.get('probability', 0) * 100)}%)"
                for u in top3
                if u.get('university_name')
            ]
            if names:
                parts.append(f"{label}档前3：{'、'.join(names)}")

    return "\n".join(parts)


# ---- 院校对比工具 -----------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="院校对比")
async def compare_universities(
    university_names: list[str],
    province: str,
    subject_type: str,
) -> dict[str, Any]:
    """
    对比多所院校的录取数据和专业设置。

    Args:
        university_names: 院校名称列表（最多5所）
        province: 省份
        subject_type: 科类

    Returns:
        各院校的对比数据（录取分数、位次、概率、专业）
    """
    if not university_names:
        return _error("请至少提供一所院校名称")
    if len(university_names) > 5:
        return _error("最多同时对比 5 所院校")

    try:
        async with pg_manager.get_async_session_context() as session:
            # 串行查询（AsyncSession 不支持并发 execute）
            comparisons: list[dict[str, Any]] = []
            for name in university_names:
                n = name.strip()
                if not n:
                    continue
                try:
                    detail = await zhiyuan_repository.get_university_detail(session, n)
                    if detail:
                        scores = await zhiyuan_repository.query_admission_scores(
                            session,
                            university_name=n,
                            province=province,
                            subject_type=subject_type,
                        )
                        detail["admission_scores"] = scores
                        comparisons.append(detail)
                except (DatabaseError, DataNotFoundError):
                    continue

            if not comparisons:
                return _error("未找到任何可对比的院校数据")

            return _success({"comparisons": comparisons, "count": len(comparisons)})
    except InvalidParameterError as e:
        return _error(str(e))
    except Exception as e:
        logger.exception(f"compare_universities 失败: {e}")
        return _error(f"院校对比失败: {e}")


# ---- 知识图谱查询工具 -------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="知识图谱查询")
async def query_knowledge_graph(
    entity: str,
    relation_type: str = "",
    depth: int = 2,
) -> dict[str, Any]:
    """
    查询知识图谱，探索院校、专业之间的关系。

    Args:
        entity: 实体名称（院校名或专业名）
        relation_type: 关系类型过滤（has_major/same_level/same_province/belongs_to，空字符串表示全部）
        depth: 遍历深度（1-4，默认2）

    Returns:
        关系列表
    """
    if not entity or not entity.strip():
        return _error("实体名称不能为空")

    try:
        async with pg_manager.get_async_session_context() as session:
            relations = await zhiyuan_repository.query_graph(
                session,
                start_entity=entity.strip(),
                relation_type=relation_type or None,
                depth=depth,
            )
        if not relations:
            return _error(f"未找到与 '{entity}' 相关的图谱关系")
        return _success({"relations": relations, "count": len(relations)})
    except DatabaseError as e:
        logger.error(f"query_knowledge_graph 数据库错误: {e}")
        return _error("图谱查询服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"query_knowledge_graph 未知错误: {e}")
        return _error(f"图谱查询失败: {e}")


# ---- 政策检索工具 -----------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="政策检索")
async def search_policy(
    question: str,
    top_k: int = 5,
) -> dict[str, Any]:
    """
    搜索高考政策、院校招生政策相关信息。

    Args:
        question: 用户问题（如"什么是平行志愿"）
        top_k: 返回结果数量（默认5）

    Returns:
        相关政策信息列表
    """
    if not question or len(question.strip()) < 2:
        return _error("问题至少需要 2 个字符")

    try:
        async with pg_manager.get_async_session_context() as session:
            result = await zhiyuan_repository.search_policy(
                session,
                question=question.strip(),
                top_k=min(max(1, top_k), 10),
            )
        if result.get("total", 0) == 0:
            q_display = question[:30] + ("..." if len(question) > 30 else "")
            return _error(f"未找到与 '{q_display}' 相关的政策信息")
        return _success(result)
    except InvalidParameterError as e:
        return _error(str(e))
    except DatabaseError as e:
        logger.error(f"search_policy 数据库错误: {e}")
        return _error("政策检索服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"search_policy 未知错误: {e}")
        return _error(f"政策检索失败: {e}")


# ---- 录取概率分析工具 -------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="录取概率分析")
async def analyze_admission_probability(
    user_rank: int,
    university_name: str,
    province: str,
    subject_type: str,
) -> dict[str, Any]:
    """
    分析用户被指定院校录取的概率。

    Args:
        user_rank: 用户省位次
        university_name: 目标院校全名
        province: 省份
        subject_type: 科类

    Returns:
        录取概率分析（含概率值、历年趋势、建议）
    """
    if user_rank <= 0:
        return _error("位次必须为正数")
    if not university_name or not university_name.strip():
        return _error("院校名称不能为空")

    try:
        async with pg_manager.get_async_session_context() as session:
            scores = await zhiyuan_repository.query_admission_scores(
                session,
                university_name=university_name.strip(),
                province=province,
                subject_type=subject_type,
            )

            if not scores:
                return _error(
                    f"未找到 {university_name} 在 {province} {subject_type} 的录取数据"
                )

            # 计算平均位次和概率
            ranks = [s["avg_rank"] for s in scores if s.get("avg_rank")]
            if not ranks:
                return _error(f"{university_name} 缺少位次数据，无法分析")

            avg_rank = sum(ranks) / len(ranks)
            ratio = user_rank / avg_rank if avg_rank > 0 else float("inf")
            probability = estimate_admission_probability(ratio)
            prob_pct = int(probability * 100)

            # 历年趋势
            trend = _analyze_rank_trend(scores)

            # 生成建议文本
            if probability >= 0.85:
                suggestion = f"录取概率很高（{prob_pct}%），可作为保底志愿。"
            elif probability >= 0.70:
                suggestion = f"录取概率较高（{prob_pct}%），适合作为稳妥志愿。"
            elif probability >= 0.35:
                suggestion = f"有一定录取概率（{prob_pct}%），可尝试冲刺。"
            else:
                suggestion = f"录取概率较低（{prob_pct}%），建议慎重考虑。"

            return _success({
                "university_name": university_name,
                "user_rank": user_rank,
                "avg_rank": int(avg_rank),
                "ratio": round(ratio, 2),
                "probability": probability,
                "probability_percent": prob_pct,
                "trend": trend,
                "suggestion": suggestion,
                "scores": scores,
            })
    except InvalidParameterError as e:
        return _error(str(e))
    except DatabaseError as e:
        logger.error(f"analyze_admission_probability 数据库错误: {e}")
        return _error("录取概率分析服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"analyze_admission_probability 未知错误: {e}")
        return _error(f"录取概率分析失败: {e}")


def _analyze_rank_trend(
    scores: list[dict[str, Any]],
) -> str:
    """
    分析历年位次趋势（上升/下降/平稳）。

    Args:
        scores: 历年录取数据（按年份降序）

    Returns:
        趋势描述文本
    """
    if len(scores) < 2:
        return "数据不足，无法判断趋势"

    ranks = [(s["year"], s["avg_rank"]) for s in scores if s.get("avg_rank")]
    ranks.sort(key=lambda x: x[0])  # 按年份升序

    if len(ranks) < 2:
        return "数据不足，无法判断趋势"

    first_rank = ranks[0][1]
    last_rank = ranks[-1][1]

    if first_rank == 0:
        return "数据异常，无法判断趋势"

    change_pct = (last_rank - first_rank) / first_rank

    if change_pct < -0.1:
        return f"位次逐年上升（{abs(int(change_pct * 100))}%），录取难度降低"
    elif change_pct > 0.1:
        return f"位次逐年下降（{int(change_pct * 100)}%），录取难度增加"
    else:
        return "位次相对稳定，录取难度变化不大"


# ---- 系统工具 ---------------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="系统状态")
async def get_system_status() -> dict[str, Any]:
    """
    查询系统运行状态和数据概览。

    Returns:
        系统健康状态、数据统计
    """
    try:
        async with pg_manager.get_async_session_context() as session:
            # 串行查询（AsyncSession 不支持并发 execute）
            health = await zhiyuan_repository.get_health(session)
            stats = await zhiyuan_repository.get_statistics(session)

        return _success({
            "health": health,
            "statistics": stats,
            "timestamp": datetime.now().isoformat(),
        })
    except Exception as e:
        logger.exception(f"get_system_status 失败: {e}")
        return _error(f"系统状态查询失败: {e}")


# ---- 推荐专业工具 -----------------------------------------------------------


@tool(category="zhiyuan", tags=["志愿填报"], display_name="推荐专业")
async def recommend_majors(
    score: int,
    province: str,
    subject_type: str,
    interests: str = "",
) -> dict[str, Any]:
    """
    根据分数和兴趣推荐适合的专业。

    Args:
        score: 高考分数
        province: 省份
        subject_type: 科类
        interests: 兴趣方向（如"计算机"、"医学"，可选）

    Returns:
        推荐专业列表
    """
    try:
        async with pg_manager.get_async_session_context() as session:
            # 先估算位次
            rank_data = await zhiyuan_repository.get_score_rank(
                session, score=score, province=province, subject_type=subject_type
            )
            if rank_data is None:
                return _error("无法估算位次，请确认分数和省份信息")

            rank_value = rank_data["rank"]

            # 获取该位次附近的院校方案作为参考
            plan = await zhiyuan_repository.generate_plan(
                session,
                score=score,
                rank=rank_value,
                province=province,
                subject_type=subject_type,
            )

            # 从方案中提取专业
            all_majors: list[dict[str, Any]] = []
            seen_majors: set = set()

            for category in ("rush", "stable", "safe"):
                for uni in plan.get(category, []):
                    for major in uni.get("majors", []):
                        mname = major.get("major_name", "")
                        if mname and mname not in seen_majors:
                            seen_majors.add(mname)
                            all_majors.append({
                                "major_name": mname,
                                "plan_count": major.get("plan_count", 0),
                                "university_name": uni["university_name"],
                                "category": category,
                            })

            # 如果有兴趣方向，优先匹配
            if interests:
                interest_lower = interests.strip().lower()
                matched = [
                    m for m in all_majors
                    if interest_lower in m["major_name"].lower()
                ]
                if matched:
                    all_majors = matched + [
                        m for m in all_majors if m not in matched
                    ]

            return _success({
                "recommendations": all_majors[:20],
                "total": len(all_majors),
                "user_rank": rank_value,
            })
    except InvalidParameterError as e:
        return _error(str(e))
    except DatabaseError as e:
        logger.error(f"recommend_majors 数据库错误: {e}")
        return _error("专业推荐服务暂不可用，请稍后重试")
    except Exception as e:
        logger.exception(f"recommend_majors 未知错误: {e}")
        return _error(f"专业推荐失败: {e}")



