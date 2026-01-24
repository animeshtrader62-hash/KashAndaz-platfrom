import uuid
from datetime import date

from sqlalchemy import (
    String,
    DateTime,
    ForeignKey,
    func,
    Index,
    Numeric,
    CheckConstraint,
    Date,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class MissingCashbackRequest(Base):
    __tablename__ = "missing_cashback_requests"
    __table_args__ = (
        CheckConstraint(
            "status IN ('pending','approved','rejected')",
            name="ck_missing_cashback_status_valid",
        ),
        CheckConstraint("order_amount > 0", name="ck_missing_cashback_order_amount_positive"),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), nullable=False)

    order_id: Mapped[str] = mapped_column(String(120), nullable=False)
    order_amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    order_date: Mapped[date] = mapped_column(Date, nullable=False)

    expected_cashback: Mapped[float | None] = mapped_column(Numeric(12, 2), nullable=True)
    screenshot_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    notes: Mapped[str | None] = mapped_column(String(1000), nullable=True)

    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    admin_comment: Mapped[str | None] = mapped_column(String(500), nullable=True)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())


Index("ix_missing_cashback_user_id", MissingCashbackRequest.user_id)
Index("ix_missing_cashback_store_id", MissingCashbackRequest.store_id)
Index("ix_missing_cashback_status", MissingCashbackRequest.status)
