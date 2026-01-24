from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models import Click, Store, User


def activate_cashback(db: Session, user: User, store_id: str):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store or not store.is_active:
        return None, None

    click = Click(user_id=user.id, store_id=store.id)
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
