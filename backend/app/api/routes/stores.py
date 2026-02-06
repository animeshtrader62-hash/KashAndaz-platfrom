from fastapi import APIRouter, Depends
from starlette.responses import Response
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.schemas.store import StoreOut
from app.services.store_service import get_stores

router = APIRouter(prefix="/stores", tags=["stores"])


STORE_DESCRIPTIONS: dict[str, str] = {
    "Flipkart": "Flipkart is one of India's leading online marketplaces, offering products across electronics, fashion, home, and more.",
    "Amazon": "Amazon is a global online marketplace offering a wide range of products including electronics, fashion, home, and essentials.",
    "Myntra": "Myntra is a leading fashion destination in India for clothing, footwear, accessories, and lifestyle products.",
    "Ajio": "AJIO is a fashion and lifestyle platform offering curated apparel, footwear, and accessories across top brands.",
}


@router.get("", response_model=dict)
def list_stores(
    response: Response,
    category: str | None = None,
    search: str | None = None,
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    stores = get_stores(db, category, search, limit=limit, offset=offset)

    # Public store catalog changes infrequently; allow short caching.
    response.headers["Cache-Control"] = "public, max-age=120"

    payload: list[dict] = []
    for store in stores:
        item = StoreOut.model_validate(store).model_dump()
        # Mirror field for frontend clients expecting store_logo_url
        if item.get("store_logo_url") is None:
            item["store_logo_url"] = item.get("logo_url")
        # Provide trust description if available (optional)
        if item.get("store_description") is None:
            item["store_description"] = STORE_DESCRIPTIONS.get(item.get("name") or "")
        payload.append(item)

    return {"stores": payload}
