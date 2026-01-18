from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.models import Transaction

ALLOWED_TRANSITIONS = {
    "pending": {"confirmed", "declined"},
    "confirmed": {"paid"},
    "declined": set(),
    "paid": set(),
}


def can_transition(current: str, target: str) -> bool:
    return target in ALLOWED_TRANSITIONS.get(current, set())


def update_status(db: Session, tx: Transaction, target_status: str) -> Transaction:
    if not can_transition(tx.status, target_status):
        raise ValueError(f"Invalid transition: {tx.status} -> {target_status}")

    tx.status = target_status
    now = datetime.now(timezone.utc)
    if target_status == "confirmed":
        tx.confirmed_at = now
    if target_status == "paid":
        tx.paid_at = now

    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx
