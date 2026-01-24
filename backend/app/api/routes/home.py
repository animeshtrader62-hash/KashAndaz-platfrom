from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session
import structlog
from app.core.auth import get_optional_user
from app.db.deps import get_db_optional
from app.schemas.home import HomeResponse, WalletSummary
from app.schemas.store import StoreOut
from app.services.wallet_service import get_wallet_summary
from app.models import Store

router = APIRouter(prefix="/home", tags=["home"])

logger = structlog.get_logger(__name__)


STORE_DESCRIPTIONS: dict[str, str] = {
    "Flipkart": "Flipkart is one of India's leading online marketplaces, offering products across electronics, fashion, home, and more.",
    "Amazon": "Amazon is a global online marketplace offering a wide range of products including electronics, fashion, home, and essentials.",
    "Myntra": "Myntra is a leading fashion destination in India for clothing, footwear, accessories, and lifestyle products.",
    "Ajio": "AJIO is a fashion and lifestyle platform offering curated apparel, footwear, and accessories across top brands.",
}


@router.get("", response_model=HomeResponse)
def home(
    response: Response,
    db: Session | None = Depends(get_db_optional),
    user=Depends(get_optional_user),
):
    try:
        if user:
            response.headers["Cache-Control"] = "private, no-store"
        else:
            response.headers["Cache-Control"] = "public, max-age=60"

        mode = "auth" if user else "guest"

        summary = {"total_earned": 0.0, "pending": 0.0, "available": 0.0}
        if user and db is not None:
            try:
                summary = get_wallet_summary(db, user.id)
            except Exception as e:
                logger.warning("home_wallet_failed", error=str(e))

        stores: list[Store] = []
        if db is not None:
            try:
                stores = (
                    db.query(Store)
                    .filter(Store.is_active == True)  # noqa: E712
                    .order_by(Store.name.asc())
                    .limit(10)
                    .all()
                )
            except Exception as e:
                logger.warning("home_stores_failed", error=str(e))

        top_stores_payload: list[dict] = []
        for s in stores:
            item = StoreOut.model_validate(s).model_dump()
            if item.get("store_logo_url") is None:
                item["store_logo_url"] = item.get("logo_url")
            if item.get("store_description") is None:
                item["store_description"] = STORE_DESCRIPTIONS.get(item.get("name") or "")
            top_stores_payload.append(item)

        return HomeResponse(
            status="ok",
            mode=mode,
            banners=[],
            trending_stores=[],
            categories=[],
            wallet=WalletSummary(
                total_earned=float(summary.get("total_earned") or 0.0),
                pending=float(summary.get("pending") or 0.0),
                available=float(summary.get("available") or 0.0),
                currency="INR",
            ),
            top_stores=top_stores_payload,
        )
    except Exception as e:
        logger.error("home_unhandled_error", error=str(e), exc_info=True)
        response.headers["Cache-Control"] = "public, max-age=30"
        return HomeResponse(
            status="ok",
            mode="guest",
            banners=[],
            trending_stores=[],
            categories=[],
            wallet=WalletSummary(total_earned=0.0, pending=0.0, available=0.0, currency="INR"),
            top_stores=[],
        )
