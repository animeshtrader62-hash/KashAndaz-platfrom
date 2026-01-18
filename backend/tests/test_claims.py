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
async def test_claim_submit_approve_reject(client, db_session_override):
    admin = models.User(name="Admin", email="cadmin@test.com", phone="000", hashed_password="x", role="admin")
    user = models.User(name="User", email="c@test.com", phone="111", hashed_password="x")
    store = models.Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    db_session_override.add_all([admin, user, store])
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "store_id": store.id,
        "order_id": "order-777",
        "description": "Missing cashback",
        "screenshot_url": "https://s3.example.com/shot.png",
    }

    async with client as ac:
        res = await ac.post("/api/claims", json=payload, headers=headers)
        assert res.status_code == 200
        claim_id = res.json()["claim_id"]

        admin_headers = {"Authorization": f"Bearer {create_access_token(admin.id)}"}
        res = await ac.post(
            f"/api/admin/claims/{claim_id}/approve?credit_amount=50",
            headers=admin_headers,
        )
        assert res.status_code == 200
        assert res.json()["state"] == "approved"

    claim = db_session_override.query(models.Claim).filter(models.Claim.id == claim_id).first()
    assert claim.status == "approved"


@pytest.mark.anyio
async def test_claim_reject(client, db_session_override):
    admin = models.User(name="Admin", email="cadmin2@test.com", phone="000", hashed_password="x", role="admin")
    user = models.User(name="User", email="c2@test.com", phone="111", hashed_password="x")
    store = models.Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    db_session_override.add_all([admin, user, store])
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "store_id": store.id,
        "order_id": "order-888",
    }

    async with client as ac:
        res = await ac.post("/api/claims", json=payload, headers=headers)
        claim_id = res.json()["claim_id"]

        admin_headers = {"Authorization": f"Bearer {create_access_token(admin.id)}"}
        res = await ac.post(
            f"/api/admin/claims/{claim_id}/reject",
            headers=admin_headers,
        )
        assert res.status_code == 200
        assert res.json()["state"] == "rejected"
