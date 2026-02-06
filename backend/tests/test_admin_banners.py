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
async def test_admin_banner_create_and_list(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin@banners.test",
        phone="999",
        hashed_password="x",
        role="admin",
    )
    store = models.Store(name="Flipkart", cashback_rate="5%", cashback_type="percentage", is_active=True)
    db_session_override.add_all([admin, store])
    db_session_override.commit()

    now = datetime.now(timezone.utc)
    offer = models.Offer(
        store_id=store.id,
        title="Sale",
        description=None,
        affiliate_redirect_url="https://example.com/offer",
        cashback_text="Up to 9% Cashback",
        start_at=now,
        end_at=now + timedelta(days=1),
        status="active",
        created_by=admin.id,
    )
    db_session_override.add(offer)
    db_session_override.commit()

    token = create_access_token(admin.id)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "offer_id": offer.id,
        "image_url": "https://example.com/banner.png",
        "priority": 1,
        "start_at": now.isoformat(),
        "end_at": (now + timedelta(hours=1)).isoformat(),
        "status": "active",
    }

    async with client as ac:
        res = await ac.post("/api/admin/banners", json=payload, headers=headers)
        assert res.status_code == 200
        created = res.json()
        assert created["offer_id"] == offer.id
        assert created["status"] == "active"

        res = await ac.get("/api/admin/banners", headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert len(body["banners"]) == 1

        logs = db_session_override.query(models.AdminLog).all()
        assert len(logs) >= 1
