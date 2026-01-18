import hmac
import hashlib
import json
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.db.base import Base
from app.db.deps import get_db
from app.core.config import settings
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


def build_signed_body(payload: dict) -> tuple[str, str]:
    raw = json.dumps(payload, separators=(",", ":"), sort_keys=True)
    signature = hmac.new(
        settings.webhook_secret.encode("utf-8"),
        raw.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return raw, signature


@pytest.mark.anyio
async def test_tracking_webhook_idempotent(client, db_session_override):
    user = models.User(name="User", email="u2@test.com", phone="222", hashed_password="x")
    store = models.Store(name="Flipkart", cashback_rate="5%", cashback_type="percentage")
    db_session_override.add_all([user, store])
    db_session_override.commit()

    click = models.Click(user_id=user.id, store_id=store.id)
    db_session_override.add(click)
    db_session_override.commit()
    db_session_override.refresh(click)

    payload = {
        "external_order_id": "order-123",
        "store_id": store.id,
        "click_id": click.id,
        "purchase_amount": 2500,
        "cashback_amount": 125,
        "cashback_rate": "5%",
        "status": "pending",
    }
    raw, signature = build_signed_body(payload)
    headers = {
        settings.webhook_signature_header: signature,
        "Content-Type": "application/json",
    }

    async with client as ac:
        res = await ac.post("/api/webhooks/tracking", content=raw, headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert body["status"] == "ok"
        assert body["duplicate"] is False

        res = await ac.post("/api/webhooks/tracking", content=raw, headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert body["duplicate"] is True
