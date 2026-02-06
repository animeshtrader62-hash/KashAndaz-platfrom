from __future__ import annotations

from datetime import datetime, timezone
from urllib.parse import urlparse

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import AdminLog, Offer, Store
from app.schemas.offer import (
    AdminOffersListResponse,
    OfferCreate,
    OfferOut,
    OfferStatusUpdate,
    OfferUpdate,
)

router = APIRouter(prefix="/admin/offers", tags=["admin"])


def _log(db: Session, admin_id: str, action: str) -> None:
    db.add(AdminLog(admin_id=admin_id, action=action))


def _validate_absolute_url(url: str) -> str:
    u = (url or "").strip()
    parsed = urlparse(u)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise HTTPException(status_code=400, detail="affiliate_redirect_url must be an absolute URL")
    return u


def _validate_window(start_at: datetime, end_at: datetime) -> None:
    if start_at >= end_at:
        raise HTTPException(status_code=400, detail="start_at must be before end_at")


@router.post("", response_model=OfferOut)
def create_offer(
    payload: OfferCreate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    store = db.query(Store).filter(Store.id == payload.store_id).first()
    if not store or not store.is_active:
        raise HTTPException(status_code=400, detail="store_id must refer to an active store")

    _validate_window(payload.start_at, payload.end_at)

    offer = Offer(
        store_id=payload.store_id,
        title=payload.title.strip(),
        description=payload.description.strip() if payload.description else None,
        affiliate_redirect_url=_validate_absolute_url(payload.affiliate_redirect_url),
        cashback_text=payload.cashback_text.strip(),
        start_at=payload.start_at,
        end_at=payload.end_at,
        status=payload.status,
        created_by=admin.id,
    )

    db.add(offer)
    _log(db, admin.id, f"offer_create offer_id={offer.id} store_id={offer.store_id}")
    db.commit()
    db.refresh(offer)
    return OfferOut.model_validate(offer)


@router.put("/{offer_id}", response_model=OfferOut)
def update_offer(
    offer_id: str,
    payload: OfferUpdate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    # store_id is intentionally immutable to reduce accidental cross-store reassignment.
    if payload.title is not None:
        offer.title = payload.title.strip()
    if payload.description is not None:
        offer.description = payload.description.strip() or None
    if payload.affiliate_redirect_url is not None:
        offer.affiliate_redirect_url = _validate_absolute_url(payload.affiliate_redirect_url)
    if payload.cashback_text is not None:
        offer.cashback_text = payload.cashback_text.strip()

    if payload.start_at is not None:
        offer.start_at = payload.start_at
    if payload.end_at is not None:
        offer.end_at = payload.end_at
    if payload.start_at is not None or payload.end_at is not None:
        _validate_window(offer.start_at, offer.end_at)

    if payload.status is not None:
        offer.status = payload.status

    _log(db, admin.id, f"offer_update offer_id={offer.id}")
    db.add(offer)
    db.commit()
    db.refresh(offer)
    return OfferOut.model_validate(offer)


@router.patch("/{offer_id}/status", response_model=OfferOut)
def set_offer_status(
    offer_id: str,
    payload: OfferStatusUpdate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    offer = db.query(Offer).filter(Offer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    offer.status = payload.status
    _log(db, admin.id, f"offer_status offer_id={offer.id} status={payload.status}")
    db.add(offer)
    db.commit()
    db.refresh(offer)
    return OfferOut.model_validate(offer)


@router.get("", response_model=AdminOffersListResponse)
def list_offers(
    store_id: str | None = None,
    status: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be 1..100")

    q = db.query(Offer)
    if store_id:
        q = q.filter(Offer.store_id == store_id)
    if status:
        q = q.filter(Offer.status == status)

    total_items = q.count()
    rows = q.order_by(Offer.start_at.desc()).offset((page - 1) * limit).limit(limit).all()

    total_pages = (total_items + limit - 1) // limit if limit else 1
    return AdminOffersListResponse(
        offers=[OfferOut.model_validate(o) for o in rows],
        pagination={
            "current_page": page,
            "total_pages": total_pages,
            "total_items": total_items,
        },
    )


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)
