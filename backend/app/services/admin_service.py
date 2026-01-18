from sqlalchemy.orm import Session
from app.models import User, WalletLedger, RiskFlag


def block_user(db: Session, user: User) -> User:
    user.is_blocked = True
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def unblock_user(db: Session, user: User) -> User:
    user.is_blocked = False
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def manual_ledger_entry(
    db: Session,
    user_id: str,
    entry_type: str,
    amount: float,
    source_type: str,
    source_id: str,
) -> WalletLedger:
    entry = WalletLedger(
        user_id=user_id,
        entry_type=entry_type,
        amount=amount,
        source_type=source_type,
        source_id=source_id,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def get_risk_flags(db: Session, user_id: str):
    return db.query(RiskFlag).filter(RiskFlag.user_id == user_id).all()
