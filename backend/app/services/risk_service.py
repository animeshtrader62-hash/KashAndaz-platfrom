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
    subq = (
        db.query(Click.user_id, func.count(Click.id).label("clicks"))
        .group_by(Click.user_id)
        .subquery()
    )
    users = (
        db.query(User)
        .join(subq, User.id == subq.c.user_id)
        .filter(subq.c.clicks >= click_threshold)
        .all()
    )

    flagged = 0
    for user in users:
        tx_count = (
            db.query(func.count(Transaction.id))
            .filter(Transaction.user_id == user.id)
            .scalar()
        )
        if tx_count == 0:
            create_flag(db, user.id, "clicks_no_sales", f"Clicks >= {click_threshold}")
            flagged += 1

    return flagged
