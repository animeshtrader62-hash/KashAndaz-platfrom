"""Admin security: user lockout, token revocation, reset fields

- Add login lockout metadata fields to users
- Add token_version to support token revocation
- Add password reset token storage fields

Revision ID: 20260209_admin_security_user_fields
Revises: 20260206_wallet_ledger_idempotency
Create Date: 2026-02-09
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "20260209_admin_security_user_fields"
down_revision = "20260206_wallet_ledger_idempotency"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "users" not in tables:
        return

    cols = {c["name"] for c in inspector.get_columns("users")}

    additions: list[tuple[str, sa.Column]] = []
    if "failed_login_attempts" not in cols:
        additions.append(("failed_login_attempts", sa.Column("failed_login_attempts", sa.Integer(), nullable=False, server_default="0")))
    if "locked_until" not in cols:
        additions.append(("locked_until", sa.Column("locked_until", sa.DateTime(timezone=True), nullable=True)))
    if "last_failed_login_at" not in cols:
        additions.append(("last_failed_login_at", sa.Column("last_failed_login_at", sa.DateTime(timezone=True), nullable=True)))
    if "last_login_at" not in cols:
        additions.append(("last_login_at", sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True)))
    if "last_login_ip" not in cols:
        additions.append(("last_login_ip", sa.Column("last_login_ip", sa.String(length=64), nullable=True)))
    if "token_version" not in cols:
        additions.append(("token_version", sa.Column("token_version", sa.Integer(), nullable=False, server_default="0")))
    if "password_reset_token_hash" not in cols:
        additions.append(("password_reset_token_hash", sa.Column("password_reset_token_hash", sa.String(length=128), nullable=True)))
    if "password_reset_requested_at" not in cols:
        additions.append(("password_reset_requested_at", sa.Column("password_reset_requested_at", sa.DateTime(timezone=True), nullable=True)))
    if "password_reset_requested_ip" not in cols:
        additions.append(("password_reset_requested_ip", sa.Column("password_reset_requested_ip", sa.String(length=64), nullable=True)))
    if "password_reset_token_expires_at" not in cols:
        additions.append(("password_reset_token_expires_at", sa.Column("password_reset_token_expires_at", sa.DateTime(timezone=True), nullable=True)))
    if "password_reset_token_used_at" not in cols:
        additions.append(("password_reset_token_used_at", sa.Column("password_reset_token_used_at", sa.DateTime(timezone=True), nullable=True)))
    if "password_reset_used_ip" not in cols:
        additions.append(("password_reset_used_ip", sa.Column("password_reset_used_ip", sa.String(length=64), nullable=True)))

    if not additions:
        return

    # SQLite needs batch mode for safe ALTERs across versions.
    with op.batch_alter_table("users") as batch_op:
        for _, col in additions:
            batch_op.add_column(col)


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "users" not in tables:
        return

    cols = {c["name"] for c in inspector.get_columns("users")}
    drop_order = [
        "password_reset_used_ip",
        "password_reset_token_used_at",
        "password_reset_token_expires_at",
        "password_reset_requested_ip",
        "password_reset_requested_at",
        "password_reset_token_hash",
        "token_version",
        "last_login_ip",
        "last_login_at",
        "last_failed_login_at",
        "locked_until",
        "failed_login_attempts",
    ]

    with op.batch_alter_table("users") as batch_op:
        for name in drop_order:
            if name in cols:
                batch_op.drop_column(name)
