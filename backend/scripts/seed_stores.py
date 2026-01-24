"""Seed minimal store data into the local DB.

This is for local development only so the Flutter Stores Listing UI can render real
cards from `/api/stores` without any UI-side mock/fallback data.

Usage (PowerShell):
  Set-Location backend-worktree/backend
  python -m scripts.seed_stores
"""

from __future__ import annotations

from sqlalchemy import select

from app.db.base import Base
from app.db.session import SessionLocal, engine
from app.models.store import Store


SEED_STORES: list[dict[str, str]] = [
    {
        "name": "Amazon",
        "logo_url": "https://www.google.com/s2/favicons?sz=128&domain_url=amazon.in",
        "cashback_rate": "7%",
        "cashback_type": "percentage",
        "category": "Marketplace",
    },
    {
        "name": "Flipkart",
        "logo_url": "https://www.google.com/s2/favicons?sz=128&domain_url=flipkart.com",
        "cashback_rate": "5%",
        "cashback_type": "percentage",
        "category": "Marketplace",
    },
    {
        "name": "Myntra",
        "logo_url": "https://www.google.com/s2/favicons?sz=128&domain_url=myntra.com",
        "cashback_rate": "9%",
        "cashback_type": "percentage",
        "category": "Fashion",
    },
    {
        "name": "Ajio",
        "logo_url": "https://www.google.com/s2/favicons?sz=128&domain_url=ajio.com",
        "cashback_rate": "6%",
        "cashback_type": "percentage",
        "category": "Fashion",
    },
]


def main() -> None:
    # Ensure tables exist for fresh local sqlite DB.
    Base.metadata.create_all(engine)

    with SessionLocal() as db:
        existing = {s.name: s for s in db.scalars(select(Store)).all()}

        inserted = 0
        updated = 0

        for payload in SEED_STORES:
            name = payload["name"]
            store = existing.get(name)
            if store is None:
                db.add(
                    Store(
                        name=name,
                        logo_url=payload["logo_url"],
                        cashback_rate=payload["cashback_rate"],
                        cashback_type=payload["cashback_type"],
                        category=payload.get("category"),
                        is_active=True,
                    )
                )
                inserted += 1
                continue

            changed = False
            if (store.logo_url or "") != payload["logo_url"]:
                store.logo_url = payload["logo_url"]
                changed = True
            if store.cashback_rate != payload["cashback_rate"]:
                store.cashback_rate = payload["cashback_rate"]
                changed = True
            if store.cashback_type != payload["cashback_type"]:
                store.cashback_type = payload["cashback_type"]
                changed = True
            if (store.category or "") != (payload.get("category") or ""):
                store.category = payload.get("category")
                changed = True
            if store.is_active is not True:
                store.is_active = True
                changed = True
            if changed:
                updated += 1

        db.commit()

        if inserted == 0 and updated == 0:
            print("seed_stores: no-op (stores already up-to-date)")
            return

        print(f"seed_stores: inserted {inserted}, updated {updated}")


if __name__ == "__main__":
    main()
