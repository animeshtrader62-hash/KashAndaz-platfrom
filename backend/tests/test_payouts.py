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
async def test_admin_payout_marks_completed(client, db_session_override):
    admin = models.User(name="Admin", email="admin@test.com", phone="000", hashed_password="x", role="admin")
    user = models.User(name="User", email="p@test.com", phone="111", hashed_password="x")
    db_session_override.add_all([admin, user])
    db_session_override.commit()

    withdrawal = models.Withdrawal(
        user_id=user.id,
        amount=100,
        status="pending",
        method="upi",
        upi_id="user@upi",
    )
    db_session_override.add(withdrawal)
    db_session_override.commit()

    token = create_access_token(admin.id)
    headers = {"Authorization": f"Bearer {token}"}

    async with client as ac:
        res = await ac.post(f"/api/admin/withdrawals/{withdrawal.id}/pay", headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert body["state"] == "completed"

    updated = db_session_override.query(models.Withdrawal).first()
    assert updated.status == "completed"


@pytest.mark.anyio
async def test_non_admin_forbidden(client, db_session_override):
    user = models.User(name="User", email="p2@test.com", phone="222", hashed_password="x")
    db_session_override.add(user)
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    async with client as ac:
        res = await ac.post("/api/admin/withdrawals/any-id/pay", headers=headers)
        assert res.status_code == 403
