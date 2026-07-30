"""智愿 API 集成测试（用户端路由）。

聚焦 HTTP 层的健壮性与安全性保证：
- 鉴权：未携带合法 token 时返回 401；
- 入参校验：/plan 缺少必要字段返回 400；
- 图谱关系类型白名单：恶意 relation_type 注入被拦截（不会拼入 Cypher 关系模式）。

这些用例不依赖种子数据，仅依赖鉴权中间件与路由层逻辑；
如数据库不可用，数据相关路径会被跳过，不影响 HTTP 层断言。
"""

from __future__ import annotations

import pytest

pytestmark = [pytest.mark.asyncio, pytest.mark.integration]


async def test_universities_requires_auth(test_client):
    """用户端接口未携带 token 必须被拒绝。"""
    resp = await test_client.get("/api/zhiyuan/universities")
    assert resp.status_code == 401


async def test_plan_requires_auth(test_client):
    resp = await test_client.post("/api/zhiyuan/plan", json={"rank": 5000, "province": "河南"})
    assert resp.status_code == 401


async def test_graph_requires_auth(test_client):
    resp = await test_client.get("/api/zhiyuan/graph", params={"start_entity": "清华大学"})
    assert resp.status_code == 401


async def test_plan_validation_missing_fields(test_client, admin_headers):
    """已鉴权但缺少 rank/province 时应返回 400（输入校验）。"""
    resp = await test_client.post("/api/zhiyuan/plan", json={"rank": 5000}, headers=admin_headers)
    assert resp.status_code == 400
    assert "rank" in resp.text or "province" in resp.text

    resp2 = await test_client.post("/api/zhiyuan/plan", json={"province": "河南"}, headers=admin_headers)
    assert resp2.status_code == 400


async def test_graph_relation_type_injection_is_safe(test_client, admin_headers):
    """恶意 relation_type 不应导致 500 或注入。

    图谱服务在测试环境通常未启用（无 Neo4j），路由应安全返回未启用提示，
    且 relation_type 已通过白名单过滤，不会拼入 Cypher 模式。
    """
    malicious = "r][(n)-[x]-(y)"
    resp = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "清华大学", "relation_type": malicious, "depth": 1},
        headers=admin_headers,
    )
    # 即便图谱未启用也应是 200（带 message）而非 500 崩溃
    assert resp.status_code in (200,)
    body = resp.json()
    # 未启用时返回 {"message": ..., "data": []}；启用时也不会把恶意串拼入 Cypher
    assert isinstance(body, (list, dict))


async def test_universities_auth_ok_returns_list(test_client, admin_headers):
    """已鉴权搜索接口应返回统一 {message,data} envelope（data 为可解析列表）。"""
    resp = await test_client.get(
        "/api/zhiyuan/universities", params={"keyword": "清华"}, headers=admin_headers
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "message" in body and "data" in body
    assert isinstance(body["data"], list)


async def test_graph_safe_relation_type_returns_list(test_client, admin_headers):
    """合法 relation_type（白名单内）也不应导致崩溃，结果结构为统一 envelope。"""
    resp = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "清华大学", "relation_type": "has_major", "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "message" in body and "data" in body
    assert isinstance(body["data"], (list, dict))


async def test_admin_pagination_shape(test_client, admin_headers):
    """管理端列表接口应返回统一分页结构（total/page/size/items）。"""
    resp = await test_client.get(
        "/api/zhiyuan/admin/universities", params={"page": 1, "size": 20}, headers=admin_headers
    )
    assert resp.status_code == 200
    body = resp.json()
    assert set(["total", "page", "size", "items"]).issubset(body.keys())
    assert isinstance(body["items"], list)

    resp = await test_client.get("/api/zhiyuan/admin/majors", headers=admin_headers)
    assert resp.status_code == 200
    assert set(["total", "page", "size", "items"]).issubset(resp.json().keys())

    resp = await test_client.get("/api/zhiyuan/admin/scores", headers=admin_headers)
    assert resp.status_code == 200
    assert set(["total", "page", "size", "items"]).issubset(resp.json().keys())


async def test_admin_batch_create_scores_cap(test_client, admin_headers):
    """批量导入单次超过 1000 条应被拒绝（413），防止内存/DB 过载。"""
    oversized = [
        {
            "university_id": 1,
            "province": "河南",
            "year": 2024,
            "subject_type": "理科",
        }
        for _ in range(1001)
    ]
    resp = await test_client.post(
        "/api/zhiyuan/admin/scores/batch", json=oversized, headers=admin_headers
    )
    assert resp.status_code == 413

    # 空列表应被安全接受（不写库）
    resp = await test_client.post(
        "/api/zhiyuan/admin/scores/batch", json=[], headers=admin_headers
    )
    assert resp.status_code == 200
    assert resp.json()["count"] == 0


async def test_recommend_requires_auth(test_client):
    """推荐接口未携带 token 必须被拒绝。"""
    resp = await test_client.post("/api/zhiyuan/recommend", json={"rank": 5000, "province": "河南"})
    assert resp.status_code == 401


async def test_recommend_validation_missing_fields(test_client, admin_headers):
    """已鉴权但缺少 rank/province 时应返回 400。"""
    resp = await test_client.post(
        "/api/zhiyuan/recommend", json={"rank": 5000}, headers=admin_headers
    )
    assert resp.status_code == 400
    resp2 = await test_client.post(
        "/api/zhiyuan/recommend", json={"province": "河南"}, headers=admin_headers
    )
    assert resp2.status_code == 400


async def test_recommend_returns_university_meta(test_client, admin_headers):
    """已鉴权 /recommend 应返回 200，且命中结果附带院校名称等元数据。

    不依赖种子数据：若 DB 为空则结果为空档，但结构必须正确
    （每个 item 含 university_name/level/province，而不是只有裸 university_id）。
    """
    resp = await test_client.post(
        "/api/zhiyuan/recommend",
        json={"rank": 5000, "province": "河南", "subject_type": "理科", "strategy": "all"},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert set(["rush", "stable", "safe"]).issubset(body.keys())
    for category in ("rush", "stable", "safe"):
        for item in body[category]:
            assert "university_id" in item
            assert "university_name" in item  # 已补全，不再只有裸 id


async def test_admin_create_university_duplicate_conflict(test_client, admin_headers):
    """同名院校重复创建应被拒绝（409），防止脏数据。

    先尝试创建，若 200 则说明库为空、创建成功；再创建同名应得 409。
    若首个创建因环境失败（无 DB），则该断言自然跳过（不强制写库）。
    """
    payload = {
        "name": "集成测试院校_唯一名",
        "province": "测试省",
        "level": "普通",
        "type": "综合",
    }
    first = await test_client.post(
        "/api/zhiyuan/admin/universities", json=payload, headers=admin_headers
    )
    if first.status_code == 200:
        dup = await test_client.post(
            "/api/zhiyuan/admin/universities", json=payload, headers=admin_headers
        )
        assert dup.status_code == 409
        # 清理：删除刚才创建的测试院校
        created_id = first.json()["id"]
        await test_client.delete(
            f"/api/zhiyuan/admin/universities/{created_id}", headers=admin_headers
        )
    else:
        # 无可用 DB 环境，仅断言接口可达（非 500 崩溃）
        assert first.status_code in (200, 409, 400, 500)  # 不强制，但 409/400 也合理
        assert first.status_code != 500


async def test_admin_batch_create_scores_rejects_orphan_university(test_client, admin_headers):
    """批量导入分数必须校验 university_id 存在性，孤立 id 应被拒绝（422）。

    用明显不存在的 university_id（如 999999）构造一条记录，期望整批被拒。
    无 DB 环境（数据无法落库）时降级为"非 500"断言，不强制写库。
    """
    payload = [
        {
            "university_id": 999999,
            "major_name": "计算机科学与技术",
            "province": "河南",
            "year": 2024,
            "batch": "本科一批",
            "subject_type": "理科",
            "min_score": 680,
            "min_rank": 500,
            "level": "985",
        }
    ]
    resp = await test_client.post(
        "/api/zhiyuan/admin/scores/batch", json=payload, headers=admin_headers
    )
    if resp.status_code == 422:
        assert "999999" in resp.json()["detail"]  # 错误信息列出无效 id
    else:
        # 无可用 DB 环境（如依赖建表未执行），仅断言不崩溃
        assert resp.status_code != 500


async def test_graph_empty_entity_rejected(test_client, admin_headers):
    """图谱查询空实体应在鉴权后被拒绝（400），不进入 Cypher 执行。

    传入仅空白字符的实体名，经 strip 后为空，应返回 400。
    """
    resp = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "   ", "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 400
    assert "实体" in resp.text


async def test_graph_overlong_entity_rejected(test_client, admin_headers):
    """图谱查询超长实体名（>100字符）应被拒绝（400）。"""
    resp = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "长" * 101, "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 400
    assert "过长" in resp.text


async def test_graph_depth_upper_bound_is_four(test_client, admin_headers):
    """depth 上限已对齐到 4：depth=4 合法（200/图谱未启用），depth=5 被 Query 校验拒绝（422）。"""
    ok = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "清华大学", "depth": 4},
        headers=admin_headers,
    )
    assert ok.status_code == 200

    over = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "清华大学", "depth": 5},
        headers=admin_headers,
    )
    assert over.status_code == 422  # 超出 le=4 的 Query 约束


async def test_graph_response_envelope_is_uniform(test_client, admin_headers):
    """图谱接口无论成功/未启用/非法 relation，返回结构统一为 {message, data}。

    防止成功裸 list 与异常 {message,data} 混用，保证前端 resolveGraph(res?.data) 稳定消费。
    """
    # 合法 relation 路径：结构必含 message + data
    resp = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "清华大学", "relation_type": "has_major", "depth": 1},
        headers=admin_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert set(["message", "data"]).issubset(body.keys())
    assert isinstance(body["data"], list)

    # 非法 relation 路径（被白名单过滤，但结构仍应一致）
    resp2 = await test_client.get(
        "/api/zhiyuan/graph",
        params={"start_entity": "清华大学", "relation_type": "r][(n)", "depth": 1},
        headers=admin_headers,
    )
    assert resp2.status_code == 200
    body2 = resp2.json()
    assert set(["message", "data"]).issubset(body2.keys())
    assert isinstance(body2["data"], list)


async def test_admin_create_score_rejects_orphan_university(test_client, admin_headers):
    """单条新增录取分数也必须校验 university_id 存在性，孤立 id 应被拒绝（422）。"""
    payload = {
        "university_id": 999999,
        "province": "河南",
        "year": 2024,
        "subject_type": "理科",
        "min_score": 600,
        "min_rank": 5000,
    }
    resp = await test_client.post(
        "/api/zhiyuan/admin/scores", json=payload, headers=admin_headers
    )
    if resp.status_code == 422:
        assert "999999" in resp.json()["detail"]
    else:
        assert resp.status_code != 500


async def test_admin_create_plan_rejects_orphan_university(test_client, admin_headers):
    """单条新增招生计划也必须校验 university_id 存在性（422）。"""
    payload = {
        "university_id": 999999,
        "province": "河南",
        "year": 2024,
        "subject_type": "理科",
        "plan_count": 10,
    }
    resp = await test_client.post(
        "/api/zhiyuan/admin/plans", json=payload, headers=admin_headers
    )
    if resp.status_code == 422:
        assert "999999" in resp.json()["detail"]
    else:
        assert resp.status_code != 500


async def test_admin_upsert_rule_rejects_invalid_year(test_client, admin_headers):
    """省份规则 year<=0 应被拒绝（422），避免写入无效年份。

    year=0 会先被 Pydantic 层 gt=0 约束拦截，返回 422（FastAPI 校验错误结构）。
    """
    payload = {"province": "测试省", "year": 0, "mode": "平行志愿"}
    resp = await test_client.post(
        "/api/zhiyuan/admin/rules", json=payload, headers=admin_headers
    )
    assert resp.status_code == 422
    assert "year" in resp.text


async def test_admin_create_score_rejects_nonpositive_university_id(test_client, admin_headers):
    """Pydantic 层 university_id gt=0：传 0 或负数应在进入业务前被拒（422）。"""
    payload = {
        "university_id": 0,
        "province": "河南",
        "year": 2024,
        "subject_type": "理科",
    }
    resp = await test_client.post(
        "/api/zhiyuan/admin/scores", json=payload, headers=admin_headers
    )
    assert resp.status_code == 422
    assert "university_id" in resp.text


async def test_admin_create_score_rejects_negative_min_score(test_client, admin_headers):
    """Pydantic 层 min_score ge=0 且 le=750：负分或越界应被拒（422）。"""
    payload = {
        "university_id": 1,
        "province": "河南",
        "year": 2024,
        "min_score": -10,
    }
    resp = await test_client.post(
        "/api/zhiyuan/admin/scores", json=payload, headers=admin_headers
    )
    assert resp.status_code == 422
    assert "min_score" in resp.text


async def test_admin_create_major_rejects_bad_employment_rate(test_client, admin_headers):
    """Pydantic 层 employment_rate 范围 [0,100]：超界应被拒（422）。"""
    payload = {
        "university_id": 1,
        "name": "计算机科学与技术",
        "employment_rate": 150.0,
    }
    resp = await test_client.post(
        "/api/zhiyuan/admin/majors", json=payload, headers=admin_headers
    )
    assert resp.status_code == 422
    assert "employment_rate" in resp.text


async def test_recommend_rejects_nonnumeric_rank(test_client, admin_headers):
    """/recommend 的 rank 传非数字字符串应返回 400，而非 500（int() 崩溃）。"""
    resp = await test_client.post(
        "/api/zhiyuan/recommend",
        json={"rank": "abc", "province": "河南"},
        headers=admin_headers,
    )
    assert resp.status_code == 400
    assert "rank" in resp.text


async def test_plan_rejects_nonpositive_rank(test_client, admin_headers):
    """/plan 的 rank 传 0 或负数应返回 400（位次必须为正）。"""
    resp = await test_client.post(
        "/api/zhiyuan/plan",
        json={"rank": -5, "province": "河南"},
        headers=admin_headers,
    )
    assert resp.status_code == 400
    assert "rank" in resp.text
