import hashlib

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from yuxi.storage.postgres.manager import pg_manager
from yuxi.storage.postgres.models_business import APIKey, User
from yuxi.utils.datetime_utils import utc_now_naive

from yuxi.utils.auth_utils import AuthUtils

# 定义OAuth2密码承载器，指定token URL
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token", auto_error=False)

# API Key last_used_at 回写节流间隔（秒）：仅在距上次回写超过该间隔时才写库，
# 避免每个 API 请求都触发 DB commit。Redis 不可用时退化为每次都写。
API_KEY_LAST_USED_FLUSH_SECONDS = 300


# 获取数据库会话（异步版本）
async def get_db():
    async with pg_manager.get_async_session_context() as db:
        yield db


async def _should_flush_last_used(key_hash: str) -> bool:
    """判断是否需要回写 last_used_at 到数据库。

    使用 Redis SET NX + EX 实现节流：仅当 key 不存在（距上次回写已超过间隔）时返回 True。
    Redis 不可用时返回 True（退化为每次都写，保持原有行为）。
    """
    try:
        from yuxi.storage.redis import get_async_redis_client

        redis = await get_async_redis_client()
        cache_key = f"api_key_last_used:{key_hash}"
        # SET key 1 NX EX <seconds>：仅在 key 不存在时设置，并设过期
        was_set = await redis.set(cache_key, "1", ex=API_KEY_LAST_USED_FLUSH_SECONDS, nx=True)
        return bool(was_set)
    except Exception:
        return True


async def _verify_api_key(key: str, db: AsyncSession) -> tuple[User | None, APIKey | None]:
    """验证 API Key 并返回关联用户和 APIKey 对象"""
    key_hash = hashlib.sha256(key.encode()).hexdigest()

    result = await db.execute(select(APIKey).filter(APIKey.key_hash == key_hash))
    api_key = result.scalar_one_or_none()

    if api_key is None:
        return None, None

    if not api_key.is_enabled:
        return None, None

    if api_key.expires_at and utc_now_naive() > api_key.expires_at:
        return None, None

    if not api_key.user_id:
        return None, None

    result = await db.execute(select(User).filter(User.id == api_key.user_id))
    user = result.scalar_one_or_none()
    if user and not user.is_deleted:
        return user, api_key

    return None, None


# 获取当前用户（异步版本）
async def get_current_user(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db),
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的凭证",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if authorization is None:
        return None

    if not authorization.startswith("Bearer "):
        return None

    # 使用固定前缀切片，避免 split 在含多个 "Bearer " 时解析异常
    token = authorization[len("Bearer "):].strip()
    if not token:
        return None

    # 根据 token 前缀判断认证方式
    if token.startswith("yxkey_"):
        # API Key 认证
        user, api_key_obj = await _verify_api_key(token, db)
        if user is not None and api_key_obj is not None:
            # 节流回写 last_used_at：仅在距上次回写超过阈值时才写库
            if await _should_flush_last_used(api_key_obj.key_hash):
                api_key_obj.last_used_at = utc_now_naive()
                await db.commit()
        return user

    # JWT Token 认证
    try:
        payload = AuthUtils.verify_access_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 防御 user_id 非法类型导致 int() 抛 ValueError → 500
    try:
        uid = int(user_id)
    except (TypeError, ValueError) as exc:
        raise credentials_exception from exc

    result = await db.execute(select(User).filter(User.id == uid, User.is_deleted == 0))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    if user.is_login_locked():
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail="登录被锁定，请稍后重试",
            headers={"X-Lock-Remaining": str(user.get_remaining_lock_time())},
        )

    return user


# 获取已登录用户（抛出401如果未登录）
async def get_required_user(user: User | None = Depends(get_current_user)):
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="请登录后再访问",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.department_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="当前用户未绑定部门",
        )
    return user


# 获取管理员用户
async def get_admin_user(current_user: User = Depends(get_required_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="需要管理员权限",
        )
    return current_user


# 获取超级管理员用户
async def get_superadmin_user(current_user: User = Depends(get_required_user)):
    if current_user.role != "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="需要超级管理员权限",
        )
    return current_user
