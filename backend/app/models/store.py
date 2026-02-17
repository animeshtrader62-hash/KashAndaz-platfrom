import uuid
from sqlalchemy import String, Boolean, DateTime, func, CheckConstraint, Integer, Numeric, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


_STORE_CATEGORIES = (
    "fashion",
    "electronics",
    "beauty",
    "travel",
    "food",
    "home",
    "finance",
    "groceries",
    "other",
)


class Store(Base):
    __tablename__ = "stores"

    __table_args__ = (
        CheckConstraint("cashback_rate >= 0", name="ck_stores_cashback_rate_nonneg"),
        CheckConstraint("cashback_type IN ('percentage','flat')", name="ck_stores_cashback_type_valid"),
        CheckConstraint("popularity_score >= 0", name="ck_stores_popularity_nonneg"),
        CheckConstraint(
            "category IS NULL OR category IN ('fashion','electronics','beauty','travel','food','home','finance','groceries','other')",
            name="ck_stores_category_valid",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    store_slug: Mapped[str] = mapped_column(String(200), nullable=False, unique=True)

    logo_url: Mapped[str] = mapped_column(String(500), nullable=False)
    affiliate_base_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    cashback_rate: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    cashback_type: Mapped[str] = mapped_column(String(20), nullable=False, default="percentage")

    popularity_score: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    featured_store: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    category: Mapped[str | None] = mapped_column(String(50), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())


Index("ix_stores_slug", Store.store_slug)
Index("ix_stores_category", Store.category)
Index("ix_stores_popularity", Store.popularity_score)
Index("ix_stores_featured", Store.featured_store)
