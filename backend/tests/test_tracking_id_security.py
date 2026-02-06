from __future__ import annotations

import re

from app.services.activate_service import _generate_tracking_id


def test_tracking_id_is_url_safe_and_random_enough():
    ids = {_generate_tracking_id() for _ in range(200)}
    assert len(ids) == 200

    for tid in ids:
        assert isinstance(tid, str)
        assert len(tid) >= 32
        assert re.fullmatch(r"[A-Za-z0-9_\-]+", tid) is not None
