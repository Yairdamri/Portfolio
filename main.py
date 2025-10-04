from __future__ import annotations

from typing import Dict, List, Optional
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel, Field

import os
from datetime import datetime
from pymongo import MongoClient

# Optionally load environment variables from a local .env file (for local dev)
try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass

# --- App setup ---
app = FastAPI(title="Workout Minimal API", version="0.0.1")

# Connect to MongoDB via environment variables
MONGO_URI = os.getenv("MONGO_URI", "mongodb://db:27017/")
MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "mydatabase")
client = MongoClient(MONGO_URI)
db = client[MONGO_DB_NAME]
plans_col = db["plans"]
completions_col = db["workout_completions"]
users_col = db["users"]
sessions_col = db["sessions"]
# --- Expanded exercise database ---
exercises = [
    # Chest
    {"id": "push_up", "name": "Push-Up", "primary_muscle": "chest", "difficulty": "beginner", "time_min": 2},
    {"id": "db_bench_press", "name": "Dumbbell Bench Press", "primary_muscle": "chest", "difficulty": "intermediate", "time_min": 3},
    {"id": "incline_db_press", "name": "Incline DB Press", "primary_muscle": "chest", "difficulty": "intermediate", "time_min": 3},
    {"id": "db_fly", "name": "Dumbbell Fly", "primary_muscle": "chest", "difficulty": "intermediate", "time_min": 3},
    # Back
    {"id": "db_row", "name": "Dumbbell Row", "primary_muscle": "back", "difficulty": "beginner", "time_min": 3},
    {"id": "pull_up", "name": "Pull-Up", "primary_muscle": "back", "difficulty": "advanced", "time_min": 2},
    {"id": "lat_pulldown", "name": "Lat Pulldown", "primary_muscle": "back", "difficulty": "intermediate", "time_min": 3},
    {"id": "deadlift", "name": "Deadlift", "primary_muscle": "back", "difficulty": "advanced", "time_min": 4},
    # Legs
    {"id": "body_squat", "name": "Bodyweight Squat", "primary_muscle": "quads", "difficulty": "beginner", "time_min": 2},
    {"id": "goblet_squat", "name": "Goblet Squat", "primary_muscle": "quads", "difficulty": "beginner", "time_min": 3},
    {"id": "db_lunge", "name": "Dumbbell Lunge", "primary_muscle": "quads", "difficulty": "intermediate", "time_min": 3},
    {"id": "leg_press", "name": "Leg Press", "primary_muscle": "quads", "difficulty": "intermediate", "time_min": 3},
    {"id": "romanian_dl", "name": "Romanian Deadlift", "primary_muscle": "hamstrings", "difficulty": "intermediate", "time_min": 3},
    {"id": "leg_curl", "name": "Leg Curl", "primary_muscle": "hamstrings", "difficulty": "beginner", "time_min": 2},
    # Shoulders
    {"id": "db_shoulder_press", "name": "DB Shoulder Press", "primary_muscle": "shoulders", "difficulty": "intermediate", "time_min": 3},
    {"id": "lateral_raise", "name": "Lateral Raise", "primary_muscle": "shoulders", "difficulty": "beginner", "time_min": 2},
    {"id": "front_raise", "name": "Front Raise", "primary_muscle": "shoulders", "difficulty": "beginner", "time_min": 2},
    {"id": "face_pull", "name": "Face Pull", "primary_muscle": "shoulders", "difficulty": "intermediate", "time_min": 2},
    # Arms
    {"id": "db_curl", "name": "Dumbbell Curl", "primary_muscle": "biceps", "difficulty": "beginner", "time_min": 2},
    {"id": "hammer_curl", "name": "Hammer Curl", "primary_muscle": "biceps", "difficulty": "beginner", "time_min": 2},
    {"id": "tricep_ext", "name": "Tricep Extension", "primary_muscle": "triceps", "difficulty": "beginner", "time_min": 2},
    {"id": "tricep_dip", "name": "Tricep Dip", "primary_muscle": "triceps", "difficulty": "intermediate", "time_min": 2},
    # Core
    {"id": "plank", "name": "Plank", "primary_muscle": "core", "difficulty": "beginner", "time_min": 1},
    {"id": "crunch", "name": "Crunch", "primary_muscle": "core", "difficulty": "beginner", "time_min": 2},
    {"id": "bicycle_crunch", "name": "Bicycle Crunch", "primary_muscle": "core", "difficulty": "beginner", "time_min": 2},
    {"id": "mountain_climber", "name": "Mountain Climber", "primary_muscle": "core", "difficulty": "intermediate", "time_min": 2},
    {"id": "russian_twist", "name": "Russian Twist", "primary_muscle": "core", "difficulty": "intermediate", "time_min": 2},
    # Cardio
    {"id": "jumping_jack", "name": "Jumping Jacks", "primary_muscle": "cardio", "difficulty": "beginner", "time_min": 2},
    {"id": "burpee", "name": "Burpee", "primary_muscle": "cardio", "difficulty": "intermediate", "time_min": 2},
    {"id": "high_knees", "name": "High Knees", "primary_muscle": "cardio", "difficulty": "beginner", "time_min": 2},
]


# --- Minimal models ---
class ExerciseSet(BaseModel):
    exercise_id: str
    sets: int = Field(3, ge=1, le=6)
    reps: int = Field(10, ge=1, le=30)
    rest_seconds: int = Field(60, ge=30, le=180)


class WorkoutSession(BaseModel):
    day_index: int
    items: List[ExerciseSet]


class PlanCreateRequest(BaseModel):
    days_per_week: int = Field(..., ge=1, le=7)
    weeks: int = Field(1, ge=1, le=12)


class GenerateWorkoutRequest(BaseModel):
    """New enhanced workout generator with specific days, duration, difficulty"""
    selected_days: List[str] = Field(..., min_length=1, max_length=7)  # e.g., ["monday", "wednesday", "friday"]
    duration_minutes: int = Field(45, ge=15, le=120)
    difficulty: str = Field("intermediate", pattern="^(beginner|intermediate|advanced)$")
    weeks: int = Field(4, ge=1, le=12)


class Plan(BaseModel):
    id: str
    days_per_week: int
    weeks: int
    sessions: List[WorkoutSession]
    selected_days: List[str] = Field(default_factory=list)  # e.g., ["monday", "wednesday", "friday"]

class PlanListResponse(BaseModel):
    items: List[Plan]
    count: int


class LoggedSet(BaseModel):
    """Single set logged during workout"""
    reps: int = Field(..., ge=0, le=50)
    weight: float = Field(0, ge=0)  # Weight in kg or lbs


class LoggedExercise(BaseModel):
    """Exercise with logged sets from actual workout"""
    exercise_id: str
    sets: List[LoggedSet]


class WorkoutCompletion(BaseModel):
    """Record of a completed workout session"""
    id: str
    plan_id: str
    session_index: int  # Which session in the plan (0-indexed)
    completed_at: str  # ISO datetime
    duration_minutes: int = Field(default=0, ge=0)
    logged_exercises: List[LoggedExercise] = Field(default_factory=list)


class CompletionRequest(BaseModel):
    plan_id: str
    session_index: int
    duration_minutes: int = Field(default=45, ge=1, le=240)
    logged_exercises: List[LoggedExercise] = Field(default_factory=list)


class WeeklySummary(BaseModel):
    """Summary of workout activity for current week"""
    workouts_completed: int
    total_minutes: int
    current_streak: int
    this_week_completions: List[WorkoutCompletion]

# In-memory store for created plans
plans_store: Dict[str, Plan] = {}


# --- Auth helpers (simple token sessions) ---
def hash_password(password: str) -> str:
    import os, hashlib
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 200_000)
    return salt.hex() + ":" + dk.hex()


def verify_password(password: str, hashed: str) -> bool:
    import hashlib, hmac
    try:
        salt_hex, dk_hex = hashed.split(":", 1)
        salt = bytes.fromhex(salt_hex)
        expected = bytes.fromhex(dk_hex)
        calc = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 200_000)
        return hmac.compare_digest(calc, expected)
    except Exception:
        return False


def get_user_id(authorization: str = Header(default=None)) -> str:
    """Read Bearer token from Authorization header and resolve user_id via sessions collection."""
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


class RegisterRequest(BaseModel):
    email: str
    password: str
    name: str = ""


class AuthResponse(BaseModel):
    token: str
    user_id: str
    email: str
    name: str = ""


@app.post("/v1/auth/register", response_model=AuthResponse, status_code=201)
async def register(req: RegisterRequest):
    # Unique email
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
        # Create a session token
        token = str(uuid4())
        sessions_col.insert_one({"_id": token, "user_id": user_id, "created_at": datetime.utcnow().isoformat()})
        return AuthResponse(token=token, user_id=user_id, email=req.email, name=req.name)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {e}")


class LoginRequest(BaseModel):
    email: str
    password: str


@app.post("/v1/auth/login", response_model=AuthResponse)
async def login(req: LoginRequest):
    user = users_col.find_one({"email": req.email})
    if not user or not verify_password(req.password, user.get("password", "")):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = str(uuid4())
    sessions_col.insert_one({"_id": token, "user_id": user["_id"], "created_at": datetime.utcnow().isoformat()})
    return AuthResponse(token=token, user_id=user["_id"], email=user["email"], name=user.get("name", ""))


@app.get("/v1/auth/me")
async def me(user_id: str = Depends(get_user_id)):
    user = users_col.find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.pop("password", None)
    user["id"] = user.pop("_id")
    return user


class WorkoutHistoryItem(BaseModel):
    completion: WorkoutCompletion
    muscles: List[str] = Field(default_factory=list)
    total_sets: int = 0
    total_reps: int = 0
    total_volume: float = 0.0
    difficulty: Optional[str] = None


class WorkoutHistoryResponse(BaseModel):
    items: List[WorkoutHistoryItem]
    count: int


# --- Workout generation helpers ---
def get_exercises_by_difficulty(difficulty: str) -> List[dict]:
    """Filter exercises by difficulty level and lower."""
    levels = {"beginner": ["beginner"], "intermediate": ["beginner", "intermediate"], "advanced": ["beginner", "intermediate", "advanced"]}
    allowed = levels.get(difficulty, ["beginner", "intermediate"])
    return [ex for ex in exercises if ex["difficulty"] in allowed]


def generate_split_pattern(num_days: int) -> List[List[str]]:
    """Generate muscle group split pattern based on days per week."""
    if num_days == 1:
        return [["chest", "back", "quads", "shoulders", "core"]]  # Full body
    elif num_days == 2:
        return [["chest", "shoulders", "triceps"], ["back", "quads", "biceps", "core"]]
    elif num_days == 3:
        return [["chest", "shoulders", "triceps"], ["back", "biceps"], ["quads", "hamstrings", "core"]]  # Push/Pull/Legs
    elif num_days == 4:
        return [["chest", "triceps"], ["back", "biceps"], ["quads", "hamstrings"], ["shoulders", "core"]]
    elif num_days == 5:
        return [["chest"], ["back"], ["quads", "hamstrings"], ["shoulders", "triceps"], ["biceps", "core"]]
    else:  # 6-7 days
        return [["chest"], ["back"], ["quads"], ["hamstrings"], ["shoulders"], ["arms", "core"], ["cardio"]]


def select_exercises_for_session(muscle_groups: List[str], available_exercises: List[dict], duration: int, difficulty: str) -> List[ExerciseSet]:
    """Select exercises for a session based on muscle groups, duration, and difficulty."""
    # Estimate exercises based on duration (each exercise ~3-4 min including rest)
    num_exercises = max(3, min(8, duration // 6))
    
    # Filter exercises by muscle groups
    candidates = [ex for ex in available_exercises if ex["primary_muscle"] in muscle_groups or any(mg in ex["primary_muscle"] for mg in muscle_groups)]
    
    # If not enough, add core/cardio fillers
    if len(candidates) < num_exercises:
        fillers = [ex for ex in available_exercises if ex["primary_muscle"] in ["core", "cardio"]]
        candidates.extend(fillers)
    
    # Select exercises (avoid duplicates)
    selected = []
    seen_ids = set()
    for ex in candidates:
        if ex["id"] not in seen_ids and len(selected) < num_exercises:
            # Adjust sets/reps by difficulty
            if difficulty == "beginner":
                sets, reps, rest = 3, 12, 60
            elif difficulty == "intermediate":
                sets, reps, rest = 4, 10, 60
            else:  # advanced
                sets, reps, rest = 4, 8, 75
            
            selected.append(ExerciseSet(exercise_id=ex["id"], sets=sets, reps=reps, rest_seconds=rest))
            seen_ids.add(ex["id"])
    
    return selected


def get_week_start_end():
    """Get start and end of current week (Monday to Sunday)"""
    from datetime import timedelta
    now = datetime.utcnow()
    # Monday = 0, Sunday = 6
    weekday = now.weekday()
    week_start = (now - timedelta(days=weekday)).replace(hour=0, minute=0, second=0, microsecond=0)
    week_end = week_start + timedelta(days=7)
    return week_start, week_end


def calculate_streak(completions: List[dict]) -> int:
    """Calculate current workout streak (consecutive days with workouts)"""
    if not completions:
        return 0
    
    # Sort by date descending
    from datetime import timedelta
    sorted_completions = sorted(completions, key=lambda x: x["completed_at"], reverse=True)
    
    streak = 0
    check_date = datetime.utcnow().date()
    
    for completion in sorted_completions:
        completion_date = datetime.fromisoformat(completion["completed_at"]).date()
        
        # If this completion is on the check date or the day before, continue streak
        if completion_date == check_date or completion_date == check_date - timedelta(days=1):
            if completion_date == check_date or streak == 0:  # Start or extend streak
                streak += 1
                check_date = completion_date - timedelta(days=1)
        else:
            break
    
    return streak


# --- Routes ---
@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/v1/db/ping")
async def db_ping():
    """Simple DB health check that pings MongoDB."""
    try:
        client.admin.command("ping")
        return {"status": "ok", "db": MONGO_DB_NAME}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"DB ping failed: {exc}")


@app.get("/v1/exercises")
async def list_exercises():
    return {"items": exercises, "count": len(exercises)}


@app.post("/v1/generate", response_model=Plan, status_code=201)
async def generate_workout(req: GenerateWorkoutRequest, user_id: str = Depends(get_user_id)):
    """Generate a smart workout plan based on selected days, duration, and difficulty."""
    num_days = len(req.selected_days)
    available_exercises = get_exercises_by_difficulty(req.difficulty)
    split_pattern = generate_split_pattern(num_days)
    
    # Generate sessions for each week
    sessions: List[WorkoutSession] = []
    for week in range(req.weeks):
        for day_idx, muscle_groups in enumerate(split_pattern[:num_days]):
            exercise_sets = select_exercises_for_session(
                muscle_groups=muscle_groups,
                available_exercises=available_exercises,
                duration=req.duration_minutes,
                difficulty=req.difficulty
            )
            sessions.append(WorkoutSession(day_index=day_idx + 1, items=exercise_sets))
    
    # Create plan
    plan = Plan(
        id=str(uuid4()),
        days_per_week=num_days,
        weeks=req.weeks,
        sessions=sessions,
        selected_days=req.selected_days,
    )
    plans_store[plan.id] = plan
    
    # Persist to MongoDB
    try:
        doc = plan.model_dump()
        doc_with_metadata = {
            **doc,
            "_id": doc["id"],
            "created_at": datetime.utcnow().isoformat(),
            "selected_days": req.selected_days,
            "duration_minutes": req.duration_minutes,
            "difficulty": req.difficulty,
            "user_id": user_id,
        }
        plans_col.insert_one(doc_with_metadata)
    except Exception:
        pass
    
    return plan


@app.post("/v1/plans", response_model=Plan, status_code=201)
async def create_plan(req: PlanCreateRequest, user_id: str = Depends(get_user_id)):
    total_sessions = req.days_per_week * req.weeks
    sessions: List[WorkoutSession] = []

    for s in range(total_sessions):
        day_index = (s % req.days_per_week) + 1
        # Deterministic, simple selection: rotate through the mock list and pick 3
        picks: List[ExerciseSet] = []
        for k in range(3):
            ex = exercises[(s + k) % len(exercises)]
            picks.append(ExerciseSet(exercise_id=ex["id"]))
        sessions.append(WorkoutSession(day_index=day_index, items=picks))

    plan = Plan(
        id=str(uuid4()),
        days_per_week=req.days_per_week,
        weeks=req.weeks,
        sessions=sessions,
    )
    plans_store[plan.id] = plan
    # Persist to MongoDB
    try:
        doc = plan.model_dump()
        # Use _id for direct lookups while keeping 'id' for API responses
        doc_with_id = {**doc, "_id": doc["id"], "created_at": datetime.utcnow().isoformat(), "user_id": user_id}
        plans_col.insert_one(doc_with_id)
    except Exception:
        # If DB write fails, we still have the in-memory plan
        pass
    return plan


@app.get("/v1/plans/{plan_id}", response_model=Plan)
async def get_plan(plan_id: str, user_id: str = Depends(get_user_id)):
    # Always check DB to validate ownership
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


@app.get("/v1/plans", response_model=PlanListResponse)
async def list_plans(user_id: str = Depends(get_user_id)):
    """Return all plans currently stored in MongoDB (best-effort).
    Response shape mirrors /v1/exercises: {"items": [...], "count": N}
    """
    items: List[Plan] = []
    try:
        # Fetch all docs; ignore extra fields when validating into Plan
        cursor = plans_col.find({"user_id": user_id}, projection=None)
        try:
            cursor = cursor.sort("created_at", -1)
        except Exception:
            # If the field doesn't exist yet, proceed unsorted
            pass
        for doc in cursor:
            if "id" not in doc and "_id" in doc:
                doc["id"] = str(doc["_id"])  # ensure id present
            doc.pop("_id", None)
            try:
                items.append(Plan.model_validate(doc))
            except Exception:
                # Skip invalid docs rather than failing the whole request
                continue
    except Exception:
        # If DB unavailable, return empty for safety
        items = []
    return {"items": items, "count": len(items)}


@app.post("/v1/workouts/complete", response_model=WorkoutCompletion, status_code=201)
async def complete_workout(req: CompletionRequest, user_id: str = Depends(get_user_id)):
    """Mark a workout session as completed."""
    completion = WorkoutCompletion(
        id=str(uuid4()),
        plan_id=req.plan_id,
        session_index=req.session_index,
        completed_at=datetime.utcnow().isoformat(),
        duration_minutes=req.duration_minutes,
        logged_exercises=req.logged_exercises,
    )
    
    # Save to MongoDB
    try:
        doc = completion.model_dump()
        doc["_id"] = doc["id"]
        doc["user_id"] = user_id
        completions_col.insert_one(doc)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save completion: {e}")
    
    return completion


@app.get("/v1/workouts/summary", response_model=WeeklySummary)
async def get_weekly_summary(user_id: str = Depends(get_user_id)):
    """Get summary of workouts for the current week."""
    week_start, week_end = get_week_start_end()
    
    # Query completions for this week
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
    
    # Calculate stats
    total_minutes = sum(c.duration_minutes for c in this_week_completions)
    streak = calculate_streak(all_completions)
    
    return WeeklySummary(
        workouts_completed=len(this_week_completions),
        total_minutes=total_minutes,
        current_streak=streak,
        this_week_completions=this_week_completions,
    )


@app.get("/v1/workouts/history", response_model=WorkoutHistoryResponse)
async def get_workout_history(
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    muscle: Optional[str] = None,
    difficulty: Optional[str] = None,
    limit: int = 100,
    user_id: str = Depends(get_user_id),
):
    """Return workout completion history with optional filters.

    - date_from/date_to: ISO date or datetime (inclusive range). Example: 2025-01-01
    - muscle: primary muscle group (e.g., 'chest', 'back')
    - difficulty: 'beginner' | 'intermediate' | 'advanced'
    - limit: max number of items to return (after filtering)
    """
    from datetime import timedelta

    # Build Mongo query for time range
    query = {"user_id": user_id}
    time_filter = {}
    try:
        if date_from:
            # Support plain date (YYYY-MM-DD) or full ISO timestamp
            dt_from = datetime.fromisoformat(date_from) if 'T' in date_from else datetime.fromisoformat(date_from + 'T00:00:00')
            time_filter["$gte"] = dt_from.isoformat()
        if date_to:
            dt_to = datetime.fromisoformat(date_to) if 'T' in date_to else datetime.fromisoformat(date_to + 'T23:59:59')
            time_filter["$lte"] = dt_to.isoformat()
    except Exception:
        # Ignore invalid date filters
        time_filter = {}
    if time_filter:
        query["completed_at"] = {**time_filter}

    # Fetch completions
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

    # Helper map for exercise -> primary muscle
    ex_to_muscle = {ex["id"]: ex.get("primary_muscle") for ex in exercises}

    for d in docs:
        # Compute aggregates from logged_exercises
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

        # Lookup plan difficulty if available
        diff_val: Optional[str] = None
        try:
            pdoc = plans_col.find_one({"_id": d.get("plan_id")})
            if pdoc:
                diff_val = pdoc.get("difficulty")
        except Exception:
            pass

        # Filter by muscle and difficulty if provided
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
