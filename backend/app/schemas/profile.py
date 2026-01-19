from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict


class UserProfile(BaseModel):
    id: str
    name: str
    email: EmailStr
    phone: str | None = None
    joined_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class PaymentMethod(BaseModel):
    id: str
    type: str
    upi_id: str | None = None
    bank_account_last4: str | None = None
    is_default: bool


class ProfileResponse(BaseModel):
    user: UserProfile
    payment_methods: list[PaymentMethod]


class ProfileUpdateRequest(BaseModel):
    name: str | None = None
    phone: str | None = None
