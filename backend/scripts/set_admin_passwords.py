from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from getpass import getpass

from app.core.config import settings
from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models import User
from app.services.auth_service import validate_password_policy


@dataclass(frozen=True)
class TargetAdmin:
    email: str


TARGETS: list[TargetAdmin] = [
    TargetAdmin(email="admin@kashandaz.com"),
    TargetAdmin(email="superadmin.shadab@kashandaz.com"),
    TargetAdmin(email="superadmin.nitesh@kashandaz.com"),
]


def _enforce_admin_domain(email: str) -> None:
    domain = (settings.admin_email_domain or "kashandaz.com").lower().strip()
    if not email.lower().endswith(f"@{domain}"):
        raise SystemExit(f"Refusing to set password for non-admin domain email: {email}")


def main() -> None:
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        for t in TARGETS:
            _enforce_admin_domain(t.email)
            user = db.query(User).filter(User.email == t.email).first()
            if not user:
                raise SystemExit(f"User not found: {t.email}. Run bootstrap_admins first.")

            password = getpass(f"New password for {t.email}: ")
            validate_password_policy(password)

            user.hashed_password = hash_password(password)
            user.token_version = int(getattr(user, "token_version", 0) or 0) + 1
            user.failed_login_attempts = 0
            user.locked_until = None
            user.last_failed_login_at = None
            user.password_reset_token_hash = None
            user.password_reset_token_expires_at = None
            user.password_reset_token_used_at = None
            user.password_reset_requested_at = None
            user.password_reset_requested_ip = None
            user.password_reset_used_ip = None
            user.last_login_at = None
            user.last_login_ip = None

            db.add(user)
            db.commit()
            db.refresh(user)
            print(f"Updated: {t.email} (token_version={user.token_version}) at {now.isoformat()}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
