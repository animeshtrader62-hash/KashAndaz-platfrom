import uuid
from sqlalchemy import (
    String,
    DateTime,
    ForeignKey,
    func,
    CheckConstraint,
    Index,
    Boolean,
)
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Offer(Base):
    __tablename__ = "offers"
    __table_args__ = (
        CheckConstraint("status IN ('active','inactive')", name="ck_offers_status_valid"),
        CheckConstraint("start_at < end_at", name="ck_offers_start_before_end"),
        CheckConstraint(
            "offer_type IN ('coupon','deal','bank_offer','new_user')",
            name="ck_offers_offer_type_valid",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )

    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(String(2000), nullable=True)

    # Manual affiliate link for now; later can be auto-generated from Offer18.
    affiliate_redirect_url: Mapped[str] = mapped_column(String(2000), nullable=False)

    # Display-only text, e.g. "Up to 7% Cashback".
    cashback_text: Mapped[str] = mapped_column(String(120), nullable=False)

    offer_type: Mapped[str] = mapped_column(String(20), nullable=False, default="deal")
    is_featured: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    start_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="inactive")

    created_by: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


Index("ix_offers_store_id", Offer.store_id)
Index("ix_offers_status", Offer.status)
Index("ix_offers_window", Offer.start_at, Offer.end_at)
Index("ix_offers_created_by", Offer.created_by)
Index("ix_offers_featured", Offer.is_featured)
Index("ix_offers_type", Offer.offer_type)
