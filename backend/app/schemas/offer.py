from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict, model_validator


class OfferCreate(BaseModel):
    store_id: str
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    affiliate_redirect_url: str = Field(min_length=1, max_length=2000)
    cashback_text: str = Field(min_length=1, max_length=120)
    start_at: datetime
    end_at: datetime
    status: str = Field(default="inactive", pattern="^(active|inactive)$")

    @model_validator(mode="after")
    def _validate_window(self):
        if self.start_at >= self.end_at:
            raise ValueError("start_at must be before end_at")
        return self


class OfferUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    affiliate_redirect_url: str | None = Field(default=None, min_length=1, max_length=2000)
    cashback_text: str | None = Field(default=None, min_length=1, max_length=120)
    start_at: datetime | None = None
    end_at: datetime | None = None
    status: str | None = Field(default=None, pattern="^(active|inactive)$")

    @model_validator(mode="after")
    def _validate_window(self):
        if self.start_at is not None and self.end_at is not None:
            if self.start_at >= self.end_at:
                raise ValueError("start_at must be before end_at")
        return self


class OfferStatusUpdate(BaseModel):
    status: str = Field(pattern="^(active|inactive)$")


class OfferOut(BaseModel):
    id: str
    store_id: str
    title: str
    description: str | None = None
    affiliate_redirect_url: str
    cashback_text: str
    start_at: datetime
    end_at: datetime
    status: str
    created_by: str
    created_at: datetime
    updated_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class AdminOffersListResponse(BaseModel):
    offers: list[OfferOut]
    pagination: dict
