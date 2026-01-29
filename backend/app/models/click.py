import uuid
from sqlalchemy import String, DateTime, ForeignKey, func, Index, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Click(Base):
    __tablename__ = "clicks"
    __table_args__ = (
        UniqueConstraint("tracking_id", name="uq_clicks_tracking_id"),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), nullable=False)
    tracking_id: Mapped[str] = mapped_column(String(80), nullable=False)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())


Index("ix_clicks_user_id", Click.user_id)
Index("ix_clicks_store_id", Click.store_id)
Index("ix_clicks_tracking_id", Click.tracking_id)
