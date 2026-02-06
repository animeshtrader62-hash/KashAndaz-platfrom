import uuid
from sqlalchemy import (
    String,
    DateTime,
    ForeignKey,
    func,
    CheckConstraint,
    Index,
    Integer,
)
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Banner(Base):
    __tablename__ = "banners"
    __table_args__ = (
        CheckConstraint("status IN ('active','inactive')", name="ck_banners_status_valid"),
        CheckConstraint("start_at < end_at", name="ck_banners_start_before_end"),
        CheckConstraint("priority >= 0", name="ck_banners_priority_nonneg"),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )

    offer_id: Mapped[str] = mapped_column(String(36), ForeignKey("offers.id"), nullable=False)
    image_url: Mapped[str] = mapped_column(String(2000), nullable=False)
    priority: Mapped[int] = mapped_column(Integer, nullable=False, default=100)

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


Index("ix_banners_offer_id", Banner.offer_id)
Index("ix_banners_status", Banner.status)
Index("ix_banners_window", Banner.start_at, Banner.end_at)
Index("ix_banners_priority", Banner.priority)
Index("ix_banners_created_by", Banner.created_by)
