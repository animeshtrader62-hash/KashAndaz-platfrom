from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models import WalletLedger, Transaction, Withdrawal


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


def get_wallet_summary(db: Session, user_id: str) -> dict:
    total_earned = (
        db.query(func.coalesce(func.sum(WalletLedger.amount), 0))
        .filter(WalletLedger.user_id == user_id, WalletLedger.entry_type == "credit")
        .scalar()
    )
    withdrawn = (
        db.query(func.coalesce(func.sum(WalletLedger.amount), 0))
        .filter(
            WalletLedger.user_id == user_id,
            WalletLedger.entry_type == "debit",
            WalletLedger.source_type == "withdrawal",
        )
        .scalar()
    )
    pending = (
        db.query(func.coalesce(func.sum(Transaction.cashback_amount), 0))
        .filter(Transaction.user_id == user_id, Transaction.status == "pending")
        .scalar()
    )
    available = get_available_balance(db, user_id)

    return {
        "total_earned": float(total_earned),
        "pending": float(pending),
        "available": float(available),
        "withdrawn": float(withdrawn),
    }


def get_recent_withdrawals(db: Session, user_id: str, limit: int = 5):
    return (
        db.query(Withdrawal)
        .filter(Withdrawal.user_id == user_id)
        .order_by(Withdrawal.requested_at.desc())
        .limit(limit)
        .all()
    )
