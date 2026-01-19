from datetime import datetime
from pydantic import BaseModel, ConfigDict


class TransactionOut(BaseModel):
    id: str
    store_name: str
    store_logo: str | None = None
    order_id: str
    purchase_amount: float
    cashback_amount: float
    status: str
    created_at: datetime
    confirmed_at: datetime | None = None
    paid_at: datetime | None = None


class TransactionDetail(BaseModel):
    id: str
    store_name: str
    store_logo: str | None = None
    order_id: str
    click_id: str | None = None
    purchase_amount: float
    cashback_amount: float
    cashback_rate: str | None = None
    status: str
    status_description: str
    created_at: datetime
    confirmed_at: datetime | None = None
    paid_at: datetime | None = None
    cancelled_reason: str | None = None


class TransactionsResponse(BaseModel):
    transactions: list[TransactionOut]
    pagination: dict

    model_config = ConfigDict(from_attributes=True)
