"""智愿 tool 层单元测试（路径加载 + mock 桩，不依赖 Docker/yuxi 全量依赖）"""

import importlib.util
import sys
import types
from pathlib import Path

import pytest

# ---- 桩模块：避免 tools 顶部 import yuxi.agents.toolkits.registry / yuxi.utils 拉入重依赖 ----
def _stub(name):
    m = types.ModuleType(name)
    sys.modules[name] = m
    return m

_stub("yuxi.agents.toolkits.registry")  # 提供 @tool 装饰器依赖的模块占位
# @tool 装饰器：测试桩，原样返回函数
sys.modules["yuxi.agents.toolkits.registry"].tool = lambda *a, **k: (lambda f: f)
_stub("yuxi.utils")                      # 提供 logger 依赖的模块占位
sys.modules["yuxi.utils"].logger = types.SimpleNamespace(error=lambda *a, **k: None)
# tools 内部 try: from yuxi.knowledge.runtime import knowledge_base —— 该分支在测试中被 mock
_stub("yuxi.knowledge.runtime")
_stub("yuxi.storage.postgres.manager")
_stub("yuxi.repositories.zhiyuan_repository")
# stub yuxi.storage.neo4j so tools can import get_shared_neo4j_connection / neo4j_read
_neo4j_stub = _stub("yuxi.storage.neo4j")
_neo4j_stub.get_shared_neo4j_connection = lambda: None
_neo4j_stub.neo4j_read = lambda *a, **k: []


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


@pytest.mark.unit
def test_query_graph_empty_entity_rejected(monkeypatch):
    # 空实体名应在校验分支被拒（需先提供运行中的 Neo4j 连接以越过“服务未就绪”早返回）
    class FakeConn:
        def is_running(self):
            return True

        @property
        def driver(self):
            return object()

    neo4j_module = sys.modules["yuxi.storage.neo4j"]
    monkeypatch.setattr(neo4j_module, "get_shared_neo4j_connection", lambda: FakeConn())

    async def run():
        return await _tools.query_graph("", "has_major", 2)

    import asyncio

    result = asyncio.run(run())
    assert "不能为空" in result
    assert "服务未就绪" not in result


@pytest.mark.unit
def test_query_graph_overlong_entity_rejected(monkeypatch):
    class FakeConn:
        def is_running(self):
            return True

        @property
        def driver(self):
            return object()

    neo4j_module = sys.modules["yuxi.storage.neo4j"]
    monkeypatch.setattr(neo4j_module, "get_shared_neo4j_connection", lambda: FakeConn())

    async def run():
        return await _tools.query_graph("x" * 101, "has_major", 2)

    import asyncio

    result = asyncio.run(run())
    assert "过长" in result


@pytest.mark.unit
def test_query_graph_depth_clamped(monkeypatch):
    """depth 超出 [1,4] 应被钳制；用 spy 捕获最终传入的 Cypher 验证 *1..4。"""
    captured = {}

    # Mock Neo4j connection manager to avoid real DB dependency
    class FakeConn:
        def is_running(self):
            return True

        @property
        def driver(self):
            return object()

    def fake_neo4j_read(driver, cypher, **kwargs):
        captured["cypher"] = cypher
        captured["params"] = kwargs
        return []

    # Patch get_shared_neo4j_connection and neo4j_read in the tools module
    neo4j_module = sys.modules["yuxi.storage.neo4j"]
    monkeypatch.setattr(neo4j_module, "get_shared_neo4j_connection", lambda: FakeConn())
    monkeypatch.setattr(neo4j_module, "neo4j_read", fake_neo4j_read)

    async def run():
        return await _tools.query_graph("计算机科学与技术", "has_major", 100)

    import asyncio

    result = asyncio.run(run())
    # 深度被钳制为 4：Cypher 应包含 *1..4 而非 *1..100
    assert "*1..4" in captured["cypher"]
    assert "*1..100" not in captured["cypher"]
    # Cypher 应使用正确的变长路径语法 [r*1..4] 或 [r:RELATION*1..4]
    assert "[r" in captured["cypher"]
    assert "]" in captured["cypher"]
    # 实体名被 trim 后传入参数
    assert captured["params"]["start_entity"] == "计算机科学与技术"


@pytest.mark.unit
def test_query_graph_input_schema_depth_upper_bound():
    """QueryGraphInput 的 depth 上限应为 4（与实现钳制值、router le=4 对齐）。"""
    schema = _tools.QueryGraphInput
    # depth=4 合法
    assert schema(start_entity="清华大学", depth=4).depth == 4
    # depth=5 非法
    with pytest.raises(Exception):
        schema(start_entity="清华大学", depth=5)


@pytest.mark.unit
def test_generate_plan_rejects_nonnumeric_rank():
    """profile 中 rank 为非数字字符串时应返回友好错误，而非异常文本。"""
    import asyncio
    import json as _json

    result = asyncio.run(
        _tools.generate_application_plan(_json.dumps({"rank": "abc", "province": "河南"}))
    )
    assert "整数" in result
    assert "异常" not in result  # 不应走到 _with_repo 的异常兜底


@pytest.mark.unit
def test_generate_plan_rejects_nonpositive_rank():
    """profile 中 rank<=0 应被拒绝。"""
    import asyncio
    import json as _json

    result = asyncio.run(
        _tools.generate_application_plan(_json.dumps({"rank": -3, "province": "河南"}))
    )
    assert "正整数" in result


@pytest.mark.unit
def test_uni_cache_prune_expired_and_capacity():
    """缓存维护：过期项被清理；超容量时淘汰最旧的一批。"""
    cache = _tools._uni_cache
    cache.clear()
    now = 1_000_000.0
    ttl = _tools._CACHE_TTL
    max_size = _tools._CACHE_MAX_SIZE

    # 1) 过期清理：一条过期 + 一条新鲜
    cache["过期校"] = ({"id": 1}, now - ttl - 1)
    cache["新鲜校"] = ({"id": 2}, now - 1)
    _tools._prune_uni_cache(now)
    assert "过期校" not in cache
    assert "新鲜校" in cache

    # 2) 容量淘汰：填满至上限（全部未过期），prune 后应淘汰最旧 20%
    cache.clear()
    for i in range(max_size):
        cache[f"u{i}"] = ({"id": i}, now - (max_size - i) * 0.001)  # u0 最旧
    _tools._prune_uni_cache(now)
    assert len(cache) <= max_size - max_size // 5
    assert "u0" not in cache  # 最旧的被淘汰
    assert f"u{max_size - 1}" in cache  # 最新的保留
    cache.clear()


@pytest.mark.unit
def test_resolve_university_uses_cache():
    """同名院校在 TTL 内第二次解析应命中缓存，不再触发 repo 查询。"""
    import asyncio

    _tools._uni_cache.clear()
    calls = {"n": 0}

    class FakeRepo:
        async def get_university_by_name(self, name):
            calls["n"] += 1
            return {"id": 42, "name": name}

    async def run():
        repo = FakeRepo()
        r1 = await _tools._resolve_university(repo, "郑州大学")
        r2 = await _tools._resolve_university(repo, "郑州大学")
        return r1, r2

    r1, r2 = asyncio.run(run())
    assert r1 == r2 == {"id": 42, "name": "郑州大学"}
    assert calls["n"] == 1  # 第二次命中缓存
    _tools._uni_cache.clear()
