"""
智愿 Admin CRUD 路由 —— 管理端数据增删改查。

职责：
  - 面向管理员的数据管理接口（需 admin 权限）
  - 支持分页列表、单条 CRUD、批量导入
  - university_id 存在性校验（防止孤立外键）
  - 重复院校名校验（409 Conflict）

响应格式约定：
  - 列表：{"items": [...], "total": N, "page": P, "size": S}
  - 单条创建：{"id": N, ...fields}
  - 更新/删除：{"ok": true}
  - 批量：{"count": N}
  - 规则列表：直接返回数组（不分页）
"""

from __future__ import annotations

import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from server.utils.auth_middleware import get_db as get_db_session, get_admin_user
from yuxi.repositories.zhiyuan_models import (
    AdmissionScore,
    EnrollmentPlan,
    Major,
    ProvinceRule,
    University,
)
from yuxi.repositories.zhiyuan_repository import (
    _VALID_LEVELS,
    _VALID_PROVINCES,
    _VALID_SUBJECT_TYPES,
    _VALID_TYPES,
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/zhiyuan/admin",
    tags=["智愿-管理端"],
    dependencies=[Depends(get_admin_user)],
)

# 分页约束
DEFAULT_PAGE = 1
DEFAULT_SIZE = 20
MAX_SIZE = 200

# 批量导入上限
BATCH_MAX = 1000


# ---------------------------------------------------------------------------
# 请求模型
# ---------------------------------------------------------------------------


def _validate_province(v: str) -> str:
    if not v:
        return v
    if v not in _VALID_PROVINCES:
        raise ValueError(f"非法省份: {v}")
    return v


def _validate_subject_type(v: str) -> str:
    if not v:
        return v
    if v not in _VALID_SUBJECT_TYPES:
        raise ValueError(f"非法科类: {v}")
    return v


def _validate_level(v: str) -> str:
    if not v:
        return v
    if v not in _VALID_LEVELS:
        raise ValueError(f"非法层次: {v}")
    return v


def _validate_type(v: str) -> str:
    if not v:
        return v
    if v not in _VALID_TYPES:
        raise ValueError(f"非法类型: {v}")
    return v


class UniversityCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    province: str = Field(..., min_length=1)
    city: str = Field(default="")
    level: str = Field(default="")
    type: str = Field(default="")
    nature: str = Field(default="公办")
    website: str = Field(default="")
    intro: str = Field(default="")
    master_points: int = Field(default=0, ge=0)
    doctor_points: int = Field(default=0, ge=0)
    key_disciplines: str = Field(default="")

    validate_province = field_validator("province")(_validate_province)
    validate_level = field_validator("level")(_validate_level)
    validate_type = field_validator("type")(_validate_type)


class UniversityUpdate(UniversityCreate):
    pass


class MajorCreate(BaseModel):
    university_id: int = Field(..., gt=0)
    college_id: int = Field(default=0, ge=0)
    name: str = Field(..., min_length=1, max_length=200)
    code: str = Field(default="")
    degree: str = Field(default="")
    duration: str = Field(default="4年")
    subject_category: str = Field(default="")
    is_key: bool = Field(default=False)
    subject_requirement: str = Field(default="")
    intro: str = Field(default="")
    employment_rate: float = Field(default=0.0, ge=0.0, le=100.0)
    avg_salary: float = Field(default=0.0, ge=0.0)
    career_directions: str = Field(default="")


class MajorUpdate(MajorCreate):
    pass


class ScoreCreate(BaseModel):
    university_id: int = Field(..., gt=0)
    major_id: int = Field(default=0, ge=0)
    province: str = Field(..., min_length=1)
    year: int = Field(..., gt=0)
    subject_type: str = Field(default="")
    batch: str = Field(default="本科一批")
    min_score: int = Field(default=0, ge=0, le=750)
    max_score: int = Field(default=0, ge=0, le=750)
    avg_score: int = Field(default=0, ge=0, le=750)
    min_rank: int = Field(default=0, ge=0)
    plan_count: int = Field(default=0, ge=0)

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class ScoreUpdate(ScoreCreate):
    pass


class PlanCreate(BaseModel):
    university_id: int = Field(..., gt=0)
    major_id: int = Field(default=0, ge=0)
    province: str = Field(..., min_length=1)
    year: int = Field(..., gt=0)
    subject_type: str = Field(default="")
    batch: str = Field(default="本科一批")
    plan_count: int = Field(default=0, ge=0)
    duration: str = Field(default="4年")
    tuition: str = Field(default="")
    remark: str = Field(default="")

    validate_province = field_validator("province")(_validate_province)
    validate_subject_type = field_validator("subject_type")(_validate_subject_type)


class PlanUpdate(PlanCreate):
    pass


class RuleUpsert(BaseModel):
    province: str = Field(..., min_length=1)
    year: int = Field(..., gt=0)
    mode: str = Field(default="")
    batch_count: int = Field(default=0, ge=0)
    max_per_batch: int = Field(default=0, ge=0)
    subject_mode: str = Field(default="")
    description: str = Field(default="")
    tips: str = Field(default="")

    validate_province = field_validator("province")(_validate_province)


# ---------------------------------------------------------------------------
# 辅助函数
# ---------------------------------------------------------------------------


async def _check_university_exists(session: AsyncSession, uid: int) -> None:
    """校验 university_id 存在性，不存在则 422。"""
    result = await session.execute(
        select(University.id).where(University.id == uid)
    )
    if result.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=422,
            detail=f"university_id {uid} 不存在",
        )


async def _check_university_name_unique(
    session: AsyncSession, name: str, exclude_id: int | None = None
) -> None:
    """校验院校名称唯一性，重复则 409。"""
    stmt = select(University.id).where(University.name == name)
    if exclude_id is not None:
        stmt = stmt.where(University.id != exclude_id)
    result = await session.execute(stmt)
    if result.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=409,
            detail=f"院校名称已存在: {name}",
        )


def _paginate(page: int, size: int) -> tuple[int, int]:
    """返回 (offset, limit)。"""
    return (page - 1) * size, size


# ---------------------------------------------------------------------------
# 院校 CRUD
# ---------------------------------------------------------------------------


@router.get("/universities", summary="院校列表（分页）")
async def admin_list_universities(
    keyword: str = Query(default=""),
    province: str = Query(default=""),
    level: str = Query(default=""),
    page: int = Query(default=DEFAULT_PAGE, ge=1),
    size: int = Query(default=DEFAULT_SIZE, ge=1, le=MAX_SIZE),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """分页查询院校列表，支持关键词/省份/层次筛选。"""
    stmt = select(University)
    count_stmt = select(func.count()).select_from(University)

    if keyword:
        stmt = stmt.where(University.name.ilike(f"%{keyword}%"))
        count_stmt = count_stmt.where(University.name.ilike(f"%{keyword}%"))
    if province:
        stmt = stmt.where(University.province == province)
        count_stmt = count_stmt.where(University.province == province)
    if level:
        stmt = stmt.where(University.level == level)
        count_stmt = count_stmt.where(University.level == level)

    total = (await session.execute(count_stmt)).scalar() or 0
    offset, limit = _paginate(page, size)
    rows = (await session.execute(stmt.offset(offset).limit(limit))).scalars().all()

    return {
        "items": [r.to_dict() for r in rows],
        "total": total,
        "page": page,
        "size": size,
    }


@router.post("/universities", summary="新增院校", status_code=status.HTTP_201_CREATED)
async def admin_create_university(
    req: UniversityCreate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """新增院校，校验名称唯一性。"""
    await _check_university_name_unique(session, req.name)

    uni = University(**req.model_dump())
    session.add(uni)
    await session.commit()
    await session.refresh(uni)
    return {"id": uni.id, **uni.to_dict()}


@router.put("/universities/{university_id}", summary="更新院校")
async def admin_update_university(
    university_id: int,
    req: UniversityUpdate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """更新指定院校。"""
    uni = await session.get(University, university_id)
    if uni is None:
        raise HTTPException(status_code=404, detail=f"院校不存在: {university_id}")

    await _check_university_name_unique(session, req.name, exclude_id=university_id)

    for k, v in req.model_dump().items():
        setattr(uni, k, v)
    await session.commit()
    await session.refresh(uni)
    return {"ok": True, **uni.to_dict()}


@router.delete("/universities/{university_id}", summary="删除院校")
async def admin_delete_university(
    university_id: int,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """删除指定院校（级联删除关联专业、分数等）。"""
    uni = await session.get(University, university_id)
    if uni is None:
        raise HTTPException(status_code=404, detail=f"院校不存在: {university_id}")

    # 级联清理：删除关联专业、录取分数、招生计划
    await session.execute(delete(Major).where(Major.university_id == university_id))
    await session.execute(delete(AdmissionScore).where(AdmissionScore.university_id == university_id))
    await session.execute(delete(EnrollmentPlan).where(EnrollmentPlan.university_id == university_id))

    await session.delete(uni)
    await session.commit()
    return {"ok": True}


# ---------------------------------------------------------------------------
# 专业 CRUD
# ---------------------------------------------------------------------------


@router.get("/majors", summary="专业列表（分页）")
async def admin_list_majors(
    university_id: int = Query(default=0, ge=0),
    keyword: str = Query(default=""),
    page: int = Query(default=DEFAULT_PAGE, ge=1),
    size: int = Query(default=DEFAULT_SIZE, ge=1, le=MAX_SIZE),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """分页查询专业列表，支持按院校ID/关键词筛选。"""
    stmt = select(Major)
    count_stmt = select(func.count()).select_from(Major)

    if university_id:
        stmt = stmt.where(Major.university_id == university_id)
        count_stmt = count_stmt.where(Major.university_id == university_id)
    if keyword:
        stmt = stmt.where(Major.name.ilike(f"%{keyword}%"))
        count_stmt = count_stmt.where(Major.name.ilike(f"%{keyword}%"))

    total = (await session.execute(count_stmt)).scalar() or 0
    offset, limit = _paginate(page, size)
    rows = (await session.execute(stmt.offset(offset).limit(limit))).scalars().all()

    return {
        "items": [r.to_dict() for r in rows],
        "total": total,
        "page": page,
        "size": size,
    }


@router.post("/majors", summary="新增专业", status_code=status.HTTP_201_CREATED)
async def admin_create_major(
    req: MajorCreate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """新增专业，校验 university_id 存在性。"""
    await _check_university_exists(session, req.university_id)

    major = Major(**req.model_dump())
    session.add(major)
    await session.commit()
    await session.refresh(major)
    return {"id": major.id, **major.to_dict()}


@router.put("/majors/{major_id}", summary="更新专业")
async def admin_update_major(
    major_id: int,
    req: MajorUpdate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """更新指定专业。"""
    major = await session.get(Major, major_id)
    if major is None:
        raise HTTPException(status_code=404, detail=f"专业不存在: {major_id}")

    await _check_university_exists(session, req.university_id)

    for k, v in req.model_dump().items():
        setattr(major, k, v)
    await session.commit()
    await session.refresh(major)
    return {"ok": True, **major.to_dict()}


@router.delete("/majors/{major_id}", summary="删除专业")
async def admin_delete_major(
    major_id: int,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """删除指定专业。"""
    major = await session.get(Major, major_id)
    if major is None:
        raise HTTPException(status_code=404, detail=f"专业不存在: {major_id}")
    await session.delete(major)
    await session.commit()
    return {"ok": True}


@router.post("/majors/batch", summary="批量导入专业")
async def admin_batch_create_majors(
    items: list[MajorCreate],
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """批量导入专业，单次上限 1000 条。"""
    if len(items) > BATCH_MAX:
        raise HTTPException(
            status_code=413,
            detail=f"单次批量导入上限 {BATCH_MAX} 条，当前 {len(items)} 条",
        )
    if not items:
        return {"count": 0}

    # 批量校验 university_id 存在性
    uni_ids = {item.university_id for item in items}
    existing = {
        row[0]
        for row in (await session.execute(
            select(University.id).where(University.id.in_(uni_ids))
        )).all()
    }
    missing = uni_ids - existing
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"以下 university_id 不存在: {sorted(missing)}",
        )

    for item in items:
        session.add(Major(**item.model_dump()))
    await session.commit()
    return {"count": len(items)}


# ---------------------------------------------------------------------------
# 录取分数 CRUD
# ---------------------------------------------------------------------------


@router.get("/scores", summary="录取分数列表（分页）")
async def admin_list_scores(
    university_id: int = Query(default=0, ge=0),
    province: str = Query(default=""),
    year: int = Query(default=0, ge=0),
    page: int = Query(default=DEFAULT_PAGE, ge=1),
    size: int = Query(default=DEFAULT_SIZE, ge=1, le=MAX_SIZE),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """分页查询录取分数列表。"""
    stmt = select(AdmissionScore)
    count_stmt = select(func.count()).select_from(AdmissionScore)

    if university_id:
        stmt = stmt.where(AdmissionScore.university_id == university_id)
        count_stmt = count_stmt.where(AdmissionScore.university_id == university_id)
    if province:
        stmt = stmt.where(AdmissionScore.province == province)
        count_stmt = count_stmt.where(AdmissionScore.province == province)
    if year:
        stmt = stmt.where(AdmissionScore.year == year)
        count_stmt = count_stmt.where(AdmissionScore.year == year)

    total = (await session.execute(count_stmt)).scalar() or 0
    offset, limit = _paginate(page, size)
    rows = (await session.execute(stmt.offset(offset).limit(limit))).scalars().all()

    return {
        "items": [r.to_dict() for r in rows],
        "total": total,
        "page": page,
        "size": size,
    }


@router.post("/scores", summary="新增录取分数", status_code=status.HTTP_201_CREATED)
async def admin_create_score(
    req: ScoreCreate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """新增录取分数，校验 university_id 存在性。"""
    await _check_university_exists(session, req.university_id)

    score = AdmissionScore(**req.model_dump())
    session.add(score)
    await session.commit()
    await session.refresh(score)
    return {"id": score.id, **score.to_dict()}


@router.put("/scores/{score_id}", summary="更新录取分数")
async def admin_update_score(
    score_id: int,
    req: ScoreUpdate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """更新指定录取分数。"""
    score = await session.get(AdmissionScore, score_id)
    if score is None:
        raise HTTPException(status_code=404, detail=f"分数记录不存在: {score_id}")

    await _check_university_exists(session, req.university_id)

    for k, v in req.model_dump().items():
        setattr(score, k, v)
    await session.commit()
    await session.refresh(score)
    return {"ok": True, **score.to_dict()}


@router.delete("/scores/{score_id}", summary="删除录取分数")
async def admin_delete_score(
    score_id: int,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """删除指定录取分数。"""
    score = await session.get(AdmissionScore, score_id)
    if score is None:
        raise HTTPException(status_code=404, detail=f"分数记录不存在: {score_id}")
    await session.delete(score)
    await session.commit()
    return {"ok": True}


@router.post("/scores/batch", summary="批量导入录取分数")
async def admin_batch_create_scores(
    items: list[ScoreCreate],
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """批量导入录取分数，单次上限 1000 条。"""
    if len(items) > BATCH_MAX:
        raise HTTPException(
            status_code=413,
            detail=f"单次批量导入上限 {BATCH_MAX} 条，当前 {len(items)} 条",
        )
    if not items:
        return {"count": 0}

    # 批量校验 university_id 存在性
    uni_ids = {item.university_id for item in items}
    existing = {
        row[0]
        for row in (await session.execute(
            select(University.id).where(University.id.in_(uni_ids))
        )).all()
    }
    missing = uni_ids - existing
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"以下 university_id 不存在: {sorted(missing)}",
        )

    for item in items:
        session.add(AdmissionScore(**item.model_dump()))
    await session.commit()
    return {"count": len(items)}


# ---------------------------------------------------------------------------
# 招生计划 CRUD
# ---------------------------------------------------------------------------


@router.get("/plans", summary="招生计划列表（分页）")
async def admin_list_plans(
    university_id: int = Query(default=0, ge=0),
    province: str = Query(default=""),
    year: int = Query(default=0, ge=0),
    page: int = Query(default=DEFAULT_PAGE, ge=1),
    size: int = Query(default=DEFAULT_SIZE, ge=1, le=MAX_SIZE),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """分页查询招生计划列表。"""
    stmt = select(EnrollmentPlan)
    count_stmt = select(func.count()).select_from(EnrollmentPlan)

    if university_id:
        stmt = stmt.where(EnrollmentPlan.university_id == university_id)
        count_stmt = count_stmt.where(EnrollmentPlan.university_id == university_id)
    if province:
        stmt = stmt.where(EnrollmentPlan.province == province)
        count_stmt = count_stmt.where(EnrollmentPlan.province == province)
    if year:
        stmt = stmt.where(EnrollmentPlan.year == year)
        count_stmt = count_stmt.where(EnrollmentPlan.year == year)

    total = (await session.execute(count_stmt)).scalar() or 0
    offset, limit = _paginate(page, size)
    rows = (await session.execute(stmt.offset(offset).limit(limit))).scalars().all()

    return {
        "items": [r.to_dict() for r in rows],
        "total": total,
        "page": page,
        "size": size,
    }


@router.post("/plans", summary="新增招生计划", status_code=status.HTTP_201_CREATED)
async def admin_create_plan(
    req: PlanCreate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """新增招生计划，校验 university_id 存在性。"""
    await _check_university_exists(session, req.university_id)

    plan = EnrollmentPlan(**req.model_dump())
    session.add(plan)
    await session.commit()
    await session.refresh(plan)
    return {"id": plan.id, **plan.to_dict()}


@router.put("/plans/{plan_id}", summary="更新招生计划")
async def admin_update_plan(
    plan_id: int,
    req: PlanUpdate,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """更新指定招生计划。"""
    plan = await session.get(EnrollmentPlan, plan_id)
    if plan is None:
        raise HTTPException(status_code=404, detail=f"招生计划不存在: {plan_id}")

    await _check_university_exists(session, req.university_id)

    for k, v in req.model_dump().items():
        setattr(plan, k, v)
    await session.commit()
    await session.refresh(plan)
    return {"ok": True, **plan.to_dict()}


@router.delete("/plans/{plan_id}", summary="删除招生计划")
async def admin_delete_plan(
    plan_id: int,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """删除指定招生计划。"""
    plan = await session.get(EnrollmentPlan, plan_id)
    if plan is None:
        raise HTTPException(status_code=404, detail=f"招生计划不存在: {plan_id}")
    await session.delete(plan)
    await session.commit()
    return {"ok": True}


@router.post("/plans/batch", summary="批量导入招生计划")
async def admin_batch_create_plans(
    items: list[PlanCreate],
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """批量导入招生计划，单次上限 1000 条。"""
    if len(items) > BATCH_MAX:
        raise HTTPException(
            status_code=413,
            detail=f"单次批量导入上限 {BATCH_MAX} 条，当前 {len(items)} 条",
        )
    if not items:
        return {"count": 0}

    # 批量校验 university_id 存在性
    uni_ids = {item.university_id for item in items}
    existing = {
        row[0]
        for row in (await session.execute(
            select(University.id).where(University.id.in_(uni_ids))
        )).all()
    }
    missing = uni_ids - existing
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"以下 university_id 不存在: {sorted(missing)}",
        )

    for item in items:
        session.add(EnrollmentPlan(**item.model_dump()))
    await session.commit()
    return {"count": len(items)}


# ---------------------------------------------------------------------------
# 省份规则 CRUD
# ---------------------------------------------------------------------------


@router.get("/rules", summary="省份规则列表")
async def admin_list_rules(
    session: AsyncSession = Depends(get_db_session),
) -> list[dict[str, Any]]:
    """查询所有省份填报规则（不分页，直接返回数组）。"""
    rows = (await session.execute(
        select(ProvinceRule).order_by(ProvinceRule.province)
    )).scalars().all()
    return [r.to_dict() for r in rows]


@router.post("/rules", summary="新增/更新省份规则（upsert）")
async def admin_upsert_rule(
    req: RuleUpsert,
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """按 province 做 upsert：存在则更新，不存在则新增。"""
    result = await session.execute(
        select(ProvinceRule).where(ProvinceRule.province == req.province)
    )
    rule = result.scalar_one_or_none()

    if rule is None:
        rule = ProvinceRule(**req.model_dump())
        session.add(rule)
    else:
        for k, v in req.model_dump().items():
            setattr(rule, k, v)

    await session.commit()
    await session.refresh(rule)
    return rule.to_dict()


@router.delete("/rules/{province}", summary="删除省份规则")
async def admin_delete_rule(
    province: str,
    year: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """删除指定省份的规则。year=0 表示删除该省份所有年份的规则。"""
    stmt = delete(ProvinceRule).where(ProvinceRule.province == province)
    if year > 0:
        stmt = stmt.where(ProvinceRule.year == year)

    result = await session.execute(stmt)
    await session.commit()

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail=f"未找到省份规则: {province}")

    return {"ok": True, "deleted": result.rowcount}
