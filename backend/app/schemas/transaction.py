from datetime import datetime
from pydantic import BaseModel, ConfigDict, model_validator


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
    # Frontend-friendly alias. Keep internal naming as transactions.
    orders: list[TransactionOut] | None = None
    pagination: dict

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="after")
    def _sync_orders(self):
        if self.orders is None:
            self.orders = self.transactions
        return self
