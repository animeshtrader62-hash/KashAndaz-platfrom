"""Wallet ledger idempotency

- Enforce one ledger entry per (source_type, source_id, entry_type)
  to prevent double-credit/double-debit under concurrency.

Revision ID: 20260206_wallet_ledger_idempotency
Revises: 20260206_phase2_click_redirect
Create Date: 2026-02-06

"""

from __future__ import annotations

from alembic import op
from sqlalchemy import inspect


revision = "20260206_wallet_ledger_idempotency"
down_revision = "20260206_phase2_click_redirect"
branch_labels = None
depends_on = None


_UQ_NAME = "uq_wallet_ledger_source_entry"


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "wallet_ledger" not in tables:
        return

    existing_uqs = {uq.get("name") for uq in inspector.get_unique_constraints("wallet_ledger")}
    if _UQ_NAME not in existing_uqs:
        # SQLite doesn't support ALTER TABLE ADD CONSTRAINT, so use batch mode.
        with op.batch_alter_table("wallet_ledger") as batch_op:
            batch_op.create_unique_constraint(
                _UQ_NAME,
                ["source_type", "source_id", "entry_type"],
            )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "wallet_ledger" not in tables:
        return

    existing_uqs = {uq.get("name") for uq in inspector.get_unique_constraints("wallet_ledger")}
    if _UQ_NAME in existing_uqs:
        with op.batch_alter_table("wallet_ledger") as batch_op:
            batch_op.drop_constraint(_UQ_NAME, type_="unique")
