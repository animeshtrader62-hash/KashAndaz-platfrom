from sqlalchemy.orm import Session
from app.models import Click, Store, Transaction


def create_transaction_from_webhook(
    db: Session,
    payload: dict,
):
    click = db.query(Click).filter(Click.id == payload["click_id"]).first()
    if not click:
        return None, "click_not_found"

    store = db.query(Store).filter(Store.id == payload["store_id"]).first()
    if not store:
        return None, "store_not_found"

    if click.store_id != store.id:
        return None, "store_mismatch"

    existing = (
        db.query(Transaction)
        .filter(
            Transaction.external_order_id == payload["external_order_id"],
            Transaction.store_id == store.id,
        )
        .first()
    )
    if existing:
        return existing, "duplicate"

    tx = Transaction(
        user_id=click.user_id,
        store_id=store.id,
        click_id=click.id,
        external_order_id=payload["external_order_id"],
        purchase_amount=payload.get("purchase_amount", 0),
        cashback_amount=payload.get("cashback_amount", 0),
        cashback_rate=payload.get("cashback_rate"),
        status="pending",
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx, "created"
