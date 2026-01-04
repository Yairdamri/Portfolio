#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${K8S_REPO_URL:-}" || -z "${K8S_REPO_TOKEN:-}" || -z "${VERSION:-}" ]]; then
  echo "K8S_REPO_URL, K8S_REPO_TOKEN, and VERSION are required" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
url_no_proto=${K8S_REPO_URL#https://}
git clone "https://x-access-token:${K8S_REPO_TOKEN}@${url_no_proto}" "$tmpdir"
cd "$tmpdir"

chart_dir="${K8S_CHART_DIR:-charts/workout-stack}"
if [ ! -f "${chart_dir}/Chart.yaml" ] || [ ! -f "${chart_dir}/values.yaml" ]; then
  echo "Expected Chart.yaml/values.yaml under ${chart_dir}" >&2
  exit 1
fi

clean="${VERSION#v}"
sed -i "s/^appVersion:.*/appVersion: ${clean}/" "${chart_dir}/Chart.yaml"
sed -i -E "s/^([[:space:]]*tag:).*/\1 ${VERSION}/" "${chart_dir}/values.yaml"

git config user.email "ci@github"
git config user.name "github-actions"
git commit -am "chore: bump helm chart to ${VERSION}" || exit 0
git push
