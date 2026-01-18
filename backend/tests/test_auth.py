import pytest
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.db.base import Base
from app.db.deps import get_db


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
async def test_register_and_login(client):
    async with client as ac:
        register_payload = {
            "name": "Test User",
            "email": "test@example.com",
            "password": "password123",
            "phone": "9999999999",
        }
        res = await ac.post("/api/auth/register", json=register_payload)
        assert res.status_code == 200
        body = res.json()
        assert "token" in body
        assert body["user"]["email"] == "test@example.com"

        login_payload = {
            "email": "test@example.com",
            "password": "password123",
        }
        res = await ac.post("/api/auth/login", json=login_payload)
        assert res.status_code == 200
        body = res.json()
        assert "token" in body
        assert body["user"]["email"] == "test@example.com"