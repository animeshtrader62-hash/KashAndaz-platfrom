from __future__ import annotations

import re
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


@pytest.mark.anyio
async def test_activate_cashback_returns_tracking_redirect_url(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin@act.test",
        phone="999",
        hashed_password="x",
        role="admin",
    )
    user = models.User(name="User", email="act@test.com", phone="111", hashed_password="x")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage", is_active=True)
    db_session_override.add_all([admin, user, store])
    db_session_override.commit()

    now = datetime.now(timezone.utc)
    offer = models.Offer(
        store_id=store.id,
        title="Sale",
        description=None,
        affiliate_redirect_url="https://example.com/final",
        cashback_text="Up to 7% Cashback",
        start_at=now - timedelta(minutes=5),
        end_at=now + timedelta(minutes=5),
        status="active",
        created_by=admin.id,
    )
    db_session_override.add(offer)
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    async with client as ac:
        res = await ac.post("/api/activate-cashback", json={"store_id": store.id}, headers=headers)
        assert res.status_code == 200
        body = res.json()

        assert body["click_id"]
        assert body["deep_link"]
        assert body["affiliate_redirect_url"] == body["deep_link"]

        base = (settings.tracking_redirect_base or "").rstrip("/")
        assert base
        assert body["deep_link"].startswith(f"{base}/")

        tracking_id = body["deep_link"].rsplit("/", 1)[-1]
        assert len(tracking_id) >= 32
        assert re.fullmatch(r"[A-Za-z0-9_\-]+", tracking_id) is not None
        assert user.id not in tracking_id

        # Integration: activate -> redirect must go to the stored offer URL.
        redir = await ac.get(f"/api/r/{tracking_id}", follow_redirects=False)
        assert redir.status_code == 302
        assert redir.headers.get("location") == "https://example.com/final"

        # Immutability: offer URL changes later must NOT change existing click redirect.
        offer.affiliate_redirect_url = "https://example.com/changed"
        db_session_override.add(offer)
        db_session_override.commit()

        redir2 = await ac.get(f"/api/r/{tracking_id}", follow_redirects=False)
        assert redir2.status_code == 302
        assert redir2.headers.get("location") == "https://example.com/final"
