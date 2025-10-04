from uuid import uuid4
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from ..auth import get_user_id
from ..db import plans_col
from ..models import Plan, PlanListResponse, PlanCreateRequest, GenerateWorkoutRequest, WorkoutSession, ExerciseSet
from ..services import get_exercises_by_difficulty, generate_split_pattern, select_exercises_for_session

router = APIRouter(prefix="/v1", tags=["plans"])

plans_store = {}

@router.post("/generate", response_model=Plan, status_code=201)
async def generate_workout(req: GenerateWorkoutRequest, user_id: str = Depends(get_user_id)):
    num_days = len(req.selected_days)
    available_exercises = get_exercises_by_difficulty(req.difficulty)
    split_pattern = generate_split_pattern(num_days)
    sessions: List[WorkoutSession] = []
    for week in range(req.weeks):
        for day_idx, muscle_groups in enumerate(split_pattern[:num_days]):
            exercise_sets = select_exercises_for_session(
                muscle_groups=muscle_groups,
                available_exercises=available_exercises,
                duration=req.duration_minutes,
                difficulty=req.difficulty,
            )
            sessions.append(WorkoutSession(day_index=day_idx + 1, items=exercise_sets))
    plan = Plan(
        id=str(uuid4()),
        days_per_week=num_days,
        weeks=req.weeks,
        sessions=sessions,
        selected_days=req.selected_days,
    )
    plans_store[plan.id] = plan
    try:
        doc = plan.model_dump()
        doc_with_metadata = {
            **doc,
            "_id": doc["id"],
            "created_at": __import__('datetime').datetime.utcnow().isoformat(),
            "selected_days": req.selected_days,
            "duration_minutes": req.duration_minutes,
            "difficulty": req.difficulty,
            "user_id": user_id,
        }
        plans_col.insert_one(doc_with_metadata)
    except Exception:
        pass
    return plan

@router.post("/plans", response_model=Plan, status_code=201)
async def create_plan(req: PlanCreateRequest, user_id: str = Depends(get_user_id)):
    total_sessions = req.days_per_week * req.weeks
    sessions: List[WorkoutSession] = []
    for s in range(total_sessions):
        day_index = (s % req.days_per_week) + 1
        picks: List[ExerciseSet] = []
        from ..data import exercises
        for k in range(3):
            ex = exercises[(s + k) % len(exercises)]
            picks.append(ExerciseSet(exercise_id=ex["id"]))
        sessions.append(WorkoutSession(day_index=day_index, items=picks))
    plan = Plan(id=str(uuid4()), days_per_week=req.days_per_week, weeks=req.weeks, sessions=sessions)
    plans_store[plan.id] = plan
    try:
        doc = plan.model_dump()
        doc_with_id = {**doc, "_id": doc["id"], "created_at": __import__('datetime').datetime.utcnow().isoformat(), "user_id": user_id}
        plans_col.insert_one(doc_with_id)
    except Exception:
        pass
    return plan

@router.get("/plans/{plan_id}", response_model=Plan)
async def get_plan(plan_id: str, user_id: str = Depends(get_user_id)):
    try:
        doc = plans_col.find_one({"_id": plan_id, "user_id": user_id})
    except Exception:
        doc = None
    if not doc:
        raise HTTPException(status_code=404, detail="Plan not found")
    if "id" not in doc and "_id" in doc:
        doc["id"] = str(doc["_id"])
    doc.pop("_id", None)
    return Plan.model_validate(doc)

@router.get("/plans", response_model=PlanListResponse)
async def list_plans(user_id: str = Depends(get_user_id)):
    items: List[Plan] = []
    try:
        cursor = plans_col.find({"user_id": user_id}, projection=None)
        try:
            cursor = cursor.sort("created_at", -1)
        except Exception:
            pass
        for doc in cursor:
            if "id" not in doc and "_id" in doc:
                doc["id"] = str(doc["_id"])
            doc.pop("_id", None)
            try:
                items.append(Plan.model_validate(doc))
            except Exception:
                continue
    except Exception:
        items = []
    return {"items": items, "count": len(items)}
