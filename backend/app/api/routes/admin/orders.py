from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import Transaction, Store
from app.schemas.admin.orders import AdminOrdersResponse, AdminOrderOut

router = APIRouter(prefix="/admin/orders", tags=["admin"])


@router.get("", response_model=AdminOrdersResponse)
def list_orders(
    status: str | None = None,
    store_id: str | None = None,
    user_id: str | None = None,
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

    q = db.query(Transaction)
    if status:
        q = q.filter(Transaction.status == status)
    if store_id:
        q = q.filter(Transaction.store_id == store_id)
    if user_id:
        q = q.filter(Transaction.user_id == user_id)

    total_items = q.count()
    rows = (
        q.order_by(Transaction.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )

    store_map = {s.id: s for s in db.query(Store).all()}

    out: list[AdminOrderOut] = []
    for tx in rows:
        store = store_map.get(tx.store_id)
        out.append(
            AdminOrderOut(
                id=tx.id,
                user_id=tx.user_id,
                store_id=tx.store_id,
                store_name=store.name if store else "",
                store_logo=store.logo_url if store else None,
                order_id=tx.external_order_id,
                purchase_amount=float(tx.purchase_amount),
                cashback_amount=float(tx.cashback_amount),
                status=tx.status,
                created_at=tx.created_at,
            )
        )

    total_pages = (total_items + limit - 1) // limit if limit else 1
    return AdminOrdersResponse(
        transactions=out,
        pagination={
            "current_page": page,
            "total_pages": total_pages,
            "total_items": total_items,
        },
    )


@router.get("/users/{user_id}", response_model=AdminOrdersResponse)
def orders_for_user(
    user_id: str,
    status: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    return list_orders(status=status, store_id=None, user_id=user_id, page=page, limit=limit, db=db)
