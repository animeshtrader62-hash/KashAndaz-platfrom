import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.db.base import Base
from app.models import Transaction, User, Store
from app.jobs import confirmation_job


@pytest.fixture()
def db_session_override():
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


def test_confirmation_job_processes_pending(db_session_override, monkeypatch):
    user = User(name="U", email="u5@test.com", phone="555", hashed_password="x")
    store = Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    db_session_override.add_all([user, store])
    db_session_override.commit()

    tx = Transaction(
        user_id=user.id,
        store_id=store.id,
        external_order_id="order-pending",
        purchase_amount=1000,
        cashback_amount=50,
        status="pending",
    )
    db_session_override.add(tx)
    db_session_override.commit()

    def fake_session_local():
        return db_session_override

    class FakeAffiliateClient:
        def get_status(self, external_order_id: str) -> str:
            return "confirmed"

    called = {"count": 0}

    def fake_notify(db, tx):
        called["count"] += 1

    monkeypatch.setattr(confirmation_job, "SessionLocal", fake_session_local)
    monkeypatch.setattr(confirmation_job, "affiliate_client", FakeAffiliateClient())
    monkeypatch.setattr(confirmation_job.notification_service, "notify_cashback_confirmed", fake_notify)

    processed = confirmation_job.run_confirmation_job()
    assert processed == 1
    assert called["count"] == 1

    updated = db_session_override.query(Transaction).first()
    assert updated.status == "confirmed"
