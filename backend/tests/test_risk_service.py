import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.db.base import Base
from app import models
from app.services.risk_service import check_upi_reuse, flag_clicks_without_sales


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    try:
        yield session
    finally:
        session.close()


def test_upi_reuse_flags_user(db_session):
    user1 = models.User(name="U1", email="u1@risk.com", phone="111", hashed_password="x")
    user2 = models.User(name="U2", email="u2@risk.com", phone="222", hashed_password="x")
    db_session.add_all([user1, user2])
    db_session.commit()

    withdrawal = models.Withdrawal(
        user_id=user1.id,
        amount=100,
        status="pending",
        method="upi",
        upi_id="same@upi",
    )
    db_session.add(withdrawal)
    db_session.commit()

    check_upi_reuse(db_session, user2, "same@upi")

    flag = db_session.query(models.RiskFlag).filter(models.RiskFlag.user_id == user2.id).first()
    assert flag is not None
    assert flag.flag_type == "upi_reuse"


def test_clicks_no_sales_flag(db_session):
    user = models.User(name="U3", email="u3@risk.com", phone="333", hashed_password="x")
    store = models.Store(name="Store", cashback_rate="5%", cashback_type="percentage")
    db_session.add_all([user, store])
    db_session.commit()

    for _ in range(10):
        db_session.add(models.Click(user_id=user.id, store_id=store.id))
    db_session.commit()

    flagged = flag_clicks_without_sales(db_session, click_threshold=10)
    assert flagged == 1
    flag = db_session.query(models.RiskFlag).filter(models.RiskFlag.user_id == user.id).first()
    assert flag is not None
    assert flag.flag_type == "clicks_no_sales"
