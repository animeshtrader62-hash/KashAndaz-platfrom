from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.home import HomeResponse, WalletSummary
from app.schemas.store import StoreOut
from app.services.wallet_service import get_wallet_summary
from app.models import Store

router = APIRouter(prefix="/home", tags=["home"])


@router.get("", response_model=HomeResponse)
def home(db: Session = Depends(get_db), user=Depends(get_current_user)):
    summary = get_wallet_summary(db, user.id)
    stores = (
        db.query(Store)
        .filter(Store.is_active == True)  # noqa: E712
        .order_by(Store.name.asc())
        .limit(10)
        .all()
    )

    return HomeResponse(
        wallet=WalletSummary(
            total_earned=summary["total_earned"],
            pending=summary["pending"],
            available=summary["available"],
            currency="INR",
        ),
        top_stores=[StoreOut.model_validate(s) for s in stores],
    )
