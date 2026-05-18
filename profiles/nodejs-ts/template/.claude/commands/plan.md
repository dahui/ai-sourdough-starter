---
description: Scaffold a new plan file from the canonical template
argument-hint: <slug>
---

Scaffold a new plan file at `/plans/<slug>.md` from the canonical template.

Usage: `/plan <slug>` (slug should be kebab-case, e.g. `auth-rework`)

Steps:

1. Confirm the slug from the user input. If no slug provided, ask for one.
2. Check if `/plans/<slug>.md` already exists. If it does, ask whether to
   overwrite or pick a new slug.
3. Read `/plans/_template.md` for the canonical structure.
4. Create `/plans/<slug>.md` with the template, pre-filling the title from
   the slug.
5. Print the path of the created file and ask the user to populate the
   sections (Problem, Non-goals, Approach, Alternatives, Files to touch,
   Test strategy, Rollback, Open questions) before any production edits.

Do NOT begin editing production code in the same turn. The plan must be
populated and reviewed first.