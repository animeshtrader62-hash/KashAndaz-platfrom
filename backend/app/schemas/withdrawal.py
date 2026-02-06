from datetime import datetime
from pydantic import BaseModel, Field


class BankDetails(BaseModel):
    account_number: str = Field(min_length=6, max_length=50)
    ifsc: str = Field(min_length=4, max_length=20)
    account_holder_name: str = Field(min_length=2, max_length=120)


class WithdrawalRequest(BaseModel):
    amount: float = Field(gt=0)
    method: str = Field(pattern="^(upi|bank)$")
    upi_id: str | None = None
    bank_details: BankDetails | None = None


class WithdrawalResponse(BaseModel):
    withdrawal_id: str
    amount: float
    status: str
    message: str
    requested_at: datetime
