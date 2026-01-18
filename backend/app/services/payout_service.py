from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.models import Withdrawal


ALLOWED_PAYOUT_STATUSES = {"pending", "processing"}


def mark_withdrawal_completed(db: Session, withdrawal: Withdrawal) -> Withdrawal:
    if withdrawal.status not in ALLOWED_PAYOUT_STATUSES:
        raise ValueError("Withdrawal not eligible for payout")

    withdrawal.status = "completed"
    withdrawal.completed_at = datetime.now(timezone.utc)
    db.add(withdrawal)
    db.commit()
    db.refresh(withdrawal)
    return withdrawal
