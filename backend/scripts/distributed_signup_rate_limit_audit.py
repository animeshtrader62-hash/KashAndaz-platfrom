import asyncio
import json
import os
import sys
import time
import uuid
from dataclasses import dataclass

import httpx


@dataclass(frozen=True)
class RunConfig:
    base_urls: list[str]
    total_requests: int
    limit_expected: int
    blocked_status: int
    timeout_s: float
    ip_key: str


def _now_utc_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


async def _reset_rate_limit_key(cfg: RunConfig) -> dict:
    redis_url = (os.getenv("REDIS_URL") or "").strip() or None
    if not redis_url:
        try:
            from app.core.config import settings

            redis_url = (getattr(settings, "redis_url", "") or "").strip() or None
        except Exception:
            redis_url = None

    if not redis_url:
        return {"ok": False, "error": "missing_redis_url"}

    key = f"rate_limit:signup:{cfg.ip_key}"

    try:
        import redis.asyncio as redis
    except Exception as exc:  # pragma: no cover
        return {"ok": False, "error": f"redis_import_error:{exc!r}"}

    client = redis.from_url(
        redis_url,
        encoding="utf-8",
        decode_responses=True,
        socket_connect_timeout=2,
        socket_timeout=2,
        retry_on_timeout=False,
    )
    try:
        await client.ping()
        deleted = await client.delete(key)
        return {"ok": True, "redis_url": redis_url, "key": key, "deleted": int(deleted)}
    except Exception as exc:
        return {"ok": False, "redis_url": redis_url, "key": key, "error": f"redis_error:{exc!r}"}
    finally:
        try:
            await client.aclose()
        except Exception:
            pass


def _signup_payload(i: int) -> dict:
    ts = int(time.time() * 1000)
    return {
        "name": "Audit User",
        "email": f"audit_dist_{ts}_{i}_{uuid.uuid4().hex[:6]}@example.com",
        "password": "Testpass1",
        "phone": None,
    }


async def _one_signup(client: httpx.AsyncClient, base_url: str, i: int) -> tuple[int, float]:
    url = f"{base_url.rstrip('/')}/auth/register"
    payload = _signup_payload(i)
    t0 = time.perf_counter()
    r = await client.post(url, json=payload)
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    return r.status_code, elapsed_ms


async def run(cfg: RunConfig) -> dict:
    reset = await _reset_rate_limit_key(cfg)
    if not reset.get("ok"):
        return {
            "timestamp_utc": _now_utc_iso(),
            "status": "FAIL",
            "error": "redis_reset_failed",
            "reset": reset,
        }

    results: list[tuple[int, float, str]] = []
    async with httpx.AsyncClient(timeout=cfg.timeout_s) as client:
        tasks = []
        for i in range(cfg.total_requests):
            base = cfg.base_urls[i % len(cfg.base_urls)]
            tasks.append(_one_signup(client, base, i))

        out = await asyncio.gather(*tasks, return_exceptions=True)
        for i, item in enumerate(out):
            base = cfg.base_urls[i % len(cfg.base_urls)]
            if isinstance(item, Exception):
                results.append((0, 0.0, f"{base} exception:{item!r}"))
            else:
                status_code, elapsed_ms = item
                results.append((int(status_code), float(elapsed_ms), base))

    ok = sum(1 for s, _, _ in results if s == 200)
    blocked = sum(1 for s, _, _ in results if s == cfg.blocked_status)
    other = [
        {"status": s, "base_url": base, "elapsed_ms": round(ms, 2)}
        for (s, ms, base) in results
        if s not in {200, cfg.blocked_status}
    ]
    nonzero = [ms for _, ms, _ in results if ms > 0]
    avg_ms = round(sum(nonzero) / max(1, len(nonzero)), 2)

    status = (
        "PASS"
        if ok == cfg.limit_expected and blocked == (cfg.total_requests - cfg.limit_expected) and not other
        else "FAIL"
    )
    if ok > cfg.limit_expected:
        status = "FAIL"

    return {
        "timestamp_utc": _now_utc_iso(),
        "status": status,
        "reset": reset,
        "config": {
            "base_urls": cfg.base_urls,
            "total_requests": cfg.total_requests,
            "expected_success": cfg.limit_expected,
            "expected_blocked": cfg.total_requests - cfg.limit_expected,
            "blocked_status": cfg.blocked_status,
            "ip_key": cfg.ip_key,
        },
        "results": {
            "success": ok,
            "blocked": blocked,
            "other_count": len(other),
            "other": other[:20],
            "avg_elapsed_ms": avg_ms,
        },
        "rule": "If more than 5 succeed -> FAIL",
        "evaluation": {
            "more_than_limit_succeeded": ok > cfg.limit_expected,
        },
    }


if __name__ == "__main__":
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    sys.path.insert(0, repo_root)

    base_urls_raw = os.getenv("AUDIT_BASE_URLS") or "http://127.0.0.1:8000/api,http://127.0.0.1:8001/api"
    ip_key = os.getenv("AUDIT_IP_KEY") or "127.0.0.1"
    cfg = RunConfig(
        base_urls=[u.strip() for u in base_urls_raw.split(",") if u.strip()],
        total_requests=int(os.getenv("AUDIT_TOTAL_REQUESTS") or "20"),
        limit_expected=int(os.getenv("AUDIT_EXPECTED_SUCCESS") or "5"),
        blocked_status=int(os.getenv("AUDIT_BLOCKED_STATUS") or "429"),
        timeout_s=float(os.getenv("AUDIT_TIMEOUT_S") or "20"),
        ip_key=ip_key,
    )
    print(json.dumps(asyncio.run(run(cfg)), indent=2))
