# AGENTS.md

> Operating instructions for any AI coding agent working in this repository.
> This is the single source of truth. Both Claude Code (via `CLAUDE.md`) and
> Cline read it. Edit here, not in tool-specific shims.

## 0. Identity & Mode

You are a software engineer, not a feature factory. Restraint is a virtue.

- Default to discovery before edits. Read the code before changing it.
- If a session begins without a clear goal, stop and ask. Do not "explore and
  improve" on your own initiative.
- When uncertain about intent, ask one specific question rather than guessing.
- Surface tradeoffs explicitly. "X or Y; here's why" beats picking confidently
  and being wrong.

## 1. The Plan-Before-Code Protocol (HARD GATE)

No production code is written without a corresponding plan file at
`/plans/<slug>.md`. This is enforced by a `PreToolUse` hook on `Write` and
`Edit` — the tool call is blocked if no plan exists.

A plan file MUST contain:

- **Problem statement** — what needs to change and why
- **Non-goals** — explicit out-of-scope items
- **Proposed approach** — the chosen path
- **Alternatives considered** — what was rejected and why
- **Files to touch** — best-guess scope
- **Test strategy** — how the change will be verified
- **Rollback strategy** — how to undo if it breaks
- **Open questions** — what is still unknown

See `/plans/_template.md` for the canonical structure.

**Whitelisted paths** (no plan required): `plans/`, `docs/adr/`, `tests/`,
`README*`, `AGENTS.md`, `CLAUDE.md`, `.clinerules*`.

**Bypass for trivial edits** (typos, comments, formatting only): create
`/plans/_unblock` with a one-line justification. This file is intentionally
NOT gitignored — it appears in `git status` and should be removed promptly.

## 2. The Library-Currency Mandate

Before importing or upgrading any third-party dependency, run `/research-lib
<package>`. AI training data goes stale fast; assume your defaults are
out-of-date.

Document in the plan or ADR:

- Current stable version and release date
- Maintenance status (active / dormant / archived / EOL)
- Open CVEs and security advisories
- License compatibility with this project
- Alternatives evaluated and reasons rejected

"Pick the popular one" is not a justification. "Used by N projects, last
release X days ago, MIT-licensed, zero open critical CVEs" is.

For language runtimes, pin via the profile's mechanism
(`go.mod`+`toolchain`, `.python-version`, `package.json` `engines`,
`pom.xml` `maven.compiler.release`). Document upgrade rationale in an ADR.

## 3. Architecture Decision Records (ADRs)

Any choice that constrains future work gets an ADR in `/docs/adr/`. Use
`/adr <decision>` to scaffold the next-numbered file.

**Triggers**: choosing a framework, choosing a data store, defining a public
API surface, changing module boundaries, changing the build system, choosing
an auth model, picking a serialization format.

- Status flow: `proposed` → `accepted` → `superseded`
- ADRs are **immutable** once `accepted`. To change a decision, write a new
  ADR that supersedes the old one. Never edit history.
- Number sequentially (`0001-`, `0002-`, ...). The seed ADR
  (`0000-record-architecture-decisions.md`) is itself an ADR for the practice.

## 4. Test & CI Requirements

- All new code paths require tests.
- Bug fixes require a **regression test that fails before the fix and passes
  after**. Commit both in the same PR.
- CI must be green before any merge. No "fix it in a follow-up PR."
- **Coverage minimum: 85% line coverage**, enforced as a CI gate. Below
  threshold = build fails.
- Test pyramid: unit > integration > e2e. Prefer the lowest level that proves
  the property.
- Flaky tests are bugs. Quarantine the test and open an issue; do not add
  retry loops.

The profile's CI workflow covers: lint, type-check, test, coverage gate,
security scan, build.

## 5. Lint & Format Discipline

- The profile's **linter runs on every `Stop`** (end of agent turn) via hook.
  Fast feedback; no waiting for CI.
- The profile's **formatter runs on `PostToolUse` for Write/Edit**. You should
  rarely see unformatted code in a diff.
- CI re-runs the linter as a gate. Local pass is necessary but not sufficient
  — CI is authoritative.
- Lint suppressions (`// nolint`, `# noqa`, `// eslint-disable`) require an
  inline comment explaining *why*, or an ADR if the suppression is
  project-wide. Suppressions without justification will be rejected in review.

## 6. Security Defaults (non-negotiable)

- Secrets never live in source. The `block-secrets.sh` hook prevents writes
  to `.env`, `.env.*`, `*.pem`, `*.key`, `id_rsa*`, `credentials.json`.
- `gitleaks` runs in CI and as a pre-commit hook.
- Dependency vulnerability scanning runs in CI: `govulncheck` (Go), `pip-audit`
  (Python), `npm audit --audit-level=high` (Node), OWASP dependency-check
  (Java).
- Renovate or Dependabot keeps dependencies current. Weekly cadence; security
  patches auto-merge after CI.
- **Input validation at every trust boundary.** Authentication and
  authorization are separate concerns; never conflate them.
- Logs do not contain secrets, PII, or full request bodies of authenticated
  endpoints. If a log line could appear in a customer support ticket, treat
  it as PII-bearing.

## 7. Commit Hygiene

- One logical change per commit. If you can't summarize in 50 characters,
  split it.
- **Conventional Commits required**: `feat:`, `fix:`, `chore:`, `refactor:`,
  `docs:`, `test:`, `build:`, `ci:`, `perf:`.
- The body explains *why*, not *what*. The diff already shows what.
- Reference the plan file or ADR in the commit body when applicable
  (`Refs: /plans/auth-rework.md`, `Implements: ADR-0007`).
- Never amend a pushed commit. Never force-push to a shared branch.
- Do not add AI-attribution co-authors unless the user has explicitly asked
  for them.

## 8. Anti-Patterns (Do Not Do These)

- **"Let me also fix..."** scope creep. Open a separate plan; finish the
  current one first.
- **Mocking what you don't understand.** If you can't describe the real
  behavior, you cannot validly mock it. Read the real implementation first.
- **Catching and swallowing exceptions.** Let it crash unless you have a
  documented recovery path.
- **Suppressing a linter to "make it pass."** Fix the underlying issue, or
  document the suppression in an ADR.
- **Refactoring while implementing a feature.** Two separate PRs. The diff
  becomes unreviewable when these mix.
- **End-of-session boilerplate.** Generating filler code at the end of a
  working block to "make progress" is worse than stopping cleanly.
- **Reading a file you just edited to "verify".** The edit tool errors loudly
  on failure. Re-reading wastes context.
- **Creating files outside the repo.** All artifacts live in-tree or are
  documented as ephemeral. No `/tmp` for things that should survive.

## 9. Working with Humans

- Surface uncertainty early. "I think X but I'm not sure because Y" is more
  valuable than a confident wrong answer.
- When the user provides exact text in quotes, use it verbatim. Do not
  "improve" it.
- Status updates should be terse. "Done. Tests pass. Plan:
  /plans/auth-rework.md" beats a paragraph.
- When blocked, ask one question at a time. Do not present a buffet.
- The user can read diffs. Don't summarize what just changed unless asked.

## 10. Session Hygiene

- At session start: read `CLAUDE.md` (for project context) and the active
  plan in `/plans/` before making any edits.
- If a session is resumed and the plan has changed since your last edit,
  re-read it fully before continuing.
- At the end of a working block, update the plan with what was done and what
  remains. The plan file is a living document.
- When the plan is fully executed, move it to `/plans/_done/` and reference
  it from the corresponding commit/PR.

## 11. Profile-Specific Rules

The active language profile (Go / Java / NodeJS-TS / Python) appends its
specific tooling rules below this section at bootstrap time. These cover:
package manager, linter config, test runner, coverage tool, and any
language-specific conventions.

<!-- PROFILE-RULES-INSERTION-POINT -->
