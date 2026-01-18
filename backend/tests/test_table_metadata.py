from sqlalchemy import create_engine, inspect
from app.db.base import Base
from app import models


def test_tables_exist():
    engine = create_engine("sqlite+pysqlite:///:memory:")
    Base.metadata.create_all(engine)
    inspector = inspect(engine)
    tables = set(inspector.get_table_names())
    assert "users" in tables
    assert "stores" in tables
    assert "clicks" in tables
    assert "transactions" in tables
    assert "wallet_ledger" in tables
    assert "withdrawals" in tables
    assert "claims" in tables
    assert "risk_flags" in tables
