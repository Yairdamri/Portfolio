from uuid import uuid4
from fastapi import Depends, Header, HTTPException
import hashlib, hmac, os
from datetime import datetime

from .db import sessions_col, users_col
from .models import RegisterRequest, AuthResponse, LoginRequest


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 200_000)
    return salt.hex() + ":" + dk.hex()


def verify_password(password: str, hashed: str) -> bool:
    try:
        salt_hex, dk_hex = hashed.split(":", 1)
        salt = bytes.fromhex(salt_hex)
        expected = bytes.fromhex(dk_hex)
        calc = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 200_000)
        return hmac.compare_digest(calc, expected)
    except Exception:
        return False


def get_user_id(authorization: str = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")
    token = authorization.split(" ", 1)[1].strip()
    try:
        sess = sessions_col.find_one({"_id": token})
        if not sess:
            raise HTTPException(status_code=401, detail="Invalid session")
        return sess["user_id"]
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Auth lookup failed")


# Handlers
def handle_register(req: RegisterRequest) -> AuthResponse:
    if users_col.find_one({"email": req.email}):
        raise HTTPException(status_code=409, detail="Email already registered")
    user_id = str(uuid4())
    try:
        users_col.insert_one({
            "_id": user_id,
            "email": req.email,
            "password": hash_password(req.password),
            "name": req.name,
            "created_at": datetime.utcnow().isoformat(),
        })
        token = str(uuid4())
        sessions_col.insert_one({"_id": token, "user_id": user_id, "created_at": datetime.utcnow().isoformat()})
        return AuthResponse(token=token, user_id=user_id, email=req.email, name=req.name)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {e}")


def handle_login(req: LoginRequest) -> AuthResponse:
    user = users_col.find_one({"email": req.email})
    if not user or not verify_password(req.password, user.get("password", "")):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = str(uuid4())
    sessions_col.insert_one({"_id": token, "user_id": user["_id"], "created_at": datetime.utcnow().isoformat()})
    return AuthResponse(token=token, user_id=user["_id"], email=user["email"], name=user.get("name", ""))
