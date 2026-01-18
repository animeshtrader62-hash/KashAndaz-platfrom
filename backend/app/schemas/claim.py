from datetime import datetime
from pydantic import BaseModel, Field


class ClaimRequest(BaseModel):
    store_id: str
    order_id: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=500)
    screenshot_url: str | None = Field(default=None, max_length=500)


class ClaimResponse(BaseModel):
    claim_id: str
    status: str
    created_at: datetime
