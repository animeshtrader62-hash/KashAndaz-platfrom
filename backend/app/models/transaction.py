import uuid
from sqlalchemy import (
    String,
    DateTime,
    ForeignKey,
    func,
    Index,
    UniqueConstraint,
    Numeric,
    CheckConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Transaction(Base):
    __tablename__ = "transactions"
    __table_args__ = (
        UniqueConstraint("external_order_id", "store_id", name="uq_tx_external_order_store"),
        CheckConstraint("purchase_amount >= 0", name="ck_purchase_amount_nonneg"),
        CheckConstraint("cashback_amount >= 0", name="ck_cashback_amount_nonneg"),
        CheckConstraint(
            "status IN ('pending','confirmed','declined','paid')",
            name="ck_transaction_status_valid",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), nullable=False)
    click_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("clicks.id"), nullable=True)

    external_order_id: Mapped[str] = mapped_column(String(120), nullable=False)
    purchase_amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    cashback_amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    cashback_rate: Mapped[str | None] = mapped_column(String(50), nullable=True)

    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    confirmed_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    paid_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_reason: Mapped[str | None] = mapped_column(String(255), nullable=True)


Index("ix_transactions_user_id", Transaction.user_id)
Index("ix_transactions_store_id", Transaction.store_id)
Index("ix_transactions_status", Transaction.status)
