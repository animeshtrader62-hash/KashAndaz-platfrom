import uuid
from sqlalchemy import (
    String,
    DateTime,
    ForeignKey,
    func,
    Index,
    CheckConstraint,
    Numeric,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class WalletLedger(Base):
    __tablename__ = "wallet_ledger"
    __table_args__ = (
        CheckConstraint("amount != 0", name="ck_wallet_amount_nonzero"),
        UniqueConstraint(
            "source_type",
            "source_id",
            "entry_type",
            name="uq_wallet_ledger_source_entry",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    entry_type: Mapped[str] = mapped_column(String(10), nullable=False)  # credit/debit
    amount: Mapped[float] = mapped_column(
        Numeric(12, 2),
        nullable=False,
    )
    source_type: Mapped[str] = mapped_column(String(30), nullable=False)  # transaction/withdrawal/adjustment
    source_id: Mapped[str] = mapped_column(String(36), nullable=False)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())


Index("ix_wallet_ledger_user_id", WalletLedger.user_id)
Index("ix_wallet_ledger_source", WalletLedger.source_type, WalletLedger.source_id)
