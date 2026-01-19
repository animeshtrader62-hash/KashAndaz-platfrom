from pydantic import BaseModel
from .store import StoreOut


class WalletSummary(BaseModel):
    total_earned: float
    pending: float
    available: float
    currency: str


class HomeResponse(BaseModel):
    wallet: WalletSummary
    top_stores: list[StoreOut]
