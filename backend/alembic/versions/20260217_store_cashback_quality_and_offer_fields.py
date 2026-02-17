"""Store cashback standardization + quality fields; Offer type/featured

- Stores:
  - cashback_rate: string -> numeric
  - cashback_type: enforce {percentage, flat}
  - add store_slug (unique), popularity_score, featured_store
  - normalize category to enum-like set
  - enforce non-null logo_url (backfill using Google favicons)

- Offers:
  - add offer_type {coupon, deal, bank_offer, new_user}
  - add is_featured flag

Revision ID: 20260217_store_cashback_quality_and_offer_fields
Revises: 20260209_admin_security_user_fields
Create Date: 2026-02-17
"""

from __future__ import annotations

import re
from urllib.parse import urlparse

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "20260217_store_cashback_quality_and_offer_fields"
down_revision = "20260209_admin_security_user_fields"
branch_labels = None
depends_on = None


_CATEGORIES = {
    "fashion",
    "electronics",
    "beauty",
    "travel",
    "food",
    "home",
    "finance",
    "groceries",
    "other",
}


def _slugify(value: str) -> str:
    cleaned = (value or "").strip().lower()
    out: list[str] = []
    prev_dash = False
    for ch in cleaned:
        is_alnum = ("a" <= ch <= "z") or ("0" <= ch <= "9")
        if is_alnum:
            out.append(ch)
            prev_dash = False
        else:
            if not prev_dash:
                out.append("-")
                prev_dash = True
    slug = "".join(out).strip("-")
    return slug or "store"


_num_re = re.compile(r"[0-9]+(?:\.[0-9]+)?")


def _parse_rate(value: str | None) -> tuple[float, str]:
    """Returns (numeric_rate, cashback_type)."""
    v = (value or "").strip().lower()
    if not v:
        return 0.0, "percentage"

    inferred_type = "percentage" if "%" in v or "percent" in v else "flat" if "flat" in v or "rs" in v or "₹" in v else "percentage"

    m = _num_re.search(v)
    if not m:
        return 0.0, inferred_type

    try:
        n = float(m.group(0))
    except Exception:
        n = 0.0

    if inferred_type == "percentage" and n > 100.0:
        # Defensive: if someone stored "500" intending currency, treat as flat.
        inferred_type = "flat"

    return max(0.0, n), inferred_type


def _favicon_from_affiliate(affiliate_base_url: str | None) -> str:
    """Uses a deterministic HTTPS favicon URL (allowed by existing assets allowlist)."""
    default = "https://www.google.com/favicon.ico"
    if not affiliate_base_url:
        return default

    try:
        parsed = urlparse(affiliate_base_url)
        host = (parsed.hostname or "").strip().lower()
        if not host:
            return default
        return f"https://www.google.com/s2/favicons?domain={host}&sz=128"
    except Exception:
        return default


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)

    tables = set(inspector.get_table_names())

    if "stores" in tables:
        cols = {c["name"] for c in inspector.get_columns("stores")}

        with op.batch_alter_table("stores") as batch:
            if "store_slug" not in cols:
                batch.add_column(sa.Column("store_slug", sa.String(length=200), nullable=True))
            if "cashback_rate_num" not in cols:
                batch.add_column(sa.Column("cashback_rate_num", sa.Numeric(10, 2), nullable=False, server_default="0"))
            if "cashback_type" in cols:
                # keep existing column; we'll normalize values.
                pass
            else:
                batch.add_column(sa.Column("cashback_type", sa.String(length=20), nullable=False, server_default="percentage"))
            if "popularity_score" not in cols:
                batch.add_column(sa.Column("popularity_score", sa.Integer(), nullable=False, server_default="0"))
            if "featured_store" not in cols:
                batch.add_column(sa.Column("featured_store", sa.Boolean(), nullable=False, server_default=sa.false()))

            # Ensure category column exists (may already exist).
            if "category" not in cols:
                batch.add_column(sa.Column("category", sa.String(length=50), nullable=True))

            # Enforce logo_url non-null at the DB level after backfill.
            # If logo_url already exists but nullable, we'll alter after backfill.

        # Backfill data using Python to keep SQLite + Postgres consistent.
        stores = bind.execute(sa.text("SELECT id, name, logo_url, affiliate_base_url, cashback_rate, cashback_type, category FROM stores"))
        seen_slugs: set[str] = set()
        existing_slugs = bind.execute(sa.text("SELECT store_slug FROM stores WHERE store_slug IS NOT NULL"))
        for row in existing_slugs:
            if row[0]:
                seen_slugs.add(str(row[0]))

        for row in stores:
            store_id = row[0]
            name = row[1]
            logo_url = row[2]
            affiliate_base_url = row[3]
            cashback_rate_raw = row[4]
            cashback_type_raw = row[5]
            category_raw = row[6]

            rate_num, inferred_type = _parse_rate(str(cashback_rate_raw) if cashback_rate_raw is not None else None)

            ct = (str(cashback_type_raw or "").strip().lower())
            if ct not in {"percentage", "flat"}:
                ct = inferred_type

            slug_base = _slugify(str(name or "store"))
            slug = slug_base
            i = 2
            while slug in seen_slugs:
                slug = f"{slug_base}-{i}"
                i += 1
            seen_slugs.add(slug)

            logo = (str(logo_url).strip() if logo_url is not None else "")
            if not logo:
                logo = _favicon_from_affiliate(str(affiliate_base_url) if affiliate_base_url is not None else None)

            cat = (str(category_raw).strip().lower() if category_raw is not None else "")
            if cat == "":
                cat_val = None
            else:
                cat_val = cat if cat in _CATEGORIES else "other"

            bind.execute(
                sa.text(
                    "UPDATE stores SET store_slug=:slug, logo_url=:logo, cashback_type=:ct, cashback_rate_num=:rate, category=:cat WHERE id=:id"
                ),
                {"slug": slug, "logo": logo, "ct": ct, "rate": rate_num, "cat": cat_val, "id": store_id},
            )

        # Swap cashback_rate string -> numeric.
        with op.batch_alter_table("stores") as batch:
            if "cashback_rate" in cols:
                batch.drop_column("cashback_rate")
            batch.alter_column("cashback_rate_num", new_column_name="cashback_rate")
            batch.alter_column("store_slug", nullable=False)
            batch.alter_column("logo_url", nullable=False)

            batch.create_unique_constraint("uq_stores_store_slug", ["store_slug"])

            batch.create_check_constraint(
                "ck_stores_cashback_type_valid",
                "cashback_type IN ('percentage','flat')",
            )
            batch.create_check_constraint(
                "ck_stores_cashback_rate_nonneg",
                "cashback_rate >= 0",
            )
            batch.create_check_constraint(
                "ck_stores_popularity_nonneg",
                "popularity_score >= 0",
            )
            batch.create_check_constraint(
                "ck_stores_category_valid",
                "category IS NULL OR category IN ('fashion','electronics','beauty','travel','food','home','finance','groceries','other')",
            )

        existing_indexes = {i["name"] for i in inspector.get_indexes("stores")}
        if "ix_stores_slug" not in existing_indexes:
            op.create_index("ix_stores_slug", "stores", ["store_slug"], unique=False)
        if "ix_stores_category" not in existing_indexes:
            op.create_index("ix_stores_category", "stores", ["category"], unique=False)
        if "ix_stores_popularity" not in existing_indexes:
            op.create_index("ix_stores_popularity", "stores", ["popularity_score"], unique=False)
        if "ix_stores_featured" not in existing_indexes:
            op.create_index("ix_stores_featured", "stores", ["featured_store"], unique=False)

    if "offers" in tables:
        cols = {c["name"] for c in inspector.get_columns("offers")}
        with op.batch_alter_table("offers") as batch:
            if "offer_type" not in cols:
                batch.add_column(sa.Column("offer_type", sa.String(length=20), nullable=False, server_default="deal"))
            if "is_featured" not in cols:
                batch.add_column(sa.Column("is_featured", sa.Boolean(), nullable=False, server_default=sa.false()))

            batch.create_check_constraint(
                "ck_offers_offer_type_valid",
                "offer_type IN ('coupon','deal','bank_offer','new_user')",
            )

        existing_indexes = {i["name"] for i in inspector.get_indexes("offers")}
        if "ix_offers_featured" not in existing_indexes:
            op.create_index("ix_offers_featured", "offers", ["is_featured"], unique=False)
        if "ix_offers_type" not in existing_indexes:
            op.create_index("ix_offers_type", "offers", ["offer_type"], unique=False)


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = set(inspector.get_table_names())

    if "offers" in tables:
        cols = {c["name"] for c in inspector.get_columns("offers")}

        existing_indexes = {i["name"] for i in inspector.get_indexes("offers")}
        if "ix_offers_featured" in existing_indexes:
            op.drop_index("ix_offers_featured", table_name="offers")
        if "ix_offers_type" in existing_indexes:
            op.drop_index("ix_offers_type", table_name="offers")

        with op.batch_alter_table("offers") as batch:
            if "ck_offers_offer_type_valid" in {c["name"] for c in inspector.get_check_constraints("offers")}:
                batch.drop_constraint("ck_offers_offer_type_valid", type_="check")
            if "is_featured" in cols:
                batch.drop_column("is_featured")
            if "offer_type" in cols:
                batch.drop_column("offer_type")

    if "stores" in tables:
        cols = {c["name"] for c in inspector.get_columns("stores")}

        existing_indexes = {i["name"] for i in inspector.get_indexes("stores")}
        for idx in ["ix_stores_slug", "ix_stores_category", "ix_stores_popularity", "ix_stores_featured"]:
            if idx in existing_indexes:
                op.drop_index(idx, table_name="stores")

        with op.batch_alter_table("stores") as batch:
            # Drop constraints if they exist.
            existing_checks = {c["name"] for c in inspector.get_check_constraints("stores")}
            for name in [
                "ck_stores_cashback_type_valid",
                "ck_stores_cashback_rate_nonneg",
                "ck_stores_popularity_nonneg",
                "ck_stores_category_valid",
            ]:
                if name in existing_checks:
                    batch.drop_constraint(name, type_="check")

            # Recreate cashback_rate string column.
            if "cashback_rate" in cols:
                batch.add_column(sa.Column("cashback_rate_text", sa.String(length=50), nullable=False, server_default="0"))
                # best-effort: stringify numeric into text
                bind.execute(sa.text("UPDATE stores SET cashback_rate_text = CAST(cashback_rate AS TEXT)"))
                batch.drop_column("cashback_rate")
                batch.alter_column("cashback_rate_text", new_column_name="cashback_rate")

            if "featured_store" in cols:
                batch.drop_column("featured_store")
            if "popularity_score" in cols:
                batch.drop_column("popularity_score")
            if "store_slug" in cols:
                batch.drop_constraint("uq_stores_store_slug", type_="unique")
                batch.drop_column("store_slug")

            # logo_url back to nullable
            if "logo_url" in cols:
                batch.alter_column("logo_url", nullable=True)
