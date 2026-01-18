from sqlalchemy.orm import Session
from app.models import Transaction, WalletLedger
from app.services.transaction_service import update_status


def confirm_transaction(db: Session, tx: Transaction) -> Transaction:
    if tx.status != "pending":
        raise ValueError("Only pending transactions can be confirmed")

    if tx.cashback_amount <= 0:
        raise ValueError("Cashback amount must be positive")

    tx = update_status(db, tx, "confirmed")

    ledger = WalletLedger(
        user_id=tx.user_id,
        entry_type="credit",
        amount=tx.cashback_amount,
        source_type="transaction",
        source_id=tx.id,
    )
    db.add(ledger)
    db.commit()
    db.refresh(tx)
    return tx
