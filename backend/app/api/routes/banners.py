from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from starlette.responses import Response
from sqlalchemy.orm import Session

from app.db.deps import get_db
from app.models import Banner, Offer, Store
from app.schemas.banner import PublicBannersResponse, PublicBannerOut

router = APIRouter(prefix="/banners", tags=["banners"])


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


@router.get("", response_model=PublicBannersResponse)
def list_public_banners(
    response: Response,
    db: Session = Depends(get_db),
):
    now = _now_utc()

    rows = (
        db.query(Banner, Offer, Store)
        .join(Offer, Offer.id == Banner.offer_id)
        .join(Store, Store.id == Offer.store_id)
        .filter(
            Banner.status == "active",
            Banner.start_at <= now,
            Banner.end_at > now,
            Offer.status == "active",
            Offer.start_at <= now,
            Offer.end_at > now,
            Store.is_active == True,  # noqa: E712
        )
        .order_by(Banner.priority.asc(), Banner.created_at.desc())
        .all()
    )

    # Catalog-like; safe to cache briefly.
    response.headers["Cache-Control"] = "public, max-age=60"

    banners: list[PublicBannerOut] = []
    for banner, offer, store in rows:
        banners.append(
            PublicBannerOut(
                id=banner.id,
                image_url=banner.image_url,
                priority=int(banner.priority),
                offer_id=offer.id,
                offer_title=offer.title,
                store_id=store.id,
                store_name=store.name,
                cashback_text=offer.cashback_text,
            )
        )

    return PublicBannersResponse(banners=banners)
