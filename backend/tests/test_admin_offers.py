from __future__ import annotations

from datetime import datetime, timedelta, timezone

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
async def test_admin_offer_create_and_list(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin@offers.test",
        phone="999",
        hashed_password="x",
        role="admin",
    )
    store = models.Store(
        name="Amazon",
        store_slug="amazon",
        logo_url="https://example.com/amazon.png",
        cashback_rate=5,
        cashback_type="percentage",
        is_active=True,
    )
    db_session_override.add_all([admin, store])
    db_session_override.commit()

    token = create_access_token(admin.id)
    headers = {"Authorization": f"Bearer {token}"}

    now = datetime.now(timezone.utc)
    payload = {
        "store_id": store.id,
        "title": "Big Sale",
        "description": "Test offer",
        "affiliate_redirect_url": "https://example.com/offer",
        "cashback_text": "Up to 7% Cashback",
        "start_at": now.isoformat(),
        "end_at": (now + timedelta(days=1)).isoformat(),
        "status": "active",
    }

    async with client as ac:
        res = await ac.post("/api/admin/offers", json=payload, headers=headers)
        assert res.status_code == 200
        created = res.json()
        assert created["store_id"] == store.id
        assert created["status"] == "active"

        res = await ac.get("/api/admin/offers", headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert len(body["offers"]) == 1
        assert body["offers"][0]["title"] == "Big Sale"

        # Mutation must be logged.
        logs = db_session_override.query(models.AdminLog).all()
        assert len(logs) >= 1
