from typing import Dict, List, Optional
from pydantic import BaseModel, Field

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
    selected_days: List[str] = Field(..., min_length=1, max_length=7)
    duration_minutes: int = Field(45, ge=15, le=120)
    difficulty: str = Field("intermediate", pattern="^(beginner|intermediate|advanced)$")
    weeks: int = Field(4, ge=1, le=12)

class Plan(BaseModel):
    id: str
    days_per_week: int
    weeks: int
    sessions: List[WorkoutSession]
    selected_days: List[str] = Field(default_factory=list)

class PlanListResponse(BaseModel):
    items: List[Plan]
    count: int

class LoggedSet(BaseModel):
    reps: int = Field(..., ge=0, le=50)
    weight: float = Field(0, ge=0)

class LoggedExercise(BaseModel):
    exercise_id: str
    sets: List[LoggedSet]

class WorkoutCompletion(BaseModel):
    id: str
    plan_id: str
    session_index: int
    completed_at: str
    duration_minutes: int = Field(default=0, ge=0)
    logged_exercises: List[LoggedExercise] = Field(default_factory=list)

class CompletionRequest(BaseModel):
    plan_id: str
    session_index: int
    duration_minutes: int = Field(default=45, ge=1, le=240)
    logged_exercises: List[LoggedExercise] = Field(default_factory=list)

class WeeklySummary(BaseModel):
    workouts_completed: int
    total_minutes: int
    current_streak: int
    this_week_completions: List[WorkoutCompletion]

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

class RegisterRequest(BaseModel):
    email: str
    password: str
    name: str = ""

class AuthResponse(BaseModel):
    token: str
    user_id: str
    email: str
    name: str = ""

class LoginRequest(BaseModel):
    email: str
    password: str
