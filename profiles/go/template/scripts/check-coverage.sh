#!/usr/bin/env bash
# check-coverage.sh — enforce a minimum line-coverage threshold.
#
# Usage: ./scripts/check-coverage.sh [cover.out] [threshold]
#
# Defaults: cover.out, 85
#
# Reads the coverage profile produced by `go test -coverprofile=...` and
# fails (exit 1) if the total line coverage is below the threshold.
#
# Excludes generated files matching the patterns in EXCLUDE_PATTERNS.

set -euo pipefail

COVER_FILE="${1:-cover.out}"
THRESHOLD="${2:-85}"

EXCLUDE_PATTERNS=(
  '/mock_'
  '_mock\.go'
  '\.pb\.go'
  '_generated\.go'
  # main.go is excluded by convention: entry-point code (signal handling,
  # logger setup, env parsing) is integration-tested via the binary, not
  # unit-tested. Move testable logic into internal/ packages instead and
  # cover it there. Remove this exclusion if your project's main.go has
  # non-trivial logic you want gated.
  '/main\.go:'
)

if [[ ! -f "$COVER_FILE" ]]; then
  echo "check-coverage: $COVER_FILE not found." >&2
  echo "  Run: go test -race -coverprofile=$COVER_FILE ./..." >&2
  exit 1
fi

# Build a filtered coverage profile
FILTERED=$(mktemp)
trap 'rm -f "$FILTERED"' EXIT

head -n 1 "$COVER_FILE" > "$FILTERED"

# Apply excludes
EXCLUDE_REGEX=$(IFS='|'; echo "${EXCLUDE_PATTERNS[*]}")
tail -n +2 "$COVER_FILE" | grep -vE "$EXCLUDE_REGEX" >> "$FILTERED" || true

# Total coverage from the filtered profile
TOTAL=$(go tool cover -func="$FILTERED" | awk '/^total:/ {print $3}' | tr -d '%')

if [[ -z "$TOTAL" ]]; then
  echo "check-coverage: could not parse total coverage." >&2
  exit 1
fi

# Compare as integer (truncate decimal)
TOTAL_INT=${TOTAL%.*}

echo "coverage: ${TOTAL}% (threshold: ${THRESHOLD}%)"

if (( TOTAL_INT < THRESHOLD )); then
  echo "" >&2
  echo "FAIL: coverage ${TOTAL}% is below threshold ${THRESHOLD}%." >&2
  echo "  Add tests or, if a code path is intentionally untestable, refactor" >&2
  echo "  to extract the untestable part behind a tested interface." >&2
  exit 1
fi

echo "OK: coverage meets threshold."
