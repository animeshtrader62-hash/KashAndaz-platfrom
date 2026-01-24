from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class MissingCashbackCreateResponse(BaseModel):
    id: str
    status: str
    created_at: datetime


class MissingCashbackOut(BaseModel):
    id: str
    user_id: str
    store_id: str
    store_name: str

    order_id: str = Field(min_length=1, max_length=120)
    order_amount: Decimal
    order_date: date
    expected_cashback: Decimal | None = None

    screenshot_url: str | None = None
    notes: str | None = None

    status: str
    admin_comment: str | None = None
    created_at: datetime
