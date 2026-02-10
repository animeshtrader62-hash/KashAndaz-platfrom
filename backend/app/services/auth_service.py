import re
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models import User
from app.core.security import hash_password, verify_password


def validate_password_policy(password: str) -> None:
    # Policy: min 12, at least 1 lower/upper/digit/symbol.
    if password is None:
        raise ValueError("Password is required")
    if len(password) < 12:
        raise ValueError("Password must be at least 12 characters")
    if not re.search(r"[a-z]", password):
        raise ValueError("Password must include a lowercase letter")
    if not re.search(r"[A-Z]", password):
        raise ValueError("Password must include an uppercase letter")
    if not re.search(r"[0-9]", password):
        raise ValueError("Password must include a digit")
    if not re.search(r"[^A-Za-z0-9]", password):
        raise ValueError("Password must include a symbol")


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()


def create_user(
    db: Session,
    name: str,
    email: str,
    password: str,
    phone: str | None,
    role: str = "user",
) -> User:
    validate_password_policy(password)

    phone_value: str | None
    if phone is None:
        phone_value = None
    else:
        phone_value = phone.strip()
        if phone_value == "":
            phone_value = None

    user = User(
        name=name,
        email=email,
        phone=phone_value,
        hashed_password=hash_password(password),
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str, ip: str | None = None) -> User | None:
    user = get_user_by_email(db, email)
    if not user:
        return None
    if getattr(user, "is_blocked", False):
        return None

    now = datetime.now(timezone.utc)
    locked_until = getattr(user, "locked_until", None)
    if locked_until is not None and locked_until > now:
        return None

    if not verify_password(password, user.hashed_password):
        user.failed_login_attempts = int(getattr(user, "failed_login_attempts", 0) or 0) + 1
        user.last_failed_login_at = now
        if user.failed_login_attempts >= 5:
            user.locked_until = now + timedelta(minutes=15)
        db.add(user)
        db.commit()
        return None

    # Success
    user.failed_login_attempts = 0
    user.locked_until = None
    user.last_failed_login_at = None
    user.last_login_at = now
    if ip is not None:
        user.last_login_ip = ip
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
