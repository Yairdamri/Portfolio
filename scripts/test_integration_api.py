import os
import uuid
from typing import Optional

import pytest
from fastapi.testclient import TestClient

# Use the in-memory mongomock client for these integration tests
os.environ["USE_MOCK_DB"] = "1"

from app.main import app  # noqa: E402  (import after setting env)
from app.db import plans_col, completions_col, users_col, sessions_col  # noqa: E402


@pytest.fixture(scope="module")
def client() -> TestClient:
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(autouse=True)
def clean_database():
    collections = (plans_col, completions_col, users_col, sessions_col)
    for col in collections:
        col.delete_many({})
    yield
    for col in collections:
        col.delete_many({})


def register_user(client: TestClient, email: Optional[str] = None, password: str = "pass1234"):
    email = email or f"integration-{uuid.uuid4().hex}@example.com"
    response = client.post(
        "/v1/auth/register",
        json={"email": email, "password": password, "name": "Integration Runner"},
    )
    assert response.status_code == 200
    data = response.json()
    token = data["token"]
    user_id = data["user_id"]
    return {"Authorization": f"Bearer {token}"}, user_id, email


def test_protected_endpoints_require_authentication(client: TestClient):
    response = client.get("/v1/plans")
    assert response.status_code == 401

    response = client.post(
        "/v1/workouts/complete",
        json={
            "plan_id": "missing",
            "session_index": 0,
            "duration_minutes": 30,
            "logged_exercises": [],
        },
    )
    assert response.status_code == 401


def test_workout_flow_persists_data_and_returns_summary(client: TestClient):
    auth_headers, user_id, _ = register_user(client)

    # Create a plan for the authenticated user
    create_plan_resp = client.post(
        "/v1/plans",
        json={"days_per_week": 3, "weeks": 1},
        headers=auth_headers,
    )
    assert create_plan_resp.status_code == 201
    plan = create_plan_resp.json()
    plan_id = plan["id"]
    assert plans_col.find_one({"_id": plan_id, "user_id": user_id}) is not None

    # Retrieve the plan via API
    get_plan_resp = client.get(f"/v1/plans/{plan_id}", headers=auth_headers)
    assert get_plan_resp.status_code == 200
    assert get_plan_resp.json()["id"] == plan_id

    # Complete a workout for that plan
    complete_resp = client.post(
        "/v1/workouts/complete",
        json={
            "plan_id": plan_id,
            "session_index": 0,
            "duration_minutes": 30,
            "logged_exercises": [
                {"exercise_id": "push_up", "sets": [{"reps": 12, "weight": 0}]}
            ],
        },
        headers=auth_headers,
    )
    assert complete_resp.status_code == 201
    completion_id = complete_resp.json()["id"]
    assert completions_col.find_one({"_id": completion_id, "user_id": user_id}) is not None

    # Weekly summary should reflect the logged workout
    summary_resp = client.get("/v1/workouts/summary", headers=auth_headers)
    assert summary_resp.status_code == 200
    summary = summary_resp.json()
    assert summary["workouts_completed"] == 1
    assert summary["total_minutes"] == 30
    assert summary["current_streak"] >= 1

    # History endpoint should list the completion
    history_resp = client.get("/v1/workouts/history?limit=5", headers=auth_headers)
    assert history_resp.status_code == 200
    history = history_resp.json()
    assert history["count"] >= 1
    assert any(item["completion"]["id"] == completion_id for item in history["items"])

    # Delete the completion and ensure it is removed
    delete_resp = client.delete(f"/v1/workouts/{completion_id}", headers=auth_headers)
    assert delete_resp.status_code == 204
    assert completions_col.find_one({"_id": completion_id, "user_id": user_id}) is None

    history_after_delete = client.get("/v1/workouts/history?limit=5", headers=auth_headers)
    assert history_after_delete.status_code == 200
    deleted_ids = [item["completion"]["id"] for item in history_after_delete.json().get("items", [])]
    assert completion_id not in deleted_ids

    # A different user must not see another user's plan
    other_headers, _, _ = register_user(client)
    other_get_plan = client.get(f"/v1/plans/{plan_id}", headers=other_headers)
    assert other_get_plan.status_code == 404
