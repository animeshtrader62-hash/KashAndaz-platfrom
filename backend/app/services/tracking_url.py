from __future__ import annotations

from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit


def build_offer18_redirect_url(base_url: str, tracking_id: str) -> str:
    """Return an HTTPS URL with Offer18-compatible aff_click_id set.

    Rules:
    - URL must be absolute http/https; we upgrade http -> https.
    - Always sets/overwrites aff_click_id to the backend-generated tracking_id.
    - Preserves existing query parameters.
    """

    u = (base_url or "").strip()
    if not u:
        raise ValueError("redirect base_url is required")

    parts = urlsplit(u)
    if parts.scheme not in {"http", "https"} or not parts.netloc:
        raise ValueError("redirect base_url must be an absolute URL")

    scheme = "https"

    query = dict(parse_qsl(parts.query, keep_blank_values=True))
    query["aff_click_id"] = tracking_id

    new_query = urlencode(query, doseq=True)

    final = urlunsplit((scheme, parts.netloc, parts.path, new_query, parts.fragment))

    final_parts = urlsplit(final)
    if final_parts.scheme != "https" or not final_parts.netloc:
        raise ValueError("redirect URL must be a valid HTTPS URL")

    return final
