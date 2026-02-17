from urllib.parse import urlparse

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import Store, AdminLog
from app.schemas.admin.store import AdminStoreCreate, AdminStoreOut, AdminStoreUpdate

router = APIRouter(prefix="/admin/stores", tags=["admin"])


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


def _unique_slug(db: Session, desired: str, *, exclude_store_id: str | None = None) -> str:
    base = _slugify(desired)
    slug = base
    i = 2
    while True:
        q = db.query(Store.id).filter(Store.store_slug == slug)
        if exclude_store_id:
            q = q.filter(Store.id != exclude_store_id)
        exists = q.first()
        if not exists:
            return slug
        slug = f"{base}-{i}"
        i += 1


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
                "store_slug": s.store_slug,
                "logo_url": s.logo_url,
                "affiliate_base_url": s.affiliate_base_url,
                "cashback_rate": s.cashback_rate,
                "cashback_type": s.cashback_type,
                "popularity_score": getattr(s, "popularity_score", 0) or 0,
                "featured_store": bool(getattr(s, "featured_store", False)),
                "category": s.category,
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
    if not payload.logo_url:
        raise HTTPException(status_code=400, detail="logo_url is required")
    logo_url = _validate_https_logo(payload.logo_url)
    if logo_url is None:
        raise HTTPException(status_code=400, detail="logo_url is required")

    slug = _unique_slug(db, payload.store_slug or payload.name)

    store = Store(
        name=payload.name,
        store_slug=slug,
        logo_url=logo_url,
        affiliate_base_url=(payload.affiliate_base_url.strip() if payload.affiliate_base_url else None),
        cashback_rate=float(payload.cashback_rate),
        cashback_type=payload.cashback_type,
        popularity_score=int(payload.popularity_score or 0),
        featured_store=bool(payload.featured_store),
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
        store_slug=store.store_slug,
        logo_url=store.logo_url,
        affiliate_base_url=store.affiliate_base_url,
        cashback_rate=store.cashback_rate,
        cashback_type=store.cashback_type,
        popularity_score=getattr(store, "popularity_score", 0) or 0,
        featured_store=bool(getattr(store, "featured_store", False)),
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
        store.logo_url = _validate_https_logo(payload.logo_url) or store.logo_url
    if payload.name is not None:
        store.name = payload.name
    if payload.store_slug is not None:
        store.store_slug = _unique_slug(db, payload.store_slug, exclude_store_id=store.id)
    if payload.affiliate_base_url is not None:
        store.affiliate_base_url = payload.affiliate_base_url.strip() or None
    if payload.cashback_rate is not None:
        store.cashback_rate = float(payload.cashback_rate)
    if payload.cashback_type is not None:
        store.cashback_type = payload.cashback_type
    if payload.popularity_score is not None:
        store.popularity_score = int(payload.popularity_score)
    if payload.featured_store is not None:
        store.featured_store = bool(payload.featured_store)
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
        store_slug=store.store_slug,
        logo_url=store.logo_url,
        affiliate_base_url=store.affiliate_base_url,
        cashback_rate=store.cashback_rate,
        cashback_type=store.cashback_type,
        popularity_score=getattr(store, "popularity_score", 0) or 0,
        featured_store=bool(getattr(store, "featured_store", False)),
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
