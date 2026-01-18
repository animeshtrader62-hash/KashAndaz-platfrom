from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings


def get_engine():
    return create_engine(settings.database_url, pool_pre_ping=True)


def get_sessionmaker():
    engine = get_engine()
    return sessionmaker(autocommit=False, autoflush=False, bind=engine)
