from __future__ import annotations

import asyncio
import time
from typing import Final

import structlog

from app.core.redis_client import get_redis

logger = structlog.get_logger(__name__)

_RATE_LIMIT_LUA: Final[str] = """
local current = redis.call('INCR', KEYS[1])
if current == 1 then
  redis.call('EXPIRE', KEYS[1], ARGV[1])
end
return current
""".strip()

_fallback_lock = asyncio.Lock()
_fallback_attempts: dict[str, list[float]] = {}


def _normalize_rate_limit_key(key: str) -> tuple[str, str, str]:
    raw = (key or "").strip()
    if raw.startswith("rate_limit:"):
        parts = raw.split(":", 2)
        if len(parts) == 3:
            action, ip = parts[1], parts[2]
        else:
            action, ip = "unknown", raw
        return raw, action, ip

    if ":" in raw:
        action, ip = raw.split(":", 1)
        return f"rate_limit:{action}:{ip}", action, ip

    ip = raw
    return f"rate_limit:signup:{ip}", "signup", ip


async def _fallback_check_rate_limit(*, redis_key: str, limit: int, window_seconds: int) -> bool:
    now = time.time()
    cutoff = now - window_seconds

    async with _fallback_lock:
        timestamps = _fallback_attempts.get(redis_key, [])
        timestamps = [ts for ts in timestamps if ts >= cutoff]
        if len(timestamps) >= limit:
            _fallback_attempts[redis_key] = timestamps
            return False
        timestamps.append(now)
        _fallback_attempts[redis_key] = timestamps
        return True


async def check_rate_limit(key: str, limit: int, window_seconds: int) -> bool:
    redis_key, action, ip = _normalize_rate_limit_key(key)

    try:
        client = await get_redis()
        if client is None:
            raise RuntimeError("redis_unavailable")

        current = await client.eval(_RATE_LIMIT_LUA, 1, redis_key, int(window_seconds))
        try:
            current_int = int(current)
        except Exception:
            current_int = 0

        if current_int > limit:
            logger.info(
                "rate_limit_blocked",
                action=action,
                ip=ip,
                limit=limit,
                window_seconds=window_seconds,
            )
            return False

        logger.info(
            "rate_limit_hit",
            action=action,
            ip=ip,
            current=current_int,
            limit=limit,
            window_seconds=window_seconds,
        )
        return True

    except Exception as exc:
        logger.warning(
            "redis_error",
            action=action,
            ip=ip,
            error=str(exc),
        )

        allowed = await _fallback_check_rate_limit(
            redis_key=redis_key,
            limit=limit,
            window_seconds=window_seconds,
        )
        if not allowed:
            logger.info(
                "rate_limit_blocked",
                action=action,
                ip=ip,
                limit=limit,
                window_seconds=window_seconds,
                fallback=True,
            )
        else:
            logger.info(
                "rate_limit_hit",
                action=action,
                ip=ip,
                limit=limit,
                window_seconds=window_seconds,
                fallback=True,
            )
        return allowed
