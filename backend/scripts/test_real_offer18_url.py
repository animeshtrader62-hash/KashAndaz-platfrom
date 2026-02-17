"""Test build_offer18_redirect_url with the REAL Offer18 affiliate link format."""
from __future__ import annotations

import os
import sys
from pathlib import Path
from urllib.parse import parse_qs, parse_qsl, urlsplit

_backend_root = str(Path(__file__).resolve().parent.parent)
if _backend_root not in sys.path:
    sys.path.insert(0, _backend_root)
os.chdir(_backend_root)

from app.services.tracking_url import build_offer18_redirect_url

REAL_URL = "https://kashandaz11024353.o18a.com/c?o=21873265&m=27925&a=741842&aff_click_id="
TRACKING_ID = "KA_TestTrackingId1234567890abcdefgh"

PASS = "\033[92mPASS\033[0m"
FAIL = "\033[91mFAIL\033[0m"
checks: list[tuple[str, bool]] = []


def check(label: str, condition: bool) -> None:
    checks.append((label, condition))
    print(f"  [{PASS if condition else FAIL}] {label}")


def main() -> None:
    print("=" * 70)
    print("Real Offer18 URL Verification")
    print(f"Input:  {REAL_URL}")
    print("=" * 70)

    result = build_offer18_redirect_url(REAL_URL, TRACKING_ID)
    print(f"\nOutput: {result}\n")

    parts = urlsplit(result)
    qs = parse_qs(parts.query)
    all_params = parse_qsl(parts.query, keep_blank_values=True)

    print("--- URL structure ---")
    check("Scheme is https", parts.scheme == "https")
    check("Host is kashandaz11024353.o18a.com", parts.netloc == "kashandaz11024353.o18a.com")
    check("Path is /c", parts.path == "/c")

    print("\n--- Offer18 params preserved ---")
    check("o=21873265 preserved", qs.get("o") == ["21873265"])
    check("m=27925 preserved", qs.get("m") == ["27925"])
    check("a=741842 preserved", qs.get("a") == ["741842"])

    print("\n--- aff_click_id ---")
    aff_values = qs.get("aff_click_id", [])
    check("aff_click_id present", len(aff_values) > 0)
    check("aff_click_id equals tracking_id", aff_values == [TRACKING_ID])
    aff_count = sum(1 for k, _ in all_params if k == "aff_click_id")
    check("aff_click_id appears exactly once (no duplicate)", aff_count == 1)
    check("aff_click_id is NOT empty", aff_values != [""] and aff_values != [])

    print("\n--- Param count ---")
    check("Total params = 4 (o, m, a, aff_click_id)", len(all_params) == 4)

    print("\n--- Edge cases ---")
    # Also test with a URL that does NOT have aff_click_id pre-set
    url_no_aff = "https://kashandaz11024353.o18a.com/c?o=21873265&m=27925&a=741842"
    result2 = build_offer18_redirect_url(url_no_aff, TRACKING_ID)
    parts2 = urlsplit(result2)
    qs2 = parse_qs(parts2.query)
    check("Works when aff_click_id is NOT in source URL", qs2.get("aff_click_id") == [TRACKING_ID])

    # Test with HTTP (should upgrade to HTTPS)
    url_http = "http://kashandaz11024353.o18a.com/c?o=21873265&m=27925&a=741842&aff_click_id="
    result3 = build_offer18_redirect_url(url_http, TRACKING_ID)
    parts3 = urlsplit(result3)
    check("HTTP upgraded to HTTPS", parts3.scheme == "https")

    # Test with pre-filled aff_click_id (should overwrite)
    url_prefilled = "https://kashandaz11024353.o18a.com/c?o=21873265&m=27925&a=741842&aff_click_id=OLD_VALUE"
    result4 = build_offer18_redirect_url(url_prefilled, TRACKING_ID)
    qs4 = parse_qs(urlsplit(result4).query)
    check("Pre-filled aff_click_id gets overwritten", qs4.get("aff_click_id") == [TRACKING_ID])

    # Summary
    total = len(checks)
    passed = sum(1 for _, ok in checks if ok)
    failed = total - passed
    print(f"\n{'=' * 70}")
    if failed == 0:
        print(f"ALL {total} CHECKS PASSED — Real Offer18 URL compatible")
    else:
        print(f"{passed}/{total} PASSED, {failed} FAILED")
        for label, ok in checks:
            if not ok:
                print(f"  FAIL: {label}")
    print("=" * 70)
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
