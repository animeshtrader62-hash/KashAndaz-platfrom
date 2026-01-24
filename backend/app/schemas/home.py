from pydantic import BaseModel, Field
from .store import StoreOut


class WalletSummary(BaseModel):
    total_earned: float
    pending: float
    available: float
    currency: str


class HomeResponse(BaseModel):
    status: str = "ok"
    mode: str = "guest"
    banners: list[dict] = Field(default_factory=list)
    trending_stores: list[StoreOut] = Field(default_factory=list)
    categories: list[dict] = Field(default_factory=list)
    wallet: WalletSummary
    top_stores: list[StoreOut]
