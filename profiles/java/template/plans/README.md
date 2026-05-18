# /plans/

This directory holds plan files. AGENTS.md §1 requires a plan file to exist
before any production code is written; the plan-gate hook
(`.claude/hooks/require-plan.sh`) enforces this on `Write` and `Edit` calls.

## Conventions

- **One plan per substantive change.** A plan is a feature, a refactor, a
  migration, or a non-trivial bug investigation. Not every commit needs its
  own plan.
- **Naming**: kebab-case slug, e.g. `auth-rework.md`, `migrate-to-postgres.md`.
- **Lifecycle**:
  - Active plans live at `/plans/<slug>.md`
  - Completed plans move to `/plans/_done/<slug>.md` (referenced from the
    final commit/PR)
- **Template**: copy `_template.md` for the canonical structure.

## Files in this directory

- `_template.md` — the canonical plan structure. Do not delete; the
  `/plan` slash command reads it.
- `README.md` — this file.
- `_unblock` — if present, bypasses the plan-gate hook. **Not gitignored**
  — appears in `git status` as a visible reminder. Use sparingly.

## When the hook blocks you

The hook prints a message explaining what to do. Most commonly:

```
Run /plan <slug> to scaffold a plan file
```

For truly trivial edits (typos, formatting, comments only), you may use
`/unblock <one-line justification>` to create `_unblock`. Remove `_unblock`
when done.
