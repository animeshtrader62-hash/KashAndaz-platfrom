import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.db.base import Base
from app import models
from app.services.transaction_service import can_transition, update_status


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


def test_transition_rules():
    assert can_transition("pending", "confirmed") is True
    assert can_transition("pending", "declined") is True
    assert can_transition("pending", "paid") is False
    assert can_transition("confirmed", "paid") is True
    assert can_transition("confirmed", "declined") is False


def test_update_status_flow(db_session):
    user = models.User(name="U", email="u@test.com", phone="123", hashed_password="x")
    store = models.Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    db_session.add_all([user, store])
    db_session.commit()

    tx = models.Transaction(
        user_id=user.id,
        store_id=store.id,
        external_order_id="order-xyz",
        purchase_amount=1000,
        cashback_amount=50,
        status="pending",
    )
    db_session.add(tx)
    db_session.commit()
    db_session.refresh(tx)

    tx = update_status(db_session, tx, "confirmed")
    assert tx.status == "confirmed"
    assert tx.confirmed_at is not None

    tx = update_status(db_session, tx, "paid")
    assert tx.status == "paid"
    assert tx.paid_at is not None

    with pytest.raises(ValueError):
        update_status(db_session, tx, "declined")
