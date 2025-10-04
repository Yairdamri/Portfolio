from fastapi import FastAPI, HTTPException
from .config import APP_TITLE, APP_VERSION
from .db import client, db
from .routers import auth as auth_router
from .routers import plans as plans_router
from .routers import workouts as workouts_router
from .routers import exercises as exercises_router

app = FastAPI(title=APP_TITLE, version=APP_VERSION)

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/v1/db/ping")
async def db_ping():
    try:
        client.admin.command("ping")
        return {"status": "ok", "db": db.name}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"DB ping failed: {exc}")

# Routers
app.include_router(auth_router.router)
app.include_router(plans_router.router)
app.include_router(workouts_router.router)
app.include_router(exercises_router.router)
