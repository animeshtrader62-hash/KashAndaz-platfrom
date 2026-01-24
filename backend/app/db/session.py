from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import settings


def _create_engine():
	url = settings.database_url

	# SQLite: keep a single connection and allow cross-thread usage.
	# This avoids one-connection-per-thread behavior that can grow memory over time
	# in a long-lived threadpool.
	if url.startswith("sqlite"):
		return create_engine(
			url,
			pool_pre_ping=True,
			connect_args={"check_same_thread": False},
			poolclass=StaticPool,
		)

	# Non-SQLite (e.g., Postgres): use a bounded pool with keepalive checks.
	return create_engine(
		url,
		pool_pre_ping=True,
		pool_size=5,
		max_overflow=10,
		pool_recycle=1800,
	)


engine = _create_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
