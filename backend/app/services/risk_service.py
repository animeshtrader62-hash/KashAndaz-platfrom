from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models import RiskFlag, Withdrawal, Click, Transaction, User


def create_flag(db: Session, user_id: str, flag_type: str, details: str | None = None) -> RiskFlag:
    flag = RiskFlag(user_id=user_id, flag_type=flag_type, details=details)
    db.add(flag)
    db.commit()
    db.refresh(flag)
    return flag


def check_upi_reuse(db: Session, user: User, upi_id: str) -> None:
    if not upi_id:
        return
    existing = (
        db.query(Withdrawal)
        .filter(Withdrawal.upi_id == upi_id, Withdrawal.user_id != user.id)
        .first()
    )
    if existing:
        create_flag(
            db,
            user.id,
            "upi_reuse",
            f"UPI {upi_id} seen for another user",
        )


def flag_clicks_without_sales(db: Session, click_threshold: int = 10) -> int:
    # Compute candidates in SQL to avoid N+1. Keep the run bounded to prevent
    # long jobs on large datasets.
    CANDIDATE_LIMIT = 500

    clicks_subq = (
        db.query(Click.user_id.label("user_id"), func.count(Click.id).label("clicks"))
        .group_by(Click.user_id)
        .subquery()
    )

    tx_subq = (
        db.query(Transaction.user_id.label("user_id"), func.count(Transaction.id).label("txs"))
        .group_by(Transaction.user_id)
        .subquery()
    )

    user_ids = (
        db.query(clicks_subq.c.user_id)
        .outerjoin(tx_subq, tx_subq.c.user_id == clicks_subq.c.user_id)
        .filter(clicks_subq.c.clicks >= click_threshold)
        .filter(func.coalesce(tx_subq.c.txs, 0) == 0)
        .order_by(clicks_subq.c.clicks.desc())
        .limit(CANDIDATE_LIMIT)
        .all()
    )

    flagged = 0
    for (user_id,) in user_ids:
        create_flag(db, user_id, "clicks_no_sales", f"Clicks >= {click_threshold}")
        flagged += 1

    return flagged
