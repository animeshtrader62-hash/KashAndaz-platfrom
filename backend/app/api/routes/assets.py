from __future__ import annotations

import ipaddress
from urllib.parse import urlparse

import httpx
from fastapi import APIRouter, HTTPException, Query, Response

router = APIRouter(prefix="/assets", tags=["assets"])

# Very small allowlist to prevent SSRF.
_ALLOWED_HOSTS: set[str] = {
    "www.google.com",
}


def _is_public_ip(hostname: str) -> bool:
    """Best-effort SSRF guard for direct IP hostnames."""
    try:
        ip = ipaddress.ip_address(hostname)
    except ValueError:
        return True  # hostname, not a direct IP

    return not (
        ip.is_private
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_multicast
        or ip.is_reserved
        or ip.is_unspecified
    )


@router.get("/image")
async def proxy_image(
    response: Response,
    url: str = Query(..., description="Absolute https URL for an image"),
):
    parsed = urlparse(url)

    if parsed.scheme != "https":
        raise HTTPException(status_code=400, detail="Only https URLs are allowed")

    if not parsed.hostname:
        raise HTTPException(status_code=400, detail="Invalid URL")

    host = parsed.hostname.lower()
    if host not in _ALLOWED_HOSTS:
        raise HTTPException(status_code=400, detail=f"Host not allowed: {host}")

    if not _is_public_ip(host):
        raise HTTPException(status_code=400, detail="Host not allowed")

    timeout = httpx.Timeout(8.0, connect=5.0)
    headers = {
        "User-Agent": "KashAndaz/1.0 (logo-proxy)",
        "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
    }

    async with httpx.AsyncClient(timeout=timeout, follow_redirects=True, headers=headers) as client:
        upstream = await client.get(url)

    if upstream.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Upstream status {upstream.status_code}")

    content_type = (upstream.headers.get("content-type") or "").split(";")[0].strip().lower()
    if not content_type.startswith("image/"):
        raise HTTPException(status_code=502, detail="Upstream is not an image")

    # Allow caching since these are immutable-ish favicons.
    response.headers["Cache-Control"] = "public, max-age=86400"

    return Response(content=upstream.content, media_type=content_type)
