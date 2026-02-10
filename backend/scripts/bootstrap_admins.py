from __future__ import annotations

import os
from dataclasses import dataclass
from getpass import getpass

from app.core.config import settings
from app.db.session import SessionLocal
from app.models import User
from app.services.auth_service import create_user


@dataclass(frozen=True)
class SeedAdmin:
    email: str
    role: str
    env_password_key: str


SEED_ADMINS: list[SeedAdmin] = [
    SeedAdmin(email="admin@kashandaz.com", role="super_admin", env_password_key="SEED_ADMIN_PASSWORD_ADMIN"),
    SeedAdmin(
        email="superadmin.shadab@kashandaz.com",
        role="admin",
        env_password_key="SEED_ADMIN_PASSWORD_SHADAB",
    ),
    SeedAdmin(
        email="superadmin.nitesh@kashandaz.com",
        role="admin",
        env_password_key="SEED_ADMIN_PASSWORD_NITESH",
    ),
]


def _enforce_admin_domain(email: str) -> None:
    domain = (settings.admin_email_domain or "kashandaz.com").lower().strip()
    if not email.lower().endswith(f"@{domain}"):
        raise SystemExit(f"Refusing to seed non-admin domain email: {email}")


def main() -> None:
    env = (settings.app_env or "development").lower()
    if env in {"prod", "production"}:
        if os.getenv("CONFIRM_PRODUCTION_ADMIN_BOOTSTRAP") != "YES":
            raise SystemExit(
                "Refusing to run in production without CONFIRM_PRODUCTION_ADMIN_BOOTSTRAP=YES"
            )

    db = SessionLocal()
    try:
        for entry in SEED_ADMINS:
            _enforce_admin_domain(entry.email)

            existing = db.query(User).filter(User.email == entry.email).first()
            if existing:
                if existing.role != entry.role:
                    existing.role = entry.role
                    db.add(existing)
                    db.commit()
                continue

            password = os.getenv(entry.env_password_key)
            if not password:
                password = getpass(f"Set password for {entry.email} ({entry.role}): ")

            # create_user enforces password policy.
            create_user(
                db=db,
                name=entry.email.split("@")[0],
                email=entry.email,
                password=password,
                phone=None,
                role=entry.role,
            )
    finally:
        db.close()


if __name__ == "__main__":
    main()
