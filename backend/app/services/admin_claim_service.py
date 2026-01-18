from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.models import Claim, WalletLedger


def approve_claim(db: Session, claim: Claim, credit_amount: float) -> Claim:
    if claim.status != "pending":
        raise ValueError("Claim already resolved")

    claim.status = "approved"
    claim.resolved_at = datetime.now(timezone.utc)
    db.add(claim)
    db.flush()

    ledger = WalletLedger(
        user_id=claim.user_id,
        entry_type="credit",
        amount=credit_amount,
        source_type="claim",
        source_id=claim.id,
    )
    db.add(ledger)
    db.commit()
    db.refresh(claim)
    return claim


def reject_claim(db: Session, claim: Claim) -> Claim:
    if claim.status != "pending":
        raise ValueError("Claim already resolved")

    claim.status = "rejected"
    claim.resolved_at = datetime.now(timezone.utc)
    db.add(claim)
    db.commit()
    db.refresh(claim)
    return claim
