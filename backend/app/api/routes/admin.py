from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.auth import require_admin
from app.db.deps import get_db
from app.models import User
from app.services.admin_service import block_user, unblock_user, manual_ledger_entry, get_risk_flags

router = APIRouter(prefix="/admin", tags=["admin"])


@router.post("/users/{user_id}/block", response_model=dict)
def block(user_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user = block_user(db, user)
    return {"status": "ok", "user_id": user.id, "blocked": user.is_blocked}


@router.post("/users/{user_id}/unblock", response_model=dict)
def unblock(user_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user = unblock_user(db, user)
    return {"status": "ok", "user_id": user.id, "blocked": user.is_blocked}


@router.post("/ledger/manual", response_model=dict)
def manual_ledger(
    user_id: str,
    entry_type: str,
    amount: float,
    source_type: str,
    source_id: str,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
):
    if entry_type not in {"credit", "debit"}:
        raise HTTPException(status_code=400, detail="Invalid entry_type")
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")

    entry = manual_ledger_entry(db, user_id, entry_type, amount, source_type, source_id)
    return {"status": "ok", "entry_id": entry.id}


@router.get("/users/{user_id}/risk-flags", response_model=dict)
def risk_flags(user_id: str, db: Session = Depends(get_db), _=Depends(require_admin)):
    flags = get_risk_flags(db, user_id)
    return {"flags": [{"id": f.id, "type": f.flag_type, "details": f.details} for f in flags]}
