from pydantic import BaseModel, Field


class TrackingWebhookPayload(BaseModel):
    external_order_id: str = Field(min_length=1, max_length=120)
    store_id: str
    click_id: str
    purchase_amount: float = Field(ge=0)
    cashback_amount: float = Field(ge=0)
    cashback_rate: str | None = None
    status: str | None = None


class TrackingWebhookResponse(BaseModel):
    status: str
    transaction_id: str | None = None
    duplicate: bool = False
