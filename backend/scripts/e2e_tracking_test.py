"""End-to-end local tracking flow verification script.

Tests the full activate -> redirect -> DB cycle:
1. Registers a test user
2. Seeds a store + offer
3. Calls POST /api/activate-cashback
4. Calls GET /api/r/{tracking_id} (no follow)
5. Verifies 302 + aff_click_id in Location header
6. Verifies existing query params preserved
7. Verifies Click row in DB with correct redirect_url

Usage: cd backend && python scripts/e2e_tracking_test.py
Requires: local server running on http://127.0.0.1:8000
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Ensure the backend package is importable regardless of cwd.
_backend_root = str(Path(__file__).resolve().parent.parent)
if _backend_root not in sys.path:
    sys.path.insert(0, _backend_root)
os.chdir(_backend_root)
from urllib.parse import parse_qs, urlsplit

import httpx

BASE = "http://127.0.0.1:8000/api"
PASS = "\033[92mPASS\033[0m"
FAIL = "\033[91mFAIL\033[0m"
results: list[tuple[str, bool]] = []


def check(label: str, condition: bool) -> None:
    results.append((label, condition))
    status = PASS if condition else FAIL
    print(f"  [{status}] {label}")


def main() -> None:
    print("=" * 60)
    print("KashAndaz E2E Tracking Flow Test")
    print("=" * 60)

    # --- Step 1: Register ---
    print("\n--- Step 1: Register test user ---")
    r = httpx.post(
        f"{BASE}/auth/register",
        json={
            "name": "E2ETestUser",
            "email": "e2e@example.com",
            "password": "Test1234!secure",
            "phone": "9876543210",
        },
    )
    check("Register returns 200", r.status_code == 200)
    reg_body = r.json()
    token = reg_body.get("token", "")
    check("Token is non-empty", len(token) > 10)
    print(f"  Token: {token[:30]}...")

    # --- Step 2: Seed store + offer via DB ---
    print("\n--- Step 2: Seed store + offer ---")
    from app.db.session import SessionLocal
    from app.models import Click, Offer, Store, User

    db = SessionLocal()
    user = db.query(User).filter(User.email == "e2e@example.com").first()
    assert user, "User not found after registration"
    user.role = "admin"
    db.commit()

    store = Store(
        name="E2EStore",
        store_slug="e2estore",
        logo_url="https://example.com/logo.png",
        affiliate_base_url="https://www.offer18.com/test",
        cashback_rate=5.0,
        cashback_type="percentage",
        is_active=True,
    )
    db.add(store)
    db.commit()
    db.refresh(store)
    print(f"  Store ID: {store.id}")

    now = datetime.now(timezone.utc)
    offer = Offer(
        store_id=store.id,
        title="E2E Test Offer",
        affiliate_redirect_url="https://www.offer18.com/redirect?offer_id=123&sub1=existing",
        cashback_text="Up to 5% Cashback",
        offer_type="deal",
        is_featured=False,
        start_at=now - timedelta(hours=1),
        end_at=now + timedelta(days=1),
        status="active",
        created_by=user.id,
    )
    db.add(offer)
    db.commit()
    db.refresh(offer)
    store_id = store.id
    offer_id = offer.id
    user_id = user.id
    print(f"  Offer ID: {offer_id}")
    db.close()

    # Re-login to pick up the updated role in the JWT.
    print("\n--- Step 2b: Re-login after role promotion ---")
    login_r = httpx.post(
        f"{BASE}/auth/login",
        json={"email": "e2e@example.com", "password": "Test1234!secure"},
    )
    check("Re-login returns 200", login_r.status_code == 200)
    token = login_r.json().get("token", token)
    print(f"  New token: {token[:30]}...")

    # --- Step 3: Activate cashback ---
    print("\n--- Step 3: POST /api/activate-cashback ---")
    headers = {"Authorization": f"Bearer {token}"}
    act = httpx.post(
        f"{BASE}/activate-cashback",
        json={"store_id": store_id},
        headers=headers,
    )
    check("Activate returns 200", act.status_code == 200)
    act_body = act.json()
    print(f"  Response: {json.dumps(act_body, indent=2, default=str)}")

    deep_link = act_body.get("deep_link", "")
    check("deep_link is non-empty", len(deep_link) > 0)
    check("deep_link contains /api/r/", "/api/r/" in deep_link)

    affiliate_redirect_url = act_body.get("affiliate_redirect_url", "")
    check("affiliate_redirect_url equals deep_link", affiliate_redirect_url == deep_link)

    tracking_id = deep_link.rsplit("/", 1)[-1] if deep_link else ""
    check("tracking_id starts with KA_", tracking_id.startswith("KA_"))
    check("tracking_id length >= 32", len(tracking_id) >= 32)
    print(f"  Tracking ID: {tracking_id}")

    # --- Step 4: GET /api/r/{tracking_id} (no follow) ---
    print(f"\n--- Step 4: GET /api/r/{tracking_id[:20]}... ---")
    redir = httpx.get(f"{BASE}/r/{tracking_id}", follow_redirects=False)
    check("Redirect returns 302", redir.status_code == 302)

    location = redir.headers.get("location", "")
    print(f"  Location: {location}")
    check("Location header is non-empty", len(location) > 0)

    parts = urlsplit(location)
    check("Redirect uses HTTPS", parts.scheme == "https")

    qs = parse_qs(parts.query)
    aff_click_id = qs.get("aff_click_id", [None])[0]
    check("aff_click_id present in redirect URL", aff_click_id is not None)
    check("aff_click_id matches tracking_id", aff_click_id == tracking_id)

    # --- Step 5: Existing query params preserved ---
    print("\n--- Step 5: Query param preservation ---")
    check("offer_id preserved", "offer_id" in qs)
    check("sub1 preserved", "sub1" in qs)
    base_path = f"{parts.scheme}://{parts.netloc}{parts.path}"
    check("Base URL path preserved", base_path == "https://www.offer18.com/redirect")

    # --- Step 6: DB verification ---
    print("\n--- Step 6: DB Click row verification ---")
    db2 = SessionLocal()
    click = db2.query(Click).filter(Click.tracking_id == tracking_id).first()
    check("Click row exists in DB", click is not None)
    if click:
        check("Click.tracking_id matches", click.tracking_id == tracking_id)
        check("Click.store_id matches", click.store_id == store_id)
        check("Click.offer_id matches", click.offer_id == offer_id)
        check("Click.user_id matches", click.user_id == user_id)
        check("Click.redirect_url is non-empty", bool(click.redirect_url))
        check(
            "Click.redirect_url contains aff_click_id",
            "aff_click_id" in (click.redirect_url or ""),
        )
        check("Click.expires_at is set", click.expires_at is not None)
        print(f"  Click.redirect_url: {click.redirect_url}")
        print(f"  Click.expires_at:   {click.expires_at}")
    db2.close()

    # --- Summary ---
    print("\n" + "=" * 60)
    total = len(results)
    passed = sum(1 for _, ok in results if ok)
    failed = total - passed
    if failed == 0:
        print(f"RESULT: ALL {total} CHECKS PASSED")
        print("VERDICT: TRACKING FLOW IS PRODUCTION-READY")
    else:
        print(f"RESULT: {passed}/{total} PASSED, {failed} FAILED")
        print("FAILURES:")
        for label, ok in results:
            if not ok:
                print(f"  - {label}")
        print("VERDICT: DO NOT DEPLOY — FIX FAILURES FIRST")
    print("=" * 60)

    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
