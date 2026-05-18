#!/usr/bin/env bash
# stop-lint.sh — Stop hook
#
# Runs the profile's linter at the end of every agent turn. Fast feedback
# without waiting for CI. Discovers the profile from .starter-manifest.json
# (written at copier render time). If no profile is detected (e.g. in the
# starter repo itself), exits silently.
#
# Failures from the linter are reported back to the agent via stderr but
# do NOT block — the agent should see the errors and address them on the
# next turn.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
MANIFEST="$PROJECT_DIR/.starter-manifest.json"

if [[ ! -f "$MANIFEST" ]]; then
  exit 0
fi

PROFILE=$(jq -r '.profile // empty' "$MANIFEST" 2>/dev/null || true)
if [[ -z "$PROFILE" ]]; then
  exit 0
fi

cd "$PROJECT_DIR" || exit 0

case "$PROFILE" in
  go)
    if command -v golangci-lint >/dev/null 2>&1; then
      golangci-lint run --timeout=2m ./... 2>&1 || \
        echo "[stop-lint] golangci-lint reported issues; address before next turn." >&2
    fi
    ;;
  python)
    if command -v ruff >/dev/null 2>&1; then
      ruff check . 2>&1 || \
        echo "[stop-lint] ruff reported issues; address before next turn." >&2
    fi
    ;;
  nodejs-ts)
    if command -v pnpm >/dev/null 2>&1 && [[ -f package.json ]]; then
      pnpm -s lint 2>&1 || \
        echo "[stop-lint] pnpm lint reported issues; address before next turn." >&2
    fi
    ;;
  java)
    if command -v mvn >/dev/null 2>&1 && [[ -f pom.xml ]]; then
      mvn -q -B checkstyle:check 2>&1 || \
        echo "[stop-lint] checkstyle reported issues; address before next turn." >&2
    fi
    ;;
esac

exit 0
