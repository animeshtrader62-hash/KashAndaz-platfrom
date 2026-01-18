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
async def test_admin_block_unblock_and_manual_ledger(client, db_session_override):
    admin = models.User(name="Admin", email="admin3@test.com", phone="000", hashed_password="x", role="admin")
    user = models.User(name="User", email="u@test.com", phone="123", hashed_password="x")
    db_session_override.add_all([admin, user])
    db_session_override.commit()

    admin_headers = {"Authorization": f"Bearer {create_access_token(admin.id)}"}

    async with client as ac:
        res = await ac.post(f"/api/admin/users/{user.id}/block", headers=admin_headers)
        assert res.status_code == 200
        assert res.json()["blocked"] is True

        res = await ac.post(f"/api/admin/users/{user.id}/unblock", headers=admin_headers)
        assert res.status_code == 200
        assert res.json()["blocked"] is False

        res = await ac.post(
            "/api/admin/ledger/manual",
            params={
                "user_id": user.id,
                "entry_type": "credit",
                "amount": 25,
                "source_type": "adjustment",
                "source_id": "adj-1",
            },
            headers=admin_headers,
        )
        assert res.status_code == 200


@pytest.mark.anyio
async def test_admin_risk_flags(client, db_session_override):
    admin = models.User(name="Admin", email="admin4@test.com", phone="000", hashed_password="x", role="admin")
    user = models.User(name="User", email="u2@test.com", phone="123", hashed_password="x")
    db_session_override.add_all([admin, user])
    db_session_override.commit()

    db_session_override.add(models.RiskFlag(user_id=user.id, flag_type="upi_reuse", details="dup"))
    db_session_override.commit()

    admin_headers = {"Authorization": f"Bearer {create_access_token(admin.id)}"}

    async with client as ac:
        res = await ac.get(f"/api/admin/users/{user.id}/risk-flags", headers=admin_headers)
        assert res.status_code == 200
        assert len(res.json()["flags"]) == 1
