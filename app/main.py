from fastapi import FastAPI, HTTPException
from .config import APP_TITLE, APP_VERSION
from .db import client, db
from .routers import auth as auth_router
from .routers import plans as plans_router
from .routers import workouts as workouts_router
from .routers import exercises as exercises_router
from .routers.business_metrics import metrics
from .middleware import log_requests_middleware
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(message)s')

app = FastAPI(title=APP_TITLE, version=APP_VERSION)

# Add middleware
app.middleware("http")(log_requests_middleware)

# Lifecycle events
@app.on_event("startup")
async def startup_event():
    metrics.log_startup()

@app.on_event("shutdown")
async def shutdown_event():
    metrics.log_shutdown()

@app.get("/health")
async def health():
    metrics.log_health_check("ok")
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
