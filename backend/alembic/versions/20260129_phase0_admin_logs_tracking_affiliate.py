"""Phase 0: admin logs, tracking id, affiliate base url

Revision ID: 20260129_phase0
Revises: 
Create Date: 2026-01-29

"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "20260129_phase0"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    # admin_logs
    if "admin_logs" not in tables:
        op.create_table(
            "admin_logs",
            sa.Column("id", sa.String(length=36), primary_key=True, nullable=False),
            sa.Column("admin_id", sa.String(length=36), sa.ForeignKey("users.id"), nullable=False),
            sa.Column("action", sa.String(length=255), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
        )

    # Ensure indexes exist (safe for dev DBs where table pre-existed)
    if "admin_logs" in tables:
        existing = {idx.get("name") for idx in inspector.get_indexes("admin_logs")}
        if "ix_admin_logs_admin_id" not in existing:
            op.create_index("ix_admin_logs_admin_id", "admin_logs", ["admin_id"])
        if "ix_admin_logs_created_at" not in existing:
            op.create_index("ix_admin_logs_created_at", "admin_logs", ["created_at"])

    # stores.affiliate_base_url
    if "stores" in tables:
        store_cols = {c["name"] for c in inspector.get_columns("stores")}
        if "affiliate_base_url" not in store_cols:
            op.add_column(
                "stores",
                sa.Column("affiliate_base_url", sa.String(length=500), nullable=True),
            )

    # clicks.tracking_id (required + unique)
    if "clicks" in tables:
        click_cols = {c["name"] for c in inspector.get_columns("clicks")}
        if "tracking_id" not in click_cols:
            op.add_column(
                "clicks",
                sa.Column("tracking_id", sa.String(length=80), nullable=True),
            )

        # Backfill existing rows if any: set tracking_id deterministically from id
        op.execute("UPDATE clicks SET tracking_id = 'KA-BACKFILL-' || id WHERE tracking_id IS NULL")

        # SQLite can't reliably ALTER COLUMN; use batch for cross-db safety.
        existing_uniques = {uc.get("name") for uc in inspector.get_unique_constraints("clicks")}
        existing_indexes = {idx.get("name") for idx in inspector.get_indexes("clicks")}
        with op.batch_alter_table("clicks") as batch_op:
            batch_op.alter_column(
                "tracking_id",
                existing_type=sa.String(length=80),
                nullable=False,
            )
            if "uq_clicks_tracking_id" not in existing_uniques:
                batch_op.create_unique_constraint("uq_clicks_tracking_id", ["tracking_id"])
            if "ix_clicks_tracking_id" not in existing_indexes:
                batch_op.create_index("ix_clicks_tracking_id", ["tracking_id"])


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "clicks" in tables:
        existing_indexes = {idx.get("name") for idx in inspector.get_indexes("clicks")}
        if "ix_clicks_tracking_id" in existing_indexes:
            op.drop_index("ix_clicks_tracking_id", table_name="clicks")
        existing_uniques = {uc.get("name") for uc in inspector.get_unique_constraints("clicks")}
        if "uq_clicks_tracking_id" in existing_uniques:
            op.drop_constraint("uq_clicks_tracking_id", "clicks", type_="unique")
        click_cols = {c["name"] for c in inspector.get_columns("clicks")}
        if "tracking_id" in click_cols:
            op.drop_column("clicks", "tracking_id")

    if "stores" in tables:
        store_cols = {c["name"] for c in inspector.get_columns("stores")}
        if "affiliate_base_url" in store_cols:
            op.drop_column("stores", "affiliate_base_url")

    if "admin_logs" in tables:
        existing = {idx.get("name") for idx in inspector.get_indexes("admin_logs")}
        if "ix_admin_logs_created_at" in existing:
            op.drop_index("ix_admin_logs_created_at", table_name="admin_logs")
        if "ix_admin_logs_admin_id" in existing:
            op.drop_index("ix_admin_logs_admin_id", table_name="admin_logs")
        op.drop_table("admin_logs")
