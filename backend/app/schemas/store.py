from pydantic import BaseModel, ConfigDict, model_validator


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
    store_slug: str | None = None
    logo_url: str | None = None
    # Backwards/forwards compatibility with frontend contract
    store_logo_url: str | None = None
    cashback_rate: str
    cashback_type: str
    popularity_score: int = 0
    # Optional trust/branding copy
    store_description: str | None = None
    category: str | None = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="after")
    def _sync_logo_url_fields(self):
        if self.store_slug is None:
            self.store_slug = _slugify(self.name)

        self.logo_url = _normalize_logo_url(self.logo_url)
        self.store_logo_url = _normalize_logo_url(self.store_logo_url)

        if self.store_logo_url is None:
            self.store_logo_url = self.logo_url
        return self
