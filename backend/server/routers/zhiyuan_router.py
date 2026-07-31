"""
智愿（Zhiyuan）API 路由层 —— FastAPI 端点定义。

职责边界：
  - 仅负责 HTTP 层的请求解析、参数校验、响应序列化
  - 所有业务逻辑委托给 ZhiyuanRepository
  - 统一异常处理：将 RepositoryError 映射为合适的 HTTP 状态码
  - 不直接操作数据库（session 由依赖注入提供）

优化记录：
  - 2026-07-31：统一异常处理中间件、参数白名单校验前移、类型注解全覆盖、
    边界条件处理（空参数、非法值）、缓存失效在写入操作后自动触发
"""

from __future__ import annotations

import functools
import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.ext.asyncio import AsyncSession

from server.utils.auth_middleware import get_db as get_db_session, get_required_user
from yuxi.repositories.zhiyuan_repository import (
    DatabaseError,
    DataNotFoundError,
    InvalidParameterError,
    RepositoryError,
    zhiyuan_repository,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/zhiyuan", tags=["智愿"], dependencies=[Depends(get_required_user)])
zhiyuan = router  # 对外导出别名，保持 server.routers.__init__ 的 `from ... import zhiyuan` 兼容

# ---------------------------------------------------------------------------
# 常量定义（避免魔法数字/字符串散落）
# ---------------------------------------------------------------------------

# 高考分数范围
SCORE_MIN: int = 200
SCORE_MAX: int = 750

# 分页
DEFAULT_PAGE_LIMIT: int = 50
MAX_PAGE_LIMIT: int = 200

# 志愿分档中英文映射（与仓库层保持一致）
PLAN_CATEGORIES: dict[str, str] = {"rush": "冲", "stable": "稳", "safe": "保"}

# ---------------------------------------------------------------------------
# 共享参数校验（避免 5 个 Request Model 中重复定义）
# ---------------------------------------------------------------------------


def _validate_province(v: str) -> str:
    """省份白名单校验（空串放行，配合可选字段）。"""
    from yuxi.repositories.zhiyuan_repository import _VALID_PROVINCES
    if not v:
        return v
    if v not in _VALID_PROVINCES:
        raise ValueError(f"非法省份: {v}")
    return v


def _validate_subject_type(v: str) -> str:
    """科类白名单校验（空串放行，配合可选字段）。"""
    from yuxi.repositories.zhiyuan_repository import _VALID_SUBJECT_TYPES
    if not v:
        return v
    if v not in _VALID_SUBJECT_TYPES:
        raise ValueError(f"非法科类: {v}")
    return v


# ---------------------------------------------------------------------------
# 请求/响应模型
# ---------------------------------------------------------------------------


class PlanGenerateRequest(BaseModel):
    """志愿方案生成请求。"""
    score: int = Field(..., ge=SCORE_MIN, le=SCORE_MAX, description="高考分数")
    rank: int = Field(..., ge=1, description="省位次")
    province: str = Field(..., min_length=1, description="省份")
    subject_type: str = Field(..., min_length=1, description="科类")
    subject_combination: str = Field(default="", description="选科组合")

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class ScoreRankRequest(BaseModel):
    """分数位次查询请求。"""
    score: int = Field(..., ge=SCORE_MIN, le=SCORE_MAX, description="高考分数")
    province: str = Field(..., min_length=1, description="省份")
    subject_type: str = Field(..., min_length=1, description="科类")

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class UniversityQueryParams(BaseModel):
    """院校查询参数。"""
    keyword: str = Field(default="", description="关键词")
    province: str = Field(default="", description="省份")
    level: str = Field(default="", description="层次")
    type: str = Field(default="", description="类型")
    limit: int = Field(default=DEFAULT_PAGE_LIMIT, ge=1, le=MAX_PAGE_LIMIT, description="每页数量")
    offset: int = Field(default=0, ge=0, description="偏移量")


class PolicySearchRequest(BaseModel):
    """政策检索请求。"""
    question: str = Field(..., min_length=2, max_length=500, description="问题")
    top_k: int = Field(default=5, ge=1, le=20, description="返回数量")


class GraphQueryRequest(BaseModel):
    """图谱查询请求。"""
    start_entity: str = Field(..., min_length=1, max_length=100, description="起始实体")
    relation_type: str = Field(default="", description="关系类型")
    depth: int = Field(default=2, ge=1, le=4, description="遍历深度")


class CompareRequest(BaseModel):
    """院校对比请求。"""
    university_names: list[str] = Field(
        ..., min_length=1, max_length=5, description="院校名称列表"
    )
    province: str = Field(..., min_length=1, description="省份")
    subject_type: str = Field(..., min_length=1, description="科类")

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class AdmissionQueryRequest(BaseModel):
    """院校录取详情查询请求。"""
    university_name: str = Field(..., min_length=1, description="院校名称")
    province: str = Field(..., min_length=1, description="省份")
    subject_type: str = Field(..., min_length=1, description="科类")

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class ScoreQueryRequest(BaseModel):
    """录取分数查询请求。"""
    university_name: str = Field(..., min_length=1, description="院校名称")
    province: str = Field(default="", description="省份（可空；缺省时不限省份）")
    subject_type: str = Field(default="", description="科类（可空）")
    years: int = Field(default=3, ge=1, le=5, description="年份数")

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class RecommendRequest(BaseModel):
    """专业推荐请求。"""
    score: int = Field(..., ge=SCORE_MIN, le=SCORE_MAX, description="高考分数")
    province: str = Field(..., min_length=1, description="省份")
    subject_type: str = Field(..., min_length=1, description="科类")
    interests: str = Field(default="", description="兴趣方向（如'计算机'、'医学'）")

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class CompareMajorsRequest(BaseModel):
    """专业对比请求。"""
    major_names: list[str] = Field(
        ..., min_length=1, max_length=10, description="专业名称列表"
    )
    university_names: list[str] = Field(
        default=[], max_length=10, description="院校名称列表（可选，不传则查所有院校）"
    )


# ---------------------------------------------------------------------------
# 异常处理映射
# ---------------------------------------------------------------------------


def _handle_repo_error(e: Exception) -> HTTPException:
    """将 RepositoryError 映射为 HTTPException。"""
    if isinstance(e, InvalidParameterError):
        return HTTPException(status_code=400, detail=str(e))
    if isinstance(e, DataNotFoundError):
        return HTTPException(status_code=404, detail=str(e))
    if isinstance(e, DatabaseError):
        return HTTPException(status_code=503, detail="数据服务暂不可用，请稍后重试")
    if isinstance(e, RepositoryError):
        return HTTPException(status_code=500, detail=str(e))
    return HTTPException(status_code=500, detail=f"服务器内部错误: {e}")


def _route_handler(endpoint_name: str):
    """路由层统一异常处理装饰器，消除 10+ 个端点中的重复 try/except 模式。"""
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                return await func(*args, **kwargs)
            except HTTPException:
                raise
            except RepositoryError as e:
                raise _handle_repo_error(e)
            except Exception as e:
                logger.exception(f"{endpoint_name} 未预期错误")
                raise HTTPException(status_code=500, detail=f"{endpoint_name}失败: {e}")
        return wrapper
    return decorator


# ---------------------------------------------------------------------------
# 院校相关 API
# ---------------------------------------------------------------------------


@router.get("/universities", summary="院校列表查询")
@_route_handler("list_universities")
async def list_universities(
    keyword: str = Query(default="", description="关键词"),
    province: str = Query(default="", description="省份"),
    level: str = Query(default="", description="层次(985/211/双一流/普通)"),
    type: str = Query(default="", description="院校类型"),
    limit: int = Query(default=DEFAULT_PAGE_LIMIT, ge=1, le=MAX_PAGE_LIMIT),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """分页查询院校列表，支持多条件筛选。"""
    return await zhiyuan_repository.list_universities(
        session,
        keyword=keyword or None,
        province=province or None,
        level=level or None,
        school_type=type or None,
        limit=limit,
        offset=offset,
    )


@router.get("/universities/{university_name}", summary="院校详情")
@_route_handler("get_university_detail")
async def get_university_detail(
    university_name: str,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """获取指定院校的详细信息（含专业列表）。录取分数由前端单独调 /scores 获取。"""
    detail = await zhiyuan_repository.get_university_detail(session, university_name)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"未找到院校: {university_name}")
    return detail


@router.post("/universities/compare", summary="院校对比")
@_route_handler("compare_universities")
async def compare_universities(
    req: CompareRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """对比多所院校的录取数据。"""
    async def _fetch_one(name: str) -> dict[str, Any] | None:
        detail = await zhiyuan_repository.get_university_detail(session, name)
        if detail:
            scores = await zhiyuan_repository.query_admission_scores(
                session,
                university_name=name,
                province=req.province,
                subject_type=req.subject_type,
            )
            detail["admission_scores"] = scores
        return detail

    # 串行查询避免 AsyncSession 并发错误（同一 session 不支持 asyncio.gather）
    comparisons = []
    for name in req.university_names:
        result = await _fetch_one(name)
        if result is not None:
            comparisons.append(result)
    return {"comparisons": comparisons, "count": len(comparisons)}


# ---------------------------------------------------------------------------
# 录取分数与位次 API
# ---------------------------------------------------------------------------


@router.post("/scores", summary="查询录取分数")
@_route_handler("query_admission_scores")
async def query_admission_scores(
    req: ScoreQueryRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """查询指定院校的历年录取分数和位次。"""
    scores = await zhiyuan_repository.query_admission_scores(
        session,
        university_name=req.university_name,
        province=req.province,
        subject_type=req.subject_type,
        years=req.years,
    )
    return {"scores": scores, "count": len(scores)}


@router.post("/rank", summary="分数转位次")
@_route_handler("get_score_rank")
async def get_score_rank(
    req: ScoreRankRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """根据分数估算省位次。"""
    result = await zhiyuan_repository.get_score_rank(
        session,
        score=req.score,
        province=req.province,
        subject_type=req.subject_type,
    )
    if result is None:
        raise HTTPException(
            status_code=404,
            detail=f"未找到 {req.province} {req.subject_type} {req.score}分 的位次数据",
        )
    return {
        "rank": result["rank"],
        "score": req.score,
        "same_score_count": result["same_score_count"],
    }


@router.post("/admission", summary="院校录取详情")
@_route_handler("query_university_admission")
async def query_university_admission(
    req: AdmissionQueryRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """查询指定院校的完整录取详情（含分数和计划）。"""
    return await zhiyuan_repository.query_university_admission(
        session,
        university_name=req.university_name,
        province=req.province,
        subject_type=req.subject_type,
    )


# ---------------------------------------------------------------------------
# 志愿方案 API
# ---------------------------------------------------------------------------


@router.post("/plan", summary="生成志愿方案")
@_route_handler("generate_plan")
async def generate_plan(
    req: PlanGenerateRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """生成冲稳保三档志愿方案。"""
    return await zhiyuan_repository.generate_plan(
        session,
        score=req.score,
        rank=req.rank,
        province=req.province,
        subject_type=req.subject_type,
        subject_combination=req.subject_combination,
    )


# ---------------------------------------------------------------------------
# 知识图谱 API
# ---------------------------------------------------------------------------


@router.post("/graph", summary="知识图谱查询")
@_route_handler("query_graph")
async def query_graph(
    req: GraphQueryRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """从指定实体出发查询知识图谱关系。"""
    relations = await zhiyuan_repository.query_graph(
        session,
        start_entity=req.start_entity,
        relation_type=req.relation_type or None,
        depth=req.depth,
    )
    return {"relations": relations, "count": len(relations)}


# ---------------------------------------------------------------------------
# 政策检索 API
# ---------------------------------------------------------------------------


@router.post("/policy/search", summary="政策检索")
@_route_handler("search_policy")
async def search_policy(
    req: PolicySearchRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """搜索高考政策相关信息。"""
    return await zhiyuan_repository.search_policy(
        session,
        question=req.question,
        top_k=req.top_k,
    )


@router.get("/policy/suggestions", summary="政策建议问题")
async def get_policy_suggestions() -> dict[str, Any]:
    """获取推荐的常见问题列表（静态数据，不查库）。"""
    suggestions = [
        "什么是平行志愿？",
        "如何选择冲稳保院校？",
        "投档线和录取线有什么区别？",
        "什么是征集志愿？",
        "新高考选科对专业的影响？",
        "什么是专业级差？",
        "服从调剂的利弊？",
        "如何根据位次选学校？",
        "提前批和普通批的区别？",
        "什么是定向招生？",
    ]
    return {"suggestions": suggestions}


# ---------------------------------------------------------------------------
# 系统 API
# ---------------------------------------------------------------------------


@router.get("/health", summary="系统健康检查")
async def health_check(
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """检查数据库连接和各表数据量。数据库不可用时返回 503。"""
    try:
        return await zhiyuan_repository.get_health(session)
    except Exception as e:
        logger.exception("health_check 失败")
        raise HTTPException(status_code=503, detail=f"健康检查失败: {e}")


@router.get("/statistics", summary="系统统计")
@_route_handler("get_statistics")
async def get_statistics(
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """获取系统数据统计概览。"""
    return await zhiyuan_repository.get_statistics(session)


# ---------------------------------------------------------------------------
# 专业推荐 API
# ---------------------------------------------------------------------------


@router.post("/recommend", summary="推荐专业")
@_route_handler("recommend_majors")
async def recommend_majors(
    req: RecommendRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """根据分数和兴趣推荐适合的专业。"""
    return await zhiyuan_repository.recommend_majors(
        session,
        score=req.score,
        province=req.province,
        subject_type=req.subject_type,
        interests=req.interests,
    )


# ---------------------------------------------------------------------------
# 省份规则 API
# ---------------------------------------------------------------------------


@router.get("/rules/{province}", summary="省份填报规则")
@_route_handler("get_province_rule")
async def get_province_rule(
    province: str,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """获取指定省份的最新填报规则。"""
    return await zhiyuan_repository.get_province_rule(session, province)


# ---------------------------------------------------------------------------
# 专业对比 API
# ---------------------------------------------------------------------------


@router.post("/majors/compare", summary="专业对比")
@_route_handler("compare_majors")
async def compare_majors(
    req: CompareMajorsRequest,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """对比多所院校的同一专业（或多个专业）。"""
    return await zhiyuan_repository.compare_majors(
        session,
        major_names=req.major_names,
        university_names=req.university_names or None,
    )


# ---------------------------------------------------------------------------
# 选科检查 API
# ---------------------------------------------------------------------------


@router.get("/subject-check", summary="选科检查")
@_route_handler("check_subject")
async def check_subject(
    subject_combination: str = Query(..., min_length=1, description="选科组合（如'物理+化学+生物'）"),
    university_name: str = Query(default="", description="院校名称（可选）"),
    major_name: str = Query(default="", description="专业名称（可选模糊匹配）"),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """检查选科组合是否满足院校/专业的选科要求。"""
    return await zhiyuan_repository.check_subject(
        session,
        subject_combination=subject_combination,
        university_name=university_name,
        major_name=major_name,
    )
