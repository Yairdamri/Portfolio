#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  echo "No SLACK_WEBHOOK_URL set, skipping Slack notification"
  exit 0
fi

icon() {
  local status="${1:-}"
  if [[ "$status" == "success" ]]; then
    echo "V"
  else
    echo "X"
  fi
}

run_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}"

message=$(cat <<EOF
CI/CD results:
unit_backend: $(icon "${UNIT_BACKEND:-}") (${UNIT_BACKEND:-unknown})
unit_frontend: $(icon "${UNIT_FRONTEND:-}") (${UNIT_FRONTEND:-unknown})
integration: $(icon "${INTEGRATION:-}") (${INTEGRATION:-unknown})
e2e: $(icon "${E2E:-}") (${E2E:-unknown})
version_tag: $(icon "${VERSION_TAG:-}") (${VERSION_TAG:-unknown})
build_images: $(icon "${BUILD_IMAGES:-}") (${BUILD_IMAGES:-unknown})
deploy: $(icon "${DEPLOY:-}") (${DEPLOY:-unknown})
run: ${run_url}
EOF
)

payload=$(SLACK_TEXT="$message" python3 - <<'PY'
import json
import os

print(json.dumps({"text": os.environ["SLACK_TEXT"]}))
PY
)

curl -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_WEBHOOK_URL"
