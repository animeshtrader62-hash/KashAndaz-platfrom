from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models import WalletLedger


def get_available_balance(db: Session, user_id: str) -> float:
    credits = (
        db.query(func.coalesce(func.sum(WalletLedger.amount), 0))
        .filter(WalletLedger.user_id == user_id, WalletLedger.entry_type == "credit")
        .scalar()
    )
    debits = (
        db.query(func.coalesce(func.sum(WalletLedger.amount), 0))
        .filter(WalletLedger.user_id == user_id, WalletLedger.entry_type == "debit")
        .scalar()
    )
    return float(credits) - float(debits)
