from app.db.session import SessionLocal
from app.models import Transaction
from app.services.confirmation_service import confirm_transaction
from app.services.notification_service import notification_service


class AffiliateClient:
    def get_status(self, external_order_id: str) -> str:
        # Placeholder: implement real affiliate API lookup
        return "confirmed"


affiliate_client = AffiliateClient()


def run_confirmation_job() -> int:
    db = SessionLocal()
    processed = 0
    try:
        import time

        BATCH_SIZE = 500
        MAX_SECONDS = 240
        started = time.monotonic()

        while True:
            if time.monotonic() - started > MAX_SECONDS:
                break

            batch = (
                db.query(Transaction)
                .filter(Transaction.status == "pending")
                .order_by(Transaction.created_at.asc())
                .limit(BATCH_SIZE)
                .all()
            )
            if not batch:
                break

            for tx in batch:
                status = affiliate_client.get_status(tx.external_order_id)
                if status == "confirmed":
                    try:
                        confirmed_tx = confirm_transaction(db, tx)
                        notification_service.notify_cashback_confirmed(db, confirmed_tx)
                        processed += 1
                    except Exception:
                        db.rollback()
                elif status == "declined":
                    tx.status = "declined"
                    db.add(tx)
                    db.commit()

        return processed
    finally:
        db.close()
