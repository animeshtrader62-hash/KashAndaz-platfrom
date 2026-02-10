from __future__ import annotations

from datetime import datetime, timedelta, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from jose import jwt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import models
from app.core.config import settings
from app.core.security import create_access_token, hash_password
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


def _auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.anyio
async def test_auth_integrity_role_claim_present_and_tamper_fails_and_expired_401(client, db_session_override):
    user = models.User(
        name="Viewer",
        email="viewer@zt.test",
        phone="101",
        hashed_password=hash_password("pass1234"),
        role="viewer",
    )
    db_session_override.add(user)
    db_session_override.commit()

    token = create_access_token(user.id, role=user.role)
    payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    assert payload.get("role") == "viewer"

    # Manually modifying JWT must fail signature validation.
    tampered = token[:-1] + ("a" if token[-1] != "a" else "b")
    res = await client.get("/api/admin/dashboard", headers=_auth(tampered))
    assert res.status_code == 401

    # Expired token must always return 401.
    expired_payload = {
        "sub": user.id,
        "role": "viewer",
        "exp": datetime.now(timezone.utc) - timedelta(seconds=10),
    }
    expired = jwt.encode(expired_payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    res = await client.get("/api/admin/dashboard", headers=_auth(expired))
    assert res.status_code == 401


@pytest.mark.anyio
async def test_backend_rejects_unauthorized_roles_admin_users_endpoint(client, db_session_override):
    viewer = models.User(
        name="Viewer",
        email="viewer2@zt.test",
        phone="201",
        hashed_password="x",
        role="viewer",
    )
    admin = models.User(
        name="Admin",
        email="admin@zt.test",
        phone="202",
        hashed_password="x",
        role="admin",
    )
    super_admin = models.User(
        name="Super",
        email="super@zt.test",
        phone="203",
        hashed_password="x",
        role="super_admin",
    )
    db_session_override.add_all([viewer, admin, super_admin])
    db_session_override.commit()

    viewer_token = create_access_token(viewer.id, role=viewer.role)
    admin_token = create_access_token(admin.id, role=admin.role)
    super_token = create_access_token(super_admin.id, role=super_admin.role)

    res = await client.get("/api/admin/users", headers=_auth(viewer_token))
    assert res.status_code == 403

    res = await client.get("/api/admin/users", headers=_auth(admin_token))
    assert res.status_code == 403

    res = await client.get("/api/admin/users", headers=_auth(super_token))
    assert res.status_code == 200


@pytest.mark.anyio
async def test_claims_access_by_role_and_transitions_and_audit_logs(client, db_session_override):
    viewer = models.User(
        name="Viewer",
        email="viewer3@zt.test",
        phone="301",
        hashed_password="x",
        role="viewer",
    )
    admin = models.User(
        name="Admin",
        email="admin3@zt.test",
        phone="302",
        hashed_password="x",
        role="admin",
    )
    super_admin = models.User(
        name="Super",
        email="super3@zt.test",
        phone="303",
        hashed_password="x",
        role="super_admin",
    )
    store = models.Store(name="S", cashback_rate="1%", cashback_type="percentage", is_active=True)
    db_session_override.add_all([viewer, admin, super_admin, store])
    db_session_override.flush()
    claim = models.Claim(user_id=viewer.id, store_id=store.id, order_id="ORDER-1", description=None)
    db_session_override.add(claim)
    db_session_override.commit()

    viewer_token = create_access_token(viewer.id, role=viewer.role)
    admin_token = create_access_token(admin.id, role=admin.role)
    super_token = create_access_token(super_admin.id, role=super_admin.role)

    # viewer can read list
    res = await client.get("/api/admin/claims", headers=_auth(viewer_token))
    assert res.status_code == 200

    # viewer cannot approve
    res = await client.post(
        f"/api/admin/claims/{claim.id}/approve?credit_amount=10",
        headers=_auth(viewer_token),
    )
    assert res.status_code == 403

    # admin can approve
    res = await client.post(
        f"/api/admin/claims/{claim.id}/approve?credit_amount=10",
        headers=_auth(admin_token),
    )
    assert res.status_code == 200

    # approve same claim twice must fail
    res = await client.post(
        f"/api/admin/claims/{claim.id}/approve?credit_amount=10",
        headers=_auth(admin_token),
    )
    assert res.status_code in {400, 409}

    # reject after approve must be blocked
    res = await client.post(
        f"/api/admin/claims/{claim.id}/reject",
        headers=_auth(admin_token),
    )
    assert res.status_code in {400, 409}

    # audit log entry created
    res = await client.get(f"/api/admin/claims/{claim.id}/audit", headers=_auth(admin_token))
    assert res.status_code == 200
    body = res.json()
    assert isinstance(body.get("events"), list)
    assert any("claim_approve" in str(e.get("action", "")) for e in body["events"])

    # super_admin can approve another pending claim
    claim2 = models.Claim(user_id=viewer.id, store_id=store.id, order_id="ORDER-2", description=None)
    db_session_override.add(claim2)
    db_session_override.commit()
    res = await client.post(
        f"/api/admin/claims/{claim2.id}/approve?credit_amount=5",
        headers=_auth(super_token),
    )
    assert res.status_code == 200


@pytest.mark.anyio
async def test_dashboard_hard_gate(client, db_session_override):
    user = models.User(
        name="User",
        email="user@zt.test",
        phone="401",
        hashed_password="x",
        role="user",
    )
    viewer = models.User(
        name="Viewer",
        email="viewer4@zt.test",
        phone="402",
        hashed_password="x",
        role="viewer",
    )
    db_session_override.add_all([user, viewer])
    db_session_override.commit()

    user_token = create_access_token(user.id, role=user.role)
    viewer_token = create_access_token(viewer.id, role=viewer.role)

    res = await client.get("/api/admin/dashboard")
    assert res.status_code == 401

    res = await client.get("/api/admin/dashboard", headers=_auth(user_token))
    assert res.status_code == 403

    res = await client.get("/api/admin/dashboard", headers=_auth(viewer_token))
    assert res.status_code == 200


@pytest.mark.anyio
async def test_users_blocking_and_login_behavior(client, db_session_override):
    super_admin = models.User(
        name="Super",
        email="super-login@example.com",
        phone="501",
        hashed_password=hash_password("superpass"),
        role="super_admin",
    )
    admin = models.User(
        name="Admin",
        email="admin-login@example.com",
        phone="502",
        hashed_password=hash_password("adminpass"),
        role="admin",
    )
    viewer = models.User(
        name="Viewer",
        email="viewer-login@example.com",
        phone="503",
        hashed_password=hash_password("viewerpass"),
        role="viewer",
    )
    db_session_override.add_all([super_admin, admin, viewer])
    db_session_override.commit()

    super_token = create_access_token(super_admin.id, role=super_admin.role)
    viewer_token = create_access_token(viewer.id, role=viewer.role)

    # viewer cannot block/unblock
    res = await client.post(f"/api/admin/users/{admin.id}/block", headers=_auth(viewer_token))
    assert res.status_code == 403

    # super_admin blocks admin
    res = await client.post(f"/api/admin/users/{admin.id}/block", headers=_auth(super_token))
    assert res.status_code == 200

    # blocked admin cannot login
    res = await client.post(
        "/api/auth/login",
        json={"email": "admin-login@example.com", "password": "adminpass"},
    )
    assert res.status_code == 401

    # blocking admin does not affect super_admin login
    res = await client.post(
        "/api/auth/login",
        json={"email": "super-login@example.com", "password": "superpass"},
    )
    assert res.status_code == 200

    # unblock restores login
    res = await client.post(f"/api/admin/users/{admin.id}/unblock", headers=_auth(super_token))
    assert res.status_code == 200
    res = await client.post(
        "/api/auth/login",
        json={"email": "admin-login@example.com", "password": "adminpass"},
    )
    assert res.status_code == 200


@pytest.mark.anyio
async def test_api_pressure_limits_enforced_max_50(client, db_session_override):
    admin = models.User(
        name="Admin",
        email="admin-limit@zt.test",
        phone="601",
        hashed_password="x",
        role="admin",
    )
    db_session_override.add(admin)
    # create 60 stores
    stores = [
        models.Store(name=f"S{i}", cashback_rate="1%", cashback_type="percentage", is_active=True)
        for i in range(60)
    ]
    db_session_override.add_all(stores)
    db_session_override.commit()

    token = create_access_token(admin.id, role=admin.role)

    res = await client.get("/api/admin/stores?limit=500&page=1", headers=_auth(token))
    assert res.status_code == 200
    body = res.json()
    assert len(body.get("stores", [])) == 50
