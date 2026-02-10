from datetime import datetime, timedelta, timezone
from jose import jwt
from passlib.context import CryptContext
from .config import settings

# Password hashing
# - Default to bcrypt for predictable latency and broad compatibility.
# - Keep argon2 verification enabled for backward compatibility (existing hashes).
pwd_context = CryptContext(
    schemes=["bcrypt", "argon2"],
    deprecated="auto",
    bcrypt__rounds=12,
    # Argon2 params used only if/when generating argon2 hashes.
    argon2__time_cost=2,
    argon2__memory_cost=32768,  # KiB (32 MiB)
    argon2__parallelism=2,
)


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: str, role: str | None = None, token_version: int | None = None) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_exp_minutes)
    to_encode = {"sub": subject, "exp": expire}
    if role:
        to_encode["role"] = role
    if token_version is not None:
        to_encode["tv"] = int(token_version)
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_exp_days)
    to_encode = {"sub": subject, "exp": expire, "type": "refresh"}
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)
