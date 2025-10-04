from fastapi import APIRouter, Depends, HTTPException
from ..models import RegisterRequest, LoginRequest
from ..auth import handle_register, handle_login, get_user_id
from ..db import users_col

router = APIRouter(prefix="/v1/auth", tags=["auth"])

@router.post("/register")
async def register(req: RegisterRequest):
    return handle_register(req)

@router.post("/login")
async def login(req: LoginRequest):
    return handle_login(req)

@router.get("/me")
async def me(user_id: str = Depends(get_user_id)):
    user = users_col.find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.pop("password", None)
    user["id"] = user.pop("_id")
    return user
