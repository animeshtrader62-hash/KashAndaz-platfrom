from datetime import datetime, timedelta, timezone
import secrets
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models import Click, Offer, Store, User


def _generate_tracking_id() -> str:
    """Generate an unguessable, URL-safe tracking id.

    Requirements:
    - cryptographically secure randomness
    - URL-safe
    - length >= 32 characters
    - MUST NOT encode user_id, timestamp, or sequential data
    """
    # token_urlsafe(32) typically yields ~43 URL-safe chars.
    # Keep a short, non-sensitive prefix for readability/debugging.
    while True:
        token = secrets.token_urlsafe(32)
        tracking_id = f"KA_{token}"
        if len(tracking_id) >= 32:
            return tracking_id


def activate_cashback(db: Session, user: User, store_id: str):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store or not store.is_active:
        return None, "store_not_active_or_not_found"

    now = datetime.now(timezone.utc)
    offer = (
        db.query(Offer)
        .filter(
            Offer.store_id == store.id,
            Offer.status == "active",
            Offer.start_at <= now,
            Offer.end_at > now,
        )
        .order_by(Offer.start_at.desc())
        .first()
    )
    if not offer:
        # Phase 2 integrity: cannot generate a deterministic redirect without an active offer.
        return None, "no_active_offer"

    # tracking_id must be unique; retry a few times if collision occurs.
    tracking_id = _generate_tracking_id()
    for _ in range(10):
        exists = db.query(Click.id).filter(Click.tracking_id == tracking_id).first()
        if not exists:
            break
        tracking_id = _generate_tracking_id()

    expires_at = now + timedelta(minutes=30)

    click = Click(
        user_id=user.id,
        store_id=store.id,
        tracking_id=tracking_id,
        offer_id=offer.id,
        redirect_url=offer.affiliate_redirect_url,
        expires_at=expires_at,
    )
    db.add(click)
    db.commit()
    db.refresh(click)

    base = (settings.tracking_redirect_base or "").rstrip("/")
    deep_link = f"{base}/{click.tracking_id}"

    return click, {
        "deep_link": deep_link,
        "affiliate_redirect_url": deep_link,
        "click_id": click.id,
        "store_name": store.name,
        "message": "Cashback activated! Shop now to earn.",
        "expires_at": expires_at,
    }
