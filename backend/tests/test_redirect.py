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
async def test_redirect_by_tracking_id_302_uses_stored_click_redirect_url(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin@redir.test",
        phone="999",
        hashed_password="x",
        role="admin",
    )
    user = models.User(name="User", email="user@redir.test", phone="111", hashed_password="x")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage", is_active=True)
    db_session_override.add_all([admin, user, store])
    db_session_override.commit()

    click = models.Click(
        user_id=user.id,
        store_id=store.id,
        tracking_id="KA-TEST-123",
        offer_id=None,
        redirect_url="https://example.com/immutable",
    )
    db_session_override.add(click)
    db_session_override.commit()

    async with client as ac:
        res = await ac.get("/api/r/KA-TEST-123", follow_redirects=False)
        assert res.status_code == 302
        assert res.headers.get("location") == "https://example.com/immutable"


@pytest.mark.anyio
async def test_redirect_legacy_click_backfills_and_becomes_immutable(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin@immut.test",
        phone="999",
        hashed_password="x",
        role="admin",
    )
    user = models.User(name="User", email="user@immut.test", phone="111", hashed_password="x")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage", is_active=True)
    db_session_override.add_all([admin, user, store])
    db_session_override.commit()

    click = models.Click(user_id=user.id, store_id=store.id, tracking_id="KA-LEGACY-1")
    db_session_override.add(click)
    db_session_override.commit()

    now = datetime.now(timezone.utc)
    offer = models.Offer(
        store_id=store.id,
        title="Sale",
        description=None,
        affiliate_redirect_url="https://example.com/original",
        cashback_text="Up to 7% Cashback",
        start_at=now - timedelta(minutes=5),
        end_at=now + timedelta(minutes=5),
        status="active",
        created_by=admin.id,
    )
    db_session_override.add(offer)
    db_session_override.commit()

    async with client as ac:
        res1 = await ac.get("/api/r/KA-LEGACY-1", follow_redirects=False)
        assert res1.status_code == 302
        assert res1.headers.get("location") == "https://example.com/original"

        # Offer changes later must NOT change existing click redirect.
        offer.affiliate_redirect_url = "https://example.com/changed"
        db_session_override.add(offer)
        db_session_override.commit()

        # The click should have been backfilled (redirect_url stored).
        db_session_override.refresh(click)
        assert click.redirect_url == "https://example.com/original"

        res2 = await ac.get("/api/r/KA-LEGACY-1", follow_redirects=False)
        assert res2.status_code == 302
        assert res2.headers.get("location") == "https://example.com/original"


@pytest.mark.anyio
async def test_redirect_invalid_tracking_id_404(client, db_session_override):
    async with client as ac:
        res = await ac.get("/api/r/does-not-exist", follow_redirects=False)
        assert res.status_code == 404
        assert res.json().get("detail") == "Click not found"


@pytest.mark.anyio
async def test_redirect_expired_click_410(client, db_session_override):
    user = models.User(name="User", email="user@exp.test", phone="111", hashed_password="x")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage", is_active=True)
    db_session_override.add_all([user, store])
    db_session_override.commit()

    click = models.Click(
        user_id=user.id,
        store_id=store.id,
        tracking_id="KA-EXPIRED-1",
        redirect_url="https://example.com/immutable",
        expires_at=datetime.now(timezone.utc) - timedelta(seconds=1),
    )
    db_session_override.add(click)
    db_session_override.commit()

    async with client as ac:
        res = await ac.get("/api/r/KA-EXPIRED-1", follow_redirects=False)
        assert res.status_code == 410
        assert res.json().get("detail") == "Click expired"
