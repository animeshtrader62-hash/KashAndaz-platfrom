from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import Claim
from app.services.admin_claim_service import approve_claim, reject_claim

router = APIRouter(prefix="/admin/claims", tags=["admin-claims"])


@router.post("/{claim_id}/approve", response_model=dict)
def approve(
    claim_id: str,
    credit_amount: float,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")

    try:
        claim = approve_claim(db, claim, credit_amount)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return {"status": "ok", "claim_id": claim.id, "state": claim.status}


@router.post("/{claim_id}/reject", response_model=dict)
def reject(
    claim_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")

    try:
        claim = reject_claim(db, claim)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return {"status": "ok", "claim_id": claim.id, "state": claim.status}
