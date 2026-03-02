from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.schemas.auth import SignupRequest, LoginRequest, TokenResponse
from app.core.security import create_access_token, create_refresh_token
from app.services.auth_service import create_user, get_user_by_email, authenticate_user
from app.services.rate_limiter import check_rate_limit

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
async def register(payload: SignupRequest, request: Request, db: Session = Depends(get_db)):
    client_ip = getattr(getattr(request, "client", None), "host", None) or "unknown"
    allowed = await check_rate_limit(client_ip, limit=5, window_seconds=3600)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many signup attempts. Try again later.",
        )

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

    token = create_access_token(user.id)
    return TokenResponse(token=token, user=user)


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, payload.email, payload.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    token = create_access_token(user.id)
    return TokenResponse(token=token, user=user)
