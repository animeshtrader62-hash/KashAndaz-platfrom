from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session
from app.core.auth import get_optional_user
from app.db.deps import get_db
from app.schemas.home import HomeResponse, WalletSummary
from app.schemas.store import StoreOut
from app.services.wallet_service import get_wallet_summary
from app.models import Store

router = APIRouter(prefix="/home", tags=["home"])


STORE_DESCRIPTIONS: dict[str, str] = {
    "Flipkart": "Flipkart is one of India's leading online marketplaces, offering products across electronics, fashion, home, and more.",
    "Amazon": "Amazon is a global online marketplace offering a wide range of products including electronics, fashion, home, and essentials.",
    "Myntra": "Myntra is a leading fashion destination in India for clothing, footwear, accessories, and lifestyle products.",
    "Ajio": "AJIO is a fashion and lifestyle platform offering curated apparel, footwear, and accessories across top brands.",
}


@router.get("", response_model=HomeResponse)
def home(
    response: Response,
    db: Session = Depends(get_db),
    user=Depends(get_optional_user),
):
    if user:
        response.headers["Cache-Control"] = "private, no-store"
    else:
        response.headers["Cache-Control"] = "public, max-age=60"

    if user:
        summary = get_wallet_summary(db, user.id)
    else:
        summary = {"total_earned": 0.0, "pending": 0.0, "available": 0.0}
    stores = (
        db.query(Store)
        .filter(Store.is_active == True)  # noqa: E712
        .order_by(Store.name.asc())
        .limit(10)
        .all()
    )

    top_stores_payload: list[dict] = []
    for s in stores:
        item = StoreOut.model_validate(s).model_dump()
        if item.get("store_logo_url") is None:
            item["store_logo_url"] = item.get("logo_url")
        if item.get("store_description") is None:
            item["store_description"] = STORE_DESCRIPTIONS.get(item.get("name") or "")
        top_stores_payload.append(item)

    return HomeResponse(
        wallet=WalletSummary(
            total_earned=summary["total_earned"],
            pending=summary["pending"],
            available=summary["available"],
            currency="INR",
        ),
        top_stores=top_stores_payload,
    )
