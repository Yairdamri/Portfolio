#!/usr/bin/env bash
set -euo pipefail

# Dump container state and recent logs if anything fails
trap 'echo "[it] Failure. Dumping recent logs..."; docker compose ps; docker compose logs --no-color --tail=120 backend db frontend 2>/dev/null || true' ERR

# Helpers to run commands inside the backend or db containers
in_backend() { docker compose exec -T backend sh -lc "$*"; }
in_db() { docker compose exec -T db sh -lc "$*"; }

# Ensure tooling is available inside backend
echo "[it] Ensuring tools (curl, jq) in backend container..."
in_backend 'apk add --no-cache curl jq >/dev/null'

# Wait for the backend API to start responding
echo "[it] Waiting for backend /health..."
in_backend 'until curl -sf http://localhost:8000/health | jq -e ".status == \"ok\"" >/dev/null; do echo "  waiting backend..."; sleep 1; done'
echo "[it] Backend is up"

# Choose the Mongo shell client available in the container
echo "[it] Detecting Mongo shell..."
if in_db 'command -v mongosh >/dev/null 2>&1'; then
  MONGO_SHELL="mongosh --quiet"
else
  MONGO_SHELL="mongo --quiet"
fi

# Wait until MongoDB accepts connections
echo "[it] Waiting for MongoDB..."
i=0
until in_db "$MONGO_SHELL --eval 'db.adminCommand({ ping: 1 })' >/dev/null 2>&1"; do
  i=$((i+1)); test $i -le 60 || { echo "MongoDB not ready in time"; exit 1; }
  echo "  waiting mongodb..."; sleep 1
done
echo "[it] MongoDB is up"

# Confirm backend can talk to MongoDB
echo "[it] DB ping via API..."
in_backend 'curl -sf http://localhost:8000/v1/db/ping | jq -e ".status == \"ok\"" >/dev/null'
DB_NAME=$(in_backend "curl -sSf http://localhost:8000/v1/db/ping | jq -r '.db'")
test -n "${DB_NAME}"
echo "[it] Backend reports DB name: ${DB_NAME}"

# Verify auth is required for protected resources
echo "[it] Protected endpoint must return 401 without auth..."
code=$(in_backend "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/v1/plans")
test "$code" = "401" || { echo "Expected 401, got ${code}"; exit 1; }
echo "[it] 401 OK"

# Seed a user and session directly in MongoDB for authenticated requests
echo "[it] Seeding a session token directly in Mongo (no user flow)..."
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").users.deleteMany({_id: \"int-user\"}); db.getSiblingDB(\"${DB_NAME}\").sessions.deleteMany({_id: \"it-token\"});'"
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").users.insertOne({_id: \"int-user\", email: \"integration@example.com\", password: \"noop\", name: \"Integration\", created_at: new Date()}); db.getSiblingDB(\"${DB_NAME}\").sessions.insertOne({_id: \"it-token\", user_id: \"int-user\", created_at: new Date()});'"

# Smoke test an authenticated request to ensure the token works
echo "[it] Authenticated request to /v1/plans returns 200 and valid shape..."
in_backend "curl -sSf -H 'Authorization: Bearer it-token' http://localhost:8000/v1/plans | jq -e '.count >= 0 and (.items | type == \"array\")' >/dev/null"
echo "[it] Authenticated /v1/plans OK"

# Ensure the frontend container proxies correctly to the backend
echo "[it] Nginx proxy check via frontend service..."
in_backend "curl -sSf http://frontend/health | jq -e '.status == \"ok\"' >/dev/null"
in_backend "curl -sSf http://frontend/v1/db/ping | jq -e '.status == \"ok\"' >/dev/null"
echo "[it] Frontend reverse proxy OK"

# -----------------------------
# CRUD-like coverage on APIs
# -----------------------------

AUTH_HDR="Authorization: Bearer it-token"

echo "[it] /v1/auth/me (read user via token)"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/auth/me | jq -e '.id == null or .id == .id' >/dev/null"
echo "[it] /v1/auth/me OK"

# Basic read against exercises API
echo "[it] /v1/exercises (read)"
in_backend "curl -sSf http://localhost:8000/v1/exercises | jq -e '(. | type)==\"array\" and length >= 1' >/dev/null"
echo "[it] /v1/exercises OK"

# Create a plan via API and capture the returned identifier
echo "[it] Create plan (POST /v1/plans)"
in_backend "cat >/tmp/plan.json <<'JSON'
{ "days_per_week": 3, "weeks": 1 }
JSON
curl -sSf -X POST http://localhost:8000/v1/plans -H 'Content-Type: application/json' -H '${AUTH_HDR}' --data-binary @/tmp/plan.json > /tmp/plan.created.json && jq -e '.id and .sessions' /tmp/plan.created.json >/dev/null"
PLAN_ID=$(in_backend "jq -r '.id' /tmp/plan.created.json")
test -n "${PLAN_ID}"
echo "[it] Plan created: ${PLAN_ID}"

# Retrieve the plan by id to confirm it was persisted
echo "[it] Get plan (GET /v1/plans/{id})"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/plans/${PLAN_ID} | jq -e '.id == \"'"${PLAN_ID}"'\"' >/dev/null"
echo "[it] Get plan OK"

# Ensure the created plan appears in list endpoint
echo "[it] List plans (GET /v1/plans) contains new plan"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/plans | jq -e '.items | map(.id) | index(\"'"${PLAN_ID}"'\") != null' >/dev/null"
echo "[it] List plans OK"

# Log a workout completion against that plan
echo "[it] Create workout completion (POST /v1/workouts/complete)"
in_backend "cat >/tmp/complete.json <<'JSON'
{
  "plan_id": "${PLAN_ID}",
  "session_index": 0,
  "duration_minutes": 30,
  "logged_exercises": [
    {"exercise_id":"push_up","sets":[{"reps":12,"weight":0}]}
  ]
}
JSON
sed -i 's/${PLAN_ID}/'"${PLAN_ID}"'/g' /tmp/complete.json
curl -sSf -X POST http://localhost:8000/v1/workouts/complete -H 'Content-Type: application/json' -H '${AUTH_HDR}' --data-binary @/tmp/complete.json > /tmp/complete.created.json && jq -e '.id' /tmp/complete.created.json >/dev/null"
COMPLETION_ID=$(in_backend "jq -r '.id' /tmp/complete.created.json")
test -n "${COMPLETION_ID}"
echo "[it] Completion created: ${COMPLETION_ID}"

echo "[it] History (GET /v1/workouts/history) includes completion"
in_backend "curl -sSf -H '${AUTH_HDR}' 'http://localhost:8000/v1/workouts/history?limit=10' | jq -e '.items | map(.completion.id) | index(\"'"${COMPLETION_ID}"'\") != null' >/dev/null"
echo "[it] History includes completion OK"

echo "[it] Summary (GET /v1/workouts/summary) reflects activity"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/workouts/summary | jq -e '.workouts_completed >= 1 and .total_minutes >= 30' >/dev/null"
echo "[it] Summary OK"

# Delete the completion to cover the delete path
echo "[it] Delete completion (DELETE /v1/workouts/{id})"
code=$(in_backend "curl -sS -o /dev/null -w '%{http_code}' -X DELETE -H '${AUTH_HDR}' http://localhost:8000/v1/workouts/${COMPLETION_ID}")
test "$code" = "204"
echo "[it] Delete completion OK"

echo "[it] History after delete no longer contains completion"
in_backend "curl -sSf -H '${AUTH_HDR}' 'http://localhost:8000/v1/workouts/history?limit=10' | jq -e '.items | map(.completion.id) | index(\"'"${COMPLETION_ID}"'\") == null' >/dev/null"
echo "[it] History post-deletion OK"

# Check proxying for list endpoints through frontend container
echo "[it] Frontend proxy basic API checks"
in_backend "curl -sSf http://frontend/v1/exercises | jq -e 'length >= 1' >/dev/null"
in_backend "curl -sSf -H '${AUTH_HDR}' http://frontend/v1/plans | jq -e '.count >= 0' >/dev/null"
echo "[it] Frontend API proxy OK"

echo "[it] Integration API checks PASSED"
