from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.profile import ProfileResponse, ProfileUpdateRequest, UserProfile

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=ProfileResponse)
def get_profile(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return ProfileResponse(
        user=UserProfile(
            id=user.id,
            name=user.name,
            email=user.email,
            phone=user.phone,
            joined_at=user.created_at,
        ),
        payment_methods=[],
    )


@router.put("", response_model=ProfileResponse)
def update_profile(
    payload: ProfileUpdateRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    if payload.name is not None:
        user.name = payload.name
    if payload.phone is not None:
        user.phone = payload.phone

    db.add(user)
    db.commit()
    db.refresh(user)

    return ProfileResponse(
        user=UserProfile(
            id=user.id,
            name=user.name,
            email=user.email,
            phone=user.phone,
            joined_at=user.created_at,
        ),
        payment_methods=[],
    )
