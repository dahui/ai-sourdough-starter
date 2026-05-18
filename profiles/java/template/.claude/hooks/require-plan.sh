#!/usr/bin/env bash
# require-plan.sh — PreToolUse hook for Write|Edit
#
# Blocks file edits unless at least one non-template plan file exists in
# /plans/. Whitelisted paths bypass the gate. /plans/_unblock acts as an
# emergency escape hatch.
#
# Receives JSON on stdin with structure:
#   { "tool_input": { "file_path": "..." }, "cwd": "...", ... }
#
# Exit 0 = allow. Exit 2 = block with stderr message visible to Claude.

set -euo pipefail

INPUT=$(cat)

# Resolve target file path (may be relative or absolute)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Resolve project root: prefer $CLAUDE_PROJECT_DIR, fall back to cwd from stdin
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(echo "$INPUT" | jq -r '.cwd // empty')}"
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$PWD"
fi

# Whitelisted paths: never require a plan
case "$FILE_PATH" in
  */plans/*|*/docs/adr/*|*README*|*AGENTS.md|*CLAUDE.md|*/.clinerules/*|*/tests/*|*/test/*|*/scripts/*)
    exit 0
    ;;
esac

# Emergency escape hatch
if [[ -f "$PROJECT_DIR/plans/_unblock" ]]; then
  exit 0
fi

# Require at least one non-template, non-readme plan file
PLANS_DIR="$PROJECT_DIR/plans"
if [[ ! -d "$PLANS_DIR" ]]; then
  cat <<EOF >&2
Blocked: no /plans/ directory exists in this project.

This project enforces the Plan-Before-Code Protocol (AGENTS.md §1).
Run /plan <slug> to scaffold a plan, or create /plans/_unblock with a
one-line justification for a trivial-edit bypass.
EOF
  exit 2
fi

PLAN_COUNT=$(find "$PLANS_DIR" -maxdepth 1 -name '*.md' \
  ! -name '_template.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')

if [[ "$PLAN_COUNT" -eq 0 ]]; then
  cat <<EOF >&2
Blocked: no plan file exists in /plans/.

This project enforces the Plan-Before-Code Protocol (AGENTS.md §1). To
proceed:

  1. Run /plan <slug> to scaffold a plan file, OR
  2. Touch /plans/_unblock with a one-line justification for a trivial
     bypass (typos, comments, formatting only)

Whitelisted paths (no plan needed): plans/, docs/adr/, tests/, README*,
AGENTS.md, CLAUDE.md, .clinerules/, scripts/.
EOF
  exit 2
fi

exit 0
