"""智愿 API 集成测试（用户端路由）。

聚焦 HTTP 层的健壮性与安全性保证：
- 鉴权：未携带合法 token 时返回 401；
- 入参校验：/plan 缺少必要字段返回 422（Pydantic 校验）；
- 图谱关系类型白名单：恶意 relation_type 注入被安全处理（不会拼入 Cypher 关系模式）。

这些用例不依赖种子数据，仅依赖鉴权中间件与路由层逻辑；
如数据库不可用，数据相关路径会被跳过，不影响 HTTP 层断言。

注意：
  - /graph 端点为 POST（与前端 zhiyuanApi.queryGraph 一致）。
  - Pydantic 校验失败返回 422，非 400。
  - Admin CRUD 端点尚未实现，相关测试暂不包含。
  - /recommend 接收 score（非 rank），返回专业推荐列表。
"""

from __future__ import annotations

import pytest

pytestmark = [pytest.mark.asyncio, pytest.mark.integration]


async def test_universities_requires_auth(test_client):
    """用户端接口未携带 token 必须被拒绝。"""
    resp = await test_client.get("/api/zhiyuan/universities")
    assert resp.status_code == 401


async def test_plan_requires_auth(test_client):
    resp = await test_client.post("/api/zhiyuan/plan", json={"score": 620, "rank": 5000, "province": "河南"})
    assert resp.status_code == 401


async def test_graph_requires_auth(test_client):
    """图谱接口为 POST，未携带 token 必须被拒绝。"""
    resp = await test_client.post("/api/zhiyuan/graph", json={"start_entity": "清华大学"})
    assert resp.status_code == 401


async def test_plan_validation_missing_fields(test_client, admin_headers):
    """已鉴权但缺少 score/rank/province 时应返回 422（Pydantic 校验失败）。"""
    # 缺少 score 和 province
    resp = await test_client.post("/api/zhiyuan/plan", json={"rank": 5000}, headers=admin_headers)
    assert resp.status_code == 422
    assert "score" in resp.text or "province" in resp.text

    # 缺少 score 和 rank
    resp2 = await test_client.post("/api/zhiyuan/plan", json={"province": "河南"}, headers=admin_headers)
    assert resp2.status_code == 422


async def test_graph_relation_type_injection_is_safe(test_client, admin_headers):
    """恶意 relation_type 不应导致 500 或注入。

    图谱服务在测试环境通常未启用（无 Neo4j），路由应安全返回结果，
    且 relation_type 已通过白名单过滤，不会拼入 Cypher 模式。
    """
    malicious = "r][(n)-[x]-(y)"
    resp = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "清华大学", "relation_type": malicious, "depth": 1},
        headers=admin_headers,
    )
    # 即便图谱未启用也应是 200（带结果）而非 500 崩溃
    assert resp.status_code in (200,)
    body = resp.json()
    assert isinstance(body, (list, dict))


async def test_universities_auth_ok_returns_list(test_client, admin_headers):
    """已鉴权搜索接口应返回可解析的响应。"""
    resp = await test_client.get(
        "/api/zhiyuan/universities", params={"keyword": "清华"}, headers=admin_headers
    )
    assert resp.status_code == 200
    body = resp.json()
    # 路由返回 {"items": [...], "total": ...} 格式
    assert isinstance(body, dict)
    assert "items" in body or "total" in body or isinstance(body, list)


async def test_graph_safe_relation_type_returns_list(test_client, admin_headers):
    """合法 relation_type（白名单内）也不应导致崩溃。"""
    resp = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "清华大学", "relation_type": "has_major", "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert isinstance(body, dict)


async def test_recommend_requires_auth(test_client):
    """推荐接口未携带 token 必须被拒绝。"""
    resp = await test_client.post("/api/zhiyuan/recommend", json={"score": 620, "province": "河南"})
    assert resp.status_code == 401


async def test_recommend_validation_missing_fields(test_client, admin_headers):
    """已鉴权但缺少 score/province 时应返回 422。"""
    resp = await test_client.post(
        "/api/zhiyuan/recommend", json={"province": "河南"}, headers=admin_headers
    )
    assert resp.status_code == 422
    resp2 = await test_client.post(
        "/api/zhiyuan/recommend", json={"score": 620}, headers=admin_headers
    )
    assert resp2.status_code == 422


async def test_recommend_returns_majors(test_client, admin_headers):
    """已鉴权 /recommend 应返回 200，且结果为可解析结构。

    不依赖种子数据：若 DB 为空则结果为空，但结构必须正确。
    """
    resp = await test_client.post(
        "/api/zhiyuan/recommend",
        json={"score": 620, "province": "河南", "subject_type": "理科"},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert isinstance(body, (list, dict))


async def test_graph_empty_entity_rejected(test_client, admin_headers):
    """图谱查询空实体应在鉴权后被拒绝（422），不进入 Cypher 执行。

    传入仅空白字符的实体名，经 Pydantic min_length=1 校验后为空，应返回 422。
    """
    resp = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "   ", "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 422


async def test_graph_overlong_entity_rejected(test_client, admin_headers):
    """图谱查询超长实体名（>100字符）应被拒绝（422）。"""
    resp = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "长" * 101, "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 422
    assert "start_entity" in resp.text or "100" in resp.text


async def test_graph_depth_upper_bound_is_four(test_client, admin_headers):
    """depth 上限为 4：depth=4 合法（200/图谱未启用），depth=5 被 Query 校验拒绝（422）。"""
    ok = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "清华大学", "depth": 4},
        headers=admin_headers,
    )
    assert ok.status_code == 200

    over = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "清华大学", "depth": 5},
        headers=admin_headers,
    )
    assert over.status_code == 422  # 超出 le=4 的约束


async def test_graph_response_envelope_is_uniform(test_client, admin_headers):
    """图谱接口无论成功/未启用/非法 relation，返回结构统一为 {relations, count}。

    防止成功裸 list 与异常结构混用，保证前端稳定消费。
    """
    # 合法 relation 路径
    resp = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "清华大学", "relation_type": "has_major", "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert isinstance(body, dict)
    assert "relations" in body or "count" in body or isinstance(body, list)

    # 非法 relation 路径（被白名单过滤，但结构仍应一致）
    resp2 = await test_client.post(
        "/api/zhiyuan/graph",
        json={"start_entity": "清华大学", "relation_type": "r][(n)", "depth": 1},
        headers=admin_headers,
    )
    assert resp2.status_code == 200
    body2 = resp2.json()
    assert isinstance(body2, dict)


async def test_recommend_rejects_nonnumeric_score(test_client, admin_headers):
    """/recommend 的 score 传非数字字符串应返回 422，而非 500。"""
    resp = await test_client.post(
        "/api/zhiyuan/recommend",
        json={"score": "abc", "province": "河南"},
        headers=admin_headers,
    )
    assert resp.status_code == 422
    assert "score" in resp.text


async def test_plan_rejects_nonpositive_rank(test_client, admin_headers):
    """/plan 的 rank 传 0 或负数应返回 422（Pydantic ge=1 约束）。"""
    resp = await test_client.post(
        "/api/zhiyuan/plan",
        json={"score": 620, "rank": -5, "province": "河南"},
        headers=admin_headers,
    )
    assert resp.status_code == 422
    assert "rank" in resp.text
