from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import User, Transaction
from app.schemas.admin_dashboard import AdminDashboardResponse, AdminDashboardMetrics

router = APIRouter(prefix="/admin/dashboard", tags=["admin"])


@router.get("", response_model=AdminDashboardResponse)
def dashboard(db: Session = Depends(get_db), _=Depends(require_admin)):
    total_users = db.query(func.count(User.id)).scalar() or 0
    total_orders = db.query(func.count(Transaction.id)).scalar() or 0

    pending_cashback = (
        db.query(func.coalesce(func.sum(Transaction.cashback_amount), 0))
        .filter(Transaction.status == "pending")
        .scalar()
        or 0
    )
    confirmed_cashback = (
        db.query(func.coalesce(func.sum(Transaction.cashback_amount), 0))
        .filter(Transaction.status == "confirmed")
        .scalar()
        or 0
    )
    paid_cashback = (
        db.query(func.coalesce(func.sum(Transaction.cashback_amount), 0))
        .filter(Transaction.status == "paid")
        .scalar()
        or 0
    )

    return AdminDashboardResponse(
        metrics=AdminDashboardMetrics(
            total_users=int(total_users),
            total_orders=int(total_orders),
            pending_cashback=float(pending_cashback),
            confirmed_cashback=float(confirmed_cashback),
            paid_cashback=float(paid_cashback),
        )
    )
