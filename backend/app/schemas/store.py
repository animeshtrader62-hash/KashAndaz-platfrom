from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field, model_validator


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


def _slugify(value: str) -> str:
    cleaned = (value or "").strip().lower()
    out: list[str] = []
    prev_dash = False
    for ch in cleaned:
        is_alnum = ("a" <= ch <= "z") or ("0" <= ch <= "9")
        if is_alnum:
            out.append(ch)
            prev_dash = False
        else:
            if not prev_dash:
                out.append("-")
                prev_dash = True
    slug = "".join(out).strip("-")
    return slug or "store"


def _normalize_logo_url(url: str | None) -> str | None:
    if not url:
        return None

    u = url.strip()
    if not u:
        return None

    # Disallow SVG placeholders.
    if u.lower().endswith(".svg"):
        return None

    # Enforce HTTPS only.
    if u.startswith("http://"):
        u = "https://" + u[len("http://") :]
    if not u.startswith("https://"):
        return None

    return u


class StoreOut(BaseModel):
    id: str
    name: str
    store_slug: str
    logo_url: str
    # Backwards/forwards compatibility with frontend contract
    store_logo_url: str | None = None
    cashback_rate: Decimal = Field(ge=0)
    cashback_type: str
    popularity_score: int = 0
    featured_store: bool = False
    # Optional trust/branding copy
    store_description: str | None = None
    category: str | None = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="after")
    def _sync_logo_url_fields(self):
        if not self.store_slug:
            self.store_slug = _slugify(self.name)

        self.logo_url = _normalize_logo_url(self.logo_url) or self.logo_url
        self.store_logo_url = _normalize_logo_url(self.store_logo_url)

        if self.store_logo_url is None:
            self.store_logo_url = self.logo_url

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
                    raise ValueError("Invalid store category")
                self.category = cat
        return self
