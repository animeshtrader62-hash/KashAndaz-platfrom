from __future__ import annotations

from datetime import datetime, timezone
import threading
import time

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from app.db.deps import get_db
from app.models import Click, Offer

router = APIRouter(prefix="/r", tags=["redirect"])


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


def _normalize_utc(dt: datetime) -> datetime:
    # SQLite often returns naive datetimes even when timezone=True.
    # Treat naive values as UTC for consistent comparisons.
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt


_RATE_WINDOW_SECONDS = 60
_IP_LIMIT_PER_WINDOW = 300
_TRACKING_LIMIT_PER_WINDOW = 120

_ip_window: dict[str, tuple[int, int]] = {}
_tracking_window: dict[str, tuple[int, int]] = {}
_rl_lock = threading.Lock()


def _rate_limit_or_429(bucket: dict[str, tuple[int, int]], key: str, limit: int) -> None:
    """Fixed-window, in-memory rate limiter.

    Note: per-process only (intentionally minimal per Phase 2 constraints).
    """
    now_bucket = int(time.time() // _RATE_WINDOW_SECONDS)
    with _rl_lock:
        prev = bucket.get(key)
        if prev is None or prev[0] != now_bucket:
            bucket[key] = (now_bucket, 1)
        else:
            count = prev[1] + 1
            bucket[key] = (now_bucket, count)
            if count > limit:
                raise HTTPException(status_code=429, detail="Too many requests")

        # Best-effort cleanup to keep memory bounded.
        if len(bucket) > 50_000:
            for k, (b, _) in list(bucket.items()):
                if b != now_bucket:
                    bucket.pop(k, None)


@router.get("/{tracking_id}")
def redirect_by_tracking_id(
    tracking_id: str,
    request: Request,
    db: Session = Depends(get_db),
):
    client_ip = getattr(getattr(request, "client", None), "host", None) or "unknown"
    _rate_limit_or_429(_ip_window, client_ip, _IP_LIMIT_PER_WINDOW)
    _rate_limit_or_429(_tracking_window, f"{client_ip}:{tracking_id}", _TRACKING_LIMIT_PER_WINDOW)

    click = db.query(Click).filter(Click.tracking_id == tracking_id).first()
    if not click:
        raise HTTPException(status_code=404, detail="Click not found")

    now = _now_utc()
    if getattr(click, "expires_at", None) is not None:
        expires_at = _normalize_utc(click.expires_at)
        if expires_at <= now:
            raise HTTPException(status_code=410, detail="Click expired")

    # Phase 2 deterministic redirect: redirect only to the immutable stored URL.
    if getattr(click, "redirect_url", None):
        return RedirectResponse(url=click.redirect_url, status_code=302)

    # Backwards compatibility for legacy clicks created before Phase 2 columns existed.
    # One-time resolve + persist, so subsequent redirects become deterministic.
    offer = (
        db.query(Offer)
        .filter(
            Offer.store_id == click.store_id,
            Offer.status == "active",
            Offer.start_at <= now,
            Offer.end_at > now,
        )
        .order_by(Offer.start_at.desc())
        .first()
    )
    if not offer:
        raise HTTPException(status_code=404, detail="No active offer")

    try:
        click.offer_id = offer.id
        click.redirect_url = offer.affiliate_redirect_url
        db.add(click)
        db.commit()
    except Exception:
        # If persistence fails for any reason, still redirect (best-effort for legacy).
        db.rollback()

    return RedirectResponse(url=offer.affiliate_redirect_url, status_code=302)
