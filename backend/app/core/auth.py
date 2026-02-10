from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from dataclasses import dataclass
import structlog
from app.core.config import settings
from app.db.deps import get_db, get_db_optional
from app.models import User

security = HTTPBearer(auto_error=False)
optional_security = HTTPBearer(auto_error=False)

logger = structlog.get_logger(__name__)


@dataclass(frozen=True)
class AuthContext:
    user: User
    role: str


def _decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    if not credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    token = credentials.credentials
    payload = _decode_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    if user.is_blocked:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User blocked")

    # If a role claim is present, reject stale tokens when role changed server-side.
    token_role = payload.get("role")
    if token_role is not None and token_role != user.role:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token role is outdated")

    # Token version: enables revocation on password reset.
    token_tv = payload.get("tv")
    if token_tv is not None:
        if int(token_tv) != int(getattr(user, "token_version", 0)):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")
    else:
        # If server has rotated tokens, require tv claim.
        if int(getattr(user, "token_version", 0)) > 0:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")
    return user


def get_auth_context(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
) -> AuthContext:
    if not credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    token = credentials.credentials
    payload = _decode_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    if user.is_blocked:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User blocked")

    role = payload.get("role")
    if role is None:
        # Backward compatible fallback.
        role = user.role
    elif role != user.role:
        # Prevent replay after role downgrade/upgrade.
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token role is outdated")

    token_tv = payload.get("tv")
    if token_tv is not None:
        if int(token_tv) != int(getattr(user, "token_version", 0)):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")
    else:
        if int(getattr(user, "token_version", 0)) > 0:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")

    return AuthContext(user=user, role=str(role))


def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(optional_security),
    db: Session | None = Depends(get_db_optional),
) -> User | None:
    if not credentials:
        return None
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        user_id = payload.get("sub")
        if not user_id:
            return None
    except JWTError:
        return None
    except Exception as e:
        logger.warning("optional_auth_decode_failed", error=str(e))
        return None

    if db is None:
        return None

    try:
        user = db.query(User).filter(User.id == user_id).first()
        return user
    except Exception as e:
        logger.warning("optional_auth_db_failed", error=str(e))
        return None


def require_admin(ctx: AuthContext = Depends(get_auth_context)) -> User:
    if ctx.role not in {"admin", "super_admin"}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")
    return ctx.user


def require_super_admin(ctx: AuthContext = Depends(get_auth_context)) -> User:
    if ctx.role != "super_admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Super admin only")
    return ctx.user


def require_admin_viewer(ctx: AuthContext = Depends(get_auth_context)) -> User:
    if ctx.role not in {"viewer", "admin", "super_admin"}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")
    return ctx.user
