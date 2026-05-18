#!/usr/bin/env bash
# require-plan-bash.sh — PreToolUse hook for Bash
#
# Mirrors require-plan.sh for shell-based file creation. Triggers when the
# Bash command contains file-creating verbs (touch, tee, cp, mv) writing
# into the project. Skips read-only commands, git operations, package
# manager invocations, etc.
#
# Exit 0 = allow. Exit 2 = block.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Resolve project root
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(echo "$INPUT" | jq -r '.cwd // empty')}"
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$PWD"
fi

# Match file-creating patterns. Anchored to detect actual command verbs,
# not substrings (e.g. "git mv" is git, not the mv coreutil — git handled below).
needs_plan=0
case "$CMD" in
  # File-creating coreutils as the leading command
  touch\ *|*\ touch\ *) needs_plan=1 ;;
  *\>\ *|*\>\>\ *)      needs_plan=1 ;;   # shell redirection writes
  *\|\ tee\ *|*\|tee\ *) needs_plan=1 ;;
  tee\ *)                needs_plan=1 ;;
  cp\ *|*\ cp\ *)        needs_plan=1 ;;
  mv\ *|*\ mv\ *)        needs_plan=1 ;;
  mkdir\ *)              needs_plan=1 ;;
esac

# Always allow git commands (even git mv) — git operations are not raw
# file creation in the AGENTS.md sense; they're version-control state.
case "$CMD" in
  git\ *) needs_plan=0 ;;
esac

if [[ "$needs_plan" -eq 0 ]]; then
  exit 0
fi

# Allow if writing exclusively into whitelisted paths
case "$CMD" in
  *plans/*|*docs/adr/*|*tests/*|*test/*|*scripts/*|*.clinerules/*)
    # Heuristic: if the command mentions a whitelisted path, allow. This is
    # intentionally permissive — the strict gate is require-plan.sh on Edit/Write.
    exit 0
    ;;
esac

# Emergency escape hatch
if [[ -f "$PROJECT_DIR/plans/_unblock" ]]; then
  exit 0
fi

# Plan check
PLANS_DIR="$PROJECT_DIR/plans"
PLAN_COUNT=0
if [[ -d "$PLANS_DIR" ]]; then
  PLAN_COUNT=$(find "$PLANS_DIR" -maxdepth 1 -name '*.md' \
    ! -name '_template.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
fi

if [[ "$PLAN_COUNT" -eq 0 ]]; then
  cat <<EOF >&2
Blocked: bash command creates files but no plan file exists in /plans/.

Command was: $CMD

This project enforces the Plan-Before-Code Protocol (AGENTS.md §1).
Run /plan <slug> to scaffold a plan, or touch /plans/_unblock for a
trivial-edit bypass.
EOF
  exit 2
fi

exit 0
