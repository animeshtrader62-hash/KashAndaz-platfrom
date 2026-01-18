from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import Withdrawal
from app.services.payout_service import mark_withdrawal_completed

router = APIRouter(prefix="/admin/withdrawals", tags=["admin-withdrawals"])


@router.post("/{withdrawal_id}/pay", response_model=dict)
def pay_withdrawal(
    withdrawal_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    withdrawal = db.query(Withdrawal).filter(Withdrawal.id == withdrawal_id).first()
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")

    try:
        withdrawal = mark_withdrawal_completed(db, withdrawal)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return {
        "status": "ok",
        "withdrawal_id": withdrawal.id,
        "state": withdrawal.status,
    }
