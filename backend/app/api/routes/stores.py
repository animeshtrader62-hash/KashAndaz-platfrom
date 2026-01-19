from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.schemas.store import StoreOut
from app.services.store_service import get_stores

router = APIRouter(prefix="/stores", tags=["stores"])


@router.get("", response_model=dict)
def list_stores(
    category: str | None = None,
    search: str | None = None,
    db: Session = Depends(get_db),
):
    stores = get_stores(db, category, search)
    return {"stores": [StoreOut.model_validate(s) for s in stores]}
