import re
from datetime import datetime, timedelta

from app.services import (
    generate_split_pattern,
    select_exercises_for_session,
    get_exercises_by_difficulty,
    calculate_streak,
    get_week_start_end,
)
from app.data import exercises


def test_generate_split_pattern_lengths():
    assert len(generate_split_pattern(1)) == 1
    assert len(generate_split_pattern(2)) == 2
    assert len(generate_split_pattern(3)) == 3
    assert len(generate_split_pattern(4)) == 4
    assert len(generate_split_pattern(5)) == 5
    assert len(generate_split_pattern(7)) >= 5


def test_select_exercises_respects_difficulty():
    avail = get_exercises_by_difficulty('beginner')
    groups = ['chest', 'back', 'quads']
    items = select_exercises_for_session(groups, avail, duration=30, difficulty='beginner')
    assert len(items) >= 3
    # In our logic, beginner uses reps=12
    assert all(i.reps in (8, 10, 12) for i in items)


def test_calculate_streak_today_and_yesterday():
    today = datetime.utcnow().replace(microsecond=0)
    yesterday = today - timedelta(days=1)
    completions = [
        {"completed_at": today.isoformat()},
        {"completed_at": yesterday.isoformat()},
    ]
    assert calculate_streak(completions) >= 2


# --- Additional Unit Tests ---

def test_get_exercises_by_difficulty_beginner_only():
    items = get_exercises_by_difficulty('beginner')
    assert len(items) > 0
    assert all(x['difficulty'] == 'beginner' for x in items)


def test_get_exercises_by_difficulty_intermediate_includes_beginner():
    items = get_exercises_by_difficulty('intermediate')
    assert len(items) > 0
    allowed = {'beginner', 'intermediate'}
    assert all(x['difficulty'] in allowed for x in items)


def test_get_exercises_by_difficulty_unknown_defaults_to_beginner_plus_intermediate():
    items = get_exercises_by_difficulty('unknown')
    allowed = {'beginner', 'intermediate'}
    assert all(x['difficulty'] in allowed for x in items)


def test_select_exercises_duration_bounds_and_uniqueness():
    avail = get_exercises_by_difficulty('advanced')  # widest set
    # Very short duration -> min 3
    items_short = select_exercises_for_session(['chest'], avail, duration=12, difficulty='intermediate')
    assert len(items_short) == 3
    # Very long duration -> max 8
    items_long = select_exercises_for_session(['back'], avail, duration=300, difficulty='intermediate')
    assert len(items_long) == 8
    # Uniqueness by exercise id
    ids = [i.exercise_id for i in items_long]
    assert len(ids) == len(set(ids))


def test_select_exercises_uses_fillers_when_insufficient():
    # Choose a muscle group unlikely to exist to force fillers (core/cardio)
    avail = get_exercises_by_difficulty('beginner')
    selected = select_exercises_for_session(['nonexistent-group'], avail, duration=30, difficulty='beginner')
    # Map id -> primary_muscle from static data
    idx = {ex['id']: ex['primary_muscle'] for ex in exercises}
    primaries = {idx[i.exercise_id] for i in selected if i.exercise_id in idx}
    assert any(p in {'core', 'cardio'} for p in primaries)


def test_select_exercises_parameters_by_difficulty():
    avail = get_exercises_by_difficulty('advanced')
    groups = ['chest', 'back', 'quads']
    # beginner
    items_b = select_exercises_for_session(groups, avail, duration=30, difficulty='beginner')
    assert len(items_b) >= 3 and all((i.sets, i.reps, i.rest_seconds) == (3, 12, 60) for i in items_b)
    # intermediate
    items_i = select_exercises_for_session(groups, avail, duration=30, difficulty='intermediate')
    assert len(items_i) >= 3 and all((i.sets, i.reps, i.rest_seconds) == (4, 10, 60) for i in items_i)
    # advanced
    items_a = select_exercises_for_session(groups, avail, duration=30, difficulty='advanced')
    assert len(items_a) >= 3 and all((i.sets, i.reps, i.rest_seconds) == (4, 8, 75) for i in items_a)


def test_get_week_start_end_invariants():
    start, end = get_week_start_end()
    assert (end - start).days == 7
    assert start.hour == 0 and start.minute == 0 and start.second == 0 and start.microsecond == 0
    # Monday == 0
    assert start.weekday() == 0


def test_calculate_streak_empty_returns_zero():
    assert calculate_streak([]) == 0


def test_calculate_streak_non_consecutive_counts_recent_only():
    today = datetime.utcnow().replace(microsecond=0)
    two_days_ago = today - timedelta(days=2)
    completions = [
        {"completed_at": today.isoformat()},
        {"completed_at": two_days_ago.isoformat()},
    ]
    # Non-consecutive -> streak should be 1 (today only)
    assert calculate_streak(completions) == 1


def test_generate_split_pattern_edge_cases():
    # 0 or negative should return 7-day fallback per implementation
    assert len(generate_split_pattern(0)) == 7
    assert len(generate_split_pattern(-3)) == 7
    # 6 and 7 days also yield 7 buckets in current logic's fallback
    assert len(generate_split_pattern(6)) == 7
    assert len(generate_split_pattern(7)) == 7
