"""Phase 2: click redirect integrity

- Persist immutable click -> offer binding (offer_id + redirect_url)
- Persist optional click expires_at for redirect expiry enforcement

Revision ID: 20260206_phase2_click_redirect
Revises: 20260129_offers_banners
Create Date: 2026-02-06

"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "20260206_phase2_click_redirect"
down_revision = "20260129_offers_banners"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "clicks" not in tables:
        return

    click_cols = {c["name"] for c in inspector.get_columns("clicks")}

    if "offer_id" not in click_cols:
        # Keep nullable for backwards compatibility with existing clicks.
        # New clicks are expected to set this at activation time.
        op.add_column("clicks", sa.Column("offer_id", sa.String(length=36), nullable=True))

    if "redirect_url" not in click_cols:
        # Immutable redirect target; used by /api/r/{tracking_id}.
        op.add_column("clicks", sa.Column("redirect_url", sa.String(length=2000), nullable=True))

    if "expires_at" not in click_cols:
        op.add_column("clicks", sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True))

    existing_indexes = {idx.get("name") for idx in inspector.get_indexes("clicks")}
    if "ix_clicks_offer_id" not in existing_indexes:
        op.create_index("ix_clicks_offer_id", "clicks", ["offer_id"])


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "clicks" not in tables:
        return

    existing_indexes = {idx.get("name") for idx in inspector.get_indexes("clicks")}
    if "ix_clicks_offer_id" in existing_indexes:
        op.drop_index("ix_clicks_offer_id", table_name="clicks")

    click_cols = {c["name"] for c in inspector.get_columns("clicks")}
    if "expires_at" in click_cols:
        op.drop_column("clicks", "expires_at")
    if "redirect_url" in click_cols:
        op.drop_column("clicks", "redirect_url")
    if "offer_id" in click_cols:
        op.drop_column("clicks", "offer_id")
