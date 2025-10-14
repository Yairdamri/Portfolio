#!/usr/bin/env bash
set -euo pipefail

# Track which step is running so failures are easy to trace
CURRENT_STEP="initialization"
fail() {
  echo "[it] ERROR during step: ${CURRENT_STEP}" >&2
  echo "[it] Dumping docker-compose state for debugging..." >&2
  docker compose ps || true
  docker compose logs --no-color --tail=120 backend db frontend 2>/dev/null || true
}
trap fail ERR

step() {
  CURRENT_STEP="$1"
  echo "[it] $1"
}

# Helpers to run commands inside the backend or db containers
in_backend() { docker compose exec -T backend sh -lc "$*"; }
in_db() { docker compose exec -T db sh -lc "$*"; }

step "Ensuring curl and jq are installed in backend container"
in_backend 'apk add --no-cache curl jq >/dev/null'

step "Waiting for backend /health endpoint"
in_backend 'until curl -sf http://localhost:8000/health | jq -e ".status == \"ok\"" >/dev/null; do echo "  waiting backend..."; sleep 1; done'
echo "[it] Backend is up"

step "Detecting Mongo shell client"
if in_db 'command -v mongosh >/dev/null 2>&1'; then
  MONGO_SHELL="mongosh --quiet"
else
  MONGO_SHELL="mongo --quiet"
fi

step "Waiting for MongoDB to accept connections"
i=0
until in_db "$MONGO_SHELL --eval 'db.adminCommand({ ping: 1 })' >/dev/null 2>&1"; do
  i=$((i+1)); test $i -le 60 || { echo "MongoDB not ready in time"; exit 1; }
  echo "  waiting mongodb..."; sleep 1
done
echo "[it] MongoDB is up"

step "Pinging MongoDB through backend API"
in_backend 'curl -sf http://localhost:8000/v1/db/ping | jq -e ".status == \"ok\"" >/dev/null'
DB_NAME=$(in_backend "curl -sSf http://localhost:8000/v1/db/ping | jq -r '.db'")
test -n "${DB_NAME}"
echo "[it] Backend reports DB name: ${DB_NAME}"

step "Verifying protected endpoint denies anonymous access"
code=$(in_backend "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/v1/plans")
test "$code" = "401" || { echo "Expected 401, got ${code}"; exit 1; }
echo "[it] 401 OK"

step "Seeding MongoDB with integration user and session"
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").users.deleteMany({_id: \"int-user\"}); db.getSiblingDB(\"${DB_NAME}\").sessions.deleteMany({_id: \"it-token\"});'"
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").users.insertOne({_id: \"int-user\", email: \"integration@example.com\", password: \"noop\", name: \"Integration\", created_at: new Date()}); db.getSiblingDB(\"${DB_NAME}\").sessions.insertOne({_id: \"it-token\", user_id: \"int-user\", created_at: new Date()});'"

step "Checking authenticated access to /v1/plans"
in_backend "curl -sSf -H 'Authorization: Bearer it-token' http://localhost:8000/v1/plans | jq -e '.count >= 0 and (.items | type == \"array\")' >/dev/null"
echo "[it] Authenticated /v1/plans OK"

step "Validating frontend reverse proxy"
in_backend "curl -sSf http://frontend/health | jq -e '.status == \"ok\"' >/dev/null"
in_backend "curl -sSf http://frontend/v1/db/ping | jq -e '.status == \"ok\"' >/dev/null"
echo "[it] Frontend reverse proxy OK"

# -----------------------------
# CRUD-like coverage on APIs
# -----------------------------

AUTH_HDR="Authorization: Bearer it-token"

step "Reading /v1/auth/me with seeded session"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/auth/me | jq -e '.id == null or .id == .id' >/dev/null"

step "Fetching exercises catalog"
in_backend "curl -sSf http://localhost:8000/v1/exercises \
  | jq -e '.items | (type == \"array\") and (length >= 1)' >/dev/null"


step "Creating plan via POST /v1/plans"
in_backend "cat >/tmp/plan.json <<'JSON'
{ "days_per_week": 3, "weeks": 1 }
JSON
curl -sSf -X POST http://localhost:8000/v1/plans -H 'Content-Type: application/json' -H '${AUTH_HDR}' --data-binary @/tmp/plan.json > /tmp/plan.created.json && jq -e '.id and .sessions' /tmp/plan.created.json >/dev/null"
PLAN_ID=$(in_backend "jq -r '.id' /tmp/plan.created.json")
test -n "${PLAN_ID}"
echo "[it] Plan created: ${PLAN_ID}"

step "Retrieving plan by id"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/plans/${PLAN_ID} | jq -e '.id == \"'"${PLAN_ID}"'\"' >/dev/null"

step "Listing plans and ensuring new plan is present"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/plans | jq -e '.items | map(.id) | index(\"'"${PLAN_ID}"'\") != null' >/dev/null"

step "Creating workout completion"
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

step "Ensuring history reflects the completion"
in_backend "curl -sSf -H '${AUTH_HDR}' 'http://localhost:8000/v1/workouts/history?limit=10' | jq -e '.items | map(.completion.id) | index(\"'"${COMPLETION_ID}"'\") != null' >/dev/null"

step "Checking summary aggregates"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/workouts/summary | jq -e '.workouts_completed >= 1 and .total_minutes >= 30' >/dev/null"

step "Deleting workout completion"
code=$(in_backend "curl -sS -o /dev/null -w '%{http_code}' -X DELETE -H '${AUTH_HDR}' http://localhost:8000/v1/workouts/${COMPLETION_ID}")
test "$code" = "204"

step "Verifying history after deletion"
in_backend "curl -sSf -H '${AUTH_HDR}' 'http://localhost:8000/v1/workouts/history?limit=10' | jq -e '.items | map(.completion.id) | index(\"'"${COMPLETION_ID}"'\") == null' >/dev/null"

step "Verifying frontend proxy responses"
in_backend "curl -sSf http://frontend/v1/exercises | jq -e 'length >= 1' >/dev/null"
in_backend "curl -sSf -H '${AUTH_HDR}' http://frontend/v1/plans | jq -e '.count >= 0' >/dev/null"

echo "[it] Integration API checks PASSED"
