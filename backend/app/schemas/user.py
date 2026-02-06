from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict


class UserOut(BaseModel):
    id: str
    name: str
    email: EmailStr
    phone: str | None = None
    created_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)
