import asyncio
import json
import os
import sys
import time


def _load_settings_redis_url() -> str | None:
    try:
        from app.core.config import settings

        url = (getattr(settings, "redis_url", None) or "").strip()
        return url or None
    except Exception:
        return None


async def _ping(url: str) -> dict:
    try:
        import redis.asyncio as redis
    except Exception as exc:  # pragma: no cover
        return {"ok": False, "error": f"redis_import_error:{exc!r}"}

    client = redis.from_url(
        url,
        encoding="utf-8",
        decode_responses=True,
        socket_connect_timeout=2,
        socket_timeout=2,
        retry_on_timeout=False,
    )
    try:
        t0 = time.perf_counter()
        pong = await client.ping()
        elapsed_ms = (time.perf_counter() - t0) * 1000.0
        return {"ok": bool(pong), "pong": pong, "elapsed_ms": round(elapsed_ms, 2)}
    except Exception as exc:
        return {"ok": False, "error": f"redis_connect_error:{exc!r}"}
    finally:
        try:
            await client.aclose()
        except Exception:
            pass


async def main() -> None:
    env_url = (os.getenv("REDIS_URL") or "").strip() or None
    settings_url = _load_settings_redis_url()

    url = env_url or settings_url
    result = {
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "env_REDIS_URL_present": bool(env_url),
        "settings_redis_url_present": bool(settings_url),
        "redis_url_source": "env" if env_url else ("settings" if settings_url else None),
        "redis_url": url,
        "ping": None,
    }

    if not url:
        result["ping"] = {"ok": False, "error": "missing_redis_url"}
        print(json.dumps(result, indent=2))
        raise SystemExit(2)

    result["ping"] = await _ping(url)
    print(json.dumps(result, indent=2))
    if not result["ping"].get("ok"):
        raise SystemExit(1)


if __name__ == "__main__":
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    sys.path.insert(0, repo_root)
    asyncio.run(main())
