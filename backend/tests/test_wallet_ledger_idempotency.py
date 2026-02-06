from __future__ import annotations

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app import models
from app.services.confirmation_service import confirm_transaction


@pytest.fixture()
def engine():
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    return engine


def test_wallet_ledger_credit_is_idempotent_under_concurrent_confirm(engine):
    Session = sessionmaker(bind=engine)

    s1 = Session()
    s2 = Session()
    try:
        user = models.User(name="User", email="user@ledger.test", phone="111", hashed_password="x")
        store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage", is_active=True)
        s1.add_all([user, store])
        s1.commit()

        tx = models.Transaction(
            user_id=user.id,
            store_id=store.id,
            external_order_id="ORDER-LEDGER-1",
            purchase_amount=100.0,
            cashback_amount=5.0,
            cashback_rate="5%",
            status="pending",
        )
        s1.add(tx)
        s1.commit()

        # Simulate two workers reading the same pending transaction.
        tx1 = s1.query(models.Transaction).filter(models.Transaction.id == tx.id).one()
        tx2 = s2.query(models.Transaction).filter(models.Transaction.id == tx.id).one()
        assert tx1.status == "pending"
        assert tx2.status == "pending"

        confirm_transaction(s1, tx1)

        # Second worker attempts confirmation using a stale "pending" instance.
        # Must not double-credit.
        confirm_transaction(s2, tx2)

        credited = (
            s1.query(models.WalletLedger)
            .filter(
                models.WalletLedger.source_type == "transaction",
                models.WalletLedger.source_id == tx.id,
                models.WalletLedger.entry_type == "credit",
            )
            .count()
        )
        assert credited == 1
    finally:
        s1.close()
        s2.close()
