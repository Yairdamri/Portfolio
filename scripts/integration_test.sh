#!/usr/bin/env bash
set -euo pipefail

BASE="${BASE:-http://localhost:8000}"
EMAIL="ci+$(date +%s)@example.com"
PASS="pass1234"
NAME="CI Runner"

# Helper: perform curl, capturing HTTP status and body
curl_json() {
  local method="$1"; shift
  local url="$1"; shift
  local data="${1:-}"; shift || true
  local auth_header="${1:-}"; shift || true
  local tmp_body
  tmp_body=$(mktemp)
  local http
  if [ -n "$data" ]; then
    http=$(curl -s -o "$tmp_body" -w "%{http_code}" -X "$method" -H 'Content-Type: application/json' $auth_header -d "$data" "$url" || true)
  else
    http=$(curl -s -o "$tmp_body" -w "%{http_code}" -X "$method" $auth_header "$url" || true)
  fi
  echo "$http" "$tmp_body"
}

# Register
read -r HTTP TMP < <(curl_json POST "$BASE/v1/auth/register" "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"name\":\"$NAME\"}")
BODY=$(cat "$TMP")
if [ "$HTTP" = "201" ]; then
  TOKEN=$(echo "$BODY" | sed -n 's/.*"token":"\([^"]\+\)".*/\1/p')
else
  # If already exists, login
  read -r HTTP TMP < <(curl_json POST "$BASE/v1/auth/login" "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}")
  BODY=$(cat "$TMP")
  if [ "$HTTP" != "200" ]; then
    echo "Auth failed: HTTP $HTTP Body: $BODY" >&2
    exit 1
  fi
  TOKEN=$(echo "$BODY" | sed -n 's/.*"token":"\([^"]\+\)".*/\1/p')
fi
if [ -z "${TOKEN:-}" ]; then
  echo "Failed to retrieve token" >&2
  echo "$BODY" >&2
  exit 1
fi
AUTH="-H Authorization: Bearer\ $TOKEN"

echo "Token acquired. Testing API..."

# Health
curl -fsS "$BASE/health" >/dev/null

# Create plan
read -r HTTP TMP < <(curl_json POST "$BASE/v1/plans" "{\"days_per_week\":3,\"weeks\":1}" "$AUTH")
BODY=$(cat "$TMP")
if [ "$HTTP" != "201" ]; then
  echo "Create plan failed: HTTP $HTTP Body: $BODY" >&2
  exit 1
fi
PLAN_ID=$(echo "$BODY" | sed -n 's/.*"id":"\([^"]\+\)".*/\1/p')
[ -n "$PLAN_ID" ] || { echo "No plan id in response" >&2; exit 1; }

# Complete workout
read -r HTTP TMP < <(curl_json POST "$BASE/v1/workouts/complete" "{\"plan_id\":\"$PLAN_ID\",\"session_index\":0,\"duration_minutes\":30,\"logged_exercises\":[{\"exercise_id\":\"push_up\",\"sets\":[{\"reps\":10,\"weight\":0}]}]}" "$AUTH")
if [ "$HTTP" != "201" ]; then
  echo "Complete workout failed: HTTP $HTTP" >&2
  cat "$TMP" >&2
  exit 1
fi

# Weekly summary
read -r HTTP TMP < <(curl_json GET "$BASE/v1/workouts/summary" "" "$AUTH")
if [ "$HTTP" != "200" ]; then
  echo "Summary failed: HTTP $HTTP" >&2
  cat "$TMP" >&2
  exit 1
fi

# History
read -r HTTP TMP < <(curl_json GET "$BASE/v1/workouts/history?limit=10" "" "$AUTH")
if [ "$HTTP" != "200" ]; then
  echo "History failed: HTTP $HTTP" >&2
  cat "$TMP" >&2
  exit 1
fi

# Plans list
read -r HTTP TMP < <(curl_json GET "$BASE/v1/plans" "" "$AUTH")
if [ "$HTTP" != "200" ]; then
  echo "List plans failed: HTTP $HTTP" >&2
  cat "$TMP" >&2
  exit 1
fi

# Get plan by id
read -r HTTP TMP < <(curl_json GET "$BASE/v1/plans/$PLAN_ID" "" "$AUTH")
if [ "$HTTP" != "200" ]; then
  echo "Get plan failed: HTTP $HTTP" >&2
  cat "$TMP" >&2
  exit 1
fi

echo "Integration tests OK"
