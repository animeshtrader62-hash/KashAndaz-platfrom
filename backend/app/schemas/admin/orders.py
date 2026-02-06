from datetime import datetime
from pydantic import BaseModel, ConfigDict, model_validator


class AdminOrderOut(BaseModel):
    id: str
    user_id: str
    store_id: str
    store_name: str
    store_logo: str | None = None
    order_id: str
    purchase_amount: float
    cashback_amount: float
    status: str
    created_at: datetime


class AdminOrdersResponse(BaseModel):
    transactions: list[AdminOrderOut]
    # Frontend-friendly alias
    orders: list[AdminOrderOut] | None = None
    pagination: dict

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="after")
    def _sync_orders(self):
        if self.orders is None:
            self.orders = self.transactions
        return self
