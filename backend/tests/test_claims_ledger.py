import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.db.base import Base
from app import models
from app.services.admin_claim_service import approve_claim


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


def test_claim_approval_creates_ledger(db_session):
    user = models.User(name="User", email="cl@test.com", phone="555", hashed_password="x")
    store = models.Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    db_session.add_all([user, store])
    db_session.commit()

    claim = models.Claim(user_id=user.id, store_id=store.id, order_id="order-999")
    db_session.add(claim)
    db_session.commit()

    approve_claim(db_session, claim, credit_amount=40)

    ledger = (
        db_session.query(models.WalletLedger)
        .filter(models.WalletLedger.source_type == "claim")
        .first()
    )
    assert ledger is not None
    assert float(ledger.amount) == 40
