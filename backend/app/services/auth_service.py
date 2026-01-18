from sqlalchemy.orm import Session
from app.models import User
from app.core.security import hash_password, verify_password


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()


def create_user(db: Session, name: str, email: str, password: str, phone: str | None) -> User:
    user = User(
        name=name,
        email=email,
        phone=phone,
        hashed_password=hash_password(password),
        role="user",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user
