import asyncio
import ipaddress
import os
import sys
import time
from collections import defaultdict, deque

import uvicorn
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from server.routers import router
from server.utils.lifespan import lifespan
from server.utils.common_utils import setup_logging
from server.utils.access_log_middleware import AccessLogMiddleware

# 设置日志配置
setup_logging()

RATE_LIMIT_MAX_ATTEMPTS = 10
RATE_LIMIT_WINDOW_SECONDS = 60
RATE_LIMIT_ENDPOINTS = {("/api/auth/token", "POST")}
DEFAULT_DEVELOPMENT_CORS_ORIGINS = ("http://localhost:5173", "http://127.0.0.1:5173")
EXPLICIT_CORS_METHODS = ("DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT")
EXPLICIT_CORS_HEADERS = ("Accept", "Authorization", "Content-Type", "Last-Event-ID", "X-Requested-With")

# 登录限流：Redis 不可用时回退到进程内内存计数（多 Worker 下被稀释，仅作降级兜底）。
_login_attempts: defaultdict[str, deque[float]] = defaultdict(deque)
_attempt_lock = asyncio.Lock()


def _parse_trusted_proxies() -> set[str]:
    """解析 YUXI_TRUSTED_PROXIES 环境变量，返回受信代理 IP/CIDR 集合。

    仅当直连客户端 IP 属于该集合时，才信任 x-forwarded-for；否则以直连 IP 为准，
    防止未经过代理的攻击者伪造 X-Forwarded-For 绕过限流。
    """
    raw = os.getenv("YUXI_TRUSTED_PROXIES", "").strip()
    if not raw:
        return set()
    return {item.strip() for item in raw.split(",") if item.strip()}


_TRUSTED_PROXIES = _parse_trusted_proxies()


def _ip_matches_proxy(client_ip: str, proxy_spec: str) -> bool:
    """判断 client_ip 是否匹配 proxy_spec（单 IP 或 CIDR）。"""
    try:
        if "/" in proxy_spec:
            return ipaddress.ip_address(client_ip) in ipaddress.ip_network(proxy_spec, strict=False)
        return client_ip == proxy_spec
    except (ValueError, TypeError):
        return False


def _extract_client_ip(request: Request) -> str:
    """提取客户端真实 IP。

    仅当直连客户端属于 YUXI_TRUSTED_PROXIES 时才信任 x-forwarded-for，
    避免非代理场景下伪造头绕过按 IP 限流。
    """
    direct_ip = request.client.host if request.client else "unknown"

    if _TRUSTED_PROXIES and any(_ip_matches_proxy(direct_ip, spec) for spec in _TRUSTED_PROXIES):
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
    return direct_ip


def _parse_cors_origins() -> list[str]:
    value = os.getenv("YUXI_CORS_ORIGINS")
    origins = [origin.strip() for origin in (value or "").split(",") if origin.strip()]
    if origins:
        return origins

    environment = (os.getenv("YUXI_ENV") or "development").strip().lower()
    if environment in {"production", "prod"}:
        return []

    return list(DEFAULT_DEVELOPMENT_CORS_ORIGINS)


def _build_cors_options(origins: list[str] | None = None) -> dict[str, object]:
    allow_origins = _parse_cors_origins() if origins is None else origins
    if "*" in allow_origins:
        return {
            "allow_origins": ["*"],
            "allow_credentials": False,
            "allow_methods": ["*"],
            "allow_headers": ["*"],
        }

    return {
        "allow_origins": allow_origins,
        "allow_credentials": True,
        "allow_methods": list(EXPLICIT_CORS_METHODS),
        "allow_headers": list(EXPLICIT_CORS_HEADERS),
        "expose_headers": ["Content-Disposition", "X-Lock-Remaining"],
    }


app = FastAPI(lifespan=lifespan)
# 所有业务接口统一挂载到 /api，具体分组在 server.routers 中集中注册。
app.include_router(router, prefix="/api")

# CORS 设置
app.add_middleware(
    CORSMiddleware,
    **_build_cors_options(),
)


def _login_rate_key(client_ip: str) -> str:
    return f"login_attempts:{client_ip}"


async def _check_and_record_redis(client_ip: str) -> tuple[bool, int]:
    """Redis 原子计数限流。返回 (允许, 重试等待秒数)。"""
    from yuxi.storage.redis import get_async_redis_client

    redis = await get_async_redis_client()
    key = _login_rate_key(client_ip)
    pipe = redis.pipeline()
    pipe.incr(key)
    pipe.expire(key, RATE_LIMIT_WINDOW_SECONDS, nx=True)
    results = await pipe.execute()
    count = int(results[0])
    if count > RATE_LIMIT_MAX_ATTEMPTS:
        ttl = await redis.ttl(key)
        return False, max(1, ttl)
    return True, 0


async def _clear_redis_attempts(client_ip: str) -> None:
    """登录成功后清除 Redis 计数。"""
    try:
        from yuxi.storage.redis import get_async_redis_client

        redis = await get_async_redis_client()
        await redis.delete(_login_rate_key(client_ip))
    except Exception:
        pass


async def _check_and_record_memory(client_ip: str) -> tuple[bool, int]:
    """进程内内存限流（Redis 不可用时的降级兜底）。"""
    now = time.monotonic()
    async with _attempt_lock:
        attempt_history = _login_attempts[client_ip]
        while attempt_history and now - attempt_history[0] > RATE_LIMIT_WINDOW_SECONDS:
            attempt_history.popleft()
        if len(attempt_history) >= RATE_LIMIT_MAX_ATTEMPTS:
            retry_after = int(max(1, RATE_LIMIT_WINDOW_SECONDS - (now - attempt_history[0])))
            return False, retry_after
        attempt_history.append(now)
    return True, 0


async def _clear_memory_attempts(client_ip: str) -> None:
    async with _attempt_lock:
        _login_attempts.pop(client_ip, None)


class LoginRateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        normalized_path = request.url.path.rstrip("/") or "/"
        request_signature = (normalized_path, request.method.upper())

        if request_signature in RATE_LIMIT_ENDPOINTS:
            client_ip = _extract_client_ip(request)

            # 优先使用 Redis 跨 Worker 限流；不可用时降级到进程内内存。
            try:
                allowed, retry_after = await _check_and_record_redis(client_ip)
            except Exception:
                allowed, retry_after = await _check_and_record_memory(client_ip)

            if not allowed:
                return JSONResponse(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    content={"detail": "登录尝试过于频繁，请稍后再试"},
                    headers={"Retry-After": str(retry_after)},
                )

            response = await call_next(request)

            if response.status_code < 400:
                try:
                    await _clear_redis_attempts(client_ip)
                except Exception:
                    await _clear_memory_attempts(client_ip)

            return response

        return await call_next(request)


# 添加访问日志中间件（记录请求处理时间）
app.add_middleware(AccessLogMiddleware)

# 添加登录限流中间件
app.add_middleware(LoginRateLimitMiddleware)

if __name__ == "__main__":
    # uvicorn.run(app, host="0.0.0.0", port=5050, threads=10, workers=10, reload=True)

    uvicorn.run(
        "server.main:app",
        host="0.0.0.0",
        port=5050,
        reload=True,
        # 与 docker-compose 开发环境保持一致，避免 package 下代码变更不触发热重载。
        reload_dirs=["server", "package"],
    )
