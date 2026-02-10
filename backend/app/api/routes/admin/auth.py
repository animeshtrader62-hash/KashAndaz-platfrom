import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.email import send_password_reset_email
from app.core.security import create_access_token, hash_password
from app.core.auth import require_admin_viewer
from app.db.deps import get_db
from app.schemas.admin.auth import (
    AdminLoginRequest,
    AdminPasswordResetConfirm,
    AdminPasswordResetConfirmedResponse,
    AdminPasswordResetRequest,
    AdminPasswordResetRequestedResponse,
    AdminTokenResponse,
)
from app.services.auth_service import authenticate_user, get_user_by_email, validate_password_policy


router = APIRouter(prefix="/admin/auth", tags=["admin-auth"])


def _enforce_admin_email_domain(email: str) -> None:
    domain = (getattr(settings, "admin_email_domain", None) or "kashandaz.com").lower().strip()
    if not domain:
        return
    if not email.lower().endswith(f"@{domain}"):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")


@router.post("/login", response_model=AdminTokenResponse)
def admin_login(payload: AdminLoginRequest, request: Request, db: Session = Depends(get_db)):
    _enforce_admin_email_domain(payload.email)

    ip = None
    if request.client is not None:
        ip = request.client.host

    user = authenticate_user(db, payload.email, payload.password, ip=ip)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    # Admin panel is internal: only allow staff roles.
    role = str(getattr(user, "role", "") or "").lower()
    if role not in {"viewer", "admin", "super_admin"}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    token = create_access_token(user.id, role=user.role, token_version=getattr(user, "token_version", 0))
    return AdminTokenResponse(token=token, user=user)


@router.post("/logout", response_model=dict)
def admin_logout(db: Session = Depends(get_db), user=Depends(require_admin_viewer)):
    # Stateless JWT logout: bump token_version to revoke existing tokens.
    user.token_version = int(getattr(user, "token_version", 0) or 0) + 1
    db.add(user)
    db.commit()
    return {"ok": True}


def _hash_reset_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


@router.post("/password-reset/request", response_model=AdminPasswordResetRequestedResponse)
def request_password_reset(payload: AdminPasswordResetRequest, request: Request, db: Session = Depends(get_db)):
    # Do not reveal whether the email exists.
    email = payload.email.strip().lower()
    _enforce_admin_email_domain(email)

    user = get_user_by_email(db, email)
    if not user:
        return AdminPasswordResetRequestedResponse(ok=True)

    role = str(getattr(user, "role", "") or "").lower()
    if role not in {"viewer", "admin", "super_admin"}:
        return AdminPasswordResetRequestedResponse(ok=True)

    token = secrets.token_urlsafe(32)
    token_hash = _hash_reset_token(token)
    now = datetime.now(timezone.utc)
    user.password_reset_token_hash = token_hash
    user.password_reset_requested_at = now
    user.password_reset_requested_ip = request.client.host if request.client is not None else None
    user.password_reset_token_expires_at = now + timedelta(minutes=15)
    user.password_reset_token_used_at = None
    user.password_reset_used_ip = None
    db.add(user)
    db.commit()

    reset_link = f"{settings.admin_panel_base_url.rstrip('/')}/reset-password?token={token}"
    try:
        send_password_reset_email(to_email=email, reset_link=reset_link)
    except Exception:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Email service unavailable")
    return AdminPasswordResetRequestedResponse(ok=True)


@router.post("/password-reset/confirm", response_model=AdminPasswordResetConfirmedResponse)
def confirm_password_reset(payload: AdminPasswordResetConfirm, request: Request, db: Session = Depends(get_db)):
    validate_password_policy(payload.new_password)
    token_hash = _hash_reset_token(payload.token.strip())
    now = datetime.now(timezone.utc)

    from app.models import User  # local import to avoid circulars

    user = db.query(User).filter(User.password_reset_token_hash == token_hash).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired token")

    expires_at = getattr(user, "password_reset_token_expires_at", None)
    used_at = getattr(user, "password_reset_token_used_at", None)
    if used_at is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired token")
    if expires_at is None or expires_at <= now:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired token")

    # Enforce admin domain + staff roles.
    _enforce_admin_email_domain(str(getattr(user, "email", "")))
    role = str(getattr(user, "role", "") or "").lower()
    if role not in {"viewer", "admin", "super_admin"}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    user.hashed_password = hash_password(payload.new_password)
    user.password_reset_token_used_at = now
    user.password_reset_used_ip = request.client.host if request.client is not None else None
    user.password_reset_token_hash = None
    user.password_reset_requested_at = None
    user.password_reset_requested_ip = None
    user.password_reset_token_expires_at = None
    user.token_version = int(getattr(user, "token_version", 0) or 0) + 1
    user.failed_login_attempts = 0
    user.locked_until = None
    user.last_failed_login_at = None
    db.add(user)
    db.commit()
    return AdminPasswordResetConfirmedResponse(ok=True)
