import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.base import Base
from app import models


@pytest.fixture()
def db_session():
    engine = create_engine("sqlite+pysqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    try:
        yield session
    finally:
        session.close()


def test_unique_transaction_external_order(db_session):
    user = models.User(name="A", email="a@test.com", phone="999", hashed_password="x")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage")
    db_session.add_all([user, store])
    db_session.commit()

    tx1 = models.Transaction(
        user_id=user.id,
        store_id=store.id,
        external_order_id="order-1",
        purchase_amount=1000,
        cashback_amount=50,
        status="pending",
    )
    db_session.add(tx1)
    db_session.commit()

    tx2 = models.Transaction(
        user_id=user.id,
        store_id=store.id,
        external_order_id="order-1",
        purchase_amount=900,
        cashback_amount=45,
        status="pending",
    )
    db_session.add(tx2)
    with pytest.raises(Exception):
        db_session.commit()


def test_wallet_ledger_nonzero(db_session):
    user = models.User(name="B", email="b@test.com", phone="998", hashed_password="x")
    db_session.add(user)
    db_session.commit()

    entry = models.WalletLedger(
        user_id=user.id,
        entry_type="credit",
        amount=0,
        source_type="adjustment",
        source_id="adj-1",
    )
    db_session.add(entry)
    with pytest.raises(Exception):
        db_session.commit()
