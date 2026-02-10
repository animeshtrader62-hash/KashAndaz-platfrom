from pydantic import BaseModel, EmailStr, Field
from app.schemas.user import UserOut


class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class AdminTokenResponse(BaseModel):
    token: str
    user: UserOut


class AdminPasswordResetRequest(BaseModel):
    email: EmailStr


class AdminPasswordResetConfirm(BaseModel):
    token: str = Field(min_length=10, max_length=512)
    new_password: str = Field(min_length=12, max_length=128)


class AdminPasswordResetRequestedResponse(BaseModel):
    ok: bool = True


class AdminPasswordResetConfirmedResponse(BaseModel):
    ok: bool = True
