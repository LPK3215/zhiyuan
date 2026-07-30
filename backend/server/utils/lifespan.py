import asyncio
import os
from contextlib import asynccontextmanager
from typing import Awaitable, Callable, TypeVar

from fastapi import FastAPI

from yuxi.services.task_service import tasker
from yuxi.agents.mcp.service import ensure_builtin_mcp_servers_in_db
from yuxi.models.providers.service import ensure_builtin_model_providers_in_db
from yuxi.services.run_queue_service import close_queue_clients, get_redis_client
from yuxi.storage.postgres.manager import pg_manager
from yuxi.storage.neo4j import close_shared_neo4j_connection
from yuxi.knowledge.runtime import knowledge_base
from yuxi.utils import logger
from yuxi.agents.backends.sandbox import init_sandbox_provider, shutdown_sandbox_provider
from yuxi import get_version
from yuxi.config import config

T = TypeVar("T")


async def _init_step(
    name: str,
    action: Callable[[], Awaitable[T]],
    *,
    critical: bool = False,
) -> T | None:
    """统一执行启动步骤。

    critical=True: 致命依赖（PostgreSQL/Redis），失败时记录 FATAL 并重新抛出，阻止服务以半初始化状态上线。
    critical=False: 可降级依赖（知识库/沙盒/图谱/checkpointer 等），失败时记录 ERROR 并返回 None，服务继续启动。
    """
    try:
        return await action()
    except Exception as e:
        if critical:
            logger.fatal(f"[startup] 致命依赖初始化失败，服务拒绝启动 - {name}: {e}")
            raise
        logger.error(f"[startup] 可降级依赖初始化失败，服务继续启动 - {name}: {e}")
        return None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """FastAPI lifespan 事件管理器。

    启动步骤分为两类：
    - 致命依赖（critical=True）：PostgreSQL 建表、Redis 预热。失败则整服务不启动，避免半初始化运行态。
    - 可降级依赖（critical=False）：MCP、Skills、默认 Agent、模型供应商、配置、知识库、沙盒、LangGraph checkpoint。
      失败时记录日志并继续，对应能力在运行时按需报错或走 LITE 路径。
    """
    # ---- 致命依赖：PostgreSQL ----
    async def _init_database():
        pg_manager.initialize()
        await pg_manager.create_tables()
        await pg_manager.ensure_business_schema()
        await pg_manager.ensure_knowledge_schema()

        # 智愿业务表（自包含元数据，未并入 BusinessBase），启动时一并建表，
        # 确保 docker compose up 后无需依赖种子脚本即可建表。
        from yuxi.repositories.zhiyuan_models import Base as ZhiyuanBase

        async with pg_manager.async_engine.begin() as conn:
            await conn.run_sync(ZhiyuanBase.metadata.create_all)

    await _init_step("PostgreSQL 初始化", _init_database, critical=True)

    # ---- 可降级依赖：内置 MCP 服务器 ----
    await _init_step(
        "内置 MCP 服务器",
        ensure_builtin_mcp_servers_in_db,
    )

    # ---- 可降级依赖：内置 Skills ----
    async def _init_builtin_skills():
        from yuxi.agents.skills.service import init_builtin_skills

        async with pg_manager.get_async_session_context() as session:
            await init_builtin_skills(session)

    await _init_step("内置 Skills", _init_builtin_skills)

    # ---- 可降级依赖：默认 Agent 与子智能体 ----
    async def _ensure_default_agents():
        from yuxi.repositories.agent_repository import AgentRepository

        async with pg_manager.get_async_session_context() as session:
            repository = AgentRepository(session)
            await repository.ensure_default_agent()
            await repository.ensure_general_purpose_subagent()
            await repository.ensure_web_search_subagent()
            await repository.ensure_deep_research_agents()

    await _init_step("默认 Agent", _ensure_default_agents)

    # ---- 可降级依赖：内置模型供应商 ----
    async def _init_model_providers():
        async with pg_manager.get_async_session_context() as session:
            await ensure_builtin_model_providers_in_db(session)

    await _init_step("内置模型供应商", _init_model_providers)

    # ---- 可降级依赖：模型缓存 ----
    async def _init_model_cache():
        from yuxi.models.providers.cache import model_cache
        from yuxi.models.providers.service import get_all_model_providers

        async with pg_manager.get_async_session_context() as session:
            providers = await get_all_model_providers(session)
            model_cache.rebuild(providers)

    await _init_step("模型缓存", _init_model_cache)

    # ---- 可降级依赖：配置选项 ----
    async def _init_config_options():
        from yuxi.config.options import ensure_options_in_db

        async with pg_manager.get_async_session_context() as session:
            await ensure_options_in_db(session)

    await _init_step("配置选项", _init_config_options)

    # ---- 可降级依赖：知识库管理器（LITE 模式跳过） ----
    if os.environ.get("LITE_MODE", "").lower() in ("true", "1"):
        logger.info("LITE_MODE enabled, skipping knowledge base initialization")
    else:
        await _init_step("知识库管理器", knowledge_base.initialize)

    # ---- 致命依赖：Redis 预热（ARQ 投递依赖） ----
    async def _init_redis():
        redis = await get_redis_client()
        await redis.ping()

    await _init_step("Redis 预热", _init_redis, critical=True)

    # 启动应用级运行时配置同步线程。
    config.start_runtime_sync()

    # ---- 可降级依赖：沙盒 ----
    async def _init_sandbox():
        await asyncio.to_thread(init_sandbox_provider)

    await _init_step("沙盒 Provider", _init_sandbox)

    # ---- 可降级依赖：LangGraph Checkpoint 表 ----
    async def _init_checkpointer():
        from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver

        checkpointer = AsyncPostgresSaver(pg_manager.langgraph_pool)
        await checkpointer.setup()
        logger.info("LangGraph Checkpoint tables verified/created!")

    await _init_step("LangGraph Checkpoint", _init_checkpointer)

    await tasker.start()
    logger.info(f"""

░██     ░██                       ░██
 ░██   ░██
  ░██ ░██   ░██    ░██ ░██    ░██ ░██
   ░████    ░██    ░██  ░██  ░██  ░██
    ░██     ░██    ░██   ░█████   ░██
    ░██     ░██   ░███  ░██  ░██  ░██
    ░██      ░█████░██ ░██    ░██ ░██  v{get_version()}

    """)
    logger.info("Yuxi backend startup complete")
    yield
    await tasker.shutdown()
    shutdown_sandbox_provider()
    await close_queue_clients()
    close_shared_neo4j_connection()
    await pg_manager.close()
