from datetime import datetime
from pydantic import BaseModel, ConfigDict


class WalletBalance(BaseModel):
    total_earned: float
    pending: float
    available: float
    withdrawn: float


class WithdrawalItem(BaseModel):
    id: str
    amount: float
    status: str
    upi_id: str | None = None
    requested_at: datetime
    completed_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class WalletResponse(BaseModel):
    balance: WalletBalance
    recent_withdrawals: list[WithdrawalItem]
