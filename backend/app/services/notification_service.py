import structlog
from sqlalchemy.orm import Session
from app.models import User, Transaction

logger = structlog.get_logger()


class NotificationService:
    def notify_cashback_confirmed(self, db: Session, tx: Transaction) -> None:
        user = db.query(User).filter(User.id == tx.user_id).first()
        if not user:
            return
        logger.info(
            "notify_cashback_confirmed",
            user_id=user.id,
            email=user.email,
            transaction_id=tx.id,
            cashback_amount=float(tx.cashback_amount),
        )


notification_service = NotificationService()
