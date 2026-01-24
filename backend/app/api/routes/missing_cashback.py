from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, File, Form, UploadFile
from sqlalchemy.orm import Session

from app.core.auth import get_current_user
from app.db.deps import get_db
from app.models import Store
from app.schemas.missing_cashback import MissingCashbackOut
from app.services.missing_cashback_service import (
    create_missing_cashback_request,
    list_my_missing_cashback_requests,
)

router = APIRouter(prefix="/missing-cashback", tags=["missing_cashback"])


@router.post("", response_model=MissingCashbackOut)
def submit_missing_cashback(
    store_id: str = Form(...),
    order_id: str = Form(...),
    order_amount: Decimal = Form(...),
    order_date: date = Form(...),
    expected_cashback: Decimal | None = Form(default=None),
    notes: str | None = Form(default=None),
    screenshot: UploadFile | None = File(default=None),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    try:
        req = create_missing_cashback_request(
            db=db,
            user=user,
            store_id=store_id,
            order_id=order_id,
            order_amount=order_amount,
            order_date=order_date,
            expected_cashback=expected_cashback,
            notes=notes,
            screenshot=screenshot,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    store = db.query(Store).filter(Store.id == req.store_id).first()
    store_name_value = store.name if store else ""

    return MissingCashbackOut(
        id=req.id,
        user_id=req.user_id,
        store_id=req.store_id,
        store_name=store_name_value,
        order_id=req.order_id,
        order_amount=req.order_amount,
        order_date=req.order_date,
        expected_cashback=req.expected_cashback,
        screenshot_url=req.screenshot_url,
        notes=req.notes,
        status=req.status,
        admin_comment=req.admin_comment,
        created_at=req.created_at,
    )


@router.get("/my", response_model=list[MissingCashbackOut])
def my_missing_cashback(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    rows = list_my_missing_cashback_requests(db=db, user=user)
    out: list[MissingCashbackOut] = []
    for req, store_name in rows:
        out.append(
            MissingCashbackOut(
                id=req.id,
                user_id=req.user_id,
                store_id=req.store_id,
                store_name=store_name,
                order_id=req.order_id,
                order_amount=req.order_amount,
                order_date=req.order_date,
                expected_cashback=req.expected_cashback,
                screenshot_url=req.screenshot_url,
                notes=req.notes,
                status=req.status,
                admin_comment=req.admin_comment,
                created_at=req.created_at,
            )
        )
    return out
