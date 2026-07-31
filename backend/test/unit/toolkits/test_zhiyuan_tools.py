"""智愿 tool 层单元测试（路径加载 + mock 桩，不依赖 Docker/yuxi 全量依赖）

测试当前 zhiyuan_tools.py 中的工具函数：
  search_universities / get_university_detail / query_admission_scores /
  estimate_rank / generate_plan / compare_universities / query_knowledge_graph /
  search_policy / analyze_admission_probability / get_system_status / recommend_majors
"""

from __future__ import annotations

import importlib.util
import sys
import types
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# ---- 桩模块：避免 tools 顶部 import 拉入重依赖 ----
def _stub(name):
    m = types.ModuleType(name)
    sys.modules[name] = m
    return m

# @tool 装饰器桩：原样返回函数（不创建 langchain StructuredTool）
_registry_stub = _stub("yuxi.agents.toolkits.registry")
_registry_stub.tool = lambda *a, **k: (lambda f: f)

# pg_manager 桩
_pg_stub = _stub("yuxi.storage.postgres.manager")
_pg_stub.pg_manager = MagicMock()

# zhiyuan_repository 桩
_repo_stub = _stub("yuxi.repositories.zhiyuan_repository")
_repo_stub.ZhiyuanRepository = MagicMock()
_repo_stub.zhiyuan_repository = MagicMock()
_repo_repo = MagicMock()
_repo_stub.zhiyuan_repository = _repo_repo
_repo_stub.estimate_admission_probability = lambda ratio: 0.95 if ratio <= 0.7 else (0.85 if ratio <= 0.9 else (0.70 if ratio <= 1.0 else (0.55 if ratio <= 1.1 else (0.35 if ratio <= 1.3 else 0.15))))

# 异常类桩
for _exc_name in ("DatabaseError", "DataNotFoundError", "InvalidParameterError", "RepositoryError"):
    _exc = type(_exc_name, (Exception,), {})
    setattr(_repo_stub, _exc_name, _exc)


def _load_tools():
    path = (
        Path(__file__).resolve().parents[3]
        / "package"
        / "yuxi"
        / "agents"
        / "toolkits"
        / "buildin"
        / "zhiyuan_tools.py"
    )
    spec = importlib.util.spec_from_file_location("yuxi.agents.toolkits.buildin.zhiyuan_tools", path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["yuxi.agents.toolkits.buildin.zhiyuan_tools"] = mod
    spec.loader.exec_module(mod)
    return mod


_tools = _load_tools()


# ---- 辅助：构造 mock async context manager ----


def _make_session_ctx():
    """创建一个 mock 的 async context manager，模拟 pg_manager.get_async_session_context()"""
    session = MagicMock()
    ctx = MagicMock()
    ctx.__aenter__ = AsyncMock(return_value=session)
    ctx.__aexit__ = AsyncMock(return_value=None)
    return ctx, session


# ========== search_universities 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_universities_success():
    ctx, session = _make_session_ctx()
    mock_result = {"items": [{"name": "清华大学", "level": "985"}], "total": 1}
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "list_universities", new=AsyncMock(return_value=mock_result)):
        result = await _tools.search_universities(keyword="清华", limit=10)
    assert result["success"] is True
    assert result["data"]["total"] == 1


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_universities_limit_capped():
    """limit 超过 50 应被钳制为 50。"""
    ctx, session = _make_session_ctx()
    captured = {}
    async def fake_list(session, **kwargs):
        captured["limit"] = kwargs.get("limit")
        return {"items": [], "total": 0}
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "list_universities", new=fake_list):
        await _tools.search_universities(limit=999)
    assert captured["limit"] == 50


# ========== get_university_detail 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_detail_success():
    ctx, session = _make_session_ctx()
    mock_detail = {"name": "清华大学", "level": "985", "majors": []}
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "get_university_detail", new=AsyncMock(return_value=mock_detail)):
        result = await _tools.get_university_detail("清华大学")
    assert result["success"] is True
    assert result["data"]["name"] == "清华大学"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_detail_empty_name():
    result = await _tools.get_university_detail("")
    assert result["success"] is False
    assert "不能为空" in result["error"]


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_university_detail_not_found():
    ctx, session = _make_session_ctx()
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "get_university_detail", new=AsyncMock(return_value=None)):
        result = await _tools.get_university_detail("不存在的大学")
    assert result["success"] is False
    assert "未找到" in result["error"]


# ========== query_admission_scores 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_admission_scores_success():
    ctx, session = _make_session_ctx()
    mock_scores = [
        {"year": 2025, "min_score": 688, "avg_rank": 190, "batch": "本科一批"},
        {"year": 2024, "min_score": 690, "avg_rank": 180, "batch": "本科一批"},
    ]
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "query_admission_scores", new=AsyncMock(return_value=mock_scores)):
        result = await _tools.query_admission_scores(
            university_name="清华大学", province="河南", subject_type="理科",
        )
    assert result["success"] is True
    assert len(result["data"]) == 2


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_admission_scores_missing_params():
    result = await _tools.query_admission_scores("", "河南", "理科")
    assert result["success"] is False
    assert "不能为空" in result["error"]


# ========== estimate_rank 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_estimate_rank_success():
    ctx, session = _make_session_ctx()
    mock_rank = {"rank": 5000, "same_score_count": 80}
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "get_score_rank", new=AsyncMock(return_value=mock_rank)):
        result = await _tools.estimate_rank(score=620, province="河南", subject_type="理科")
    assert result["success"] is True
    assert result["data"]["rank"] == 5000


@pytest.mark.unit
@pytest.mark.asyncio
async def test_estimate_rank_not_found():
    ctx, session = _make_session_ctx()
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "get_score_rank", new=AsyncMock(return_value=None)):
        result = await _tools.estimate_rank(score=620, province="河南", subject_type="理科")
    assert result["success"] is False
    assert "未能" in result["error"]


# ========== generate_plan 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_generate_plan_success():
    ctx, session = _make_session_ctx()
    mock_plan = {
        "rush": [{"university_name": "武大", "rank_ratio": 1.02, "probability": 0.55}],
        "stable": [],
        "safe": [{"university_name": "郑大", "rank_ratio": 0.65, "probability": 0.95}],
        "summary": {"total": 2, "rush_count": 1, "stable_count": 0, "safe_count": 1},
    }
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "generate_plan", new=AsyncMock(return_value=mock_plan)):
        result = await _tools.generate_plan(
            score=620, rank=5000, province="河南", subject_type="理科",
        )
    assert result["success"] is True
    assert "summary_text" in result["data"]
    assert "冲" in result["data"]["summary_text"]


# ========== analyze_admission_probability 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_analyze_admission_probability_success():
    """验证录取概率分析工具能正确使用 avg_rank 数据（Issue 2 修复验证）。"""
    ctx, session = _make_session_ctx()
    mock_scores = [
        {"year": 2025, "min_score": 688, "avg_rank": 190, "batch": "本科一批"},
        {"year": 2024, "min_score": 690, "avg_rank": 180, "batch": "本科一批"},
        {"year": 2023, "min_score": 685, "avg_rank": 200, "batch": "本科一批"},
    ]
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "query_admission_scores", new=AsyncMock(return_value=mock_scores)):
        result = await _tools.analyze_admission_probability(
            user_rank=5000, university_name="清华大学", province="河南", subject_type="理科",
        )
    # 修复前：avg_rank 全为 0 → ranks 列表为空 → 返回 "缺少位次数据"
    # 修复后：avg_rank > 0 → 正常计算概率
    assert result["success"] is True
    assert "probability" in result["data"]
    assert 0 <= result["data"]["probability"] <= 1.0
    assert result["data"]["avg_rank"] > 0


@pytest.mark.unit
@pytest.mark.asyncio
async def test_analyze_admission_probability_no_data():
    ctx, session = _make_session_ctx()
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "query_admission_scores", new=AsyncMock(return_value=[])):
        result = await _tools.analyze_admission_probability(
            user_rank=5000, university_name="清华大学", province="河南", subject_type="理科",
        )
    assert result["success"] is False
    assert "未找到" in result["error"]


@pytest.mark.unit
@pytest.mark.asyncio
async def test_analyze_admission_probability_invalid_rank():
    result = await _tools.analyze_admission_probability(
        user_rank=0, university_name="清华大学", province="河南", subject_type="理科",
    )
    assert result["success"] is False
    assert "正数" in result["error"]


# ========== query_knowledge_graph 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_knowledge_graph_empty_entity():
    result = await _tools.query_knowledge_graph("")
    assert result["success"] is False
    assert "不能为空" in result["error"]


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_knowledge_graph_success():
    ctx, session = _make_session_ctx()
    mock_relations = [
        {"start": "清华大学", "end": "计算机科学与技术", "relation": "has_major"},
    ]
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "query_graph", new=AsyncMock(return_value=mock_relations)):
        result = await _tools.query_knowledge_graph("清华大学")
    assert result["success"] is True
    assert result["data"]["count"] == 1


@pytest.mark.unit
@pytest.mark.asyncio
async def test_query_knowledge_graph_no_results():
    ctx, session = _make_session_ctx()
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "query_graph", new=AsyncMock(return_value=[])):
        result = await _tools.query_knowledge_graph("不存在的实体")
    assert result["success"] is False
    assert "未找到" in result["error"]


# ========== search_policy 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_policy_success():
    ctx, session = _make_session_ctx()
    mock_result = {"results": [{"title": "平行志愿", "content": "..."}], "total": 1}
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "search_policy", new=AsyncMock(return_value=mock_result)):
        result = await _tools.search_policy("什么是平行志愿")
    assert result["success"] is True


@pytest.mark.unit
@pytest.mark.asyncio
async def test_search_policy_short_question():
    result = await _tools.search_policy("a")
    assert result["success"] is False
    assert "2 个字符" in result["error"]


# ========== get_system_status 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_get_system_status_success():
    ctx, session = _make_session_ctx()
    mock_health = {"status": "ok", "tables": {}}
    mock_stats = {"university_count": 100}
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "get_health", new=AsyncMock(return_value=mock_health)), \
         patch.object(_tools.zhiyuan_repository, "get_statistics", new=AsyncMock(return_value=mock_stats)):
        result = await _tools.get_system_status()
    assert result["success"] is True
    assert result["data"]["health"]["status"] == "ok"
    assert result["data"]["statistics"]["university_count"] == 100


# ========== compare_universities 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_universities_too_many():
    result = await _tools.compare_universities(
        ["校A", "校B", "校C", "校D", "校E", "校F"], "河南", "理科",
    )
    assert result["success"] is False
    assert "5" in result["error"]


@pytest.mark.unit
@pytest.mark.asyncio
async def test_compare_universities_empty_list():
    result = await _tools.compare_universities([], "河南", "理科")
    assert result["success"] is False
    assert "至少" in result["error"]


# ========== recommend_majors 测试 ==========


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_majors_success():
    ctx, session = _make_session_ctx()
    mock_rank = {"rank": 5000, "same_score_count": 80}
    mock_plan = {
        "rush": [{"university_name": "武大", "majors": [{"major_name": "法学", "plan_count": 5}]}],
        "stable": [],
        "safe": [],
        "summary": {"total": 1, "rush_count": 1, "stable_count": 0, "safe_count": 0},
    }
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "get_score_rank", new=AsyncMock(return_value=mock_rank)), \
         patch.object(_tools.zhiyuan_repository, "generate_plan", new=AsyncMock(return_value=mock_plan)):
        result = await _tools.recommend_majors(
            score=620, province="河南", subject_type="理科",
        )
    assert result["success"] is True
    assert result["data"]["total"] >= 1


@pytest.mark.unit
@pytest.mark.asyncio
async def test_recommend_majors_no_rank():
    ctx, session = _make_session_ctx()
    with patch.object(_tools.pg_manager, "get_async_session_context", return_value=ctx), \
         patch.object(_tools.zhiyuan_repository, "get_score_rank", new=AsyncMock(return_value=None)):
        result = await _tools.recommend_majors(
            score=620, province="河南", subject_type="理科",
        )
    assert result["success"] is False
    assert "位次" in result["error"]
