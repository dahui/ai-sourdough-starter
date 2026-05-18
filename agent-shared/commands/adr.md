---
description: Scaffold the next-numbered Architecture Decision Record
argument-hint: <decision-title>
---

Scaffold the next-numbered Architecture Decision Record in `/docs/adr/`.

Usage: `/adr <decision-title>` (kebab-case, e.g. `/adr choose-postgres-over-mysql`)

Steps:

1. Confirm the decision title from user input. If none provided, ask.
2. List existing files in `/docs/adr/` matching `NNNN-*.md`. Find the
   highest number and increment by 1, zero-padded to 4 digits.
3. Read `/docs/adr/0000-record-architecture-decisions.md` as the template.
4. Create `/docs/adr/NNNN-<title>.md` with:
   - Title: "ADR-NNNN: <Decision Title>"
   - Status: proposed
   - Date: today's date (YYYY-MM-DD)
   - Context section (empty, prompts user to fill)
   - Decision section (empty)
   - Consequences section (positive, negative, neutral subsections, empty)
   - Alternatives Considered section (empty)
5. Print the path and remind the user that ADRs are immutable once status
   becomes `accepted`. To change a decision later, write a new ADR that
   supersedes this one.

Do NOT mark an ADR as `accepted` automatically — that requires explicit
user action after review.
