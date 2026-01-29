from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import User
from app.schemas.admin_users import AdminUsersResponse, AdminUserOut, AdminWalletSummary
from app.services.wallet_service import get_wallet_summary

router = APIRouter(prefix="/admin/users", tags=["admin"])


@router.get("", response_model=AdminUsersResponse)
def list_users(
    search: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be 1..100")

    q = db.query(User)
    if search:
        s = f"%{search.strip()}%"
        q = q.filter(or_(User.email.ilike(s), User.name.ilike(s)))

    total_items = q.count()
    users = (
        q.order_by(User.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )

    payload: list[AdminUserOut] = []
    for u in users:
        summary = get_wallet_summary(db, u.id)
        payload.append(
            AdminUserOut(
                user_id=u.id,
                email=u.email,
                status="blocked" if u.is_blocked else "active",
                wallet_summary=AdminWalletSummary(
                    total_earned=summary["total_earned"],
                    pending=summary["pending"],
                    available=summary["available"],
                    withdrawn=summary["withdrawn"],
                ),
            )
        )

    total_pages = (total_items + limit - 1) // limit if limit else 1
    return AdminUsersResponse(
        users=payload,
        pagination={
            "current_page": page,
            "total_pages": total_pages,
            "total_items": total_items,
        },
    )
