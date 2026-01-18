from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models import Store


def get_stores(db: Session, category: str | None, search: str | None):
    query = db.query(Store)
    if category:
        query = query.filter(Store.category == category)
    if search:
        like_term = f"%{search}%"
        query = query.filter(or_(Store.name.ilike(like_term), Store.category.ilike(like_term)))
    return query.order_by(Store.name.asc()).all()
