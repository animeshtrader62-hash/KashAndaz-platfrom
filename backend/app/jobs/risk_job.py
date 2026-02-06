from app.db.session import SessionLocal
from app.services.risk_service import flag_clicks_without_sales


def run_risk_job() -> int:
    db = SessionLocal()
    try:
        return flag_clicks_without_sales(db)
    finally:
        db.close()
