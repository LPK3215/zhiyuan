"""智愿 - 数据访问层"""

from sqlalchemy import and_, desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from yuxi.repositories.zhiyuan_models import (
    AdmissionScore,
    EnrollmentPlan,
    Major,
    ProvinceRule,
    ScoreRank,
    University,
)

# LIKE 通配符转义字符，用于防止用户输入的 % / _ / \ 改变模糊匹配语义（查询注入防护）
_LIKE_ESCAPE_CHAR = "\\"
# search_* 方法返回的硬上限，防止恶意/异常传入超大 limit 触发全表返回
_SEARCH_LIMIT_CAP = 100


def _escape_like(value: str) -> str:
    """转义 SQL LIKE 通配符，使用户输入被当作字面量匹配。

    转义 \\、%、_ 三个特殊字符，配合 ESCAPE 子句使用。
    """
    return (
        value.replace("\\", "\\\\")
        .replace("%", "\\%")
        .replace("_", "\\_")
    )


# 科类别名映射：新旧高考科类名称兼容。
# 前端可能传 "物理"/"历史"（新高考 3+1+2），但历史数据存的是 "理科"/"文科"（传统文理）。
# 映射后用 IN 查询，确保任一别名都能匹配到数据。
_SUBJECT_TYPE_ALIASES: dict[str, list[str]] = {
    "物理": ["物理", "理科", "物理类"],
    "理科": ["理科", "物理", "物理类"],
    "物理类": ["物理类", "物理", "理科"],
    "历史": ["历史", "文科", "历史类"],
    "文科": ["文科", "历史", "历史类"],
    "历史类": ["历史类", "历史", "文科"],
}


def _subject_type_filter(subject_type: str) -> list[str]:
    """返回 subject_type 的所有别名（含自身），用于 IN 查询。"""
    if not subject_type:
        return []
    return _SUBJECT_TYPE_ALIASES.get(subject_type, [subject_type])


class ZhiyuanRepository:
    """志愿填报数据访问"""

    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    # ===== 院校 =====

    async def get_university_by_name(self, name: str) -> dict | None:
        result = await self.db.execute(
            select(University)
            .where(University.name.ilike(f"%{_escape_like(name)}%", escape=_LIKE_ESCAPE_CHAR))
            .limit(1)
        )
        row = result.scalar_one_or_none()
        return row.to_dict() if row else None

    async def get_university_id_by_name(self, name: str) -> int | None:
        """按院校名（精确）解析主键 id，用于只知道院校名时的定位。"""
        stmt = select(University.id).where(University.name == name).limit(1)
        row = (await self.db.execute(stmt)).first()
        return row[0] if row else None

    async def get_university_maps(
        self, ids: set[int], fields: tuple[str, ...] = ("name", "level", "province")
    ) -> dict[int, dict]:
        """批量解析院校 id -> 指定字段字典（单条 IN 查询，避免 N+1）。

        供推荐/方案接口补充院校名称等展示信息，使用当前会话，避免嵌套开启新 session。

        字段白名单：仅允许 University 真实列名，屏蔽非列属性（如私有方法、to_dict
        等可调用，或可能的敏感字段），避免 getattr 出非列对象导致 SQL 拼装崩溃或
        字段泄漏。非法字段被静默忽略（向后兼容，正常调用方始终传合法字段）。
        """
        if not ids:
            return {}
        allowed = frozenset(University.__table__.columns.keys())
        safe_fields = tuple(f for f in fields if f in allowed)
        # 防御：极端情况下全部字段非法，至少回退到 name（id 始终返回）
        if not safe_fields:
            safe_fields = ("name",)
        cols = [getattr(University, f) for f in safe_fields]
        stmt = select(University.id, *cols).where(University.id.in_(ids))
        rows = (await self.db.execute(stmt)).all()
        return {
            row.id: {f: getattr(row, f) for f in safe_fields}
            for row in rows
        }

    async def search_universities(
        self, province: str = "", level: str = "", type_: str = "", keyword: str = "", limit: int = 20
    ) -> list[dict]:
        conditions = []
        if province:
            conditions.append(University.province == province)
        if level:
            conditions.append(University.level.ilike(f"%{_escape_like(level)}%", escape=_LIKE_ESCAPE_CHAR))
        if type_:
            conditions.append(University.type.ilike(f"%{_escape_like(type_)}%", escape=_LIKE_ESCAPE_CHAR))
        if keyword:
            conditions.append(University.name.ilike(f"%{_escape_like(keyword)}%", escape=_LIKE_ESCAPE_CHAR))

        # 资源防护：limit 硬上限，防止恶意/异常传入超大值触发全表返回
        safe_limit = min(max(limit, 1), _SEARCH_LIMIT_CAP)

        stmt = select(University)
        if conditions:
            stmt = stmt.where(and_(*conditions))
        stmt = stmt.limit(safe_limit)

        result = await self.db.execute(stmt)
        return [row.to_dict() for row in result.scalars().all()]

    # ===== 专业 =====

    async def get_majors_by_university(
        self, university_id: int, limit: int = 100
    ) -> list[dict]:
        # limit 默认 100：防止专业数极多的院校一次返回全表，降低详情页延迟
        result = await self.db.execute(
            select(Major)
            .where(Major.university_id == university_id)
            .limit(limit)
        )
        return [row.to_dict() for row in result.scalars().all()]

    async def search_majors(self, name: str = "", university_id: int = 0, limit: int = 20) -> list[dict]:
        conditions = []
        if name:
            conditions.append(Major.name.ilike(f"%{_escape_like(name)}%", escape=_LIKE_ESCAPE_CHAR))
        if university_id:
            conditions.append(Major.university_id == university_id)

        # 资源防护：limit 硬上限，防止恶意/异常传入超大值触发全表返回
        safe_limit = min(max(limit, 1), _SEARCH_LIMIT_CAP)

        stmt = select(Major)
        if conditions:
            stmt = stmt.where(and_(*conditions))
        stmt = stmt.limit(safe_limit)

        result = await self.db.execute(stmt)
        return [row.to_dict() for row in result.scalars().all()]

    async def compare_majors(self, major_names: list[str], university_name: str = "") -> list[dict]:
        # 资源防护：专业数量上限 20，避免恶意/异常传入超大列表导致 IN (...) 膨胀
        if len(major_names) > 20:
            major_names = major_names[:20]
        conditions = [Major.name.in_(major_names)]
        if university_name:
            # 先找university_id
            uni_result = await self.db.execute(
                select(University.id)
                .where(University.name.ilike(f"%{_escape_like(university_name)}%", escape=_LIKE_ESCAPE_CHAR))
                .limit(1)
            )
            uni_id = uni_result.scalar_one_or_none()
            if uni_id:
                conditions.append(Major.university_id == uni_id)

        result = await self.db.execute(select(Major).where(and_(*conditions)))
        return [row.to_dict() for row in result.scalars().all()]

    # ===== 录取分数 =====

    async def query_admission_scores(
        self,
        university_id: int = 0,
        province: str = "",
        year: int = 0,
        subject_type: str = "",
        major_id: int = 0,
        years_back: int = 3,
    ) -> list[dict]:
        conditions = []
        if university_id:
            conditions.append(AdmissionScore.university_id == university_id)
        if province:
            conditions.append(AdmissionScore.province == province)
        if subject_type:
            conditions.append(AdmissionScore.subject_type.in_(_subject_type_filter(subject_type)))
        if major_id:
            conditions.append(AdmissionScore.major_id == major_id)
        if year:
            conditions.append(AdmissionScore.year >= year - years_back + 1)
            conditions.append(AdmissionScore.year <= year)

        # LEFT JOIN 院校表和专业表，使结果直接包含 university_name / major_name，
        # 避免 Agent 工具和前端需要二次查询补全名称。
        stmt = (
            select(
                AdmissionScore,
                University.name.label("university_name"),
                Major.name.label("major_name"),
            )
            .outerjoin(University, AdmissionScore.university_id == University.id)
            .outerjoin(Major, AdmissionScore.major_id == Major.id)
        )
        if conditions:
            stmt = stmt.where(and_(*conditions))
        stmt = stmt.order_by(desc(AdmissionScore.year)).limit(50)

        result = await self.db.execute(stmt)
        rows = []
        for row in result.all():
            score = row[0]
            d = score.to_dict()
            d["university_name"] = row[1] or ""
            d["major_name"] = row[2] or ""
            rows.append(d)
        return rows

    # ===== 一分一段 =====

    async def get_latest_rank_year(self, province: str = "") -> int | None:
        """查询一分一段表中最近可用年份（供 year=0 时自动解析）。"""
        stmt = select(func.max(ScoreRank.year))
        if province:
            stmt = stmt.where(ScoreRank.province == province)
        return (await self.db.execute(stmt)).scalar()

    async def get_rank_by_score(
        self, score: int, province: str, year: int, subject_type: str = ""
    ) -> dict | None:
        # 防御：省份/年份为空会污染位次查询结果，直接返回空
        if not province or year <= 0:
            return None
        conditions = [
            ScoreRank.province == province,
            ScoreRank.year == year,
            ScoreRank.score == score,
        ]
        if subject_type:
            conditions.append(ScoreRank.subject_type.in_(_subject_type_filter(subject_type)))

        result = await self.db.execute(
            select(ScoreRank).where(and_(*conditions)).limit(1)
        )
        row = result.scalar_one_or_none()
        return row.to_dict() if row else None

    async def get_nearest_rank(
        self, score: int, province: str, year: int, subject_type: str = ""
    ) -> dict | None:
        """找最接近分数的位次记录（分数可能不在表中）"""
        # 防御：省份/年份为空会污染位次查询结果，直接返回空
        if not province or year <= 0:
            return None
        conditions = [
            ScoreRank.province == province,
            ScoreRank.year == year,
            ScoreRank.score <= score,
        ]
        if subject_type:
            conditions.append(ScoreRank.subject_type.in_(_subject_type_filter(subject_type)))

        result = await self.db.execute(
            select(ScoreRank).where(and_(*conditions)).order_by(desc(ScoreRank.score)).limit(1)
        )
        row = result.scalar_one_or_none()
        return row.to_dict() if row else None

    # ===== 冲稳保推荐 =====

    async def recommend_by_rank(
        self, rank: int, province: str,         subject_type: str = "", strategy: str = "all"
    ) -> dict:
        """基于位次的冲稳保推荐

        策略：用历年录取最低位次与用户位次对比
        ratio = 用户位次 / 院校平均位次
        - ratio > 1：用户位次低于院校（数字大=排名靠后=分数低），考不上
        - ratio < 1：用户位次高于院校，能考上

        分类区间（与 calculate_probability 概率模型对齐）：
        - 冲：1.0 < ratio <= 1.3（用户略低于院校，概率 35-55%，有希望但难）
        - 稳：0.75 <= ratio <= 1.0（匹配区间，概率 70-85%）
        - 保：0.4 <= ratio < 0.75（用户高于院校，概率 85-95%，安全保底）
        - ratio > 1.3 或 ratio < 0.4：过滤（差距过大不现实 / 院校太差浪费志愿）
        """
        # 防御：非法位次（<=0）无法参与比值计算，直接返回空档
        if rank <= 0:
            return {"rush": [], "stable": [], "safe": []}

        # 取最近3年的录取数据
        stmt = (
            select(
                AdmissionScore.university_id,
                func.avg(AdmissionScore.min_rank).label("avg_rank"),
                func.min(AdmissionScore.min_rank).label("best_rank"),
                func.max(AdmissionScore.min_rank).label("worst_rank"),
                func.count(AdmissionScore.id).label("year_count"),
            )
            .where(
                and_(
                    AdmissionScore.province == province,
                    AdmissionScore.min_rank > 0,
                    AdmissionScore.major_id == 0,  # 院校整体线
                )
            )
            .group_by(AdmissionScore.university_id)
            .having(func.count(AdmissionScore.id) >= 2)  # 至少2年数据
        )
        if subject_type:
            stmt = stmt.where(AdmissionScore.subject_type.in_(_subject_type_filter(subject_type)))

        result = await self.db.execute(stmt)
        rows = result.all()

        rush, stable, safe = [], [], []
        for row in rows:
            avg_rank = int(row.avg_rank)
            if avg_rank == 0:
                continue
            ratio = rank / avg_rank
            if 1.0 < ratio <= 1.3:
                # 用户位次略低于院校 → 冲（有希望但难）
                rush.append({"university_id": row.university_id, "avg_rank": avg_rank, "ratio": round(ratio, 2)})
            elif 0.75 <= ratio <= 1.0:
                # 匹配区间 → 稳
                stable.append({"university_id": row.university_id, "avg_rank": avg_rank, "ratio": round(ratio, 2)})
            elif 0.4 <= ratio < 0.75:
                # 用户位次高于院校 → 保底
                safe.append({"university_id": row.university_id, "avg_rank": avg_rank, "ratio": round(ratio, 2)})
            # ratio > 1.3 或 ratio < 0.4：差距过大，过滤

        # 排序：冲按 ratio 升序（接近1的优先，最有希望）；稳按接近1；保按 ratio 降序（接近0.75的优先）
        rush.sort(key=lambda x: x["ratio"])
        stable.sort(key=lambda x: abs(x["ratio"] - 1.0))
        safe.sort(key=lambda x: -x["ratio"])

        output = {}
        if strategy in ("all", "rush"):
            output["rush"] = rush[:15]
        if strategy in ("all", "stable"):
            output["stable"] = stable[:20]
        if strategy in ("all", "safe"):
            output["safe"] = safe[:15]
        return output

    # ===== 录取概率 =====

    async def calculate_probability(self, rank: int, university_id: int, province: str, years: int = 3) -> dict:
        """基于历年位次波动估算录取概率"""
        # 防御：非法位次（<=0）无法参与比值计算
        if rank <= 0:
            return {"probability": None, "reason": "位次必须为正"}
        scores = await self.query_admission_scores(
            university_id=university_id, province=province, years_back=years
        )
        if not scores:
            return {"probability": None, "reason": "无历年数据"}

        ranks = [s["min_rank"] for s in scores if s["min_rank"] > 0]
        if not ranks:
            return {"probability": None, "reason": "无位次数据"}

        avg_rank = sum(ranks) / len(ranks)
        # 简单概率模型：位次比越接近1概率越高
        ratio = rank / avg_rank
        if ratio <= 0.7:
            prob = 0.95
        elif ratio <= 0.9:
            prob = 0.85
        elif ratio <= 1.0:
            prob = 0.70
        elif ratio <= 1.1:
            prob = 0.55
        elif ratio <= 1.3:
            prob = 0.35
        else:
            prob = 0.15

        return {
            "probability": prob,
            "avg_rank": int(avg_rank),
            "user_rank": rank,
            "ratio": round(ratio, 3),
            "years_data": len(ranks),
            "rank_range": [min(ranks), max(ranks)],
        }

    # ===== 位次趋势 =====

    async def rank_trend(self, university_id: int, province: str, years: int = 5) -> list[dict]:
        scores = await self.query_admission_scores(
            university_id=university_id, province=province, years_back=years
        )
        return [
            {"year": s["year"], "min_rank": s["min_rank"], "min_score": s["min_score"]}
            for s in sorted(scores, key=lambda x: x["year"])
            if s["min_rank"] > 0
        ]

    # ===== 招生计划 =====

    async def get_enrollment_plan(
        self, university_id: int, province: str, year: int = 0
    ) -> list[dict]:
        conditions = [
            EnrollmentPlan.university_id == university_id,
            EnrollmentPlan.province == province,
        ]
        if year:
            conditions.append(EnrollmentPlan.year == year)

        stmt = select(EnrollmentPlan).where(and_(*conditions)).order_by(desc(EnrollmentPlan.year)).limit(50)
        result = await self.db.execute(stmt)
        return [row.to_dict() for row in result.scalars().all()]

    async def get_university_majors(
        self,
        university_id: int,
        province: str,
        subject_combination: str = "",
        top_n: int = 5,
    ) -> list[dict]:
        """获取某院校在某省的招生计划专业（关联 Major，用于方案的专业维度）。

        - 取最新年份的招生计划，关联 Major 得到专业名/选科要求/就业率；
        - 若提供 subject_combination，过滤掉选科不满足的专业；
        - 按招生人数降序取前 top_n 个。
        """
        # 该院校在该省的最新招生年份
        latest = (
            await self.db.execute(
                select(func.max(EnrollmentPlan.year))
                .where(
                    and_(
                        EnrollmentPlan.university_id == university_id,
                        EnrollmentPlan.province == province,
                    )
                )
            )
        ).scalar()
        if not latest:
            return []

        stmt = (
            select(
                EnrollmentPlan.major_id,
                EnrollmentPlan.plan_count,
                EnrollmentPlan.batch,
                EnrollmentPlan.tuition,
                Major.name,
                Major.subject_requirement,
                Major.employment_rate,
            )
            .join(Major, Major.id == EnrollmentPlan.major_id)
            .where(
                and_(
                    EnrollmentPlan.university_id == university_id,
                    EnrollmentPlan.province == province,
                    EnrollmentPlan.year == latest,
                    EnrollmentPlan.major_id > 0,
                )
            )
            .order_by(desc(EnrollmentPlan.plan_count))
            .limit(50)
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        user_subjects = set()
        if subject_combination:
            user_subjects = {
                s.strip()
                for s in subject_combination.replace("+", ",").replace("、", ",").split(",")
                if s.strip()
            }

        majors = []
        for row in rows:
            req = row.subject_requirement or ""
            if user_subjects and req:
                req_subjects = {
                    s.strip()
                    for s in req.replace("+", ",").replace("、", ",").split(",")
                    if s.strip()
                }
                if req_subjects and not req_subjects.issubset(user_subjects):
                    continue  # 选科不满足，跳过
            majors.append(
                {
                    "major_name": row.name,
                    "plan_count": row.plan_count,
                    "batch": row.batch,
                    "tuition": row.tuition,
                    "subject_requirement": req,
                    "employment_rate": row.employment_rate,
                }
            )
            if len(majors) >= top_n:
                break
        return majors

    async def get_university_majors_batch(
        self,
        university_ids: set[int],
        province: str,
        subject_combination: str = "",
        top_n: int = 3,
    ) -> dict[int, list[dict]]:
        """批量获取多所院校在某省的招生计划专业（单条 IN 查询，消除逐校 N+1）。

        用于 /plan 等需要一次性补全多所院校专业维度的场景。
        返回 {university_id: [major dict, ...]}，无招生计划的院校返回空列表。
        """
        if not university_ids:
            return {}

        # 1) 批量取每所院校在该省的最新招生年份（按院校分组）
        latest_rows = (
            await self.db.execute(
                select(
                    EnrollmentPlan.university_id,
                    func.max(EnrollmentPlan.year).label("latest_year"),
                )
                .where(
                    and_(
                        EnrollmentPlan.university_id.in_(university_ids),
                        EnrollmentPlan.province == province,
                    )
                )
                .group_by(EnrollmentPlan.university_id)
            )
        ).all()
        latest_by_uni: dict[int, int] = {r.university_id: r.latest_year for r in latest_rows}
        if not latest_by_uni:
            return {uid: [] for uid in university_ids}

        # 2) 批量 JOIN 取所有院校、对应最新年份的招生计划专业
        stmt = (
            select(
                EnrollmentPlan.university_id,
                EnrollmentPlan.year,
                EnrollmentPlan.major_id,
                EnrollmentPlan.plan_count,
                EnrollmentPlan.batch,
                EnrollmentPlan.tuition,
                Major.name,
                Major.subject_requirement,
                Major.employment_rate,
            )
            .join(Major, Major.id == EnrollmentPlan.major_id)
            .where(
                and_(
                    EnrollmentPlan.university_id.in_(university_ids),
                    EnrollmentPlan.province == province,
                    EnrollmentPlan.year.in_(latest_by_uni.values()),
                    EnrollmentPlan.major_id > 0,
                )
            )
            .order_by(
                EnrollmentPlan.university_id,
                desc(EnrollmentPlan.plan_count),
            )
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        user_subjects = set()
        if subject_combination:
            user_subjects = {
                s.strip()
                for s in subject_combination.replace("+", ",").replace("、", ",").split(",")
                if s.strip()
            }

        # 3) 按院校分组，每校取前 top_n 个（选科过滤在 Python 端完成）
        grouped: dict[int, list[dict]] = {uid: [] for uid in university_ids}
        counts: dict[int, int] = {}
        for row in rows:
            uid = row.university_id
            # 仅保留该校“最新年份”的计划（IN 可能带入更早年份的重复行）
            if row.year != latest_by_uni.get(uid):
                continue
            if counts.get(uid, 0) >= top_n:
                continue
            req = row.subject_requirement or ""
            if user_subjects and req:
                req_subjects = {
                    s.strip()
                    for s in req.replace("+", ",").replace("、", ",").split(",")
                    if s.strip()
                }
                if req_subjects and not req_subjects.issubset(user_subjects):
                    continue
            grouped.setdefault(uid, []).append(
                {
                    "major_name": row.name,
                    "plan_count": row.plan_count,
                    "batch": row.batch,
                    "tuition": row.tuition,
                    "subject_requirement": req,
                    "employment_rate": row.employment_rate,
                }
            )
            counts[uid] = counts.get(uid, 0) + 1

        # 回退：当 EnrollmentPlan.major_id=0（不区分专业的招生计划）导致 JOIN Major 查不到时，
        # 直接从 Major 表取该院校的专业作为兜底，避免 /plan 的 majors 恒为空。
        # 注意：仅对有招生计划（在 latest_by_uni 中）但 JOIN 结果为空的院校回退；
        # 完全没有招生计划的院校应返回空列表（与单校版 get_university_majors 行为一致）。
        empty_uids = [uid for uid in university_ids if uid in latest_by_uni and not grouped.get(uid)]
        if empty_uids:
            fallback_rows = (
                await self.db.execute(
                    select(
                        Major.university_id,
                        Major.name,
                        Major.subject_requirement,
                        Major.employment_rate,
                    )
                    .where(Major.university_id.in_(empty_uids))
                    .order_by(Major.university_id, desc(Major.employment_rate))
                )
            ).all()
            fcounts: dict[int, int] = {}
            for row in fallback_rows:
                uid = row.university_id
                if fcounts.get(uid, 0) >= top_n:
                    continue
                req = row.subject_requirement or ""
                if user_subjects and req:
                    req_subjects = {
                        s.strip()
                        for s in req.replace("+", ",").replace("、", ",").split(",")
                        if s.strip()
                    }
                    if req_subjects and not req_subjects.issubset(user_subjects):
                        continue
                grouped.setdefault(uid, []).append(
                    {
                        "major_name": row.name,
                        "plan_count": 0,
                        "batch": "",
                        "tuition": "",
                        "subject_requirement": req,
                        "employment_rate": row.employment_rate,
                    }
                )
                fcounts[uid] = fcounts.get(uid, 0) + 1
        return grouped

    # ===== 省份规则 =====

    async def get_province_rule(self, province: str) -> dict | None:
        result = await self.db.execute(
            select(ProvinceRule).where(ProvinceRule.province == province).limit(1)
        )
        row = result.scalar_one_or_none()
        return row.to_dict() if row else None

    # ===== 选科检查 =====

    async def check_subject_requirement(self, subject_combination: str, province: str = "") -> list[dict]:
        """检查选科组合能报哪些专业（返回兼容的专业）。

        性能优化：仅扫描「有选科要求」的专业（无要求专业恒兼容，无需进库），
        并可选按省份过滤（结合招生计划定位该省招生院校），避免一次性 load 全表。
        """
        subjects = {
            s.strip()
            for s in subject_combination.replace("+", ",").replace("、", ",").split(",")
            if s.strip()
        }
        if not subjects:
            return []

        conditions = [Major.subject_requirement != ""]
        if province:
            # 该省有招生计划的院校专业才参与匹配，缩小扫描范围
            sub = select(EnrollmentPlan.university_id).where(
                EnrollmentPlan.province == province
            ).distinct()
            conditions.append(Major.university_id.in_(sub))

        stmt = select(Major).where(and_(*conditions)).limit(200)
        majors = (await self.db.execute(stmt)).scalars().all()

        compatible = []
        for m in majors:
            req = m.subject_requirement
            req_subjects = {
                s.strip()
                for s in req.replace("+", ",").replace("、", ",").split(",")
                if s.strip()
            }
            if req_subjects.issubset(subjects):
                compatible.append(m.to_dict())
            if len(compatible) >= 50:
                break

        return compatible
