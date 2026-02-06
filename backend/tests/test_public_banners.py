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
async def test_public_banners_filters_and_sorts(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin@pubbanners.test",
        phone="999",
        hashed_password="x",
        role="admin",
    )
    store = models.Store(name="Myntra", cashback_rate="5%", cashback_type="percentage", is_active=True)
    db_session_override.add_all([admin, store])
    db_session_override.commit()

    now = datetime.now(timezone.utc)
    offer = models.Offer(
        store_id=store.id,
        title="Winter Sale",
        description=None,
        affiliate_redirect_url="https://example.com/offer",
        cashback_text="Up to 8% Cashback",
        start_at=now - timedelta(hours=1),
        end_at=now + timedelta(hours=2),
        status="active",
        created_by=admin.id,
    )
    db_session_override.add(offer)
    db_session_override.commit()

    b1 = models.Banner(
        offer_id=offer.id,
        image_url="https://example.com/b2.png",
        priority=2,
        start_at=now - timedelta(minutes=10),
        end_at=now + timedelta(minutes=10),
        status="active",
        created_by=admin.id,
    )
    b2 = models.Banner(
        offer_id=offer.id,
        image_url="https://example.com/b1.png",
        priority=1,
        start_at=now - timedelta(minutes=10),
        end_at=now + timedelta(minutes=10),
        status="active",
        created_by=admin.id,
    )
    b3 = models.Banner(
        offer_id=offer.id,
        image_url="https://example.com/hidden.png",
        priority=0,
        start_at=now - timedelta(minutes=10),
        end_at=now + timedelta(minutes=10),
        status="inactive",
        created_by=admin.id,
    )
    db_session_override.add_all([b1, b2, b3])
    db_session_override.commit()

    async with client as ac:
        res = await ac.get("/api/banners")
        assert res.status_code == 200
        body = res.json()
        assert len(body["banners"]) == 2
        assert body["banners"][0]["priority"] == 1
        assert body["banners"][1]["priority"] == 2
        assert body["banners"][0]["offer_title"] == "Winter Sale"
        assert body["banners"][0]["store_name"] == "Myntra"
