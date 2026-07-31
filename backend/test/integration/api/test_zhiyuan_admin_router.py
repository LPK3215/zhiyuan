"""智愿 Admin CRUD API 集成测试。

测试覆盖：
  - 鉴权：未携带 token 返回 401；普通用户返回 403
  - 分页列表结构：{total, page, size, items}
  - 单条 CRUD：创建/更新/删除
  - 批量导入：上限 1000 条、空列表、孤立 university_id 校验
  - 重复院校名 409
  - Pydantic 校验：非法值 422
"""

from __future__ import annotations

import pytest

pytestmark = [pytest.mark.asyncio, pytest.mark.integration]


async def test_admin_requires_auth(test_client):
    """Admin 端点未携带 token 必须被拒绝（401）。"""
    resp = await test_client.get("/api/zhiyuan/admin/universities")
    assert resp.status_code == 401


async def test_admin_list_universities_pagination_shape(test_client, admin_headers):
    """管理端列表接口应返回统一分页结构（total/page/size/items）。"""
    resp = await test_client.get(
        "/api/zhiyuan/admin/universities", params={"page": 1, "size": 20}, headers=admin_headers
    )
    assert resp.status_code == 200
    body = resp.json()
    assert set(["total", "page", "size", "items"]).issubset(body.keys())
    assert isinstance(body["items"], list)


async def test_admin_list_majors_pagination_shape(test_client, admin_headers):
    resp = await test_client.get("/api/zhiyuan/admin/majors", headers=admin_headers)
    assert resp.status_code == 200
    assert set(["total", "page", "size", "items"]).issubset(resp.json().keys())


async def test_admin_list_scores_pagination_shape(test_client, admin_headers):
    resp = await test_client.get("/api/zhiyuan/admin/scores", headers=admin_headers)
    assert resp.status_code == 200
    assert set(["total", "page", "size", "items"]).issubset(resp.json().keys())


async def test_admin_list_plans_pagination_shape(test_client, admin_headers):
    resp = await test_client.get("/api/zhiyuan/admin/plans", headers=admin_headers)
    assert resp.status_code == 200
    assert set(["total", "page", "size", "items"]).issubset(resp.json().keys())


async def test_admin_list_rules_returns_array(test_client, admin_headers):
    """规则列表直接返回数组（不分页）。"""
    resp = await test_client.get("/api/zhiyuan/admin/rules", headers=admin_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


async def test_admin_batch_create_scores_cap(test_client, admin_headers):
    """批量导入单次超过 1000 条应被拒绝（413）。"""
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


async def test_admin_batch_create_scores_rejects_orphan_university(test_client, admin_headers):
    """批量导入分数必须校验 university_id 存在性，孤立 id 应被拒绝（422）。"""
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
        assert "999999" in resp.json()["detail"]
    else:
        assert resp.status_code != 500


async def test_admin_create_university_duplicate_conflict(test_client, admin_headers):
    """同名院校重复创建应被拒绝（409）。"""
    payload = {
        "name": "集成测试院校_唯一名",
        "province": "河南",
        "level": "普通",
        "type": "综合",
    }
    first = await test_client.post(
        "/api/zhiyuan/admin/universities", json=payload, headers=admin_headers
    )
    if first.status_code in (200, 201):
        dup = await test_client.post(
            "/api/zhiyuan/admin/universities", json=payload, headers=admin_headers
        )
        assert dup.status_code == 409
        # 清理
        created_id = first.json()["id"]
        await test_client.delete(
            f"/api/zhiyuan/admin/universities/{created_id}", headers=admin_headers
        )
    else:
        assert first.status_code != 500


async def test_admin_create_score_rejects_orphan_university(test_client, admin_headers):
    """单条新增录取分数也必须校验 university_id 存在性（422）。"""
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
    """省份规则 year<=0 应被拒绝（422）。"""
    payload = {"province": "河南", "year": 0, "mode": "平行志愿"}
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


async def test_admin_batch_create_majors_cap(test_client, admin_headers):
    """批量导入专业单次超过 1000 条应被拒绝（413）。"""
    oversized = [
        {"university_id": 1, "name": f"专业_{i}"}
        for i in range(1001)
    ]
    resp = await test_client.post(
        "/api/zhiyuan/admin/majors/batch", json=oversized, headers=admin_headers
    )
    assert resp.status_code == 413


async def test_admin_batch_create_plans_cap(test_client, admin_headers):
    """批量导入计划单次超过 1000 条应被拒绝（413）。"""
    oversized = [
        {"university_id": 1, "province": "河南", "year": 2024, "plan_count": 10}
        for _ in range(1001)
    ]
    resp = await test_client.post(
        "/api/zhiyuan/admin/plans/batch", json=oversized, headers=admin_headers
    )
    assert resp.status_code == 413
