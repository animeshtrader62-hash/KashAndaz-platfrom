from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models import Store


def get_stores(
    db: Session,
    category: str | None,
    search: str | None,
    *,
    limit: int = 100,
    offset: int = 0,
):
    query = db.query(Store).filter(Store.is_active == True)  # noqa: E712
    if category:
        query = query.filter(Store.category == category)
    if search:
        like_term = f"%{search}%"
        query = query.filter(or_(Store.name.ilike(like_term), Store.category.ilike(like_term)))
    limit = max(1, min(int(limit), 200))
    offset = max(0, int(offset))
    return query.order_by(Store.name.asc()).offset(offset).limit(limit).all()
