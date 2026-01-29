"""Phase 0: admin logs, tracking id, affiliate base url

Revision ID: 20260129_phase0
Revises: 
Create Date: 2026-01-29

"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "20260129_phase0"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # admin_logs
    op.create_table(
        "admin_logs",
        sa.Column("id", sa.String(length=36), primary_key=True, nullable=False),
        sa.Column("admin_id", sa.String(length=36), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("action", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
    )
    op.create_index("ix_admin_logs_admin_id", "admin_logs", ["admin_id"])
    op.create_index("ix_admin_logs_created_at", "admin_logs", ["created_at"])

    # stores.affiliate_base_url
    op.add_column("stores", sa.Column("affiliate_base_url", sa.String(length=500), nullable=True))

    # clicks.tracking_id (required + unique)
    op.add_column("clicks", sa.Column("tracking_id", sa.String(length=80), nullable=True))

    # Backfill existing rows if any: set tracking_id deterministically from id
    # (keeps uniqueness, satisfies NOT NULL once applied)
    op.execute("UPDATE clicks SET tracking_id = 'KA-BACKFILL-' || id WHERE tracking_id IS NULL")

    op.alter_column("clicks", "tracking_id", existing_type=sa.String(length=80), nullable=False)
    op.create_unique_constraint("uq_clicks_tracking_id", "clicks", ["tracking_id"])
    op.create_index("ix_clicks_tracking_id", "clicks", ["tracking_id"])


def downgrade() -> None:
    op.drop_index("ix_clicks_tracking_id", table_name="clicks")
    op.drop_constraint("uq_clicks_tracking_id", "clicks", type_="unique")
    op.drop_column("clicks", "tracking_id")

    op.drop_column("stores", "affiliate_base_url")

    op.drop_index("ix_admin_logs_created_at", table_name="admin_logs")
    op.drop_index("ix_admin_logs_admin_id", table_name="admin_logs")
    op.drop_table("admin_logs")
