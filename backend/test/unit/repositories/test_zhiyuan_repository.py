"""智愿 Repository 单元测试（使用 SQLite 内存库，不依赖 Docker）

直接按文件路径加载 models/repository，绕过 yuxi/__init__.py 的重量级依赖链。
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
College = _models.College
Major = _models.Major
AdmissionScore = _models.AdmissionScore
ScoreRank = _models.ScoreRank
ProvinceRule = _models.ProvinceRule
EnrollmentPlan = _models.EnrollmentPlan
ZhiyuanRepository = _repo_mod.ZhiyuanRepository


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
async def repo(db_session):
    return ZhiyuanRepository(db_session)


@pytest_asyncio.fixture
async def seeded_repo(db_session):
    """带种子数据的 repo"""
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
    m4 = Major(university_id=uni3.id, name="临床医学", code="100201K", degree="医学学士", duration="5年", subject_category="医学", subject_requirement="物理+化学", employment_rate=94.0, avg_salary=8500, career_directions="临床医生")
    db_session.add_all([m1, m2, m3, m4])
    await db_session.flush()

    # 录取分数（河南，近3年）
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

    # 一分一段
    ranks = [
        ScoreRank(province="河南", year=2025, subject_type="理科", score=690, rank=180, segment_count=15),
        ScoreRank(province="河南", year=2025, subject_type="理科", score=680, rank=350, segment_count=20),
        ScoreRank(province="河南", year=2025, subject_type="理科", score=620, rank=5100, segment_count=80),
        ScoreRank(province="河南", year=2025, subject_type="理科", score=580, rank=15200, segment_count=150),
        ScoreRank(province="河南", year=2025, subject_type="理科", score=500, rank=80000, segment_count=500),
    ]
    db_session.add_all(ranks)

    # 省份规则
    rule = ProvinceRule(province="河南", year=2025, mode="平行志愿", batch_count=2, max_per_batch=6, subject_mode="传统文理", description="本科一批、二批各6个志愿", tips="冲2稳2保2")
    db_session.add(rule)

    # 招生计划（清华 2025 河南，物理类，关联已有专业）
    plans = [
        EnrollmentPlan(university_id=uni1.id, major_id=m1.id, province="河南", year=2025, subject_type="理科", batch="本科一批", plan_count=10, tuition="5000", remark=""),
        EnrollmentPlan(university_id=uni1.id, major_id=m2.id, province="河南", year=2025, subject_type="理科", batch="本科一批", plan_count=15, tuition="5000", remark=""),
    ]
    db_session.add_all(plans)

    await db_session.commit()
    return ZhiyuanRepository(db_session)


# ========== 测试用例 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_by_name(seeded_repo):
    result = await seeded_repo.get_university_by_name("清华")
    assert result is not None
    assert result["name"] == "清华大学"
    assert result["level"] == "985"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_not_found(seeded_repo):
    result = await seeded_repo.get_university_by_name("不存在的大学")
    assert result is None


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_universities_by_level(seeded_repo):
    results = await seeded_repo.search_universities(level="985")
    assert len(results) == 2
    names = {r["name"] for r in results}
    assert "清华大学" in names
    assert "武汉大学" in names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_universities_by_province(seeded_repo):
    results = await seeded_repo.search_universities(province="河南")
    assert len(results) == 1
    assert results[0]["name"] == "郑州大学"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_majors_by_university(seeded_repo):
    uni = await seeded_repo.get_university_by_name("清华")
    majors = await seeded_repo.get_majors_by_university(uni["id"])
    assert len(majors) == 2
    names = {m["name"] for m in majors}
    assert "计算机科学与技术" in names
    assert "软件工程" in names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_majors_by_university_limit(seeded_repo):
    # limit 应截断返回数量，防止院校专业过多时一次返回全表
    uni = await seeded_repo.get_university_by_name("清华")
    truncated = await seeded_repo.get_majors_by_university(uni["id"], limit=1)
    assert len(truncated) == 1
    full = await seeded_repo.get_majors_by_university(uni["id"], limit=100)
    assert len(full) == 2  # 默认上限足够覆盖种子数据


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_majors(seeded_repo):
    results = await seeded_repo.compare_majors(["计算机科学与技术", "法学"])
    assert len(results) == 2
    names = {r["name"] for r in results}
    assert names == {"计算机科学与技术", "法学"}


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_admission_scores(seeded_repo):
    uni = await seeded_repo.get_university_by_name("清华")
    scores = await seeded_repo.query_admission_scores(
        university_id=uni["id"], province="河南", year=2025, subject_type="理科"
    )
    assert len(scores) == 3  # 2023, 2024, 2025
    assert all(s["min_score"] > 680 for s in scores)


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_rank_by_score(seeded_repo):
    result = await seeded_repo.get_rank_by_score(690, "河南", 2025, "理科")
    assert result is not None
    assert result["rank"] == 180


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_nearest_rank(seeded_repo):
    # 685不在表中，应找到680的记录
    result = await seeded_repo.get_nearest_rank(685, "河南", 2025, "理科")
    assert result is not None
    assert result["score"] == 680
    assert result["rank"] == 350


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_by_rank(seeded_repo):
    # 位次5000 → 武大是稳（avg~4900），清华是冲（avg~190），郑大是保（avg~14800）
    # 分类规则：ratio = user_rank / avg_rank
    #   ratio > 1.25 → rush（冲）；0.833 <= ratio <= 1.25 → stable（稳）；ratio < 0.833 → safe（保）
    result = await seeded_repo.recommend_by_rank(5000, "河南", "理科", "all")
    assert "rush" in result
    assert "stable" in result
    assert "safe" in result

    qinghua = await seeded_repo.get_university_by_name("清华")
    zhengda = await seeded_repo.get_university_by_name("郑州大学")
    wuda = await seeded_repo.get_university_by_name("武汉大学")

    # 清华 ratio≈5000/190≈26 > 1.25 → 冲
    rush_ids = [item["university_id"] for item in result["rush"]]
    assert qinghua["id"] in rush_ids
    assert qinghua["id"] not in result["stable"]
    assert qinghua["id"] not in result["safe"]

    # 郑大 ratio≈5000/14800≈0.34 < 0.833 → 保
    safe_ids = [item["university_id"] for item in result["safe"]]
    assert zhengda["id"] in safe_ids

    # 武大 ratio≈5000/4900≈1.02 ∈ [0.833,1.25) → 稳
    stable_ids = [item["university_id"] for item in result["stable"]]
    assert wuda["id"] in stable_ids

    # 单档策略：strategy="stable" 只返回稳档
    stable_only = await seeded_repo.recommend_by_rank(5000, "河南", "理科", "stable")
    assert set(stable_only.keys()) == {"stable"}
    assert wuda["id"] in [i["university_id"] for i in stable_only["stable"]]

    # 每个结果项字段完整
    for cat in ("rush", "stable", "safe"):
        for item in result[cat]:
            assert "university_id" in item and "avg_rank" in item and "ratio" in item


@pytest.mark.unit
@pytest.mark.asyncio
async def test_calculate_probability(seeded_repo):
    uni = await seeded_repo.get_university_by_name("武汉大学")
    # 位次5000 vs 武大avg ~4900 → 概率应该较高
    result = await seeded_repo.calculate_probability(5000, uni["id"], "河南", 3)
    assert result["probability"] is not None
    assert 0 < result["probability"] <= 1
    assert result["years_data"] == 3


@pytest.mark.unit
@pytest.mark.asyncio
async def test_rank_trend(seeded_repo):
    uni = await seeded_repo.get_university_by_name("清华")
    trend = await seeded_repo.rank_trend(uni["id"], "河南", 5)
    assert len(trend) == 3
    assert trend[0]["year"] == 2023
    assert trend[-1]["year"] == 2025


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_province_rule(seeded_repo):
    rule = await seeded_repo.get_province_rule("河南")
    assert rule is not None
    assert rule["mode"] == "平行志愿"
    assert rule["max_per_batch"] == 6


@pytest.mark.unit
@pytest.mark.asyncio
async def test_check_subject_requirement(seeded_repo):
    # 优化后只扫描「有选科要求」的专业；无要求的专业（法学）不再进入结果集。
    # 物理+化学+生物 → 应满足要求"物理"的计算机类 与 "物理+化学"的临床医学
    compatible = await seeded_repo.check_subject_requirement("物理+化学+生物")
    names = {m["name"] for m in compatible}
    assert "计算机科学与技术" in names  # 要求物理
    assert "临床医学" in names  # 要求物理+化学
    assert "法学" not in names  # 无要求，已排除

    # 仅选"历史" → 计算机/临床要求物理，均不满足 → 结果为空
    empty = await seeded_repo.check_subject_requirement("历史")
    assert empty == []

    # 空选科组合 → 直接返回空，不触发查询
    assert await seeded_repo.check_subject_requirement("") == []


@pytest.mark.unit
@pytest.mark.asyncio
async def test_check_subject_requirement_province_filter(seeded_repo):
    # 按省份过滤：仅匹配该省有招生计划的院校专业。
    # 种子中招生计划仅清华(河南)，故临床医学(郑大)被排除，但郑大不在河南招生计划。
    compatible = await seeded_repo.check_subject_requirement("物理+化学+生物", province="河南")
    names = {m["name"] for m in compatible}
    assert "计算机科学与技术" in names
    # 郑大临床(河南无招生计划) 不应出现
    assert "临床医学" not in names


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_id_by_name(seeded_repo):
    assert await seeded_repo.get_university_id_by_name("清华大学") is not None
    assert await seeded_repo.get_university_id_by_name("不存在的大学") is None


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_maps(seeded_repo):
    uni = await seeded_repo.get_university_by_name("清华")
    maps = await seeded_repo.get_university_maps({uni["id"]}, fields=("name", "level"))
    assert uni["id"] in maps
    assert maps[uni["id"]]["name"] == "清华大学"
    assert maps[uni["id"]]["level"] == "985"
    # 空集合返回空字典，不触发查询
    assert await seeded_repo.get_university_maps(set()) == {}


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_maps_ignores_non_column_fields(seeded_repo):
    """fields 含非列属性（如私有方法/to_dict/敏感字段）时静默忽略，不崩溃、不泄漏。"""
    uni = await seeded_repo.get_university_by_name("清华")
    # 混入非法字段：可调用方法、下划线私有、不存在的属性
    maps = await seeded_repo.get_university_maps(
        {uni["id"]},
        fields=("name", "to_dict", "__dict__", "password", "level"),
    )
    assert uni["id"] in maps
    # 合法字段正常返回
    assert maps[uni["id"]]["name"] == "清华大学"
    assert maps[uni["id"]]["level"] == "985"
    # 非法字段未进入结果（未泄漏、未混淆）
    assert "to_dict" not in maps[uni["id"]]
    assert "__dict__" not in maps[uni["id"]]
    assert "password" not in maps[uni["id"]]


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_maps_all_invalid_fields_falls_back_to_name(seeded_repo):
    """全部字段非法时回退到 name，避免返回空 cols 导致 SQL 异常。"""
    uni = await seeded_repo.get_university_by_name("清华")
    maps = await seeded_repo.get_university_maps(
        {uni["id"]}, fields=("__dict__", "not_a_column")
    )
    assert uni["id"] in maps
    assert maps[uni["id"]]["name"] == "清华大学"
    # 回退字段仅含 name（id 始终返回但不在业务字段中）
    assert set(maps[uni["id"]].keys()) == {"name"}


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_majors(seeded_repo):
    # 清华 2025 河南有 2 个招生计划专业（计算机科学与技术、软件工程）
    uni = await seeded_repo.get_university_by_name("清华")
    majors = await seeded_repo.get_university_majors(uni["id"], "河南", top_n=5)
    assert len(majors) == 2
    names = {m["major_name"] for m in majors}
    assert "计算机科学与技术" in names
    assert "软件工程" in names
    # 按招生人数降序：软件工程(15) 应排在 计算机(10) 之前
    assert majors[0]["major_name"] == "软件工程"

    # 选科过滤：只选"历史"应被过滤掉（两者都要求物理）
    filtered = await seeded_repo.get_university_majors(uni["id"], "河南", "历史", top_n=5)
    assert filtered == []

    # 选科"物理"可满足两个专业
    ok = await seeded_repo.get_university_majors(uni["id"], "河南", "物理", top_n=5)
    assert len(ok) == 2


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_majors_no_plan(seeded_repo):
    # 武汉大学在种子数据中没有招生计划 → 返回空
    uni = await seeded_repo.get_university_by_name("武汉大学")
    majors = await seeded_repo.get_university_majors(uni["id"], "河南")
    assert majors == []


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_majors_batch(seeded_repo):
    # 批量版应与单校版结果一致，且只有单条 IN 查询（消除逐校 N+1）
    qinghua = await seeded_repo.get_university_by_name("清华")
    zhengda = await seeded_repo.get_university_by_name("郑州大学")
    wuda = await seeded_repo.get_university_by_name("武汉大学")

    batch = await seeded_repo.get_university_majors_batch(
        {qinghua["id"], zhengda["id"], wuda["id"]}, "河南", top_n=5
    )
    # 清华 2 个专业、郑大/武大在种子中无招生计划 → 空（与单校版行为一致）
    assert len(batch[qinghua["id"]]) == 2
    assert batch[zhengda["id"]] == []
    assert batch[wuda["id"]] == []

    # 与单校版逐个调用结果一致（顺序可能不同，仅校验集合）
    single_qh = await seeded_repo.get_university_majors(qinghua["id"], "河南", top_n=5)
    assert {m["major_name"] for m in batch[qinghua["id"]]} == {
        m["major_name"] for m in single_qh
    }

    # 选科过滤在批量版同样生效：只选"历史"应过滤掉清华全部（均要求物理）
    filtered = await seeded_repo.get_university_majors_batch(
        {qinghua["id"]}, "河南", "历史", top_n=5
    )
    assert filtered[qinghua["id"]] == []

    # 空集合输入 → 返回空字典，不触发查询
    assert await seeded_repo.get_university_majors_batch(set(), "河南") == {}


# ===== 录取概率 / 冲稳保防御性用例 =====


@pytest.mark.unit
@pytest.mark.asyncio
async def test_calculate_probability_rank_guard(seeded_repo):
    # rank <= 0 应被防御，返回 None 而非抛除零异常
    uni = await seeded_repo.get_university_by_name("清华")
    res = await seeded_repo.calculate_probability(0, uni["id"], "河南")
    assert res["probability"] is None
    assert "位次" in res["reason"]
    res_neg = await seeded_repo.calculate_probability(-10, uni["id"], "河南")
    assert res_neg["probability"] is None


@pytest.mark.unit
@pytest.mark.asyncio
async def test_calculate_probability_ranges(seeded_repo):
    # 清华 avg_rank~190：用户位次远小于 avg（ratio<0.7）→ 高概率 0.95
    uni = await seeded_repo.get_university_by_name("清华")
    high = await seeded_repo.calculate_probability(100, uni["id"], "河南")
    assert high["probability"] == 0.95
    # 用户位次远大于 avg（ratio>1.3）→ 低概率 0.15
    low = await seeded_repo.calculate_probability(5000, uni["id"], "河南")
    assert low["probability"] == 0.15
    # 概率始终在 [0,1]
    assert 0.0 <= high["probability"] <= 1.0


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_by_rank_zero_rank(seeded_repo):
    # rank <= 0 应返回空档，而非产生负 ratio
    res = await seeded_repo.recommend_by_rank(0, "河南", "理科", "all")
    assert res == {"rush": [], "stable": [], "safe": []}
    res_neg = await seeded_repo.recommend_by_rank(-5, "河南", "理科", "all")
    assert res_neg == {"rush": [], "stable": [], "safe": []}


# ===== 模型 Mixin 共享列 =====


@pytest.mark.unit
def test_plan_score_mixin_shared_columns():
    # EnrollmentPlan 与 AdmissionScore 应共享同一组列定义（来自 PlanScoreMixin）
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
    # to_dict 不抛异常且包含共享字段
    assert "province" in _models.EnrollmentPlan.__table__.columns
    assert "province" in _models.AdmissionScore.__table__.columns


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_like_wildcard_not_injected(seeded_repo):
    # LIKE 通配符注入防护：用户输入含 % 应被当作字面量，而非模糊通配
    # 数据库中不存在名称含 "%" 字面量的院校，故应返回空
    results = await seeded_repo.search_universities(keyword="%")
    assert results == []
    # 名称含下划线通配符也应被转义
    results2 = await seeded_repo.search_universities(keyword="_")
    assert results2 == []
    # 正常关键字仍可命中
    normal = await seeded_repo.search_universities(keyword="清华")
    assert len(normal) == 1
    assert normal[0]["name"] == "清华大学"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_universities_limit_capped(seeded_repo):
    # search_* 的 limit 应有硬上限，防止全表返回
    capped = await seeded_repo.search_universities(keyword="", limit=99999)
    assert len(capped) <= 100
    # limit <= 0 应被钳制为至少 1
    at_least_one = await seeded_repo.search_universities(keyword="", limit=0)
    assert len(at_least_one) >= 1


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_majors_limit_capped(seeded_repo):
    capped = await seeded_repo.search_majors(name="", limit=99999)
    assert len(capped) <= 100
    at_least_one = await seeded_repo.search_majors(name="", limit=-5)
    assert len(at_least_one) >= 1


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_rank_by_score_empty_province_returns_none(seeded_repo):
    # 空省份/非法年份应直接返回 None，避免污染位次查询
    assert await seeded_repo.get_rank_by_score(690, "", 2025, "理科") is None
    assert await seeded_repo.get_rank_by_score(690, "河南", 0, "理科") is None
    # 正常查询仍命中
    hit = await seeded_repo.get_rank_by_score(690, "河南", 2025, "理科")
    assert hit is not None
    assert hit["rank"] == 180


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_nearest_rank_empty_province_returns_none(seeded_repo):
    assert await seeded_repo.get_nearest_rank(685, "", 2025, "理科") is None
    assert await seeded_repo.get_nearest_rank(685, "河南", -1, "理科") is None
    # 正常查询仍命中（最接近且不超过的分数 680 -> rank 350）
    hit = await seeded_repo.get_nearest_rank(685, "河南", 2025, "理科")
    assert hit is not None
    assert hit["score"] == 680
    assert hit["rank"] == 350


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_majors_university_name_wildcard_escaped(seeded_repo):
    # university_name 含通配符应被转义，不应误匹配所有院校充当过滤条件。
    # 由于 "%" 转义后匹配不到任何院校，uni_id 为 None，过滤不生效，
    # 结果应与不传 university_name 时一致（仅按专业名返回，不扩大匹配范围）。
    with_wildcard = await seeded_repo.compare_majors(["计算机科学与技术"], university_name="%")
    without_filter = await seeded_repo.compare_majors(["计算机科学与技术"])
    assert with_wildcard == without_filter
    # 关键：通配符没有被当作模糊匹配，未把"武汉大学法学"等其他院校专业也拉进来
    names = {r["name"] for r in with_wildcard}
    assert names == {"计算机科学与技术"}
