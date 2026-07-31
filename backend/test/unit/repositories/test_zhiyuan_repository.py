"""智愿 Repository 单元测试（使用 SQLite 内存库，不依赖 Docker）

直接按文件路径加载 models/repository，绕过 yuxi/__init__.py 的重量级依赖链。
测试当前仓库 API：list_universities / get_university_detail / query_admission_scores /
get_score_rank / generate_plan / get_health / get_statistics / query_university_admission
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

# 直接加载模块，绕过 yuxi 包的 __init__.py（它会拉入 minio/config/loguru 等）
_PACKAGE_DIR = Path(__file__).resolve().parents[3] / "package"

def _load_module(name: str, file_path: Path):
    spec = importlib.util.spec_from_file_location(name, file_path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

_models = _load_module("yuxi.repositories.zhiyuan_models", _PACKAGE_DIR / "yuxi" / "repositories" / "zhiyuan_models.py")

# repository 内部 import 了 models，需要先把 models 注册到 sys.modules
sys.modules.setdefault("yuxi.repositories.zhiyuan_models", _models)
_repo_mod = _load_module("yuxi.repositories.zhiyuan_repository", _PACKAGE_DIR / "yuxi" / "repositories" / "zhiyuan_repository.py")

Base = _models.Base
University = _models.University
Major = _models.Major
AdmissionScore = _models.AdmissionScore
ScoreRank = _models.ScoreRank
ProvinceRule = _models.ProvinceRule
EnrollmentPlan = _models.EnrollmentPlan
ZhiyuanRepository = _repo_mod.ZhiyuanRepository
estimate_admission_probability = _repo_mod.estimate_admission_probability
InvalidParameterError = _repo_mod.InvalidParameterError


@pytest_asyncio.fixture
async def db_session():
    """创建 SQLite 内存数据库 session"""
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session

    await engine.dispose()


@pytest_asyncio.fixture
async def seeded_session(db_session):
    """带种子数据的 session"""
    # 院校
    uni1 = University(name="清华大学", province="北京", city="北京", level="985", type="综合", nature="公办", master_points=55, doctor_points=40, key_disciplines="计算机科学与技术")
    uni2 = University(name="武汉大学", province="湖北", city="武汉", level="985", type="综合", nature="公办", master_points=46, doctor_points=30, key_disciplines="测绘科学")
    uni3 = University(name="郑州大学", province="河南", city="郑州", level="211", type="综合", nature="公办", master_points=35, doctor_points=18, key_disciplines="化学")
    db_session.add_all([uni1, uni2, uni3])
    await db_session.flush()

    # 专业
    m1 = Major(university_id=uni1.id, name="计算机科学与技术", code="080901", degree="工学学士", duration="4年", subject_category="工学", subject_requirement="物理", employment_rate=95.2, avg_salary=12500, career_directions="软件开发,算法工程师")
    m2 = Major(university_id=uni1.id, name="软件工程", code="080902", degree="工学学士", duration="4年", subject_category="工学", subject_requirement="物理", employment_rate=96.1, avg_salary=13000, career_directions="软件开发,测试工程师")
    m3 = Major(university_id=uni2.id, name="法学", code="030101K", degree="法学学士", duration="4年", subject_category="法学", subject_requirement="", employment_rate=85.3, avg_salary=8000, career_directions="律师,法官")
    m5 = Major(university_id=uni2.id, name="计算机科学与技术", code="080901", degree="工学学士", duration="4年", subject_category="工学", subject_requirement="物理", employment_rate=93.0, avg_salary=11000, career_directions="软件开发")
    m4 = Major(university_id=uni3.id, name="临床医学", code="100201K", degree="医学学士", duration="5年", subject_category="医学", subject_requirement="物理+化学", employment_rate=94.0, avg_salary=8500, career_directions="临床医生")
    db_session.add_all([m1, m2, m3, m4, m5])
    await db_session.flush()

    # 录取分数（河南，近3年）—— min_rank 用于 generate_plan 和 query_admission_scores
    scores = [
        AdmissionScore(university_id=uni1.id, major_id=0, province="河南", year=2023, subject_type="理科", batch="本科一批", min_score=685, max_score=710, avg_score=695, min_rank=200, plan_count=30),
        AdmissionScore(university_id=uni1.id, major_id=0, province="河南", year=2024, subject_type="理科", batch="本科一批", min_score=690, max_score=715, avg_score=700, min_rank=180, plan_count=30),
        AdmissionScore(university_id=uni1.id, major_id=0, province="河南", year=2025, subject_type="理科", batch="本科一批", min_score=688, max_score=712, avg_score=698, min_rank=190, plan_count=32),
        AdmissionScore(university_id=uni2.id, major_id=0, province="河南", year=2023, subject_type="理科", batch="本科一批", min_score=620, max_score=650, avg_score=635, min_rank=5000, plan_count=80),
        AdmissionScore(university_id=uni2.id, major_id=0, province="河南", year=2024, subject_type="理科", batch="本科一批", min_score=625, max_score=655, avg_score=638, min_rank=4800, plan_count=80),
        AdmissionScore(university_id=uni2.id, major_id=0, province="河南", year=2025, subject_type="理科", batch="本科一批", min_score=622, max_score=652, avg_score=636, min_rank=4900, plan_count=82),
        AdmissionScore(university_id=uni3.id, major_id=0, province="河南", year=2023, subject_type="理科", batch="本科一批", min_score=580, max_score=610, avg_score=595, min_rank=15000, plan_count=200),
        AdmissionScore(university_id=uni3.id, major_id=0, province="河南", year=2024, subject_type="理科", batch="本科一批", min_score=585, max_score=615, avg_score=598, min_rank=14500, plan_count=200),
        AdmissionScore(university_id=uni3.id, major_id=0, province="河南", year=2025, subject_type="理科", batch="本科一批", min_score=582, max_score=612, avg_score=596, min_rank=14800, plan_count=210),
    ]
    db_session.add_all(scores)

    # 一分一段 — 使用 2024 年数据（不使用 year-1=2025，测试动态年份查询）
    ranks = [
        ScoreRank(province="河南", year=2024, subject_type="理科", score=690, rank=180, segment_count=15),
        ScoreRank(province="河南", year=2024, subject_type="理科", score=680, rank=350, segment_count=20),
        ScoreRank(province="河南", year=2024, subject_type="理科", score=620, rank=5100, segment_count=80),
        ScoreRank(province="河南", year=2024, subject_type="理科", score=580, rank=15200, segment_count=150),
        ScoreRank(province="河南", year=2024, subject_type="理科", score=500, rank=80000, segment_count=500),
    ]
    db_session.add_all(ranks)

    # 省份规则
    rule = ProvinceRule(province="河南", year=2025, mode="平行志愿", batch_count=2, max_per_batch=6, subject_mode="传统文理", description="本科一批、二批各6个志愿", tips="冲2稳2保2")
    db_session.add(rule)

    # 招生计划
    plans = [
        EnrollmentPlan(university_id=uni1.id, major_id=m1.id, province="河南", year=2025, subject_type="理科", batch="本科一批", plan_count=10, tuition="5000", remark=""),
        EnrollmentPlan(university_id=uni1.id, major_id=m2.id, province="河南", year=2025, subject_type="理科", batch="本科一批", plan_count=15, tuition="5000", remark=""),
        EnrollmentPlan(university_id=uni2.id, major_id=m3.id, province="河南", year=2025, subject_type="理科", batch="本科一批", plan_count=20, tuition="4500", remark=""),
        EnrollmentPlan(university_id=uni2.id, major_id=m5.id, province="河南", year=2025, subject_type="理科", batch="本科一批", plan_count=12, tuition="5500", remark=""),
    ]
    db_session.add_all(plans)

    await db_session.commit()
    return db_session


@pytest.fixture
def repo():
    """无状态仓库实例"""
    return ZhiyuanRepository()


# ========== list_universities 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_list_universities_by_keyword(seeded_session, repo):
    result = await repo.list_universities(seeded_session, keyword="清华")
    assert result["total"] == 1
    assert result["items"][0]["name"] == "清华大学"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_list_universities_by_level(seeded_session, repo):
    result = await repo.list_universities(seeded_session, level="985")
    assert result["total"] == 2
    names = {r["name"] for r in result["items"]}
    assert "清华大学" in names
    assert "武汉大学" in names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_list_universities_by_province(seeded_session, repo):
    result = await repo.list_universities(seeded_session, province="河南")
    assert result["total"] == 1
    assert result["items"][0]["name"] == "郑州大学"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_list_universities_invalid_province(seeded_session, repo):
    with pytest.raises(InvalidParameterError):
        await repo.list_universities(seeded_session, province="火星")


@pytest.mark.unit
@pytest.mark.asyncio
async def test_list_universities_invalid_level(seeded_session, repo):
    with pytest.raises(InvalidParameterError):
        await repo.list_universities(seeded_session, level="C9")


# ========== get_university_detail 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_detail(seeded_session, repo):
    detail = await repo.get_university_detail(seeded_session, "清华大学")
    assert detail is not None
    assert detail["name"] == "清华大学"
    assert detail["level"] == "985"
    assert "majors" in detail
    assert len(detail["majors"]) >= 1


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_detail_not_found(seeded_session, repo):
    detail = await repo.get_university_detail(seeded_session, "不存在的大学")
    assert detail is None


# ========== query_admission_scores 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_admission_scores(seeded_session, repo):
    """验证 query_admission_scores 返回正确的分数和位次数据。"""
    scores = await repo.query_admission_scores(
        seeded_session,
        university_name="清华大学",
        province="河南",
        subject_type="理科",
        years=3,
    )
    assert len(scores) == 3
    # 验证 avg_rank 不再为 0（Issue 2 修复：使用 min_rank 作为 rank 值）
    for s in scores:
        assert s["avg_rank"] > 0, f"avg_rank 应为 min_rank 值，不应为 0: {s}"
        assert s["min_score"] > 600
        assert s["year"] in (2023, 2024, 2025)


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_admission_scores_empty(seeded_session, repo):
    scores = await repo.query_admission_scores(
        seeded_session,
        university_name="清华大学",
        province="北京",
        subject_type="理科",
    )
    assert scores == []


# ========== get_score_rank 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_score_rank_exact(seeded_session, repo):
    """验证精确分数匹配的位次查询。"""
    result = await repo.get_score_rank(
        seeded_session, score=690, province="河南", subject_type="理科",
    )
    assert result is not None
    assert result["rank"] == 180
    assert result["same_score_count"] == 15


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_score_rank_dynamic_year(seeded_session, repo):
    """验证动态年份查询（Issue 6 修复）：数据年份为 2024，非 year-1。"""
    # 种子数据使用 2024 年，当前年份 2026 的 year-1=2025 在库中不存在。
    # 修复后应通过 MAX(year) 找到 2024 年的数据。
    result = await repo.get_score_rank(
        seeded_session, score=620, province="河南", subject_type="理科",
    )
    assert result is not None
    assert result["rank"] == 5100


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_score_rank_nearest(seeded_session, repo):
    """验证近似分数查询：685 不在表中，应找到最近的 680。"""
    result = await repo.get_score_rank(
        seeded_session, score=685, province="河南", subject_type="理科",
    )
    assert result is not None
    # 685 介于 680(rank=350) 和 690(rank=180) 之间，应取最近的
    assert result["rank"] > 0


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_score_rank_invalid_score(seeded_session, repo):
    with pytest.raises(InvalidParameterError):
        await repo.get_score_rank(
            seeded_session, score=100, province="河南", subject_type="理科",
        )


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_score_rank_invalid_province(seeded_session, repo):
    with pytest.raises(InvalidParameterError):
        await repo.get_score_rank(
            seeded_session, score=690, province="火星", subject_type="理科",
        )


# ========== generate_plan 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_thresholds(seeded_session, repo):
    """验证冲稳保分档阈值（Issue 3 修复）。

    种子数据 avg_rank（基于 min_rank 的 3 年平均）：
      - 清华大学：avg ≈ (200+180+190)/3 ≈ 190
      - 武汉大学：avg ≈ (5000+4800+4900)/3 ≈ 4900
      - 郑州大学：avg ≈ (15000+14500+14800)/3 ≈ 14767

    阈值（修复后）：
      rush: 1.0 < ratio <= 1.3
      stable: 0.75 <= ratio <= 1.0
      safe: 0.4 <= ratio < 0.75
      ratio > 1.3 或 ratio < 0.4：过滤
    """
    # rank=5000：武大 ratio≈1.02 → rush；清华 ratio≈26.3 > 1.3 过滤；郑大 ratio≈0.34 < 0.4 过滤
    plan = await repo.generate_plan(
        seeded_session, score=620, rank=5000, province="河南", subject_type="理科",
    )
    assert "rush" in plan and "stable" in plan and "safe" in plan
    assert plan["summary"]["total"] > 0

    rush_names = [u["university_name"] for u in plan["rush"]]
    assert "武汉大学" in rush_names
    # 清华和郑大因差距过大被过滤
    all_names = set(rush_names) | {u["university_name"] for u in plan["stable"]} | {u["university_name"] for u in plan["safe"]}
    assert "清华大学" not in all_names
    assert "郑州大学" not in all_names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_stable_range(seeded_session, repo):
    """rank=4900：武大 ratio≈1.0 → stable"""
    plan = await repo.generate_plan(
        seeded_session, score=620, rank=4900, province="河南", subject_type="理科",
    )
    stable_names = [u["university_name"] for u in plan["stable"]]
    assert "武汉大学" in stable_names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_safe_range(seeded_session, repo):
    """rank=3000：武大 ratio≈0.61 → safe"""
    plan = await repo.generate_plan(
        seeded_session, score=620, rank=3000, province="河南", subject_type="理科",
    )
    safe_names = [u["university_name"] for u in plan["safe"]]
    assert "武汉大学" in safe_names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_safe_has_lower_bound(seeded_session, repo):
    """验证 safe 档有下限（Issue 3 修复）：ratio < 0.4 应被过滤。

    rank=100：武大 ratio≈0.02 < 0.4 → 过滤
    """
    plan = await repo.generate_plan(
        seeded_session, score=620, rank=100, province="河南", subject_type="理科",
    )
    # 武大 ratio ≈ 100/4900 ≈ 0.02，应被过滤（不在 safe 中）
    all_names = (
        {u["university_name"] for u in plan["rush"]}
        | {u["university_name"] for u in plan["stable"]}
        | {u["university_name"] for u in plan["safe"]}
    )
    assert "武汉大学" not in all_names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_invalid_score(seeded_session, repo):
    with pytest.raises(InvalidParameterError):
        await repo.generate_plan(
            seeded_session, score=100, rank=5000, province="河南", subject_type="理科",
        )


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_invalid_rank(seeded_session, repo):
    with pytest.raises(InvalidParameterError):
        await repo.generate_plan(
            seeded_session, score=600, rank=0, province="河南", subject_type="理科",
        )


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_empty(seeded_session, repo):
    """无录取数据的省份+科类组合应返回空方案。"""
    plan = await repo.generate_plan(
        seeded_session, score=600, rank=5000, province="北京", subject_type="理科",
    )
    assert plan["summary"]["total"] == 0
    assert plan["rush"] == []
    assert plan["stable"] == []
    assert plan["safe"] == []


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_has_probability(seeded_session, repo):
    """验证方案中每所院校都有概率值。"""
    plan = await repo.generate_plan(
        seeded_session, score=620, rank=5000, province="河南", subject_type="理科",
    )
    for category in ("rush", "stable", "safe"):
        for item in plan[category]:
            assert "probability" in item
            assert 0.0 <= item["probability"] <= 1.0
            assert "rank_ratio" in item
            assert "avg_rank" in item


# ========== estimate_admission_probability 测试 ==========


@pytest.mark.unit
def test_estimate_admission_probability_ranges():
    """验证概率分段函数。"""
    assert estimate_admission_probability(0.5) == 0.95   # ratio <= 0.7
    assert estimate_admission_probability(0.7) == 0.95   # 边界
    assert estimate_admission_probability(0.8) == 0.85   # 0.7 < ratio <= 0.9
    assert estimate_admission_probability(0.9) == 0.85   # 边界
    assert estimate_admission_probability(1.0) == 0.70   # 0.9 < ratio <= 1.0
    assert estimate_admission_probability(1.1) == 0.55   # 1.0 < ratio <= 1.1
    assert estimate_admission_probability(1.3) == 0.35   # 1.1 < ratio <= 1.3
    assert estimate_admission_probability(1.5) == 0.15   # ratio > 1.3
    assert estimate_admission_probability(0) == 0.0      # 边界
    assert estimate_admission_probability(-1) == 0.0     # 非法


# ========== get_health / get_statistics 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_health(seeded_session, repo):
    health = await repo.get_health(seeded_session)
    assert "status" in health
    assert "tables" in health


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_statistics(seeded_session, repo):
    stats = await repo.get_statistics(seeded_session)
    assert "university_count" in stats
    assert stats["university_count"] == 3


# ========== query_university_admission 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_university_admission(seeded_session, repo):
    """验证综合查询接口返回院校+分数+招生计划。"""
    result = await repo.query_university_admission(
        seeded_session, university_name="清华大学", province="河南", subject_type="理科",
    )
    assert result is not None
    assert "university" in result
    assert result["university"]["name"] == "清华大学"
    assert "scores" in result
    assert len(result["scores"]) > 0
    # 验证 avg_rank 不为 0（Issue 2 修复）
    for s in result["scores"]:
        assert s["avg_rank"] > 0


# ========== 模型 Mixin 共享列测试 ==========


@pytest.mark.unit
def test_plan_score_mixin_shared_columns():
    """EnrollmentPlan 与 AdmissionScore 应共享同一组列定义。"""
    shared = {
        "university_id",
        "major_id",
        "province",
        "year",
        "subject_type",
        "batch",
        "plan_count",
    }
    for col in shared:
        assert hasattr(_models.EnrollmentPlan, col), f"EnrollmentPlan 缺少 {col}"
        assert hasattr(_models.AdmissionScore, col), f"AdmissionScore 缺少 {col}"
    # 两表各自特有列仍存在
    assert hasattr(_models.EnrollmentPlan, "tuition")
    assert hasattr(_models.AdmissionScore, "min_rank")


# ========== recommend_majors 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_majors_success(seeded_session, repo):
    """正常推荐：应返回专业列表和位次。"""
    result = await repo.recommend_majors(
        seeded_session, score=620, province="河南", subject_type="理科"
    )
    assert "recommendations" in result
    assert "total" in result
    assert "user_rank" in result
    assert result["user_rank"]["rank"] == 5100
    assert result["total"] >= 0


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_majors_with_interests(seeded_session, repo):
    """带兴趣方向：匹配的专业应排在前面。"""
    result = await repo.recommend_majors(
        seeded_session, score=620, province="河南", subject_type="理科",
        interests="计算机"
    )
    assert result["total"] > 0
    # 第一个结果应包含"计算机"
    recs = result["recommendations"]
    if recs:
        assert "计算机" in recs[0]["major_name"]


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_majors_invalid_province(seeded_session, repo):
    """非法省份应报错。"""
    with pytest.raises(InvalidParameterError):
        await repo.recommend_majors(
            seeded_session, score=620, province="火星", subject_type="理科"
        )


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_majors_invalid_score(seeded_session, repo):
    """超范围分数应报错。"""
    with pytest.raises(InvalidParameterError):
        await repo.recommend_majors(
            seeded_session, score=100, province="河南", subject_type="理科"
        )


# ========== get_province_rule 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_province_rule_success(seeded_session, repo):
    """正常查询省份规则。"""
    result = await repo.get_province_rule(seeded_session, "河南")
    assert result["province"] == "河南"
    assert result["mode"] == "平行志愿"
    assert result["batch_count"] == 2
    assert result["max_per_batch"] == 6


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_province_rule_not_found(seeded_session, repo):
    """无数据的省份应报 DataNotFoundError。"""
    DataNotFoundError = _repo_mod.DataNotFoundError
    with pytest.raises(DataNotFoundError):
        await repo.get_province_rule(seeded_session, "北京")


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_province_rule_invalid_province(seeded_session, repo):
    """非法省份应报错。"""
    with pytest.raises(InvalidParameterError):
        await repo.get_province_rule(seeded_session, "火星")


# ========== compare_majors 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_majors_by_name(seeded_session, repo):
    """按专业名对比：应返回所有院校的该专业。"""
    result = await repo.compare_majors(
        seeded_session, major_names=["计算机科学与技术"]
    )
    assert result["count"] == 2  # 清华大学 + 武汉大学均有此专业
    names = {c["university_name"] for c in result["comparisons"]}
    assert "清华大学" in names
    assert "武汉大学" in names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_majors_multiple(seeded_session, repo):
    """多个专业对比。"""
    result = await repo.compare_majors(
        seeded_session, major_names=["计算机科学与技术", "法学"]
    )
    assert result["count"] == 3  # 2个计算机科学与技术 + 1个法学


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_majors_with_university_filter(seeded_session, repo):
    """限定院校范围。"""
    result = await repo.compare_majors(
        seeded_session,
        major_names=["计算机科学与技术", "法学"],
        university_names=["清华大学"],
    )
    assert result["count"] == 1
    assert result["comparisons"][0]["university_name"] == "清华大学"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_majors_not_found(seeded_session, repo):
    """查不到专业应报 DataNotFoundError。"""
    DataNotFoundError = _repo_mod.DataNotFoundError
    with pytest.raises(DataNotFoundError):
        await repo.compare_majors(seeded_session, major_names=["不存在的专业"])


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_majors_empty_list(seeded_session, repo):
    """空专业列表应报错。"""
    with pytest.raises(InvalidParameterError):
        await repo.compare_majors(seeded_session, major_names=[])


# ========== check_subject 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_check_subject_match(seeded_session, repo):
    """选科满足要求：matched=True。"""
    result = await repo.check_subject(
        seeded_session, subject_combination="物理+化学+生物"
    )
    assert result["total"] > 0
    # 计算机科学与技术要求"物理"，用户有物理 → matched=True
    cs_items = [c for c in result["checked"] if c["major_name"] == "计算机科学与技术"]
    if cs_items:
        assert cs_items[0]["matched"] is True


@pytest.mark.unit
@pytest.mark.asyncio
async def test_check_subject_mismatch(seeded_session, repo):
    """选科不满足要求：matched=False。"""
    result = await repo.check_subject(
        seeded_session, subject_combination="历史+政治+地理"
    )
    # 临床医学要求"物理+化学"，用户只有文科 → matched=False
    med_items = [c for c in result["checked"] if c["major_name"] == "临床医学"]
    if med_items:
        assert med_items[0]["matched"] is False
        assert result["all_match"] is False


@pytest.mark.unit
@pytest.mark.asyncio
async def test_check_subject_with_major_filter(seeded_session, repo):
    """按专业名模糊匹配。"""
    result = await repo.check_subject(
        seeded_session,
        subject_combination="物理+化学",
        major_name="计算机",
    )
    assert result["total"] > 0
    for item in result["checked"]:
        assert "计算机" in item["major_name"]


@pytest.mark.unit
@pytest.mark.asyncio
async def test_check_subject_empty_combination(seeded_session, repo):
    """空选科组合应报错。"""
    with pytest.raises(InvalidParameterError):
        await repo.check_subject(seeded_session, subject_combination="")
