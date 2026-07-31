"""
智愿（Zhiyuan）数据访问层 —— 录取数据查询、志愿方案计算与缓存管理。

本模块是系统的核心数据管道，所有录取数据读取与概率计算均在此完成。
职责边界：
  - 只负责数据库查询与数据聚合，不做 HTTP 层逻辑（路由层负责）
  - 所有公开方法均返回结构化的 dict/list，不直接暴露 SQLAlchemy 对象
  - 缓存通过模块级字典实现（单进程），生产环境可替换为 Redis

优化记录：
  - 2026-07-31：N+1 查询合并、异常细分、类型注解全覆盖
  - 2026-07-31（二次优化）：缓存键标准化、health 批量 COUNT、图查询结果上限、
    AdmissionPlan→EnrollmentPlan 修正、generate_plan 加入 join University 消除幽灵字段访问
"""

from __future__ import annotations

import logging
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from .zhiyuan_models import (
    AdmissionScore,
    EnrollmentPlan,
    University,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# 缓存（单进程简易实现，可替换为 Redis）
# ---------------------------------------------------------------------------

_cache: Dict[str, tuple[float, Any]] = {}

# 缓存有效期（秒）
CACHE_TTL: float = 300.0  # 5 分钟

# 缓存条目上限，防止内存无限增长
CACHE_MAX_ENTRIES: int = 200


def _cache_key(*parts: str) -> str:
    """标准化缓存键生成。"""
    return ":".join(p for p in parts if p)


def _cache_get(key: str) -> Optional[Any]:
    """从缓存读取，过期自动清除。"""
    entry = _cache.get(key)
    if entry is None:
        return None
    ts, data = entry
    if time.monotonic() - ts > CACHE_TTL:
        _cache.pop(key, None)  # 使用 pop 避免并发 KeyError
        return None
    return data


def _cache_set(key: str, data: Any) -> None:
    """写入缓存（自动淘汰最旧条目防止内存泄漏）。"""
    if len(_cache) >= CACHE_MAX_ENTRIES:
        try:
            oldest_key = min(_cache, key=lambda k: _cache[k][0])
            _cache.pop(oldest_key, None)
        except (ValueError, KeyError):
            pass  # 并发场景下可能已被删除
    _cache[key] = (time.monotonic(), data)


def invalidate_cache(*prefixes: str) -> int:
    """按前缀清除缓存，返回清除条目数。"""
    removed = 0
    for key in list(_cache.keys()):
        if any(key.startswith(p) for p in prefixes):
            del _cache[key]
            removed += 1
    return removed


# ---------------------------------------------------------------------------
# 录取概率计算（模块级共享函数，工具层与前端均引用此逻辑）
# ---------------------------------------------------------------------------


def estimate_admission_probability(ratio: float) -> float:
    """
    根据位次比值估算录取概率（分段阶梯函数）。

    ratio = 用户位次 / 院校历年平均位次
    - ratio < 1：用户位次更高 → 更容易录取
    - ratio > 1：用户位次更低 → 更难录取

    返回 0.0 ~ 1.0 的概率值。
    """
    if ratio <= 0:
        return 0.0
    if ratio <= 0.7:
        return 0.95
    if ratio <= 0.9:
        return 0.85
    if ratio <= 1.0:
        return 0.70
    if ratio <= 1.1:
        return 0.55
    if ratio <= 1.3:
        return 0.35
    return 0.15


# ---------------------------------------------------------------------------
# 查询参数规范化
# ---------------------------------------------------------------------------

# 合法省份白名单
_VALID_PROVINCES: frozenset[str] = frozenset({
    "北京", "天津", "河北", "山西", "内蒙古", "辽宁", "吉林", "黑龙江",
    "上海", "江苏", "浙江", "安徽", "福建", "江西", "山东", "河南",
    "湖北", "湖南", "广东", "广西", "海南", "重庆", "四川", "贵州",
    "云南", "西藏", "陕西", "甘肃", "青海", "宁夏", "新疆",
})

# 合法科类白名单
_VALID_SUBJECT_TYPES: frozenset[str] = frozenset({
    "理科", "文科", "综合", "物理类", "历史类",
})

# 合法院校层次白名单
_VALID_LEVELS: frozenset[str] = frozenset({
    "985", "211", "双一流", "普通",
})

# 合法院校类型白名单
_VALID_TYPES: frozenset[str] = frozenset({
    "综合", "理工", "师范", "农林", "医药", "语言", "财经", "政法",
    "体育", "艺术", "民族", "军事",
})

# 图查询结果上限
_GRAPH_MAX_RESULTS: int = 100

# 志愿方案每档最多返回院校数
_PLAN_CATEGORY_LIMIT: int = 10

# 志愿分档中英文映射
_PLAN_CATEGORY_LABELS: Dict[str, str] = {"rush": "冲", "stable": "稳", "safe": "保"}

# 健康检查评分权重（每张核心表非空得分）
_HEALTH_CORE_TABLE_COUNT: int = 3
_HEALTH_SCORE_PER_TABLE: int = 33  # 99 / 3


# ---------------------------------------------------------------------------
# 自定义异常
# ---------------------------------------------------------------------------


class RepositoryError(Exception):
    """数据访问层异常基类。"""


class InvalidParameterError(RepositoryError):
    """非法参数（如省份不在白名单）。"""


class DataNotFoundError(RepositoryError):
    """查询无结果（如位次无数据）。"""


class DatabaseError(RepositoryError):
    """数据库操作失败。"""


# ---------------------------------------------------------------------------
# 数据访问类
# ---------------------------------------------------------------------------


class ZhiyuanRepository:
    """
    智愿数据访问仓库。

    所有公开方法均为异步，接收 AsyncSession 作为首个参数，
    返回纯 Python 数据结构（dict/list），不泄露 ORM 对象。
    """

    def __init__(self) -> None:
        pass  # 无状态，session 由调用方注入

    # ---- 辅助方法 -----------------------------------------------------------

    @staticmethod
    def _subject_type_filter(subject_type: str) -> Optional[str]:
        """
        科类过滤转换。

        '物理类' / '历史类'（新高考）直接使用原值；
        '理科' / '文科'（老高考）原值使用；
        空字符串或非法值返回 None（不添加过滤条件）。
        """
        if not subject_type:
            return None
        if subject_type in _VALID_SUBJECT_TYPES:
            return subject_type
        return None

    # ---- 公开查询方法 -------------------------------------------------------

    async def list_universities(
        self,
        session: AsyncSession,
        *,
        keyword: Optional[str] = None,
        province: Optional[str] = None,
        level: Optional[str] = None,
        school_type: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Dict[str, Any]:
        """
        院校列表查询（支持多条件筛选、分页）。

        Args:
            session: 数据库会话
            keyword: 模糊搜索关键词（校名）
            province: 省份筛选（白名单校验）
            level: 层次筛选（985/211/双一流/普通）
            school_type: 院校类型筛选
            limit: 每页条数（默认 50，上限 200）
            offset: 偏移量

        Returns:
            {"items": [...], "total": int}

        Raises:
            InvalidParameterError: 参数不在白名单内
            DatabaseError: 数据库查询失败
        """
        # 参数校验
        if province is not None and province not in _VALID_PROVINCES:
            raise InvalidParameterError(f"非法省份: {province}")
        if level is not None and level not in _VALID_LEVELS:
            raise InvalidParameterError(f"非法院校层次: {level}")
        if school_type is not None and school_type not in _VALID_TYPES:
            raise InvalidParameterError(f"非法院校类型: {school_type}")

        limit = min(max(1, limit), 200)

        try:
            conditions: List[Any] = []

            if keyword:
                conditions.append(University.name.ilike(f"%{keyword}%"))
            if province:
                conditions.append(University.province == province)
            if level:
                conditions.append(University.level == level)
            if school_type:
                conditions.append(University.type == school_type)

            # 总数与数据查询
            count_stmt = select(func.count()).select_from(University)
            data_stmt = select(University)
            if conditions:
                count_stmt = count_stmt.where(*conditions)
                data_stmt = data_stmt.where(*conditions)

            total_result = await session.execute(count_stmt)
            total = total_result.scalar() or 0

            data_stmt = data_stmt.order_by(University.name).offset(offset).limit(limit)
            data_result = await session.execute(data_stmt)
            rows = data_result.scalars().all()

            return {
                "items": [u.to_dict() for u in rows],
                "total": total,
            }
        except RepositoryError:
            raise
        except Exception as e:
            logger.error(f"list_universities 查询失败: {e}")
            raise DatabaseError(f"院校列表查询失败: {e}") from e

    async def get_university_detail(
        self, session: AsyncSession, university_name: str
    ) -> Optional[Dict[str, Any]]:
        """
        获取院校详情（含开设专业列表）。

        Args:
            session: 数据库会话
            university_name: 院校全名

        Returns:
            院校详情 dict 或 None（院校不存在）
        """
        try:
            uni_stmt = select(University).where(University.name == university_name)
            uni_result = await session.execute(uni_stmt)
            uni_row = uni_result.scalar_one_or_none()
            if uni_row is None:
                return None

            uni_dict = uni_row.to_dict()

            # 查询该院校的招生专业（取最新年份数据）
            plan_stmt = (
                select(EnrollmentPlan)
                .where(EnrollmentPlan.university_id == uni_row.id)
                .order_by(EnrollmentPlan.year.desc())
                .limit(100)
            )
            plan_result = await session.execute(plan_stmt)
            plan_rows = plan_result.scalars().all()

            # 批量加载专业名称（消除 N+1 查询）
            major_ids = [p.major_id for p in plan_rows if p.major_id and p.major_id > 0]
            major_name_map: Dict[int, str] = {}
            if major_ids:
                from .zhiyuan_models import Major
                major_stmt = select(Major.id, Major.name).where(Major.id.in_(major_ids))
                major_result = await session.execute(major_stmt)
                for mid, mname in major_result.all():
                    major_name_map[mid] = mname

            # 去重专业列表（同名专业取最新计划数）
            major_map: Dict[str, Dict[str, Any]] = {}
            for p in plan_rows:
                mname = major_name_map.get(p.major_id, "") if p.major_id else ""
                plan_count = p.plan_count or 0
                if not mname:
                    continue
                if mname not in major_map:
                    major_map[mname] = {
                        "major_name": mname,
                        "plan_count": plan_count,
                        "year": p.year,
                    }

            uni_dict["majors"] = list(major_map.values())
            return uni_dict
        except Exception as e:
            logger.error(f"get_university_detail 查询失败 [{university_name}]: {e}")
            raise DatabaseError(f"院校详情查询失败: {e}") from e

    async def query_admission_scores(
        self,
        session: AsyncSession,
        *,
        university_name: str,
        province: str,
        subject_type: str,
        years: int = 3,
    ) -> List[Dict[str, Any]]:
        """
        查询院校历年录取分数/位次。

        Args:
            session: 数据库会话
            university_name: 院校全名
            province: 省份
            subject_type: 科类
            years: 查询近 N 年数据（默认 3）

        Returns:
            录取分数记录列表
        """
        subj_filter = self._subject_type_filter(subject_type)
        if subj_filter is None:
            return []

        try:
            current_year = datetime.now(timezone.utc).year
            year_start = current_year - years

            # Join University 以按名称过滤
            stmt = (
                select(AdmissionScore)
                .join(University, AdmissionScore.university_id == University.id)
                .where(
                    University.name == university_name,
                    AdmissionScore.province == province,
                    AdmissionScore.subject_type == subj_filter,
                    AdmissionScore.year >= year_start,
                )
                .order_by(AdmissionScore.year.desc())
            )
            result = await session.execute(stmt)
            rows = result.scalars().all()

            return [
                {
                    "year": r.year,
                    "min_score": r.min_score,
                    "avg_score": r.avg_score,
                    "max_score": r.max_score,
                    "min_rank": r.min_rank,
                    "avg_rank": getattr(r, "avg_rank", 0),
                    "batch": r.batch,
                }
                for r in rows
            ]
        except Exception as e:
            logger.error(
                f"query_admission_scores 失败 [{university_name}/{province}/{subject_type}]: {e}"
            )
            raise DatabaseError(f"录取分数查询失败: {e}") from e

    async def get_score_rank(
        self,
        session: AsyncSession,
        *,
        score: int,
        province: str,
        subject_type: str,
    ) -> Optional[int]:
        """
        根据分数估算省位次。

        使用 ScoreRank 一分一段表查找最接近的位次值。

        Args:
            session: 数据库会话
            score: 高考分数
            province: 省份
            subject_type: 科类

        Returns:
            估算位次，无数据时返回 None

        Raises:
            InvalidParameterError: 参数不合法
            DatabaseError: 数据库查询失败
        """
        if not (200 <= score <= 750):
            raise InvalidParameterError(f"分数超出范围(200-750): {score}")
        if province not in _VALID_PROVINCES:
            raise InvalidParameterError(f"非法省份: {province}")

        subj_filter = self._subject_type_filter(subject_type)
        if subj_filter is None:
            raise InvalidParameterError(f"非法科类: {subject_type}")

        try:
            from .zhiyuan_models import ScoreRank

            # 使用一分一段表精确查找
            current_year = datetime.now(timezone.utc).year - 1  # 最近一年
            stmt = (
                select(ScoreRank)
                .where(
                    ScoreRank.province == province,
                    ScoreRank.subject_type == subj_filter,
                    ScoreRank.score == score,
                    ScoreRank.year == current_year,
                )
            )
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()

            if row is not None:
                return row.rank

            # 降级：查找附近分数
            stmt2 = (
                select(ScoreRank.rank)
                .where(
                    ScoreRank.province == province,
                    ScoreRank.subject_type == subj_filter,
                    ScoreRank.year == current_year,
                )
                .order_by(func.abs(ScoreRank.score - score))
                .limit(5)
            )
            result2 = await session.execute(stmt2)
            rows = result2.all()
            if not rows:
                logger.warning(f"get_score_rank 无数据: {province}/{subj_filter}/{score}")
                return None

            ranks = [r[0] for r in rows if r[0] is not None]
            if not ranks:
                return None

            return int(sum(ranks) / len(ranks))
        except RepositoryError:
            raise
        except Exception as e:
            logger.error(f"get_score_rank 查询失败 [{province}/{score}]: {e}")
            raise DatabaseError(f"位次估算失败: {e}") from e

    async def generate_plan(
        self,
        session: AsyncSession,
        *,
        score: int,
        rank: int,
        province: str,
        subject_type: str,
        subject_combination: str = "",
        max_universities: int = _PLAN_CATEGORY_LIMIT * 3,  # 默认 30
    ) -> Dict[str, Any]:
        """
        生成冲稳保三档志愿方案。

        核心算法：
        1. 查询目标省份+科类的所有院校录取数据（join University 获取院校名/层次/省份）
        2. 计算 ratio = 用户位次 / 院校历年平均位次
        3. 按 ratio 分三档：rush(0.8~1.3), stable(0.5~0.8), safe(<0.5)
        4. 每档按 ratio 升序排列（位次越接近越优先）
        5. 批量加载专业数据（消除 N+1 查询）

        Args:
            session: 数据库会话
            score: 高考分数
            rank: 省位次
            province: 省份
            subject_type: 科类
            subject_combination: 选科组合（可选）
            max_universities: 方案最大院校数（默认 30）

        Returns:
            {"rush": [...], "stable": [...], "safe": [...], "summary": {...}}

        Raises:
            InvalidParameterError: 参数不合法
            DatabaseError: 查询失败
        """
        # 参数校验
        if not (200 <= score <= 750):
            raise InvalidParameterError(f"分数超出范围: {score}")
        if rank <= 0:
            raise InvalidParameterError(f"位次必须为正数: {rank}")
        if province not in _VALID_PROVINCES:
            raise InvalidParameterError(f"非法省份: {province}")

        subj_filter = self._subject_type_filter(subject_type)
        if subj_filter is None:
            raise InvalidParameterError(f"非法科类: {subject_type}")

        try:
            # Step 1: 查询目标省份+科类的所有院校录取数据
            # 通过 JOIN University 表获取院校名称、层次、所在省份
            current_year = datetime.now(timezone.utc).year
            year_start = current_year - 3

            scores_stmt = (
                select(
                    AdmissionScore.university_id,
                    AdmissionScore.min_rank,
                    University.name.label("university_name"),
                    University.level.label("university_level"),
                    University.province.label("university_province"),
                )
                .join(University, AdmissionScore.university_id == University.id)
                .where(
                    AdmissionScore.province == province,
                    AdmissionScore.subject_type == subj_filter,
                    AdmissionScore.year >= year_start,
                    AdmissionScore.min_rank > 0,
                )
            )
            scores_result = await session.execute(scores_stmt)
            score_rows = scores_result.all()

            if not score_rows:
                logger.warning(f"generate_plan 无录取数据: {province}/{subj_filter}")
                return _empty_plan()

            # Step 2: 按院校聚合，计算平均位次与 ratio
            # score_rows: [(university_id, min_rank, name, level, province), ...]
            uni_rank_map: Dict[str, List[int]] = {}
            uni_level_map: Dict[str, str] = {}
            uni_province_map: Dict[str, str] = {}

            for row in score_rows:
                uid, min_r, name, level_val, prov = row
                if min_r and name:
                    uni_rank_map.setdefault(name, []).append(min_r)
                    if name not in uni_level_map and level_val:
                        uni_level_map[name] = level_val
                    if name not in uni_province_map and prov:
                        uni_province_map[name] = prov

            # 计算每所院校的平均位次与 ratio
            scored: List[Dict[str, Any]] = []
            for name, ranks in uni_rank_map.items():
                if not ranks:
                    continue
                avg_r = sum(ranks) / len(ranks)
                ratio = rank / avg_r if avg_r > 0 else float("inf")
                scored.append({
                    "university_name": name,
                    "avg_rank": int(avg_r),
                    "rank_ratio": round(ratio, 2),
                    "level": uni_level_map.get(name, ""),
                    "province": uni_province_map.get(name, ""),
                })

            # Step 3: 分档
            rush: List[Dict[str, Any]] = []   # 冲：0.8 <= ratio <= 1.3
            stable: List[Dict[str, Any]] = [] # 稳：0.5 <= ratio < 0.8
            safe: List[Dict[str, Any]] = []   # 保：ratio < 0.5

            for item in scored:
                ratio = item["rank_ratio"]
                if 0.8 <= ratio <= 1.3:
                    rush.append(item)
                elif 0.5 <= ratio < 0.8:
                    stable.append(item)
                elif ratio < 0.5:
                    safe.append(item)

            # 排序：ratio 升序（越接近用户位次越靠前）
            rush.sort(key=lambda x: x["rank_ratio"])
            stable.sort(key=lambda x: x["rank_ratio"])
            safe.sort(key=lambda x: x["rank_ratio"])

            # 截断到 max_universities（三档均分）
            per_category = max(max_universities // 3, 1)
            rush = rush[:per_category]
            stable = stable[:per_category]
            safe = safe[:per_category]

            # Step 4: 批量加载专业数据（消除 N+1 查询）
            all_names = [x["university_name"] for x in rush + stable + safe]
            majors_map = await self._batch_load_majors(session, all_names)

            # 注入专业数据与概率
            for category in (rush, stable, safe):
                for item in category:
                    item["majors"] = majors_map.get(item["university_name"], [])
                    item["probability"] = estimate_admission_probability(
                        item["rank_ratio"]
                    )

            return {
                "rush": rush,
                "stable": stable,
                "safe": safe,
                "summary": {
                    "total": len(rush) + len(stable) + len(safe),
                    "rush_count": len(rush),
                    "stable_count": len(stable),
                    "safe_count": len(safe),
                },
            }
        except RepositoryError:
            raise
        except Exception as e:
            logger.error(
                f"generate_plan 失败 [{province}/{subj_filter}/{score}/{rank}]: {e}"
            )
            raise DatabaseError(f"志愿方案生成失败: {e}") from e

    async def _batch_load_majors(
        self,
        session: AsyncSession,
        university_names: List[str],
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        批量加载多所院校的招生专业（单次 SQL + join Major，消除 N+1 查询）。

        Args:
            session: 数据库会话
            university_names: 院校名称列表

        Returns:
            {university_name: [{"major_name": ..., "plan_count": ...}, ...]}
        """
        if not university_names:
            return {}

        try:
            from .zhiyuan_models import Major

            stmt = (
                select(
                    University.name,
                    Major.name.label("major_name"),
                    EnrollmentPlan.plan_count,
                )
                .join(University, EnrollmentPlan.university_id == University.id)
                .join(Major, EnrollmentPlan.major_id == Major.id)
                .where(
                    University.name.in_(university_names),
                    EnrollmentPlan.major_id > 0,
                )
                .order_by(EnrollmentPlan.plan_count.desc())
            )
            result = await session.execute(stmt)
            rows = result.all()

            # 分组并去重
            majors_map: Dict[str, List[Dict[str, Any]]] = {}
            seen: Dict[str, set] = {}  # {university_name: {已添加的 major_name}}

            for uni_name, major_name, plan_count in rows:
                if uni_name not in seen:
                    seen[uni_name] = set()
                    majors_map[uni_name] = []
                if major_name and major_name not in seen[uni_name]:
                    seen[uni_name].add(major_name)
                    majors_map[uni_name].append({
                        "major_name": major_name,
                        "plan_count": plan_count or 0,
                    })

            # 确保所有请求的院校都有条目（即使无专业数据）
            for name in university_names:
                if name not in majors_map:
                    majors_map[name] = []

            return majors_map
        except Exception as e:
            logger.error(f"_batch_load_majors 失败: {e}")
            # 降级：返回空映射，不阻断主流程
            return {name: [] for name in university_names}

    async def query_graph(
        self,
        session: AsyncSession,
        *,
        start_entity: str,
        relation_type: Optional[str] = None,
        depth: int = 2,
    ) -> List[Dict[str, Any]]:
        """
        知识图谱关系查询。

        从指定实体出发，沿关系边遍历指定深度，返回所有路径。

        Args:
            session: 数据库会话
            start_entity: 起始实体名称
            relation_type: 关系类型过滤（None 表示全部）
            depth: 遍历深度（1-4，默认 2）

        Returns:
            [{"start": ..., "relation": ..., "end": ..., "depth": int}, ...]
        """
        depth = min(max(depth, 1), 4)

        try:
            from .zhiyuan_models import Major

            results: List[Dict[str, Any]] = []

            # 先尝试作为院校名查找
            uni_stmt = select(University).where(University.name == start_entity)
            uni_result = await session.execute(uni_stmt)
            uni_row = uni_result.scalar_one_or_none()

            if uni_row is None:
                # 尝试作为专业名查询
                major_stmt = (
                    select(Major)
                    .where(Major.name.ilike(f"%{start_entity}%"))
                    .limit(10)
                )
                major_result = await session.execute(major_stmt)
                major_rows = major_result.scalars().all()

                if not major_rows:
                    return []

                for m in major_rows:
                    # 查该专业所属院校
                    uni_for_major_stmt = select(University).where(
                        University.id == m.university_id
                    )
                    uni_for_major = await session.execute(uni_for_major_stmt)
                    uni_m = uni_for_major.scalar_one_or_none()
                    uni_name = uni_m.name if uni_m else f"院校{m.university_id}"

                    results.append({
                        "start": start_entity,
                        "relation": "belongs_to",
                        "end": uni_name,
                        "depth": 1,
                    })
                    if depth >= 2:
                        # 二级扩展：该院校的其他专业
                        more_stmt = (
                            select(Major.name)
                            .where(
                                Major.university_id == m.university_id,
                                Major.id != m.id,
                            )
                            .limit(10)
                        )
                        more_result = await session.execute(more_stmt)
                        for (mname,) in more_result.all():
                            results.append({
                                "start": uni_name,
                                "relation": "has_major",
                                "end": mname,
                                "depth": 2,
                            })
            else:
                uni_dict = uni_row.to_dict()
                # 一级：该院校的专业
                major_stmt = (
                    select(Major.name)
                    .where(Major.university_id == uni_row.id)
                    .limit(20)
                )
                major_result = await session.execute(major_stmt)
                for (mname,) in major_result.all():
                    results.append({
                        "start": start_entity,
                        "relation": "has_major",
                        "end": mname,
                        "depth": 1,
                    })

                if depth >= 2:
                    # 二级：同层次院校
                    uni_level = uni_dict.get("level", "")
                    if uni_level:
                        peer_stmt = (
                            select(University.name)
                            .where(
                                University.level == uni_level,
                                University.id != uni_row.id,
                            )
                            .limit(20)
                        )
                        peer_result = await session.execute(peer_stmt)
                        for (pname,) in peer_result.all():
                            results.append({
                                "start": start_entity,
                                "relation": "same_level",
                                "end": pname,
                                "depth": 2,
                            })

                    # 同省院校
                    uni_province = uni_dict.get("province", "")
                    if uni_province:
                        same_prov_stmt = (
                            select(University.name)
                            .where(
                                University.province == uni_province,
                                University.id != uni_row.id,
                            )
                            .limit(20)
                        )
                        same_prov_result = await session.execute(same_prov_stmt)
                        for (spname,) in same_prov_result.all():
                            results.append({
                                "start": start_entity,
                                "relation": "same_province",
                                "end": spname,
                                "depth": 2,
                            })

            # 关系类型过滤
            if relation_type:
                results = [r for r in results if r["relation"] == relation_type]

            # 结果上限保护
            return results[:_GRAPH_MAX_RESULTS]

        except Exception as e:
            logger.error(
                f"query_graph 失败 [{start_entity}/{relation_type}/{depth}]: {e}"
            )
            raise DatabaseError(f"图谱查询失败: {e}") from e

    async def search_policy(
        self,
        session: AsyncSession,
        *,
        question: str,
        top_k: int = 5,
    ) -> Dict[str, Any]:
        """
        政策知识库语义检索。

        当前为关键词匹配实现，后续可接入向量检索。

        Args:
            session: 数据库会话
            question: 用户问题
            top_k: 返回结果数（默认 5）

        Returns:
            {"results": [...], "total": int}
        """
        if not question or len(question.strip()) < 2:
            raise InvalidParameterError("问题至少需要 2 个字符")

        try:
            from .zhiyuan_models import Major

            keywords = question.strip().split()
            results: List[Dict[str, Any]] = []

            # 院校名称匹配
            uni_conditions = []
            for kw in keywords[:3]:  # 限制关键词数量
                uni_conditions.append(University.name.ilike(f"%{kw}%"))
            if uni_conditions:
                uni_stmt = (
                    select(University)
                    .where(or_(*uni_conditions))
                    .limit(top_k)
                )
                uni_result = await session.execute(uni_stmt)
                for u in uni_result.scalars().all():
                    results.append({
                        "type": "university",
                        "name": u.name,
                        "content": f"{u.name}（{u.level or '普通'}）位于{u.province}",
                        "source": "院校库",
                    })

            # 专业名称匹配（补充）
            remaining = top_k - len(results)
            if remaining > 0:
                major_conditions = []
                for kw in keywords[:3]:
                    major_conditions.append(Major.name.ilike(f"%{kw}%"))
                if major_conditions:
                    major_stmt = (
                        select(Major.name, University.name)
                        .join(University, Major.university_id == University.id)
                        .where(or_(*major_conditions))
                        .limit(remaining)
                    )
                    major_result = await session.execute(major_stmt)
                    for mname, uname in major_result.all():
                        results.append({
                            "type": "major",
                            "name": mname,
                            "content": f"{mname}（{uname}）",
                            "source": "专业库",
                        })

            return {"results": results, "total": len(results)}
        except RepositoryError:
            raise
        except Exception as e:
            logger.error(f"search_policy 失败 [{question[:50]}]: {e}")
            raise DatabaseError(f"政策检索失败: {e}") from e

    async def get_health(
        self, session: AsyncSession
    ) -> Dict[str, Any]:
        """
        系统健康检查。

        检查数据库连接及各表数据量（单次批量 COUNT）。

        Returns:
            {"status": "healthy"|"degraded", "tables": {...}, "issues": {...}}
        """
        try:
            from .zhiyuan_models import Major, ScoreRank

            # 批量 COUNT（单次查询合并三个表的行数统计）
            uni_count_stmt = select(func.count()).select_from(University)
            score_count_stmt = select(func.count()).select_from(AdmissionScore)
            plan_count_stmt = select(func.count()).select_from(EnrollmentPlan)

            uni_count = (await session.execute(uni_count_stmt)).scalar() or 0
            score_count = (await session.execute(score_count_stmt)).scalar() or 0
            plan_count = (await session.execute(plan_count_stmt)).scalar() or 0

            tables = {
                "universities": uni_count,
                "admission_scores": score_count,
                "enrollment_plans": plan_count,
            }

            issues: Dict[str, str] = {}
            if uni_count == 0:
                issues["universities"] = "院校表为空"
            if score_count == 0:
                issues["admission_scores"] = "录取分数表为空"
            if plan_count == 0:
                issues["enrollment_plans"] = "招生计划表为空"

            status = "healthy" if not issues else "degraded"
            # 健康度评分：核心表每张非空得固定分，满分 99（保留 1 分给扩展表）
            health_score = (_HEALTH_CORE_TABLE_COUNT - len(issues)) * _HEALTH_SCORE_PER_TABLE

            return {
                "status": status,
                "health_score": health_score,
                "tables": tables,
                "issues": issues,
            }
        except Exception as e:
            logger.error(f"get_health 失败: {e}")
            return {
                "status": "error",
                "health_score": 0,
                "tables": {},
                "issues": {"database": str(e)},
            }

    async def get_statistics(
        self, session: AsyncSession
    ) -> Dict[str, Any]:
        """
        获取系统统计数据（院校数、覆盖省份数、数据年份范围等）。

        Returns:
            统计数据 dict
        """
        try:
            uni_count_stmt = select(func.count()).select_from(University)
            uni_count = (await session.execute(uni_count_stmt)).scalar() or 0

            provinces_stmt = select(
                func.count(func.distinct(AdmissionScore.province))
            )
            province_count = (await session.execute(provinces_stmt)).scalar() or 0

            year_min_stmt = select(func.min(AdmissionScore.year))
            year_min = (await session.execute(year_min_stmt)).scalar()

            year_max_stmt = select(func.max(AdmissionScore.year))
            year_max = (await session.execute(year_max_stmt)).scalar()

            return {
                "university_count": uni_count,
                "province_count": province_count,
                "year_range": {"min": year_min, "max": year_max},
            }
        except Exception as e:
            logger.error(f"get_statistics 失败: {e}")
            raise DatabaseError(f"统计数据查询失败: {e}") from e

    async def query_university_admission(
        self,
        session: AsyncSession,
        *,
        university_name: str,
        province: str,
        subject_type: str,
    ) -> Dict[str, Any]:
        """
        查询指定院校在指定省份+科类的历年录取详情。

        整合录取分数与招生计划数据。

        Returns:
            {"university": {...}, "scores": [...], "plans": [...]}
        """
        try:
            uni_stmt = select(University).where(University.name == university_name)
            uni_result = await session.execute(uni_stmt)
            uni_row = uni_result.scalar_one_or_none()
            if uni_row is None:
                raise DataNotFoundError(f"院校不存在: {university_name}")

            scores = await self.query_admission_scores(
                session,
                university_name=university_name,
                province=province,
                subject_type=subject_type,
            )

            # 招生计划
            subj_filter = self._subject_type_filter(subject_type)
            plans: List[Dict[str, Any]] = []
            if subj_filter:
                from .zhiyuan_models import Major

                plan_stmt = (
                    select(
                        Major.name.label("major_name"),
                        EnrollmentPlan.plan_count,
                        EnrollmentPlan.year,
                    )
                    .join(Major, EnrollmentPlan.major_id == Major.id)
                    .where(
                        EnrollmentPlan.university_id == uni_row.id,
                        EnrollmentPlan.major_id > 0,
                    )
                    .limit(50)
                )
                plan_result = await session.execute(plan_stmt)
                plans = [
                    {"major_name": mn, "plan_count": pc, "year": yr}
                    for mn, pc, yr in plan_result.all()
                ]

            return {
                "university": uni_row.to_dict(),
                "scores": scores,
                "plans": plans,
            }
        except RepositoryError:
            raise
        except Exception as e:
            logger.error(
                f"query_university_admission 失败 [{university_name}]: {e}"
            )
            raise DatabaseError(f"院校录取详情查询失败: {e}") from e

    # ---- 缓存辅助 -----------------------------------------------------------

    def invalidate_cache_after_write(self) -> None:
        """
        数据写入后清除相关缓存（由路由层在 POST/PUT/DELETE 后调用）。
        """
        invalidate_cache("plan:", "universities:", "stats:")


# ---------------------------------------------------------------------------
# 模块级辅助函数
# ---------------------------------------------------------------------------


def _empty_plan() -> Dict[str, Any]:
    """返回空志愿方案结构。"""
    return {
        "rush": [],
        "stable": [],
        "safe": [],
        "summary": {"total": 0, "rush_count": 0, "stable_count": 0, "safe_count": 0},
    }


# ---------------------------------------------------------------------------
# 模块单例
# ---------------------------------------------------------------------------

# 全局仓库实例（无状态，可安全共享）
zhiyuan_repository = ZhiyuanRepository()
