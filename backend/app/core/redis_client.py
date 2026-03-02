from __future__ import annotations

import asyncio
import os
from typing import Any, Final, Protocol

import structlog

try:
    import redis.asyncio as redis_asyncio
except Exception:  # pragma: no cover
    redis_asyncio = None  # type: ignore[assignment]

from app.core.config import settings

logger = structlog.get_logger(__name__)

_DEFAULT_SOCKET_CONNECT_TIMEOUT_S: Final[float] = 0.5
_DEFAULT_SOCKET_TIMEOUT_S: Final[float] = 0.5
_DEFAULT_PING_TIMEOUT_S: Final[float] = 0.8


class AsyncRedisClient(Protocol):
    async def ping(self) -> Any: ...

    async def eval(self, script: str, numkeys: int, *keys_and_args: Any) -> Any: ...

    async def aclose(self) -> Any: ...


_redis_singleton: AsyncRedisClient | None = None
_redis_lock = asyncio.Lock()


def _get_redis_url() -> str:
    url = (os.getenv("REDIS_URL") or getattr(settings, "redis_url", "") or "").strip()
    return url


async def get_redis() -> AsyncRedisClient | None:
    """Return a singleton async Redis client.

    Fails safely: returns None (and logs) if Redis is unavailable.
    """

    global _redis_singleton

    if _redis_singleton is not None:
        return _redis_singleton

    async with _redis_lock:
        if _redis_singleton is not None:
            return _redis_singleton

        if redis_asyncio is None:
            logger.warning("redis_error", reason="redis_package_not_available")
            return None

        url = _get_redis_url()
        if not url:
            logger.warning("redis_error", reason="missing_redis_url")
            return None

        client: AsyncRedisClient = redis_asyncio.from_url(
            url,
            encoding="utf-8",
            decode_responses=True,
            socket_connect_timeout=_DEFAULT_SOCKET_CONNECT_TIMEOUT_S,
            socket_timeout=_DEFAULT_SOCKET_TIMEOUT_S,
            health_check_interval=30,
            retry_on_timeout=True,
        )

        try:
            await asyncio.wait_for(client.ping(), timeout=_DEFAULT_PING_TIMEOUT_S)
        except Exception as exc:
            logger.warning("redis_error", error_type=type(exc).__name__)
            try:
                await client.aclose()
            except Exception:
                pass
            return None

        _redis_singleton = client
        return _redis_singleton


async def ping_redis() -> bool:
    client = await get_redis()
    if client is None:
        return False
    try:
        await asyncio.wait_for(client.ping(), timeout=_DEFAULT_PING_TIMEOUT_S)
        return True
    except Exception as exc:
        logger.warning("redis_error", error_type=type(exc).__name__)
        return False


async def close_redis() -> None:
    global _redis_singleton
    async with _redis_lock:
        if _redis_singleton is None:
            return
        try:
            await _redis_singleton.aclose()
        except Exception:
            pass
        _redis_singleton = None
