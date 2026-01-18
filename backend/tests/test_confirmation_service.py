import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.db.base import Base
from app import models
from app.services.confirmation_service import confirm_transaction


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    try:
        yield session
    finally:
        session.close()


def test_confirm_transaction_creates_ledger(db_session):
    user = models.User(name="U", email="u3@test.com", phone="333", hashed_password="x")
    store = models.Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    db_session.add_all([user, store])
    db_session.commit()

    tx = models.Transaction(
        user_id=user.id,
        store_id=store.id,
        external_order_id="order-abc",
        purchase_amount=1000,
        cashback_amount=50,
        status="pending",
    )
    db_session.add(tx)
    db_session.commit()
    db_session.refresh(tx)

    tx = confirm_transaction(db_session, tx)
    assert tx.status == "confirmed"

    ledger = (
        db_session.query(models.WalletLedger)
        .filter(models.WalletLedger.source_id == tx.id)
        .first()
    )
    assert ledger is not None
    assert ledger.entry_type == "credit"
    assert float(ledger.amount) == 50


def test_confirm_transaction_invalid_state(db_session):
    user = models.User(name="U2", email="u4@test.com", phone="444", hashed_password="x")
    store = models.Store(name="Store2", cashback_rate="5%", cashback_type="percentage")
    db_session.add_all([user, store])
    db_session.commit()

    tx = models.Transaction(
        user_id=user.id,
        store_id=store.id,
        external_order_id="order-def",
        purchase_amount=1000,
        cashback_amount=50,
        status="confirmed",
    )
    db_session.add(tx)
    db_session.commit()

    with pytest.raises(ValueError):
        confirm_transaction(db_session, tx)
