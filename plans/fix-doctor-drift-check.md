# Plan: Fix doctor's sync-commands drift check (false-positive on untracked files)

## Problem statement

`bin/doctor`'s "sync-commands produces no drift" check uses
`git status --porcelain .claude/commands .clinerules/workflows` and
treats *any* porcelain output as drift. Porcelain output for untracked
files (lines starting with `??`) is conflated with actual modifications
(`M`, ` M`, `D`, etc.).

Observed symptom: on a freshly-initialized git repo where these
directories have never been committed, doctor FAILs even though
sync-commands ran and produced no changes. Reported by Jeff right
after running `git init` for the first time on the starter.

## Non-goals

- Restructuring doctor; just fix this one check
- Adding new checks (separate plan)
- Changing what counts as "drift" semantically — still mean "tracked
  file modified by sync-commands"

## Proposed approach

Filter `??` (untracked) entries out of the porcelain output before
checking emptiness. Only modifications, deletions, and renames of
*tracked* files count as drift.

```bash
DRIFT=$(git status --porcelain .claude/commands .clinerules/workflows 2>/dev/null \
        | grep -v '^??' || true)
if [[ -z "$DRIFT" ]]; then
  # no drift
```

The `|| true` handles `grep -v` returning exit 1 when all lines start
with `??` (which is exactly the false-positive case we're fixing).

## Alternatives considered

1. **Use `git diff --quiet` instead of `git status --porcelain`**:
   cleaner semantically (diff doesn't include untracked files at all),
   but doesn't catch staged-but-not-committed changes. Rejected — we
   want to catch any in-flight modifications, not just unstaged ones.
2. **Use `git ls-files --modified`**: doesn't catch staged deletions
   or renames. Rejected — same reason.
3. **Use `git diff HEAD`**: catches everything (staged + unstaged
   changes vs the last commit). Would FAIL on a fresh repo with no
   commits (`HEAD` doesn't exist). Rejected.

Porcelain + `??` filter handles all four states correctly:

| State | Porcelain line | After filter | Counted as drift? |
|---|---|---|---|
| Untracked | `?? path` | filtered out | no |
| Unstaged modification | ` M path` | kept | yes |
| Staged modification | `M  path` | kept | yes |
| Staged + unstaged | `MM path` | kept | yes |
| Deletion | ` D path` or `D  path` | kept | yes |
| Rename | `R  old -> new` | kept | yes |

## Files to touch

- `bin/doctor` — one line in the sync-commands self-check section

## Test strategy

- Run `bin/doctor` after the change with the current repo state
  (which earlier produced the false-positive). Expect PASS.
- Manual verification of the filter logic:
  ```bash
  # Simulate drift: modify a synced file
  echo " " >> .claude/commands/plan.md
  bin/doctor   # expect FAIL with the modification detected
  git checkout .claude/commands/plan.md  # restore
  ```

## Rollback strategy

Single-line revert. The change is purely additive (adding a grep
filter); no semantic behavior changes outside the fix.

## Open questions

None.
