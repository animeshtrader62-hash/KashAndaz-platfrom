from __future__ import annotations

import sys
from pathlib import Path

import pytest


# Ensure the backend project root (the folder containing the `app/` package)
# is importable when running `pytest` from any working directory.
BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


@pytest.fixture
def anyio_backend() -> str:
    # Keep tests consistent and avoid requiring the optional `trio` dependency.
    return "asyncio"
