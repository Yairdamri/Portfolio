from datetime import datetime, timedelta
from typing import List

from .data import exercises
from .models import ExerciseSet


def get_exercises_by_difficulty(difficulty: str) -> List[dict]:
    levels = {
        "beginner": ["beginner"],
        "intermediate": ["beginner", "intermediate"],
        "advanced": ["beginner", "intermediate", "advanced"],
    }
    allowed = levels.get(difficulty, ["beginner", "intermediate"])
    return [ex for ex in exercises if ex["difficulty"] in allowed]


def generate_split_pattern(num_days: int) -> List[List[str]]:
    if num_days == 1:
        return [["chest", "back", "quads", "shoulders", "core"]]
    elif num_days == 2:
        return [["chest", "shoulders", "triceps"], ["back", "quads", "biceps", "core"]]
    elif num_days == 3:
        return [["chest", "shoulders", "triceps"], ["back", "biceps"], ["quads", "hamstrings", "core"]]
    elif num_days == 4:
        return [["chest", "triceps"], ["back", "biceps"], ["quads", "hamstrings"], ["shoulders", "core"]]
    elif num_days == 5:
        return [["chest"], ["back"], ["quads", "hamstrings"], ["shoulders", "triceps"], ["biceps", "core"]]
    else:
        return [["chest"], ["back"], ["quads"], ["hamstrings"], ["shoulders"], ["arms", "core"], ["cardio"]]


def select_exercises_for_session(muscle_groups: List[str], available_exercises: List[dict], duration: int, difficulty: str) -> List[ExerciseSet]:
    num_exercises = max(3, min(8, duration // 6))
    candidates = [ex for ex in available_exercises if ex["primary_muscle"] in muscle_groups or any(mg in ex["primary_muscle"] for mg in muscle_groups)]
    if len(candidates) < num_exercises:
        fillers = [ex for ex in available_exercises if ex["primary_muscle"] in ["core", "cardio"]]
        candidates.extend(fillers)
    selected = []
    seen_ids = set()
    for ex in candidates:
        if ex["id"] not in seen_ids and len(selected) < num_exercises:
            if difficulty == "beginner":
                sets, reps, rest = 3, 12, 60
            elif difficulty == "intermediate":
                sets, reps, rest = 4, 10, 60
            else:
                sets, reps, rest = 4, 8, 75
            selected.append(ExerciseSet(exercise_id=ex["id"], sets=sets, reps=reps, rest_seconds=rest))
            seen_ids.add(ex["id"])
    return selected


def get_week_start_end():
    now = datetime.utcnow()
    weekday = now.weekday()
    week_start = (now - timedelta(days=weekday)).replace(hour=0, minute=0, second=0, microsecond=0)
    week_end = week_start + timedelta(days=7)
    return week_start, week_end


def calculate_streak(completions: List[dict]) -> int:
    if not completions:
        return 0
    sorted_completions = sorted(completions, key=lambda x: x["completed_at"], reverse=True)
    streak = 0
    check_date = datetime.utcnow().date()
    for completion in sorted_completions:
        completion_date = datetime.fromisoformat(completion["completed_at"]).date()
        if completion_date == check_date or completion_date == check_date - timedelta(days=1):
            if completion_date == check_date or streak == 0:
                streak += 1
                check_date = completion_date - timedelta(days=1)
        else:
            break
    return streak
