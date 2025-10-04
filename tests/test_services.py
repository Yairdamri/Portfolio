import re
from datetime import datetime, timedelta

from app.services import (
    generate_split_pattern,
    select_exercises_for_session,
    get_exercises_by_difficulty,
    calculate_streak,
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
