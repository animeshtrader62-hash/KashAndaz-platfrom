from datetime import date
from decimal import Decimal
from pathlib import Path
from typing import Tuple

from fastapi import UploadFile
from sqlalchemy.orm import Session

from app.models import Store, User
from app.models.missing_cashback_request import MissingCashbackRequest


_ROOT_DIR = Path(__file__).resolve().parents[2]
_UPLOAD_DIR = _ROOT_DIR / "uploads" / "missing_cashback"


def _save_screenshot(file: UploadFile) -> str:
    _UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    filename = (file.filename or "screenshot").strip()
    ext = filename.split(".")[-1].lower() if "." in filename else ""

    try:
        if ext not in {"jpg", "jpeg", "png"}:
            raise ValueError("Unsupported file type. Please upload jpg, jpeg, or png.")

        import uuid
        import shutil

        out_path = _UPLOAD_DIR / f"{uuid.uuid4()}.{ext}"
        with out_path.open("wb") as out_file:
            # Stream copy to avoid holding large uploads in memory.
            shutil.copyfileobj(file.file, out_file, length=1024 * 1024)
    finally:
        try:
            file.file.close()
        except Exception:
            pass

    # Store as relative path (MVP). You can later serve this via a static endpoint or S3.
    return str(out_path.relative_to(_ROOT_DIR))


def create_missing_cashback_request(
    db: Session,
    user: User,
    store_id: str,
    order_id: str,
    order_amount: Decimal,
    order_date: date,
    expected_cashback: Decimal | None,
    notes: str | None,
    screenshot: UploadFile | None,
) -> MissingCashbackRequest:
    store = db.query(Store).filter(Store.id == store_id).first()
    if not store:
        raise ValueError("Store not found")

    screenshot_url: str | None = None
    if screenshot is not None:
        screenshot_url = _save_screenshot(screenshot)

    req = MissingCashbackRequest(
        user_id=user.id,
        store_id=store_id,
        order_id=order_id,
        order_amount=order_amount,
        order_date=order_date,
        expected_cashback=expected_cashback,
        notes=notes,
        screenshot_url=screenshot_url,
        status="pending",
    )

    db.add(req)
    db.commit()
    db.refresh(req)
    return req


def list_my_missing_cashback_requests(db: Session, user: User) -> list[Tuple[MissingCashbackRequest, str]]:
    rows = (
        db.query(MissingCashbackRequest, Store.name)
        .join(Store, Store.id == MissingCashbackRequest.store_id)
        .filter(MissingCashbackRequest.user_id == user.id)
        .order_by(MissingCashbackRequest.created_at.desc())
        .all()
    )
    return rows
