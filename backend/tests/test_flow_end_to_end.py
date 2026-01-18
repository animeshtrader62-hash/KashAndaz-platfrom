import json
import hmac
import hashlib
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.db.base import Base
from app.db.deps import get_db
from app.core.security import create_access_token
from app.core.config import settings
from app import models
from app.services.confirmation_service import confirm_transaction


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


def sign_webhook(payload: dict) -> tuple[str, dict]:
    raw = json.dumps(payload, separators=(",", ":"), sort_keys=True)
    signature = hmac.new(
        settings.webhook_secret.encode("utf-8"),
        raw.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    headers = {
        settings.webhook_signature_header: signature,
        "Content-Type": "application/json",
    }
    return raw, headers


@pytest.mark.anyio
async def test_end_to_end_cashback_flow(client, db_session_override):
    user = models.User(name="User", email="flow@test.com", phone="111", hashed_password="x")
    admin = models.User(name="Admin", email="adminflow@test.com", phone="000", hashed_password="x", role="admin")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage")
    db_session_override.add_all([user, admin, store])
    db_session_override.commit()

    user_token = create_access_token(user.id)
    admin_token = create_access_token(admin.id)
    user_headers = {"Authorization": f"Bearer {user_token}"}
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    async with client as ac:
        # Activate cashback
        res = await ac.post("/api/activate-cashback", json={"store_id": store.id}, headers=user_headers)
        assert res.status_code == 200
        click_id = res.json()["click_id"]

        # Webhook -> pending transaction
        payload = {
            "external_order_id": "order-flow-1",
            "store_id": store.id,
            "click_id": click_id,
            "purchase_amount": 2000,
            "cashback_amount": 100,
            "cashback_rate": "5%",
            "status": "pending",
        }
        raw, headers = sign_webhook(payload)
        res = await ac.post("/api/webhooks/tracking", content=raw, headers=headers)
        assert res.status_code == 200
        tx_id = res.json()["transaction_id"]

        # Confirm transaction (ledger credit)
        tx = db_session_override.query(models.Transaction).filter(models.Transaction.id == tx_id).first()
        assert tx is not None
        confirm_transaction(db_session_override, tx)

        # Withdraw
        res = await ac.post(
            "/api/withdraw",
            json={"amount": 50, "method": "upi", "upi_id": "user@upi"},
            headers=user_headers,
        )
        assert res.status_code == 200
        withdrawal_id = res.json()["withdrawal_id"]

        # Admin payout
        res = await ac.post(f"/api/admin/withdrawals/{withdrawal_id}/pay", headers=admin_headers)
        assert res.status_code == 200
        assert res.json()["state"] == "completed"
