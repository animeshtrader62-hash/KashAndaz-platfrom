from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.db.base import Base
from app import models
from app.jobs import risk_job


def test_risk_job_flags():
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    user = models.User(name="U", email="u@riskjob.com", phone="444", hashed_password="x")
    store = models.Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    session.add_all([user, store])
    session.commit()

    for _ in range(10):
        session.add(models.Click(user_id=user.id, store_id=store.id))
    session.commit()

    def fake_session_local():
        return session

    risk_job.SessionLocal = fake_session_local

    processed = risk_job.run_risk_job()
    assert processed == 1

    session.close()
