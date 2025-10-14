#!/usr/bin/env bash
set -euo pipefail

CURRENT_STEP="initialization"
fail() {
  echo "[e2e] ERROR during step: ${CURRENT_STEP}" >&2
  echo "[e2e] Dumping docker-compose state for debugging..." >&2
  docker compose ps || true
  docker compose logs --no-color --tail=120 frontend backend 2>/dev/null || true
}
trap fail ERR

step() {
  CURRENT_STEP="$1"
  echo "[e2e] $1"
}

in_backend() {
  docker compose exec -T backend sh -lc "$*"
}

# Base URL routed through nginx service; configurable via env
BASE_URL=${BASE_URL:-http://frontend}
# Default credentials for the synthetic E2E user
PASSWORD=${PASSWORD:-"Pass1234!"}
NAME=${NAME:-"E2E Runner"}
# Unique email per run to avoid collisions
EMAIL_SUFFIX=$(openssl rand -hex 4)
EMAIL="e2e-${EMAIL_SUFFIX}@example.com"

# FastAPI image is Alpine; make sure curl/jq are present for HTTP + JSON parsing
step "Ensuring curl and jq are present in backend container"
in_backend 'apk add --no-cache curl jq >/dev/null'

# Wait until nginx reverse proxy and backend are both reachable via /health
step "Waiting for frontend health endpoint"
in_backend "until curl -sf ${BASE_URL}/health | jq -e '.status == \"ok\"' >/dev/null; do echo '  waiting frontend...'; sleep 1; done"

# Register a brand-new user through the real API surface (via frontend)
step "Registering new user via frontend"
REGISTER_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_register.json -X POST ${BASE_URL}/v1/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"name\":\"${NAME}\"}'")
if [[ "${REGISTER_STATUS}" != "200" && "${REGISTER_STATUS}" != "201" ]]; then
  echo "[e2e] Registration failed with status ${REGISTER_STATUS}" >&2
  in_backend "cat /tmp/e2e_register.json" >&2
  exit 1
fi
in_backend "jq -e '.token and .user_id' /tmp/e2e_register.json >/dev/null"

# Login to obtain a fresh JWT token
step "Logging in with registered credentials"
LOGIN_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_login.json -X POST ${BASE_URL}/v1/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}'")
if [[ "${LOGIN_STATUS}" != "200" ]]; then
  echo "[e2e] Login failed with status ${LOGIN_STATUS}" >&2
  in_backend "cat /tmp/e2e_login.json" >&2
  exit 1
fi
TOKEN=$(in_backend "jq -r '.token // empty' /tmp/e2e_login.json")
USER_ID=$(in_backend "jq -r '.user_id // empty' /tmp/e2e_login.json")
if [[ -z "${TOKEN}" || -z "${USER_ID}" ]]; then
  echo "[e2e] Missing token or user_id in login response" >&2
  in_backend "cat /tmp/e2e_login.json" >&2
  exit 1
fi

# Confirm exercise catalog is available for authenticated user
step "Fetching exercises catalog"
in_backend "curl -sSf -H 'Authorization: Bearer ${TOKEN}' ${BASE_URL}/v1/exercises | jq -e '.items | (type == \"array\") and (length >= 1)' >/dev/null"

# Create a workout plan for the new user
step "Creating workout plan through API"
PLAN_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_plan.json -X POST ${BASE_URL}/v1/plans -H 'Content-Type: application/json' -H 'Authorization: Bearer ${TOKEN}' -d '{\"days_per_week\":3,\"weeks\":1}'")
if [[ "${PLAN_STATUS}" != "201" ]]; then
  echo "[e2e] Plan creation failed with status ${PLAN_STATUS}" >&2
  in_backend "cat /tmp/e2e_plan.json" >&2
  exit 1
fi
PLAN_ID=$(in_backend "jq -r '.id // empty' /tmp/e2e_plan.json")
if [[ -z "${PLAN_ID}" ]]; then
  echo "[e2e] Plan response missing id" >&2
  in_backend "cat /tmp/e2e_plan.json" >&2
  exit 1
fi

# Ensure the plan is visible in the user's plan list
step "Listing plans for user"
PLANS_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_plans.json -H 'Authorization: Bearer ${TOKEN}' ${BASE_URL}/v1/plans")
if [[ "${PLANS_STATUS}" != "200" ]]; then
  echo "[e2e] Listing plans failed with status ${PLANS_STATUS}" >&2
  in_backend "cat /tmp/e2e_plans.json" >&2
  exit 1
fi
in_backend "jq -e --arg id '${PLAN_ID}' '.items | map(.id) | index(\$id) != null' /tmp/e2e_plans.json >/dev/null"

# Fetch the plan by id to verify stored data
step "Retrieving plan details"
PLAN_GET_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_plan_get.json -H 'Authorization: Bearer ${TOKEN}' ${BASE_URL}/v1/plans/${PLAN_ID}")
if [[ "${PLAN_GET_STATUS}" != "200" ]]; then
  echo "[e2e] Get plan failed with status ${PLAN_GET_STATUS}" >&2
  in_backend "cat /tmp/e2e_plan_get.json" >&2
  exit 1
fi
in_backend "jq -e --arg id '${PLAN_ID}' '.id == \$id' /tmp/e2e_plan_get.json >/dev/null"

# Simulate logging a workout completion for that plan
step "Completing a workout session"
in_backend "cat >/tmp/e2e_complete.json <<JSON
{
  \"plan_id\": \"${PLAN_ID}\",
  \"session_index\": 0,
  \"duration_minutes\": 30,
  \"logged_exercises\": [
    {
      \"exercise_id\": \"push_up\",
      \"sets\": [
        { \"reps\": 12, \"weight\": 0 }
      ]
    }
  ]
}
JSON"
COMPLETE_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_completion.json -X POST ${BASE_URL}/v1/workouts/complete -H 'Content-Type: application/json' -H 'Authorization: Bearer ${TOKEN}' --data-binary @/tmp/e2e_complete.json")
if [[ "${COMPLETE_STATUS}" != "201" ]]; then
  echo "[e2e] Workout completion failed with status ${COMPLETE_STATUS}" >&2
  in_backend "cat /tmp/e2e_completion.json" >&2
  exit 1
fi
COMPLETION_ID=$(in_backend "jq -r '.id // empty' /tmp/e2e_completion.json")
if [[ -z "${COMPLETION_ID}" ]]; then
  echo "[e2e] Completion response missing id" >&2
  in_backend "cat /tmp/e2e_completion.json" >&2
  exit 1
fi

# Weekly summary should reflect the newly logged session
step "Checking weekly summary for recorded workout"
SUMMARY_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_summary.json -H 'Authorization: Bearer ${TOKEN}' ${BASE_URL}/v1/workouts/summary")
if [[ "${SUMMARY_STATUS}" != "200" ]]; then
  echo "[e2e] Weekly summary failed with status ${SUMMARY_STATUS}" >&2
  in_backend "cat /tmp/e2e_summary.json" >&2
  exit 1
fi
in_backend "jq -e '.workouts_completed >= 1 and .total_minutes >= 30' /tmp/e2e_summary.json >/dev/null"

# History should include the completion before deletion
step "Ensuring workout history includes new completion"
HISTORY_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_history_before.json -H 'Authorization: Bearer ${TOKEN}' '${BASE_URL}/v1/workouts/history?limit=10'")
if [[ "${HISTORY_STATUS}" != "200" ]]; then
  echo "[e2e] History (before delete) failed with status ${HISTORY_STATUS}" >&2
  in_backend "cat /tmp/e2e_history_before.json" >&2
  exit 1
fi
in_backend "jq -e --arg id '${COMPLETION_ID}' '.items | map(.completion.id) | index(\$id) != null' /tmp/e2e_history_before.json >/dev/null"

# Delete the recorded completion via API
step "Deleting workout completion"
DELETE_STATUS=$(in_backend "curl -sS -o /dev/null -w '%{http_code}' -X DELETE -H 'Authorization: Bearer ${TOKEN}' ${BASE_URL}/v1/workouts/${COMPLETION_ID}")
if [[ "${DELETE_STATUS}" != "204" ]]; then
  echo "[e2e] Deleting completion failed with status ${DELETE_STATUS}" >&2
  exit 1
fi

# Verify the deletion is reflected in workout history
step "Verifying completion is absent from history"
HISTORY_AFTER_STATUS=$(in_backend "curl -sS -w '%{http_code}' -o /tmp/e2e_history_after.json -H 'Authorization: Bearer ${TOKEN}' '${BASE_URL}/v1/workouts/history?limit=10'")
if [[ "${HISTORY_AFTER_STATUS}" != "200" ]]; then
  echo "[e2e] History (after delete) failed with status ${HISTORY_AFTER_STATUS}" >&2
  in_backend "cat /tmp/e2e_history_after.json" >&2
  exit 1
fi
in_backend "jq -e --arg id '${COMPLETION_ID}' '.items | map(.completion.id) | index(\$id) == null' /tmp/e2e_history_after.json >/dev/null"

# Profiles endpoint should echo the email used during signup
step "Verifying /v1/auth/me reflects current profile"
in_backend "curl -sSf -H 'Authorization: Bearer ${TOKEN}' ${BASE_URL}/v1/auth/me | jq -e --arg email '${EMAIL}' '.email == \$email' >/dev/null"

echo "[e2e] End-to-end user flow completed successfully"
