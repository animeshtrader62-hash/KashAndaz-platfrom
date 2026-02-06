from __future__ import annotations

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import models
from app.core.security import create_access_token
from app.db.base import Base
from app.db.deps import get_db
from app.main import app


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
async def test_admin_get_stores_authz_and_includes_inactive(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin@stores.test",
        phone="999",
        hashed_password="x",
        role="admin",
    )
    user = models.User(
        name="User",
        email="user@stores.test",
        phone="111",
        hashed_password="x",
        role="user",
    )
    active_store = models.Store(
        name="Amazon",
        cashback_rate="5%",
        cashback_type="percentage",
        is_active=True,
    )
    inactive_store = models.Store(
        name="Myntra",
        cashback_rate="3%",
        cashback_type="percentage",
        is_active=False,
    )
    db_session_override.add_all([admin, user, active_store, inactive_store])
    db_session_override.commit()

    admin_token = create_access_token(admin.id)
    user_token = create_access_token(user.id)

    async with client as ac:
        res = await ac.get("/api/admin/stores")
        assert res.status_code == 401

        res = await ac.get("/api/admin/stores", headers={"Authorization": f"Bearer {user_token}"})
        assert res.status_code == 403

        res = await ac.get("/api/admin/stores", headers={"Authorization": f"Bearer {admin_token}"})
        assert res.status_code == 200
        body = res.json()

        assert "stores" in body
        names = {s["name"] for s in body["stores"]}
        assert "Amazon" in names
        assert "Myntra" in names
