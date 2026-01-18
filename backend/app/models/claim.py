import uuid
from sqlalchemy import String, DateTime, ForeignKey, func, Index, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Claim(Base):
    __tablename__ = "claims"
    __table_args__ = (
        CheckConstraint(
            "status IN ('pending','approved','rejected')",
            name="ck_claim_status_valid",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), nullable=False)
    order_id: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    screenshot_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    resolved_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)


Index("ix_claims_user_id", Claim.user_id)
Index("ix_claims_store_id", Claim.store_id)
