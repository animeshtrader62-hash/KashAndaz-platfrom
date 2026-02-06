from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict, model_validator


class BannerCreate(BaseModel):
    offer_id: str
    image_url: str = Field(min_length=1, max_length=2000)
    priority: int = Field(default=100, ge=0)
    start_at: datetime
    end_at: datetime
    status: str = Field(default="inactive", pattern="^(active|inactive)$")

    @model_validator(mode="after")
    def _validate_window(self):
        if self.start_at >= self.end_at:
            raise ValueError("start_at must be before end_at")
        return self


class BannerUpdate(BaseModel):
    image_url: str | None = Field(default=None, min_length=1, max_length=2000)
    priority: int | None = Field(default=None, ge=0)
    start_at: datetime | None = None
    end_at: datetime | None = None
    status: str | None = Field(default=None, pattern="^(active|inactive)$")

    @model_validator(mode="after")
    def _validate_window(self):
        if self.start_at is not None and self.end_at is not None:
            if self.start_at >= self.end_at:
                raise ValueError("start_at must be before end_at")
        return self


class BannerStatusUpdate(BaseModel):
    status: str = Field(pattern="^(active|inactive)$")


class BannerOut(BaseModel):
    id: str
    offer_id: str
    image_url: str
    priority: int
    start_at: datetime
    end_at: datetime
    status: str
    created_by: str
    created_at: datetime
    updated_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class AdminBannersListResponse(BaseModel):
    banners: list[BannerOut]
    pagination: dict


class PublicBannerOut(BaseModel):
    id: str
    image_url: str
    priority: int
    offer_id: str
    offer_title: str
    store_id: str
    store_name: str
    cashback_text: str | None = None


class PublicBannersResponse(BaseModel):
    banners: list[PublicBannerOut]
