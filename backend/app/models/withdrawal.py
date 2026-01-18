import uuid
from sqlalchemy import String, DateTime, ForeignKey, func, Index, Numeric, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Withdrawal(Base):
    __tablename__ = "withdrawals"
    __table_args__ = (
        CheckConstraint("amount > 0", name="ck_withdrawal_amount_positive"),
        CheckConstraint(
            "status IN ('pending','processing','completed','failed')",
            name="ck_withdrawal_status_valid",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")

    method: Mapped[str] = mapped_column(String(10), nullable=False)  # upi|bank
    upi_id: Mapped[str | None] = mapped_column(String(120), nullable=True)
    bank_account_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    bank_ifsc: Mapped[str | None] = mapped_column(String(20), nullable=True)
    bank_account_holder_name: Mapped[str | None] = mapped_column(String(120), nullable=True)

    requested_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    completed_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)


Index("ix_withdrawals_user_id", Withdrawal.user_id)
