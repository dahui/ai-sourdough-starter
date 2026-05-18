#!/usr/bin/env bash
# post-edit-format.sh — PostToolUse hook for Write|Edit
#
# Auto-formats the file that was just written, dispatching to the profile's
# formatter based on extension. Best-effort: never blocks; logs failures to
# stderr but exits 0.
#
# Designed for rendered projects (with a single active profile). In the
# starter repo itself, no formatter runs because the starter doesn't have
# an active language profile.

set -uo pipefail

INPUT=$(cat 2>/dev/null || true)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

format() {
  local cmd="$1"
  shift
  if command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" "$@" >/dev/null 2>&1 || echo "post-edit-format: $cmd exited non-zero on $FILE_PATH" >&2
  fi
}

case "$FILE_PATH" in
  *.go)
    format gofmt -w "$FILE_PATH"
    format goimports -w "$FILE_PATH"
    ;;
  *.py)
    format ruff format "$FILE_PATH"
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.md)
    if command -v biome >/dev/null 2>&1; then
      biome format --write "$FILE_PATH" >/dev/null 2>&1 || true
    elif command -v prettier >/dev/null 2>&1; then
      prettier --write "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
  *.java)
    if command -v google-java-format >/dev/null 2>&1; then
      google-java-format -i "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
