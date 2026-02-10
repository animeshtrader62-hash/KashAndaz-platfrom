from urllib.parse import urlparse

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import Store, AdminLog
from app.schemas.admin.store import AdminStoreCreate, AdminStoreOut, AdminStoreUpdate

router = APIRouter(prefix="/admin/stores", tags=["admin"])


def _validate_https_logo(url: str | None) -> str | None:
    if url is None:
        return None
    u = url.strip()
    if not u:
        return None

    parsed = urlparse(u)
    if parsed.scheme != "https" or not parsed.netloc:
        raise HTTPException(status_code=400, detail="logo_url must be a valid HTTPS URL")

    return u


def _log(db: Session, admin_id: str, action: str) -> None:
    db.add(AdminLog(admin_id=admin_id, action=action))


@router.get("", response_model=dict)
def list_stores(
    page: int = 1,
    limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1:
        raise HTTPException(status_code=400, detail="limit must be >= 1")
    if limit > 50:
        limit = 50

    q = db.query(Store)
    total_items = q.count()
    rows = (
        q.order_by(Store.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )

    total_pages = (total_items + limit - 1) // limit if limit else 1
    return {
        "stores": [
            {
                "id": s.id,
                "name": s.name,
                "logo_url": s.logo_url,
                "affiliate_base_url": s.affiliate_base_url,
                "is_active": s.is_active,
                "created_at": s.created_at,
            }
            for s in rows
        ],
        "pagination": {
            "current_page": page,
            "total_pages": total_pages,
            "total_items": total_items,
        },
    }


@router.post("", response_model=AdminStoreOut)
def create_store(
    payload: AdminStoreCreate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    logo_url = _validate_https_logo(payload.logo_url)

    store = Store(
        name=payload.name,
        logo_url=logo_url,
        affiliate_base_url=(payload.affiliate_base_url.strip() if payload.affiliate_base_url else None),
        cashback_rate=payload.cashback_rate,
        cashback_type=payload.cashback_type,
        category=(payload.category.strip() if payload.category else None),
        is_active=payload.is_active,
    )

    db.add(store)
    _log(db, admin.id, f"store_create store_id={store.id} name={payload.name}")
    db.commit()
    db.refresh(store)
    return AdminStoreOut(
        id=store.id,
        name=store.name,
        logo_url=store.logo_url,
        affiliate_base_url=store.affiliate_base_url,
        cashback_rate=store.cashback_rate,
        cashback_type=store.cashback_type,
        category=store.category,
        is_active=store.is_active,
    )


@router.put("/{store_id}", response_model=AdminStoreOut)
def update_store(
    store_id: str,
    payload: AdminStoreUpdate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")

    if payload.logo_url is not None:
        store.logo_url = _validate_https_logo(payload.logo_url)
    if payload.name is not None:
        store.name = payload.name
    if payload.affiliate_base_url is not None:
        store.affiliate_base_url = payload.affiliate_base_url.strip() or None
    if payload.cashback_rate is not None:
        store.cashback_rate = payload.cashback_rate
    if payload.cashback_type is not None:
        store.cashback_type = payload.cashback_type
    if payload.category is not None:
        store.category = payload.category.strip() or None
    if payload.is_active is not None:
        store.is_active = payload.is_active

    _log(db, admin.id, f"store_update store_id={store.id}")
    db.add(store)
    db.commit()
    db.refresh(store)
    return AdminStoreOut(
        id=store.id,
        name=store.name,
        logo_url=store.logo_url,
        affiliate_base_url=store.affiliate_base_url,
        cashback_rate=store.cashback_rate,
        cashback_type=store.cashback_type,
        category=store.category,
        is_active=store.is_active,
    )


@router.post("/{store_id}/pause", response_model=dict)
def pause_store(
    store_id: str,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")
    store.is_active = False
    _log(db, admin.id, f"store_pause store_id={store.id}")
    db.add(store)
    db.commit()
    return {"status": "ok", "store_id": store.id, "is_active": store.is_active}


@router.post("/{store_id}/unpause", response_model=dict)
def unpause_store(
    store_id: str,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")
    store.is_active = True
    _log(db, admin.id, f"store_unpause store_id={store.id}")
    db.add(store)
    db.commit()
    return {"status": "ok", "store_id": store.id, "is_active": store.is_active}
