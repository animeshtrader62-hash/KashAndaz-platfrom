from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.withdrawal import WithdrawalRequest, WithdrawalResponse
from app.services.withdrawal_service import request_withdrawal

router = APIRouter(prefix="/withdraw", tags=["withdrawals"])


@router.post("", response_model=WithdrawalResponse)
def withdraw(
    payload: WithdrawalRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    # Phase 2 scope: read-only integration only.
    # No payouts/withdrawals and no wallet mutations are allowed yet.
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Withdrawals are not enabled yet",
    )

    if payload.method == "upi" and not payload.upi_id:
        raise HTTPException(status_code=400, detail="UPI ID is required")
    if payload.method == "bank" and not payload.bank_details:
        raise HTTPException(status_code=400, detail="Bank details are required")

    try:
        withdrawal = request_withdrawal(
            db=db,
            user=user,
            amount=payload.amount,
            method=payload.method,
            upi_id=payload.upi_id,
            bank_details=payload.bank_details.model_dump() if payload.bank_details else None,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return WithdrawalResponse(
        withdrawal_id=withdrawal.id,
        amount=float(withdrawal.amount),
        status=withdrawal.status,
        message="Withdrawal request submitted. You will receive money within 3-5 business days.",
        requested_at=withdrawal.requested_at,
    )
