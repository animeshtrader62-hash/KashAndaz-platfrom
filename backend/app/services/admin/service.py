from sqlalchemy.orm import Session
from app.models import User, RiskFlag, AdminLog


def log_admin_action(db: Session, admin_id: str, action: str) -> None:
    db.add(AdminLog(admin_id=admin_id, action=action))


def block_user(db: Session, user: User, admin_id: str | None = None) -> User:
    user.is_blocked = True
    db.add(user)
    if admin_id:
        log_admin_action(db, admin_id, f"user_block user_id={user.id}")
    db.commit()
    db.refresh(user)
    return user


def unblock_user(db: Session, user: User, admin_id: str | None = None) -> User:
    user.is_blocked = False
    db.add(user)
    if admin_id:
        log_admin_action(db, admin_id, f"user_unblock user_id={user.id}")
    db.commit()
    db.refresh(user)
    return user


def get_risk_flags(db: Session, user_id: str):
    return db.query(RiskFlag).filter(RiskFlag.user_id == user_id).all()
