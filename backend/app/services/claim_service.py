from sqlalchemy.orm import Session
from app.models import Claim, Store, User


def create_claim(
    db: Session,
    user: User,
    store_id: str,
    order_id: str,
    description: str | None,
    screenshot_url: str | None,
) -> Claim:
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise ValueError("Store not found")

    claim = Claim(
        user_id=user.id,
        store_id=store_id,
        order_id=order_id,
        description=description,
        screenshot_url=screenshot_url,
        status="pending",
    )
    db.add(claim)
    db.commit()
    db.refresh(claim)
    return claim
