from pydantic import BaseModel, Field


class AdminStoreCreate(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    logo_url: str | None = Field(default=None, max_length=500)
    affiliate_base_url: str | None = Field(default=None, max_length=500)
    cashback_rate: str = Field(min_length=1, max_length=50)
    cashback_type: str = Field(min_length=1, max_length=20)
    category: str | None = Field(default=None, max_length=100)
    is_active: bool = True


class AdminStoreUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=160)
    logo_url: str | None = Field(default=None, max_length=500)
    affiliate_base_url: str | None = Field(default=None, max_length=500)
    cashback_rate: str | None = Field(default=None, min_length=1, max_length=50)
    cashback_type: str | None = Field(default=None, min_length=1, max_length=20)
    category: str | None = Field(default=None, max_length=100)
    is_active: bool | None = None


class AdminStoreOut(BaseModel):
    id: str
    name: str
    logo_url: str | None = None
    affiliate_base_url: str | None = None
    cashback_rate: str
    cashback_type: str
    category: str | None = None
    is_active: bool
