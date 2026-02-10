from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.auth import require_admin, require_admin_viewer
from app.db.deps import get_db
from app.models import Claim, AdminLog
from app.schemas.admin.claims import (
    AdminClaimAuditEvent,
    AdminClaimAuditResponse,
    AdminClaimOut,
    AdminClaimsResponse,
)
from app.services.admin_claim_service import approve_claim, reject_claim

router = APIRouter(prefix="/admin/claims", tags=["admin-claims"])


def _log(db: Session, admin_id: str, action: str) -> None:
    db.add(AdminLog(admin_id=admin_id, action=action))


@router.get("", response_model=AdminClaimsResponse)
def list_claims(
    status: str | None = None,
    search: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    _=Depends(require_admin_viewer),
):
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1:
        raise HTTPException(status_code=400, detail="limit must be >= 1")
    if limit > 50:
        limit = 50

    q = db.query(Claim)
    if status:
        q = q.filter(Claim.status == status)
    if search:
        s = f"%{search.strip()}%"
        q = q.filter(or_(Claim.order_id.ilike(s), Claim.user_id.ilike(s)))

    total_items = q.count()
    rows = (
        q.order_by(Claim.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )
    total_pages = (total_items + limit - 1) // limit if limit else 1

    claims = [
        AdminClaimOut(
            id=c.id,
            user_id=c.user_id,
            store_id=c.store_id,
            order_id=c.order_id,
            description=c.description,
            screenshot_url=c.screenshot_url,
            status=c.status,
            created_at=c.created_at,
            resolved_at=c.resolved_at,
        )
        for c in rows
    ]

    return AdminClaimsResponse(
        claims=claims,
        pagination={
            "current_page": page,
            "total_pages": total_pages,
            "total_items": total_items,
        },
    )


@router.get("/{claim_id}", response_model=AdminClaimOut)
def get_claim(
    claim_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_admin_viewer),
):
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    return AdminClaimOut(
        id=claim.id,
        user_id=claim.user_id,
        store_id=claim.store_id,
        order_id=claim.order_id,
        description=claim.description,
        screenshot_url=claim.screenshot_url,
        status=claim.status,
        created_at=claim.created_at,
        resolved_at=claim.resolved_at,
    )


@router.get("/{claim_id}/audit", response_model=AdminClaimAuditResponse)
def claim_audit(
    claim_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_admin_viewer),
):
    # Simple audit trail based on admin_logs action strings.
    # Actions are written on approve/reject (below).
    prefix = f"claim_"
    needle = f"claim_id={claim_id}"
    rows = (
        db.query(AdminLog)
        .filter(AdminLog.action.ilike(f"{prefix}%"))
        .filter(AdminLog.action.ilike(f"%{needle}%"))
        .order_by(AdminLog.created_at.desc())
        .limit(100)
        .all()
    )
    return AdminClaimAuditResponse(
        events=[
            AdminClaimAuditEvent(
                id=r.id,
                admin_id=r.admin_id,
                action=r.action,
                created_at=r.created_at,
            )
            for r in rows
        ]
    )


@router.post("/{claim_id}/approve", response_model=dict)
def approve(
    claim_id: str,
    credit_amount: float,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")

    try:
        claim = approve_claim(db, claim, credit_amount)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    _log(db, admin.id, f"claim_approve claim_id={claim.id} credit_amount={credit_amount}")
    db.commit()

    return {"status": "ok", "claim_id": claim.id, "state": claim.status}


@router.post("/{claim_id}/reject", response_model=dict)
def reject(
    claim_id: str,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    claim = db.query(Claim).filter(Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")

    try:
        claim = reject_claim(db, claim)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    _log(db, admin.id, f"claim_reject claim_id={claim.id}")
    db.commit()

    return {"status": "ok", "claim_id": claim.id, "state": claim.status}
