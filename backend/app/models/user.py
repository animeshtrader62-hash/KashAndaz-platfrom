import uuid
from sqlalchemy import String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    phone: Mapped[str] = mapped_column(String(20), unique=True, nullable=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False, default="user")
    is_blocked: Mapped[bool] = mapped_column(default=False)
    failed_login_attempts: Mapped[int] = mapped_column(default=0)
    locked_until: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_failed_login_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    last_login_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_login_ip: Mapped[str | None] = mapped_column(String(64), nullable=True)

    token_version: Mapped[int] = mapped_column(default=0)

    password_reset_token_hash: Mapped[str | None] = mapped_column(String(128), nullable=True)
    password_reset_requested_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    password_reset_requested_ip: Mapped[str | None] = mapped_column(String(64), nullable=True)
    password_reset_token_expires_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    password_reset_token_used_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    password_reset_used_ip: Mapped[str | None] = mapped_column(String(64), nullable=True)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
