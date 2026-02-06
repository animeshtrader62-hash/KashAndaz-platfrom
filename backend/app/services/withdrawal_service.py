from sqlalchemy.orm import Session
from sqlalchemy import select
from app.core.config import settings
from app.models import Withdrawal, WalletLedger, User
from app.services.wallet_service import get_available_balance
from app.services.risk_service import check_upi_reuse


def request_withdrawal(
    db: Session,
    user: User,
    amount: float,
    method: str,
    upi_id: str | None,
    bank_details: dict | None,
) -> Withdrawal:
    if amount < settings.min_withdrawal_amount:
        raise ValueError("Amount below minimum threshold")

    # Acquire row-level lock on user (best-effort for SQLite)
    db.execute(select(User).where(User.id == user.id).with_for_update())

    available = get_available_balance(db, user.id)
    if amount > available:
        raise ValueError("Insufficient balance")

    if method == "upi" and upi_id:
        check_upi_reuse(db, user, upi_id)

    withdrawal = Withdrawal(
        user_id=user.id,
        amount=amount,
        status="pending",
        method=method,
        upi_id=upi_id if method == "upi" else None,
        bank_account_number=bank_details.get("account_number") if bank_details else None,
        bank_ifsc=bank_details.get("ifsc") if bank_details else None,
        bank_account_holder_name=bank_details.get("account_holder_name") if bank_details else None,
    )
    db.add(withdrawal)
    db.flush()

    ledger = WalletLedger(
        user_id=user.id,
        entry_type="debit",
        amount=amount,
        source_type="withdrawal",
        source_id=withdrawal.id,
    )
    db.add(ledger)
    db.commit()
    db.refresh(withdrawal)
    return withdrawal
