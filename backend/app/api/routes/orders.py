from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.auth import get_current_user
from app.db.deps import get_db
from app.schemas.transaction import TransactionDetail, TransactionsResponse
from app.api.routes.transactions import _list_user_transactions, _transaction_detail

router = APIRouter(prefix="/orders", tags=["orders"])


@router.get("", response_model=TransactionsResponse)
def list_orders(
    status: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    # Alias-only endpoint: same permissions, same query, same response as /transactions
    return _list_user_transactions(db=db, user=user, status=status, page=page, limit=limit)


@router.get("/{transaction_id}", response_model=TransactionDetail)
def order_detail(
    transaction_id: str,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    # Alias-only endpoint: transaction_id is the internal truth
    return _transaction_detail(transaction_id=transaction_id, db=db, user=user)
