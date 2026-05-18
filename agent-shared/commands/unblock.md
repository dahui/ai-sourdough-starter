---
description: Create /plans/_unblock with a justification — bypasses plan-gate
argument-hint: <one-line-justification>
---

Create `/plans/_unblock` with a one-line justification, temporarily
bypassing the plan-gate hook for trivial edits.

Usage: `/unblock <one-line justification>`

Steps:

1. Confirm the justification from user input. If empty, refuse and ask.
2. The justification must describe a trivial edit (typo, comment,
   formatting). If it sounds like substantive work, refuse and direct the
   user to run `/plan` instead.
3. Write `/plans/_unblock` containing:
   ```
   Unblocked at: <ISO 8601 timestamp>
   Justification: <user's one-line>
   ```
4. Print a reminder:
   - The `_unblock` file is NOT gitignored — it will appear in `git status`.
   - Remove it after the trivial edit is complete (`rm plans/_unblock`).
   - Leaving it in place permanently disables the plan-gate for everyone.

This command is intentionally friction-y. The plan-gate is the
project's primary discipline; bypasses should be rare and short-lived.
