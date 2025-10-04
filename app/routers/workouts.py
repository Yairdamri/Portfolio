from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from datetime import datetime

from ..auth import get_user_id
from ..db import completions_col, plans_col
from ..models import CompletionRequest, WorkoutCompletion, WeeklySummary, WorkoutHistoryResponse, WorkoutHistoryItem
from ..services import get_week_start_end, calculate_streak
from ..data import exercises

router = APIRouter(prefix="/v1/workouts", tags=["workouts"])

@router.post("/complete", response_model=WorkoutCompletion, status_code=201)
async def complete_workout(req: CompletionRequest, user_id: str = Depends(get_user_id)):
    completion = WorkoutCompletion(
        id=str(__import__('uuid').uuid4()),
        plan_id=req.plan_id,
        session_index=req.session_index,
        completed_at=datetime.utcnow().isoformat(),
        duration_minutes=req.duration_minutes,
        logged_exercises=req.logged_exercises,
    )
    try:
        doc = completion.model_dump()
        doc["_id"] = doc["id"]
        doc["user_id"] = user_id
        completions_col.insert_one(doc)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save completion: {e}")
    return completion

@router.get("/summary", response_model=WeeklySummary)
async def get_weekly_summary(user_id: str = Depends(get_user_id)):
    week_start, week_end = get_week_start_end()
    this_week_completions = []
    all_completions = []
    try:
        for doc in completions_col.find({"user_id": user_id}):
            doc.pop("_id", None)
            if "id" not in doc:
                continue
            all_completions.append(doc)
            completion_time = datetime.fromisoformat(doc["completed_at"])
            if week_start <= completion_time < week_end:
                this_week_completions.append(WorkoutCompletion.model_validate(doc))
    except Exception:
        pass
    total_minutes = sum(c.duration_minutes for c in this_week_completions)
    streak = calculate_streak(all_completions)
    return WeeklySummary(
        workouts_completed=len(this_week_completions),
        total_minutes=total_minutes,
        current_streak=streak,
        this_week_completions=this_week_completions,
    )

@router.get("/history", response_model=WorkoutHistoryResponse)
async def get_workout_history(
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    muscle: Optional[str] = None,
    difficulty: Optional[str] = None,
    limit: int = 100,
    user_id: str = Depends(get_user_id),
):
    query = {"user_id": user_id}
    time_filter = {}
    try:
        if date_from:
            dt_from = datetime.fromisoformat(date_from) if 'T' in date_from else datetime.fromisoformat(date_from + 'T00:00:00')
            time_filter["$gte"] = dt_from.isoformat()
        if date_to:
            dt_to = datetime.fromisoformat(date_to) if 'T' in date_to else datetime.fromisoformat(date_to + 'T23:59:59')
            time_filter["$lte"] = dt_to.isoformat()
    except Exception:
        time_filter = {}
    if time_filter:
        query["completed_at"] = {**time_filter}

    docs = []
    try:
        cursor = completions_col.find(query)
        cursor = cursor.sort("completed_at", -1)
        for doc in cursor:
            doc.pop("_id", None)
            if "id" in doc:
                docs.append(doc)
    except Exception:
        docs = []

    items: List[WorkoutHistoryItem] = []
    ex_to_muscle = {ex["id"]: ex.get("primary_muscle") for ex in exercises}

    for d in docs:
        total_sets = 0
        total_reps = 0
        total_volume = 0.0
        muscles_set = set()
        for le in (d.get("logged_exercises") or []):
            ex_id = le.get("exercise_id")
            if ex_id in ex_to_muscle and ex_to_muscle[ex_id]:
                muscles_set.add(ex_to_muscle[ex_id])
            for s in (le.get("sets") or []):
                reps = int(s.get("reps", 0))
                weight = float(s.get("weight", 0) or 0)
                total_sets += 1
                total_reps += reps
                total_volume += reps * weight
        diff_val = None
        try:
            pdoc = plans_col.find_one({"_id": d.get("plan_id")})
            if pdoc:
                diff_val = pdoc.get("difficulty")
        except Exception:
            pass
        if muscle and muscle not in muscles_set:
            continue
        if difficulty and diff_val and diff_val != difficulty:
            continue
        item = WorkoutHistoryItem(
            completion=WorkoutCompletion.model_validate(d),
            muscles=sorted(list(muscles_set)),
            total_sets=total_sets,
            total_reps=total_reps,
            total_volume=round(total_volume, 2),
            difficulty=diff_val,
        )
        items.append(item)
        if len(items) >= max(1, min(500, limit)):
            break
    return WorkoutHistoryResponse(items=items, count=len(items))
