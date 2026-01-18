from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.activate import ActivateRequest, ActivateResponse
from app.services.activate_service import activate_cashback

router = APIRouter(prefix="/activate-cashback", tags=["activate"])


@router.post("", response_model=ActivateResponse)
def activate(payload: ActivateRequest, db: Session = Depends(get_db), user=Depends(get_current_user)):
    click, response = activate_cashback(db, user, payload.store_id)
    if not click:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Store not active or not found",
        )
    return response
