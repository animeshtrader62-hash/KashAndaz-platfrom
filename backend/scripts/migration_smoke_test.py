from __future__ import annotations

import os
from pathlib import Path

from sqlalchemy import create_engine, inspect, text


def main() -> int:
    backend_root = Path(__file__).resolve().parents[1]
    alembic_ini = backend_root / "alembic.ini"

    db_path = backend_root / "migration_smoke_test.db"
    if db_path.exists():
        db_path.unlink()

    db_url = f"sqlite+pysqlite:///{db_path.as_posix()}"
    os.environ["DATABASE_URL"] = db_url

    # Alembic migrations in this repo are incremental and assume core tables exist.
    # For a true fresh-DB smoke test without relying on create_all(),
    # create a minimal baseline schema via SQL first.
    engine = create_engine(db_url)
    with engine.begin() as conn:
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

    from alembic import command
    from alembic.config import Config

    config = Config(str(alembic_ini))
    config.set_main_option("script_location", str(backend_root / "alembic"))

    try:
        command.upgrade(config, "head")
    except Exception as exc:
        print("Migration smoke test failed — investigate before proceeding")
        print(f"Error: {exc}")
        return 1

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
    if missing:
        print("Migration smoke test failed — investigate before proceeding")
        print(f"Missing tables: {missing}")
        return 1

    print("Migration smoke test passed on fresh database")
    print(f"DB file: {db_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
