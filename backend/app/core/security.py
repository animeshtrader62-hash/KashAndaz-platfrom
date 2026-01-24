from datetime import datetime, timedelta, timezone
from jose import jwt
from passlib.context import CryptContext
from .config import settings

# Passlib's Argon2 defaults can be very expensive on some dev machines (esp. Windows),
# leading to multi-second login verification. The hash itself encodes its parameters,
# so lowering *new* hash defaults does not break verification of existing users.
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    # Keep time_cost reasonable; reduce memory/parallelism for practical latency.
    argon2__time_cost=2,
    argon2__memory_cost=32768,  # KiB (32 MiB)
    argon2__parallelism=2,
)


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_exp_minutes)
    to_encode = {"sub": subject, "exp": expire}
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_exp_days)
    to_encode = {"sub": subject, "exp": expire, "type": "refresh"}
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)
