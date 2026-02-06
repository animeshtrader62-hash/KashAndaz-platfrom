import hmac
import hashlib
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from app.core.config import settings
from app.db.deps import get_db
from app.schemas.webhook import TrackingWebhookPayload, TrackingWebhookResponse
from app.services.webhook_service import create_transaction_from_webhook

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


def _verify_signature(raw_body: bytes, signature: str | None) -> bool:
    if not signature:
        return False
    expected = hmac.new(
        settings.webhook_secret.encode("utf-8"),
        raw_body,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature)


@router.post("/tracking", response_model=TrackingWebhookResponse)
async def tracking_webhook(request: Request, db: Session = Depends(get_db)):
    raw_body = await request.body()
    signature = request.headers.get(settings.webhook_signature_header)
    if not _verify_signature(raw_body, signature):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid signature")

    payload = TrackingWebhookPayload.model_validate_json(raw_body)
    tx, result = create_transaction_from_webhook(db, payload.model_dump())

    if result in {"click_not_found", "store_not_found", "store_mismatch"}:
        raise HTTPException(status_code=400, detail=result)

    if result == "duplicate":
        return TrackingWebhookResponse(status="ok", transaction_id=tx.id, duplicate=True)

    return TrackingWebhookResponse(status="ok", transaction_id=tx.id, duplicate=False)
