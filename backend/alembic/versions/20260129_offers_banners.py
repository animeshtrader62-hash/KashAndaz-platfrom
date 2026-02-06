"""Offers and banners

Revision ID: 20260129_offers_banners
Revises: 20260129_phase0
Create Date: 2026-01-29

"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "20260129_offers_banners"
down_revision = "20260129_phase0"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())
    now_default = sa.text("CURRENT_TIMESTAMP") if bind.dialect.name == "sqlite" else sa.text("now()")

    if "offers" not in tables:
        op.create_table(
            "offers",
            sa.Column("id", sa.String(length=36), primary_key=True, nullable=False),
            sa.Column("store_id", sa.String(length=36), sa.ForeignKey("stores.id"), nullable=False),
            sa.Column("title", sa.String(length=200), nullable=False),
            sa.Column("description", sa.String(length=2000), nullable=True),
            sa.Column("affiliate_redirect_url", sa.String(length=2000), nullable=False),
            sa.Column("cashback_text", sa.String(length=120), nullable=False),
            sa.Column("start_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("end_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("status", sa.String(length=20), nullable=False, server_default="inactive"),
            sa.Column("created_by", sa.String(length=36), sa.ForeignKey("users.id"), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=now_default),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                server_default=now_default,
            ),
            sa.CheckConstraint("status IN ('active','inactive')", name="ck_offers_status_valid"),
            sa.CheckConstraint("start_at < end_at", name="ck_offers_start_before_end"),
        )

    # Ensure indexes exist (safe for dev DBs where table pre-existed)
    if "offers" in set(inspector.get_table_names()):
        existing = {idx.get("name") for idx in inspector.get_indexes("offers")}
        if "ix_offers_store_id" not in existing:
            op.create_index("ix_offers_store_id", "offers", ["store_id"])
        if "ix_offers_status" not in existing:
            op.create_index("ix_offers_status", "offers", ["status"])
        if "ix_offers_window" not in existing:
            op.create_index("ix_offers_window", "offers", ["start_at", "end_at"])
        if "ix_offers_created_by" not in existing:
            op.create_index("ix_offers_created_by", "offers", ["created_by"])

    if "banners" not in tables:
        op.create_table(
            "banners",
            sa.Column("id", sa.String(length=36), primary_key=True, nullable=False),
            sa.Column("offer_id", sa.String(length=36), sa.ForeignKey("offers.id"), nullable=False),
            sa.Column("image_url", sa.String(length=2000), nullable=False),
            sa.Column("priority", sa.Integer(), nullable=False, server_default="100"),
            sa.Column("start_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("end_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("status", sa.String(length=20), nullable=False, server_default="inactive"),
            sa.Column("created_by", sa.String(length=36), sa.ForeignKey("users.id"), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=now_default),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                server_default=now_default,
            ),
            sa.CheckConstraint("status IN ('active','inactive')", name="ck_banners_status_valid"),
            sa.CheckConstraint("start_at < end_at", name="ck_banners_start_before_end"),
            sa.CheckConstraint("priority >= 0", name="ck_banners_priority_nonneg"),
        )

    if "banners" in set(inspector.get_table_names()):
        existing = {idx.get("name") for idx in inspector.get_indexes("banners")}
        if "ix_banners_offer_id" not in existing:
            op.create_index("ix_banners_offer_id", "banners", ["offer_id"])
        if "ix_banners_status" not in existing:
            op.create_index("ix_banners_status", "banners", ["status"])
        if "ix_banners_window" not in existing:
            op.create_index("ix_banners_window", "banners", ["start_at", "end_at"])
        if "ix_banners_priority" not in existing:
            op.create_index("ix_banners_priority", "banners", ["priority"])
        if "ix_banners_created_by" not in existing:
            op.create_index("ix_banners_created_by", "banners", ["created_by"])


def downgrade() -> None:
    op.drop_index("ix_banners_created_by", table_name="banners")
    op.drop_index("ix_banners_priority", table_name="banners")
    op.drop_index("ix_banners_window", table_name="banners")
    op.drop_index("ix_banners_status", table_name="banners")
    op.drop_index("ix_banners_offer_id", table_name="banners")
    op.drop_table("banners")

    op.drop_index("ix_offers_created_by", table_name="offers")
    op.drop_index("ix_offers_window", table_name="offers")
    op.drop_index("ix_offers_status", table_name="offers")
    op.drop_index("ix_offers_store_id", table_name="offers")
    op.drop_table("offers")
