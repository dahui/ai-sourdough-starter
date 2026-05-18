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

For language runtimes, pin via the profile's mechanism. Document upgrade
rationale in an ADR.

## 3. Architecture Decision Records (ADRs)

Any choice that constrains future work gets an ADR in `/docs/adr/`. Use
`/adr <decision>` to scaffold the next-numbered file.

**Triggers**: choosing a framework, choosing a data store, defining a public
API surface, changing module boundaries, changing the build system, choosing
an auth model, picking a serialization format.

- Status flow: `proposed` → `accepted` → `superseded`
- ADRs are **immutable** once `accepted`. To change a decision, write a new
  ADR that supersedes the old one. Never edit history.
- Number sequentially (`0001-`, `0002-`, ...).

## 4. Test & CI Requirements

- All new code paths require tests.
- Bug fixes require a **regression test that fails before the fix and passes
  after**. Commit both in the same PR.
- CI must be green before any merge. No "fix it in a follow-up PR."
- **Coverage minimum: 85% line coverage**, enforced as a CI gate. Below
  threshold = build fails.
- Test pyramid: unit > integration > e2e.
- Flaky tests are bugs. Quarantine and open an issue; do not add retry loops.

## 5. Lint & Format Discipline

- The profile's **linter runs on every `Stop`** (end of agent turn) via hook.
- The profile's **formatter runs on `PostToolUse` for Write/Edit**.
- CI re-runs the linter as a gate.
- Lint suppressions require inline justification or an ADR if project-wide.

## 6. Security Defaults (non-negotiable)

- Secrets never live in source. The `block-secrets.sh` hook prevents writes
  to `.env`, `.env.*`, `*.pem`, `*.key`, `id_rsa*`, `credentials.json`.
- `gitleaks` runs in CI and as a pre-commit hook.
- Dependency vulnerability scanning runs in CI.
- Input validation at every trust boundary.
- Logs do not contain secrets, PII, or full request bodies of authenticated
  endpoints.

## 7. Commit Hygiene

- One logical change per commit. If you can't summarize in 50 characters, split.
- **Conventional Commits required**: `feat:`, `fix:`, `chore:`, `refactor:`,
  `docs:`, `test:`, `build:`, `ci:`, `perf:`.
- The body explains *why*, not *what*.
- Reference the plan file or ADR in the commit body when applicable.
- Never amend a pushed commit. Never force-push to a shared branch.
- Do not add AI-attribution co-authors unless the user explicitly asks for them.

## 8. Anti-Patterns (Do Not Do These)

- **"Let me also fix..."** scope creep — open a separate plan
- **Mocking what you don't understand** — read the real implementation first
- **Catching and swallowing exceptions** — let it crash unless you have
  documented recovery
- **Suppressing a linter to "make it pass"** — fix the issue or document it
- **Refactoring while implementing a feature** — two separate PRs
- **End-of-session boilerplate** — stop cleanly instead of filling
- **Reading a file you just edited to "verify"** — the edit tool errors loudly
- **Creating files outside the repo** — no `/tmp` for things that should
  survive

## 9. Working with Humans

- Surface uncertainty early.
- When the user provides exact text in quotes, use it verbatim.
- Status updates terse; the user can read diffs.
- One question at a time when blocked.

## 10. Session Hygiene

- At session start: read `CLAUDE.md` and the active plan before any edits.
- At the end of a working block, update the plan with what was done and what
  remains.
- When the plan is fully executed, move it to `/plans/_done/` and reference
  it from the corresponding commit/PR.

## 11. Profile-Specific Rules (Go)

This project uses the **Go** profile. Apply these rules in addition to the
universal ones above.

### Tooling

- **Compiler / toolchain**: Go {{ go_version }} (pinned in `go.mod` via
  `toolchain` directive). Do not upgrade without an ADR.
- **Linter**: `golangci-lint` with the config in `.golangci.yml`. Runs in CI
  and on every Stop.
- **Formatter**: `gofmt` + `goimports`. Runs on every PostToolUse.
- **Test runner**: standard `go test`. Assertions via `github.com/stretchr/testify`.
- **Coverage tool**: `go test -coverprofile=cover.out` + `axw/gocov` for
  reporting. `scripts/check-coverage.sh` enforces the 85% threshold.
- **Vulnerability scanner**: `govulncheck` (CI).
- **Dependency manager**: `go mod`. Pin minor versions; commit `go.sum`.

### Conventions

- **Module path**: `{{ module_path }}`
- **Layout**: `cmd/<binary>/main.go` for entry points,
  `internal/<package>/` for non-public packages,
  `pkg/<package>/` only when stable + public + worth exporting (default to
  `internal/`).
- **Errors**: wrap with `fmt.Errorf("doing X: %w", err)`. Use `errors.Is` /
  `errors.As` at call sites. Define error sentinels with `errors.New` (no
  `pkg/errors`).
- **Context**: every blocking function takes `ctx context.Context` as the
  first parameter. Never store contexts in structs.
- **Logging**: `log/slog` from stdlib. Structured logs only; no `fmt.Println`
  in production code.
- **Mocks**: prefer interfaces with hand-rolled fakes over mock-gen
  frameworks. If mocks become heavy, that's a design smell.

### Build, Test, Run

```bash
make build           # go build ./...
make test            # go test -race -coverprofile=cover.out ./...
make coverage        # ./scripts/check-coverage.sh
make lint            # golangci-lint run
make vuln            # govulncheck ./...
make ship-check      # everything; matches CI
```

### Anti-patterns specific to Go

- `interface{}` / `any` as a general escape hatch — usually means a missing
  generic or a poorly-chosen interface
- Returning a pointer from a function just so the caller can set a field —
  return the value
- `init()` functions doing real work — they run before `main` and break
  testability
- Naked returns in functions longer than 10 lines
- `panic` outside of `init()` and truly unrecoverable startup conditions
