from datetime import datetime, timedelta, timezone
import time
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models import Click, Store, User


def _generate_tracking_id(user_id: str) -> str:
    # Required format: KA-{user_id}-{timestamp}
    # Use epoch milliseconds to minimize collision probability.
    ts = int(time.time() * 1000)
    return f"KA-{user_id}-{ts}"


def activate_cashback(db: Session, user: User, store_id: str):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store or not store.is_active:
        return None, None

    # tracking_id must be unique; retry a few times if collision occurs.
    tracking_id = _generate_tracking_id(user.id)
    for _ in range(5):
        exists = db.query(Click.id).filter(Click.tracking_id == tracking_id).first()
        if not exists:
            break
        tracking_id = _generate_tracking_id(user.id)

    click = Click(user_id=user.id, store_id=store.id, tracking_id=tracking_id)
    db.add(click)
    db.commit()
    db.refresh(click)

    deep_link = f"{settings.tracking_redirect_base}?click_id={click.id}&store_id={store.id}"
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=30)

    return click, {
        "deep_link": deep_link,
        "affiliate_redirect_url": deep_link,
        "click_id": click.id,
        "store_name": store.name,
        "message": "Cashback activated! Shop now to earn.",
        "expires_at": expires_at,
    }
