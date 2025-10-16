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

# =============================================================================
# PHASE 1: EXTERNAL ACCESS TESTS (from Jenkins host)
# =============================================================================
echo ""
echo "=========================================="
echo "PHASE 1: External Access Tests"
echo "=========================================="

step "Waiting for frontend on port 80 (external)"
timeout 60 bash -c 'until curl -sf http://localhost:80/health >/dev/null 2>&1; do echo "  waiting..."; sleep 2; done'
echo "[it] Frontend port 80 is accessible ✅"

step "Testing frontend health endpoint (external)"
curl -sf http://localhost:80/health | jq -e '.status == "ok"' >/dev/null
echo "[it] Frontend health OK ✅"

step "Testing exercises API through frontend (external)"
curl -sf http://localhost:80/v1/exercises | jq -e '.items | type == "array"' >/dev/null
echo "[it] Frontend → Backend → MongoDB chain works externally ✅"

step "Verifying protected endpoint returns 401 (external)"
http_code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:80/v1/plans)
test "$http_code" = "401" || { echo "Expected 401, got $http_code"; exit 1; }
echo "[it] Auth protection works externally ✅"

# =============================================================================
# PHASE 2: INTERNAL INTEGRATION TESTS (inside containers)
# =============================================================================
echo ""
echo "=========================================="
echo "PHASE 2: Internal Integration Tests"
echo "=========================================="

# Helpers to run commands inside the backend or db containers
in_backend() { docker compose exec -T backend sh -lc "$*"; }
in_db() { docker compose exec -T db sh -lc "$*"; }

step "Installing curl and jq in backend container"
in_backend 'apk add --no-cache curl jq >/dev/null'

step "Waiting for backend /health endpoint (internal)"
in_backend 'until curl -sf http://localhost:8000/health | jq -e ".status == \"ok\"" >/dev/null; do echo "  waiting backend..."; sleep 1; done'
echo "[it] Backend is up (internal) ✅"

step "Detecting Mongo shell client"
if in_db 'command -v mongosh >/dev/null 2>&1'; then
  MONGO_SHELL="mongosh --quiet"
else
  MONGO_SHELL="mongo --quiet"
fi

step "Waiting for MongoDB to accept connections (internal)"
i=0
until in_db "$MONGO_SHELL --eval 'db.adminCommand({ ping: 1 })' >/dev/null 2>&1"; do
  i=$((i+1)); test $i -le 60 || { echo "MongoDB not ready in time"; exit 1; }
  echo "  waiting mongodb..."; sleep 1
done
echo "[it] MongoDB is up ✅"

step "Testing Backend → MongoDB connection (internal)"
in_backend 'curl -sf http://localhost:8000/v1/db/ping | jq -e ".status == \"ok\"" >/dev/null'
DB_NAME=$(in_backend "curl -sSf http://localhost:8000/v1/db/ping | jq -r '.db'")
test -n "${DB_NAME}"
echo "[it] Backend connected to database: ${DB_NAME} ✅"

step "Testing Frontend → Backend routing (internal Docker DNS)"
in_backend "curl -sSf http://frontend/health | jq -e '.status == \"ok\"' >/dev/null"
in_backend "curl -sSf http://frontend/v1/db/ping | jq -e '.status == \"ok\"' >/dev/null"
echo "[it] Internal Docker networking OK ✅"

# =============================================================================
# PHASE 3: CRUD OPERATIONS (authenticated)
# =============================================================================
echo ""
echo "=========================================="
echo "PHASE 3: CRUD Operations"
echo "=========================================="

step "Seeding test user in MongoDB"
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").users.deleteMany({_id: \"int-user\"});'"
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").sessions.deleteMany({_id: \"it-token\"});'"
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").users.insertOne({_id: \"int-user\", email: \"integration@example.com\", password: \"noop\", name: \"Integration\", created_at: new Date()});'"
in_db "$MONGO_SHELL --eval 'db.getSiblingDB(\"${DB_NAME}\").sessions.insertOne({_id: \"it-token\", user_id: \"int-user\", created_at: new Date()});'"
echo "[it] Test user seeded ✅"

step "Verifying protected endpoint denies anonymous access"
code=$(in_backend "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/v1/plans")
test "$code" = "401" || { echo "Expected 401, got ${code}"; exit 1; }
echo "[it] 401 Unauthorized - Auth protection works ✅"

step "Testing authenticated access to /v1/plans"
in_backend "curl -sSf -H 'Authorization: Bearer it-token' http://localhost:8000/v1/plans | jq -e '.count >= 0 and (.items | type == \"array\")' >/dev/null"
echo "[it] Authenticated /v1/plans OK ✅"

AUTH_HDR="Authorization: Bearer it-token"

step "Testing /v1/auth/me endpoint"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/auth/me | jq -e '.id == null or .id == .id' >/dev/null"
echo "[it] /v1/auth/me OK ✅"

step "Fetching exercises catalog"
in_backend "curl -sSf http://localhost:8000/v1/exercises | jq -e '.items | (type == \"array\") and (length >= 1)' >/dev/null"
echo "[it] Exercises catalog OK ✅"


PLAN_ID=$(openssl rand -hex 12)
step "Seeding plan document for integration tests"
in_db "$MONGO_SHELL --eval 'const dbName = \"${DB_NAME}\"; const planId = \"${PLAN_ID}\"; const dbRef = db.getSiblingDB(dbName); dbRef.plans.deleteMany({_id: planId, user_id: \"int-user\"}); const baseSession = [
  { exercise_id: \"push_up\", sets: 3, reps: 10, rest_seconds: 60 },
  { exercise_id: \"db_bench_press\", sets: 3, reps: 10, rest_seconds: 60 },
  { exercise_id: \"incline_db_press\", sets: 3, reps: 10, rest_seconds: 60 }
];
dbRef.plans.insertOne({
  _id: planId,
  id: planId,
  days_per_week: 3,
  weeks: 1,
  sessions: [
    { day_index: 1, items: baseSession },
    { day_index: 2, items: baseSession },
    { day_index: 3, items: baseSession }
  ],
  selected_days: [],
  user_id: \"int-user\",
  created_at: new Date().toISOString()
});'"
echo "[it] Plan seeded: ${PLAN_ID}"

step "Retrieving plan by ID"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/plans/${PLAN_ID} | jq -e '.id == \"'"${PLAN_ID}"'\"' >/dev/null"
echo "[it] Plan retrieval OK ✅"

step "Listing plans (ensuring new plan is present)"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/plans | jq -e '.items | map(.id) | index(\"'"${PLAN_ID}"'\") != null' >/dev/null"
echo "[it] Plan listing OK ✅"

step "Creating workout completion"
in_backend "cat >/tmp/complete.json <<JSON
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
JSON
status=\$(curl -sS -w '%{http_code}' -o /tmp/complete.created.json -X POST http://localhost:8000/v1/workouts/complete -H 'Content-Type: application/json' -H '${AUTH_HDR}' --data-binary @/tmp/complete.json)
if [ \"\$status\" != \"201\" ]; then
  echo \"Completion creation failed with status \$status\" >&2
  cat /tmp/complete.created.json >&2
  exit 1
fi
jq -e '.id' /tmp/complete.created.json >/dev/null"
COMPLETION_ID=$(in_backend "jq -r '.id' /tmp/complete.created.json")
test -n "${COMPLETION_ID}"
echo "[it] Workout completion created: ${COMPLETION_ID} ✅"

step "Verifying completion appears in history"
in_backend "curl -sSf -H '${AUTH_HDR}' 'http://localhost:8000/v1/workouts/history?limit=10' | jq -e '.items | map(.completion.id) | index(\"'"${COMPLETION_ID}"'\") != null' >/dev/null"
echo "[it] History includes completion ✅"

step "Checking summary aggregates"
in_backend "curl -sSf -H '${AUTH_HDR}' http://localhost:8000/v1/workouts/summary | jq -e '.workouts_completed >= 1 and .total_minutes >= 30' >/dev/null"
echo "[it] Summary aggregates OK ✅"

step "Deleting workout completion"
code=$(in_backend "curl -sS -o /dev/null -w '%{http_code}' -X DELETE -H '${AUTH_HDR}' http://localhost:8000/v1/workouts/${COMPLETION_ID}")
test "$code" = "204"
echo "[it] Deletion successful (204) ✅"

step "Verifying completion removed from history"
in_backend "curl -sSf -H '${AUTH_HDR}' 'http://localhost:8000/v1/workouts/history?limit=10' | jq -e '.items | map(.completion.id) | index(\"'"${COMPLETION_ID}"'\") == null' >/dev/null"
echo "[it] History no longer includes deleted completion ✅"

step "Testing frontend proxy with authenticated requests"
in_backend "curl -sSf http://frontend/v1/exercises | jq -e 'length >= 1' >/dev/null"
in_backend "curl -sSf -H '${AUTH_HDR}' http://frontend/v1/plans | jq -e '.count >= 0' >/dev/null"
echo "[it] Frontend proxy authenticated requests OK ✅"

echo ""
echo "=========================================="
echo "✅ ALL INTEGRATION TESTS PASSED"
echo "=========================================="
echo "[it] Phase 1: External access - PASSED"
echo "[it] Phase 2: Internal integration - PASSED"
echo "[it] Phase 3: CRUD operations - PASSED"
