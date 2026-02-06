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

    # Immutable offer binding (set at activation time).
    # - offer_id is for auditing/future postback join.
    # - redirect_url is the immutable target used by /api/r/{tracking_id}.
    offer_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("offers.id"), nullable=True)
    redirect_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)

    tracking_id: Mapped[str] = mapped_column(String(80), nullable=False)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # Optional; when set, redirects after expiry return 410 Gone.
    expires_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)


Index("ix_clicks_user_id", Click.user_id)
Index("ix_clicks_store_id", Click.store_id)
Index("ix_clicks_tracking_id", Click.tracking_id)
Index("ix_clicks_offer_id", Click.offer_id)
