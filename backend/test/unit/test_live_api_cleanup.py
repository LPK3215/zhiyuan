from __future__ import annotations

from typing import Any

import httpx
import pytest

from testsupport.live_api_cleanup import (
    _is_pytest_resource,
    cleanup_pytest_knowledge_resources,
)


@pytest.mark.asyncio
async def test_cleanup_deletes_pytest_evaluation_resources_and_knowledge_databases():
    """只删除 pytest 前缀资源，并使用知识库真实返回的 kb_id。"""

    deleted_paths: list[str] = []
    responses: dict[str, dict[str, Any]] = {
        "/api/knowledge/databases": {
            "databases": [
                {"kb_id": "kb_test", "name": "Pytest knowledge base"},
                {"kb_id": "kb_legacy", "name": "py_test_legacy"},
                {"kb_id": "kb_prod", "name": "Production knowledge base"},
            ]
        },
        "/api/evaluation/databases/kb_test/runs": {"data": [{"run_id": "run_test", "name": "PYTEST evaluation"}]},
        "/api/evaluation/databases/kb_test/datasets": {"data": [{"dataset_id": "dataset_test", "name": "pytest plan"}]},
        "/api/evaluation/databases/kb_legacy/runs": {"data": []},
        "/api/evaluation/databases/kb_legacy/datasets": {"data": []},
        "/api/evaluation/databases/kb_prod/runs": {"data": [{"run_id": "run_prod", "name": "Production evaluation"}]},
        "/api/evaluation/databases/kb_prod/datasets": {
            "data": [
                {"dataset_id": "dataset_shared_test", "name": "Pytest shared plan"},
                {"dataset_id": "dataset_prod", "name": "Production plan"},
            ]
        },
    }

    def handle_request(request: httpx.Request) -> httpx.Response:
        """返回清理 API 的最小真实 HTTP 响应。"""

        if request.method == "DELETE":
            deleted_paths.append(request.url.path)
            return httpx.Response(200, json={})
        return httpx.Response(200, json=responses[request.url.path])

    async with httpx.AsyncClient(transport=httpx.MockTransport(handle_request), base_url="http://test") as client:
        await cleanup_pytest_knowledge_resources(client, {"Authorization": "test"})

    assert set(deleted_paths) == {
        "/api/evaluation/databases/kb_test/runs/run_test",
        "/api/evaluation/datasets/dataset_test",
        "/api/evaluation/datasets/dataset_shared_test",
        "/api/knowledge/databases/kb_test",
        "/api/knowledge/databases/kb_legacy",
    }


@pytest.mark.asyncio
async def test_cleanup_rejects_knowledge_list_error_payload():
    """知识库列表以 200 返回内部错误时，清理必须显式失败。"""

    def handle_request(request: httpx.Request) -> httpx.Response:
        """模拟知识库列表路由当前的 200 错误响应。"""

        return httpx.Response(200, json={"message": "获取数据库列表失败", "databases": []})

    async with httpx.AsyncClient(transport=httpx.MockTransport(handle_request), base_url="http://test") as client:
        with pytest.raises(RuntimeError, match="获取数据库列表失败"):
            await cleanup_pytest_knowledge_resources(client, {"Authorization": "test"})


def test_is_pytest_resource_prefix_matching():
    """资源名前缀判定应区分大小写无关、仅接受 pytest/py_test 前缀、拒绝非字符串与无关名称。"""

    # 小写前缀匹配（含驼峰/下划线/空格后缀）
    assert _is_pytest_resource("pytest knowledge base")
    assert _is_pytest_resource("pytest_plan")
    assert _is_pytest_resource("py_test_legacy")
    assert _is_pytest_resource("PYTEST evaluation")  # casefold 使大写也匹配
    assert _is_pytest_resource("Py_Test shared")  # casefold 使混合大小写也匹配

    # 非前缀 / 生产资源必须拒绝
    assert not _is_pytest_resource("Production knowledge base")
    assert not _is_pytest_resource("生产环境数据集")
    assert not _is_pytest_resource("xpytest")  # 前缀必须位于起始位置
    assert not _is_pytest_resource("my_pytest")  # 前缀不在开头

    # 非字符串与边界输入
    assert not _is_pytest_resource(None)
    assert not _is_pytest_resource(123)
    assert not _is_pytest_resource("")
    assert not _is_pytest_resource({"name": "pytest x"})
