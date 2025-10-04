from fastapi import APIRouter
from ..data import exercises

router = APIRouter(prefix="/v1", tags=["exercises"])

@router.get("/exercises")
async def list_exercises():
    return {"items": exercises, "count": len(exercises)}
