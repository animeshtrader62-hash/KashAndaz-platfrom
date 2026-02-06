from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.transaction import TransactionOut, TransactionDetail, TransactionsResponse
from app.models import Transaction, Store

router = APIRouter(prefix="/transactions", tags=["transactions"])


def _list_user_transactions(
    *,
    db: Session,
    user,
    status: str | None,
    page: int,
    limit: int,
) -> TransactionsResponse:
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be 1..100")

    query = db.query(Transaction).filter(Transaction.user_id == user.id)
    if status:
        query = query.filter(Transaction.status == status)

    total_items = query.count()
    items = (
        query.order_by(Transaction.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )

    store_ids = {tx.store_id for tx in items if tx.store_id}
    store_rows = db.query(Store).filter(Store.id.in_(store_ids)).all() if store_ids else []
    store_map = {s.id: s for s in store_rows}

    transactions = []
    for tx in items:
        store = store_map.get(tx.store_id)
        transactions.append(
            TransactionOut(
                id=tx.id,
                store_name=store.name if store else "",
                store_logo=store.logo_url if store else None,
                order_id=tx.external_order_id,
                purchase_amount=float(tx.purchase_amount),
                cashback_amount=float(tx.cashback_amount),
                status=tx.status,
                created_at=tx.created_at,
                confirmed_at=tx.confirmed_at,
                paid_at=tx.paid_at,
            )
        )

    total_pages = (total_items + limit - 1) // limit
    return TransactionsResponse(
        transactions=transactions,
        pagination={
            "current_page": page,
            "total_pages": total_pages,
            "total_items": total_items,
        },
    )


def _transaction_detail(
    *,
    transaction_id: str,
    db: Session,
    user,
) -> TransactionDetail:
    tx = (
        db.query(Transaction)
        .filter(Transaction.id == transaction_id, Transaction.user_id == user.id)
        .first()
    )
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")

    store = db.query(Store).filter(Store.id == tx.store_id).first()
    status_desc = {
        "pending": "Waiting for return period to end",
        "confirmed": "Cashback confirmed",
        "paid": "Cashback paid",
        "declined": "Transaction declined",
    }.get(tx.status, "")

    return TransactionDetail(
        id=tx.id,
        store_name=store.name if store else "",
        store_logo=store.logo_url if store else None,
        order_id=tx.external_order_id,
        click_id=tx.click_id,
        purchase_amount=float(tx.purchase_amount),
        cashback_amount=float(tx.cashback_amount),
        cashback_rate=tx.cashback_rate,
        status=tx.status,
        status_description=status_desc,
        created_at=tx.created_at,
        confirmed_at=tx.confirmed_at,
        paid_at=tx.paid_at,
        cancelled_reason=tx.cancelled_reason,
    )


@router.get("", response_model=TransactionsResponse)
def list_transactions(
    status: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return _list_user_transactions(db=db, user=user, status=status, page=page, limit=limit)


@router.get("/{transaction_id}", response_model=TransactionDetail)
def transaction_detail(
    transaction_id: str,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return _transaction_detail(transaction_id=transaction_id, db=db, user=user)
