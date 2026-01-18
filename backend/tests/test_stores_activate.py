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
async def test_list_stores_and_activate(client, db_session_override):
    user = models.User(name="User", email="u@test.com", phone="111", hashed_password="x")
    store = models.Store(name="Amazon", cashback_rate="5%", cashback_type="percentage")
    db_session_override.add_all([user, store])
    db_session_override.commit()

    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    async with client as ac:
        res = await ac.get("/api/stores", headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert "stores" in data
        assert len(data["stores"]) == 1

        res = await ac.post("/api/activate-cashback", json={"store_id": store.id}, headers=headers)
        assert res.status_code == 200
        body = res.json()
        assert body["store_name"] == "Amazon"
        assert body["click_id"]
        assert body["deep_link"]
