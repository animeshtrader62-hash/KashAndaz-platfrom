from pydantic import BaseModel, EmailStr, Field
from .user import UserOut


class SignupRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    phone: str | None = Field(default=None, max_length=20)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class TokenResponse(BaseModel):
    token: str
    user: UserOut
