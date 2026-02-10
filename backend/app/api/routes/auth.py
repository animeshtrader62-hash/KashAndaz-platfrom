from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.schemas.auth import SignupRequest, LoginRequest, TokenResponse
from app.core.security import create_access_token, create_refresh_token
from app.core.config import settings
from app.services.auth_service import create_user, get_user_by_email, authenticate_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
def register(payload: SignupRequest, db: Session = Depends(get_db)):
    # Production hardening: public signup disabled.
    if (getattr(settings, "app_env", "development") or "development").lower() in {"prod", "production"}:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")

    existing = get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = create_user(
        db=db,
        name=payload.name,
        email=payload.email,
        password=payload.password,
        phone=payload.phone,
    )

    token = create_access_token(user.id, role=user.role, token_version=getattr(user, "token_version", 0))
    return TokenResponse(token=token, user=user)


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, payload.email, payload.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    token = create_access_token(user.id, role=user.role, token_version=getattr(user, "token_version", 0))
    return TokenResponse(token=token, user=user)
