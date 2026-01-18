from datetime import datetime
from pydantic import BaseModel


class ActivateRequest(BaseModel):
    store_id: str
    product_url: str | None = None


class ActivateResponse(BaseModel):
    deep_link: str
    click_id: str
    store_name: str
    message: str
    expires_at: datetime | None = None
