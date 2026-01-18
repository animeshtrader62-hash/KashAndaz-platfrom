from pydantic import BaseModel, ConfigDict


class StoreOut(BaseModel):
    id: str
    name: str
    logo_url: str | None = None
    cashback_rate: str
    cashback_type: str
    category: str | None = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)
