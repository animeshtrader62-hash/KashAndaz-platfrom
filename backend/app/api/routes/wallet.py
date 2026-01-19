from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.wallet import WalletResponse, WalletBalance, WithdrawalItem
from app.services.wallet_service import get_wallet_summary, get_recent_withdrawals

router = APIRouter(prefix="/wallet", tags=["wallet"])


@router.get("", response_model=WalletResponse)
def wallet(db: Session = Depends(get_db), user=Depends(get_current_user)):
    summary = get_wallet_summary(db, user.id)
    withdrawals = get_recent_withdrawals(db, user.id)

    return WalletResponse(
        balance=WalletBalance(
            total_earned=summary["total_earned"],
            pending=summary["pending"],
            available=summary["available"],
            withdrawn=summary["withdrawn"],
        ),
        recent_withdrawals=[WithdrawalItem.model_validate(w) for w in withdrawals],
    )
