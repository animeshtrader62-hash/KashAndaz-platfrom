from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.auth import require_super_admin
from app.db.deps import get_db
from app.models import User
from app.core.config import settings
from app.schemas.admin.users import (
    AdminCreateStaffUserRequest,
    AdminSetUserRoleRequest,
    AdminUsersResponse,
    AdminUserOut,
    AdminWalletSummary,
)
from app.services.auth_service import create_user, get_user_by_email
from app.services.wallet_service import get_wallet_summary

router = APIRouter(prefix="/admin/users", tags=["admin"])


@router.get("", response_model=AdminUsersResponse)
def list_users(
    search: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    _=Depends(require_super_admin),
):
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1:
        raise HTTPException(status_code=400, detail="limit must be >= 1")
    if limit > 50:
        limit = 50

    q = db.query(User)
    if search:
        s = f"%{search.strip()}%"
        q = q.filter(or_(User.email.ilike(s), User.name.ilike(s)))

    total_items = q.count()
    users = q.order_by(User.created_at.desc()).offset((page - 1) * limit).limit(limit).all()

    payload: list[AdminUserOut] = []
    for u in users:
        summary = get_wallet_summary(db, u.id)
        payload.append(
            AdminUserOut(
                user_id=u.id,
                email=u.email,
                role=getattr(u, "role", None),
                name=getattr(u, "name", None),
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


def _enforce_admin_email_domain(email: str) -> None:
    domain = (getattr(settings, "admin_email_domain", None) or "kashandaz.com").lower().strip()
    if not domain:
        return
    if not email.lower().endswith(f"@{domain}"):
        raise HTTPException(status_code=400, detail="Email must be within admin domain")


@router.post("", response_model=AdminUserOut)
def create_staff_user(
    payload: AdminCreateStaffUserRequest,
    db: Session = Depends(get_db),
    _=Depends(require_super_admin),
):
    _enforce_admin_email_domain(str(payload.email))
    existing = get_user_by_email(db, str(payload.email).lower())
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = create_user(
        db=db,
        name=payload.name,
        email=str(payload.email).lower(),
        password=payload.password,
        phone=None,
        role=payload.role,
    )

    summary = get_wallet_summary(db, user.id)
    return AdminUserOut(
        user_id=user.id,
        email=user.email,
        role=getattr(user, "role", None),
        name=getattr(user, "name", None),
        status="blocked" if user.is_blocked else "active",
        wallet_summary=AdminWalletSummary(
            total_earned=summary["total_earned"],
            pending=summary["pending"],
            available=summary["available"],
            withdrawn=summary["withdrawn"],
        ),
    )


@router.patch("/{user_id}/role", response_model=AdminUserOut)
def set_user_role(
    user_id: str,
    payload: AdminSetUserRoleRequest,
    db: Session = Depends(get_db),
    _=Depends(require_super_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.role = payload.role
    db.add(user)
    db.commit()
    db.refresh(user)

    summary = get_wallet_summary(db, user.id)
    return AdminUserOut(
        user_id=user.id,
        email=user.email,
        role=getattr(user, "role", None),
        name=getattr(user, "name", None),
        status="blocked" if user.is_blocked else "active",
        wallet_summary=AdminWalletSummary(
            total_earned=summary["total_earned"],
            pending=summary["pending"],
            available=summary["available"],
            withdrawn=summary["withdrawn"],
        ),
    )
