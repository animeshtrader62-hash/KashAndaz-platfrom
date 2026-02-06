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
async def test_missing_cashback_submit_and_list(client, db_session_override):
    user = models.User(name="User", email="mc@test.com", phone="111", hashed_password="x")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage")
    db_session_override.add_all([user, store])
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "store_id": store.id,
        "order_id": "order-123",
        "order_amount": "1499.50",
        "order_date": "2026-01-22",
        "expected_cashback": "75.00",
        "notes": "Placed via app but cashback not tracked",
    }

    async with client as ac:
        res = await ac.post("/api/missing-cashback", data=payload, headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert body["status"] == "pending"
        assert body["store_id"] == store.id
        assert body["store_name"] == store.name

        res = await ac.get("/api/missing-cashback/my", headers=headers)
        assert res.status_code == 200
        items = res.json()
        assert len(items) == 1
        assert items[0]["order_id"] == "order-123"
        assert items[0]["status"] == "pending"
