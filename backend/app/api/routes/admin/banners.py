from __future__ import annotations

from urllib.parse import urlparse

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import AdminLog, Banner, Offer
from app.schemas.banner import (
    AdminBannersListResponse,
    BannerCreate,
    BannerOut,
    BannerStatusUpdate,
    BannerUpdate,
)

router = APIRouter(prefix="/admin/banners", tags=["admin"])


def _log(db: Session, admin_id: str, action: str) -> None:
    db.add(AdminLog(admin_id=admin_id, action=action))


def _validate_https_url(url: str) -> str:
    u = (url or "").strip()
    parsed = urlparse(u)
    if parsed.scheme != "https" or not parsed.netloc:
        raise HTTPException(status_code=400, detail="image_url must be a valid HTTPS URL")
    return u


@router.post("", response_model=BannerOut)
def create_banner(
    payload: BannerCreate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    offer = db.query(Offer).filter(Offer.id == payload.offer_id).first()
    if not offer:
        raise HTTPException(status_code=400, detail="offer_id must refer to an existing offer")

    banner = Banner(
        offer_id=payload.offer_id,
        image_url=_validate_https_url(payload.image_url),
        priority=int(payload.priority),
        start_at=payload.start_at,
        end_at=payload.end_at,
        status=payload.status,
        created_by=admin.id,
    )

    db.add(banner)
    _log(db, admin.id, f"banner_create banner_id={banner.id} offer_id={banner.offer_id}")
    db.commit()
    db.refresh(banner)
    return BannerOut.model_validate(banner)


@router.put("/{banner_id}", response_model=BannerOut)
def update_banner(
    banner_id: str,
    payload: BannerUpdate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    banner = db.query(Banner).filter(Banner.id == banner_id).first()
    if not banner:
        raise HTTPException(status_code=404, detail="Banner not found")

    if payload.image_url is not None:
        banner.image_url = _validate_https_url(payload.image_url)
    if payload.priority is not None:
        banner.priority = int(payload.priority)
    if payload.start_at is not None:
        banner.start_at = payload.start_at
    if payload.end_at is not None:
        banner.end_at = payload.end_at
    if payload.status is not None:
        banner.status = payload.status

    _log(db, admin.id, f"banner_update banner_id={banner.id}")
    db.add(banner)
    db.commit()
    db.refresh(banner)
    return BannerOut.model_validate(banner)


@router.patch("/{banner_id}/status", response_model=BannerOut)
def set_banner_status(
    banner_id: str,
    payload: BannerStatusUpdate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    banner = db.query(Banner).filter(Banner.id == banner_id).first()
    if not banner:
        raise HTTPException(status_code=404, detail="Banner not found")

    banner.status = payload.status
    _log(db, admin.id, f"banner_status banner_id={banner.id} status={payload.status}")
    db.add(banner)
    db.commit()
    db.refresh(banner)
    return BannerOut.model_validate(banner)


@router.get("", response_model=AdminBannersListResponse)
def list_banners(
    offer_id: str | None = None,
    status: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1:
        raise HTTPException(status_code=400, detail="limit must be >= 1")
    if limit > 50:
        limit = 50

    q = db.query(Banner)
    if offer_id:
        q = q.filter(Banner.offer_id == offer_id)
    if status:
        q = q.filter(Banner.status == status)

    total_items = q.count()
    rows = (
        q.order_by(Banner.priority.asc(), Banner.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )

    total_pages = (total_items + limit - 1) // limit if limit else 1
    return AdminBannersListResponse(
        banners=[BannerOut.model_validate(b) for b in rows],
        pagination={
            "current_page": page,
            "total_pages": total_pages,
            "total_items": total_items,
        },
    )
