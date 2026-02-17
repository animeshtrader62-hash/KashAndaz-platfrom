from decimal import Decimal
from pydantic import BaseModel, Field, model_validator


_CASHBACK_TYPES = {"percentage", "flat"}
_STORE_CATEGORIES = {
    "fashion",
    "electronics",
    "beauty",
    "travel",
    "food",
    "home",
    "finance",
    "groceries",
    "other",
}


class AdminStoreCreate(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    store_slug: str | None = Field(default=None, max_length=200)
    logo_url: str | None = Field(default=None, max_length=500)
    affiliate_base_url: str | None = Field(default=None, max_length=500)
    cashback_rate: Decimal = Field(ge=0)
    cashback_type: str = Field(min_length=1, max_length=20)
    popularity_score: int = Field(default=0, ge=0, le=10_000_000)
    featured_store: bool = False
    category: str | None = Field(default=None, max_length=100)
    is_active: bool = True

    @model_validator(mode="after")
    def _validate(self):
        ct = (self.cashback_type or "").strip().lower()
        if ct not in _CASHBACK_TYPES:
            raise ValueError("Invalid cashback_type")
        self.cashback_type = ct

        if self.cashback_type == "percentage" and self.cashback_rate > Decimal("100"):
            raise ValueError("cashback_rate must be <= 100 for percentage")

        if self.category is not None:
            cat = self.category.strip().lower()
            if cat == "":
                self.category = None
            else:
                if cat not in _STORE_CATEGORIES:
                    raise ValueError("Invalid category")
                self.category = cat

        if self.store_slug is not None:
            self.store_slug = self.store_slug.strip().lower() or None
            if self.store_slug is not None and "%" in self.store_slug:
                raise ValueError("Invalid store_slug")

        return self


class AdminStoreUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=160)
    store_slug: str | None = Field(default=None, max_length=200)
    logo_url: str | None = Field(default=None, max_length=500)
    affiliate_base_url: str | None = Field(default=None, max_length=500)
    cashback_rate: Decimal | None = Field(default=None, ge=0)
    cashback_type: str | None = Field(default=None, min_length=1, max_length=20)
    popularity_score: int | None = Field(default=None, ge=0, le=10_000_000)
    featured_store: bool | None = None
    category: str | None = Field(default=None, max_length=100)
    is_active: bool | None = None

    @model_validator(mode="after")
    def _validate(self):
        if self.cashback_type is not None:
            ct = self.cashback_type.strip().lower()
            if ct not in _CASHBACK_TYPES:
                raise ValueError("Invalid cashback_type")
            self.cashback_type = ct

        if self.cashback_rate is not None and (self.cashback_type or "") == "percentage":
            if self.cashback_rate > Decimal("100"):
                raise ValueError("cashback_rate must be <= 100 for percentage")

        if self.category is not None:
            cat = self.category.strip().lower()
            if cat == "":
                self.category = None
            else:
                if cat not in _STORE_CATEGORIES:
                    raise ValueError("Invalid category")
                self.category = cat

        if self.store_slug is not None:
            self.store_slug = self.store_slug.strip().lower() or None
            if self.store_slug is not None and "%" in self.store_slug:
                raise ValueError("Invalid store_slug")

        return self


class AdminStoreOut(BaseModel):
    id: str
    name: str
    store_slug: str
    logo_url: str
    affiliate_base_url: str | None = None
    cashback_rate: Decimal
    cashback_type: str
    popularity_score: int = 0
    featured_store: bool = False
    category: str | None = None
    is_active: bool
