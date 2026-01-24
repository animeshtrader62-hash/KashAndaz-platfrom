from typing import Generator

from .session import SessionLocal


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_db_optional() -> Generator:
    """Best-effort DB dependency.

    Used by endpoints that must never 500 even if the DB is misconfigured or down.
    Yields None when a session cannot be created.
    """
    try:
        db = SessionLocal()
    except Exception:
        yield None
        return

    try:
        yield db
    finally:
        try:
            db.close()
        except Exception:
            pass
