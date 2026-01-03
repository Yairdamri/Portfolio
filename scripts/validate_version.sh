#!/usr/bin/env bash
set -euo pipefail

version_input="${1:-}"
if [[ -z "$version_input" ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

if [[ "$version_input" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  normalized="$version_input"
elif [[ "$version_input" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  normalized="v$version_input"
else
  echo "Version must be in X.Y.Z or vX.Y.Z format" >&2
  exit 1
fi

if git rev-parse "$normalized" >/dev/null 2>&1; then
  echo "Tag $normalized already exists" >&2
  exit 1
fi

echo "version=$normalized" >> "$GITHUB_OUTPUT"
