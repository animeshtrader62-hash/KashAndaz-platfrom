from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.claim import ClaimRequest, ClaimResponse
from app.services.claim_service import create_claim

router = APIRouter(prefix="/claims", tags=["claims"])


@router.post("", response_model=ClaimResponse)
def submit_claim(
    payload: ClaimRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    try:
        claim = create_claim(
            db=db,
            user=user,
            store_id=payload.store_id,
            order_id=payload.order_id,
            description=payload.description,
            screenshot_url=payload.screenshot_url,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return ClaimResponse(
        claim_id=claim.id,
        status=claim.status,
        created_at=claim.created_at,
    )
