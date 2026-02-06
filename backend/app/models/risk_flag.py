import uuid
from sqlalchemy import String, DateTime, ForeignKey, func, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class RiskFlag(Base):
    __tablename__ = "risk_flags"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    flag_type: Mapped[str] = mapped_column(String(50), nullable=False)
    details: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())


Index("ix_risk_flags_user_id", RiskFlag.user_id)
Index("ix_risk_flags_flag_type", RiskFlag.flag_type)
