from __future__ import annotations

import hashlib
import hmac
import json

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import settings
from app.db.base import Base
from app.db.deps import get_db
from app.main import app
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


def _sign(raw_body: bytes) -> str:
    secret = settings.webhook_secret.encode("utf-8")
    return hmac.new(secret, raw_body, hashlib.sha256).hexdigest()


@pytest.mark.anyio
async def test_webhook_tracking_is_idempotent_for_duplicates(client, db_session_override):
    user = models.User(name="User", email="user@wh.test", phone="111", hashed_password="x")
    store = models.Store(
        name="Amazon",
        store_slug="amazon",
        logo_url="https://example.com/amazon.png",
        cashback_rate=5,
        cashback_type="percentage",
        is_active=True,
    )
    db_session_override.add_all([user, store])
    db_session_override.commit()

    click = models.Click(user_id=user.id, store_id=store.id, tracking_id="KA-WH-1")
    db_session_override.add(click)
    db_session_override.commit()

    payload = {
        "external_order_id": "ORDER-1",
        "store_id": store.id,
        "click_id": click.id,
        "purchase_amount": 100.0,
        "cashback_amount": 5.0,
        "cashback_rate": "5%",
        "status": "pending",
    }

    raw = json.dumps(payload).encode("utf-8")
    signature = _sign(raw)

    headers = {settings.webhook_signature_header: signature}

    async with client as ac:
        res1 = await ac.post("/api/webhooks/tracking", content=raw, headers=headers)
        assert res1.status_code == 200
        body1 = res1.json()
        assert body1["status"] == "ok"
        assert body1["duplicate"] is False
        assert body1.get("transaction_id")

        res2 = await ac.post("/api/webhooks/tracking", content=raw, headers=headers)
        assert res2.status_code == 200
        body2 = res2.json()
        assert body2["status"] == "ok"
        assert body2["duplicate"] is True
        assert body2.get("transaction_id") == body1.get("transaction_id")
