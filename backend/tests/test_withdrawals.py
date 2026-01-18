import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.db.base import Base
from app.db.deps import get_db
from app.core.security import create_access_token
from app import models


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


@pytest.fixture()
def client(db_session_override):
    def _get_db_override():
        try:
            yield db_session_override
        finally:
            pass

    app.dependency_overrides[get_db] = _get_db_override
    transport = ASGITransport(app=app)
    return AsyncClient(transport=transport, base_url="http://test")


@pytest.mark.anyio
async def test_withdrawal_success_and_ledger(client, db_session_override):
    user = models.User(name="U", email="w@test.com", phone="777", hashed_password="x")
    db_session_override.add(user)
    db_session_override.commit()

    credit = models.WalletLedger(
        user_id=user.id,
        entry_type="credit",
        amount=200,
        source_type="transaction",
        source_id="tx-1",
    )
    db_session_override.add(credit)
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "amount": 100,
        "method": "upi",
        "upi_id": "user@upi",
    }

    async with client as ac:
        res = await ac.post("/api/withdraw", json=payload, headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert body["status"] == "pending"

    ledger = (
        db_session_override.query(models.WalletLedger)
        .filter(models.WalletLedger.source_type == "withdrawal")
        .first()
    )
    assert ledger is not None
    assert float(ledger.amount) == 100


@pytest.mark.anyio
async def test_withdrawal_insufficient_balance(client, db_session_override):
    user = models.User(name="U2", email="w2@test.com", phone="888", hashed_password="x")
    db_session_override.add(user)
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "amount": 100,
        "method": "upi",
        "upi_id": "user@upi",
    }

    async with client as ac:
        res = await ac.post("/api/withdraw", json=payload, headers=headers)
        assert res.status_code == 400


@pytest.mark.anyio
async def test_withdrawal_below_minimum(client, db_session_override):
    user = models.User(name="U3", email="w3@test.com", phone="999", hashed_password="x")
    db_session_override.add(user)
    db_session_override.commit()

    credit = models.WalletLedger(
        user_id=user.id,
        entry_type="credit",
        amount=200,
        source_type="transaction",
        source_id="tx-2",
    )
    db_session_override.add(credit)
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "amount": 10,
        "method": "upi",
        "upi_id": "user@upi",
    }

    async with client as ac:
        res = await ac.post("/api/withdraw", json=payload, headers=headers)
        assert res.status_code == 400
