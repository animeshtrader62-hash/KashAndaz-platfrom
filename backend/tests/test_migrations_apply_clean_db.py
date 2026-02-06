from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest
from sqlalchemy import create_engine, inspect, text


@pytest.mark.anyio
async def test_migrations_apply_clean_db(tmp_path: Path):
    """Smoke-test Alembic on a clean SQLite file.

    NOTE: This repo's Alembic migrations are incremental and assume the core tables
    (users/stores/clicks/transactions/wallet_ledger) already exist.

    In production today, those tables are created by the app bootstrap.
    To validate migrations independently (and without relying on create_all()),
    we create a minimal baseline schema via SQL, then run `alembic upgrade head`.
    """

    backend_root = Path(__file__).resolve().parents[1]
    alembic_ini = backend_root / "alembic.ini"

    db_file = tmp_path / "migration_smoke_test.db"
    db_url = f"sqlite+pysqlite:///{db_file.as_posix()}"

    engine = create_engine(db_url)
    with engine.begin() as conn:
        # Minimal baseline schema so Alembic migrations can apply.
        conn.execute(
            text(
                """
                CREATE TABLE users (
                    id VARCHAR(36) PRIMARY KEY NOT NULL,
                    name VARCHAR(120) NOT NULL,
                    email VARCHAR(120) NOT NULL,
                    phone VARCHAR(20),
                    hashed_password VARCHAR(255) NOT NULL,
                    role VARCHAR(20) NOT NULL DEFAULT 'user',
                    is_blocked BOOLEAN NOT NULL DEFAULT 0,
                    created_at DATETIME
                );
                """
            )
        )
        conn.execute(text("CREATE UNIQUE INDEX uq_users_email ON users(email);"))

        conn.execute(
            text(
                """
                CREATE TABLE stores (
                    id VARCHAR(36) PRIMARY KEY NOT NULL,
                    name VARCHAR(160) NOT NULL,
                    logo_url VARCHAR(500),
                    cashback_rate VARCHAR(50) NOT NULL,
                    cashback_type VARCHAR(20) NOT NULL,
                    category VARCHAR(100),
                    is_active BOOLEAN NOT NULL DEFAULT 1,
                    created_at DATETIME
                );
                """
            )
        )

        conn.execute(
            text(
                """
                CREATE TABLE clicks (
                    id VARCHAR(36) PRIMARY KEY NOT NULL,
                    user_id VARCHAR(36) NOT NULL,
                    store_id VARCHAR(36) NOT NULL,
                    created_at DATETIME,
                    FOREIGN KEY(user_id) REFERENCES users(id),
                    FOREIGN KEY(store_id) REFERENCES stores(id)
                );
                """
            )
        )

        conn.execute(
            text(
                """
                CREATE TABLE transactions (
                    id VARCHAR(36) PRIMARY KEY NOT NULL,
                    user_id VARCHAR(36) NOT NULL,
                    store_id VARCHAR(36) NOT NULL,
                    click_id VARCHAR(36),
                    external_order_id VARCHAR(120) NOT NULL,
                    purchase_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
                    cashback_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
                    cashback_rate VARCHAR(50),
                    status VARCHAR(20) NOT NULL DEFAULT 'pending',
                    created_at DATETIME,
                    confirmed_at DATETIME,
                    paid_at DATETIME,
                    cancelled_reason VARCHAR(255),
                    FOREIGN KEY(user_id) REFERENCES users(id),
                    FOREIGN KEY(store_id) REFERENCES stores(id),
                    FOREIGN KEY(click_id) REFERENCES clicks(id)
                );
                """
            )
        )

        conn.execute(
            text(
                """
                CREATE TABLE wallet_ledger (
                    id VARCHAR(36) PRIMARY KEY NOT NULL,
                    user_id VARCHAR(36) NOT NULL,
                    entry_type VARCHAR(10) NOT NULL,
                    amount NUMERIC(12,2) NOT NULL,
                    source_type VARCHAR(30) NOT NULL,
                    source_id VARCHAR(36) NOT NULL,
                    created_at DATETIME,
                    FOREIGN KEY(user_id) REFERENCES users(id)
                );
                """
            )
        )

    # Run Alembic in a separate process so it picks up DATABASE_URL even if
    # other tests already imported app.db.session and initialized a global engine.
    env = dict(os.environ)
    env["DATABASE_URL"] = db_url
    proc = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=str(backend_root),
        env=env,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr or proc.stdout

    inspector = inspect(engine)
    tables = set(inspector.get_table_names())

    expected = {
        "users",
        "stores",
        "clicks",
        "transactions",
        "wallet_ledger",
        "admin_logs",
        "offers",
        "banners",
    }

    missing = sorted(expected - tables)
    assert not missing, f"Missing tables after migration: {missing}"
