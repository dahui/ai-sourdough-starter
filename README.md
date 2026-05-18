# ai-sourdough-starter

> A *starter culture* for AI-assisted software projects.
> Drop it into a new project and you get planning, library-currency checks,
> CI, coverage gates, ADRs, and security defaults — enforced by hooks,
> not by goodwill.

[![ci](https://github.com/dahui/ai-sourdough-starter/actions/workflows/test-rendering.yml/badge.svg)](https://github.com/dahui/ai-sourdough-starter/actions/workflows/test-rendering.yml)

## Why

AI coding tools, left to their defaults, produce ad-hoc commits. They jump
to code without a plan. They pick libraries from stale training data. They
"forget" to add tests. They suppress lint errors to make CI pass. They mix
refactors and features in unreviewable diffs.

This starter installs a small set of files and hooks that, once in place,
*enforce* discipline. The plan-gate hook will literally block edits to
production files if no plan exists. The coverage gate will fail CI under
85%. The library-currency mandate makes "pick the popular one" insufficient
as a justification.

It works for both **Claude Code** (with hook-level enforcement) and **Cline**
(with `.clinerules/`-based discipline and `AGENTS.md` as the universal
source of truth).

## Quick start

```bash
# Clone the starter, then render the profile you want into a new dir.
# (copier's CLI doesn't navigate into a subdirectory of a remote
# template, so a local clone is the simplest entry point.)
git clone --depth 1 --branch v0.1.0 https://github.com/dahui/ai-sourdough-starter
copier copy --trust ai-sourdough-starter/profiles/go ./my-go-service
```

The destination directory IS the project root — files land directly
in `./my-go-service/` (no nested subdirectory).

Profiles available at v0.1.0:

| Profile      | Toolchain                                              |
|--------------|--------------------------------------------------------|
| `go`         | go test + testify + golangci-lint + govulncheck        |
| `java`       | Maven + JUnit 5 + jacoco + spotless + OWASP dep-check  |
| `nodejs-ts`  | pnpm + tsc + biome + vitest + c8                       |
| `python`     | uv + ruff + mypy + pytest + pytest-cov + pip-audit     |

All profiles enforce: **85% line coverage minimum**, lint on every Stop,
plan-gate on Write/Edit, secrets denylist, conventional commits, ADR
discipline.

## What you get

```
<your-project>/
├── AGENTS.md                # universal agent rules (source of truth)
├── CLAUDE.md                # @imports AGENTS.md + project-specific notes
├── .clinerules/             # Cline-specific addenda + workflows
├── .claude/
│   ├── settings.json        # hooks + permission denylist (enforces rules)
│   ├── agents/              # architect, researcher, library-currency, reviewer, ci-bootstrapper
│   ├── commands/            # /plan, /research-lib, /architect, /adr, /review, /ship-it, ...
│   └── hooks/               # require-plan.sh, block-secrets.sh, ...
├── .github/workflows/       # CI: lint, test, coverage, security
├── docs/adr/                # architecture decision records
├── plans/                   # plan files (plan-gate reads these)
├── scripts/                 # helper scripts (coverage gate, etc.)
└── (language-specific files for your chosen profile)
```

## Core ideas

1. **AGENTS.md is the contract.** Universal rules for every AI agent
   working in the repo. Cline reads it natively; Claude Code reads it via
   `CLAUDE.md`. One file to edit, two tools enforced.

2. **Hooks turn rules into reality.** Claude Code's `PreToolUse` hooks can
   hard-block edits. The starter ships hooks for:
   - **Plan-gate**: `Write`/`Edit` blocked unless `/plans/<slug>.md` exists
   - **Secrets**: writes to `.env`, `*.pem`, `*.key` etc. blocked
   - **Format**: `gofmt` / `ruff format` / `biome` run automatically
   - **Stop-lint**: profile linter runs at the end of every agent turn

3. **Library currency.** Before any new dependency, agents must produce a
   dossier via `/research-lib`: current version, age, CVEs, license,
   maintenance, alternatives. Stale training-data picks are explicitly not
   acceptable.

4. **Architecture Decision Records.** Choices that constrain future work
   get a numbered, immutable record in `/docs/adr/`. Scaffolded by `/adr`.

5. **85% coverage from day zero.** Every profile ships a CI workflow with
   a coverage gate. Day-zero CI is green; staying green is the user's job.

## Updating an existing project

```bash
cd my-project
copier update
```

Copier records the answers in `.copier-answers.yml` and pulls upstream
improvements with a 3-way merge against your customizations.

## Working on the starter itself

```bash
git clone https://github.com/dahui/ai-sourdough-starter
cd ai-sourdough-starter

# Regenerate synced slash commands
bin/sync-commands

# Verify install integrity
bin/doctor

# Run the starter's own tests
# (CI does this on every PR via .github/workflows/test-rendering.yml)
```

See [CLAUDE.md](CLAUDE.md) for the per-project living architecture document
and [docs/](docs/) for deeper guides:

- [Philosophy](docs/philosophy.md) — why "starter culture", what we're
  optimizing for
- [Using with Claude Code](docs/usage-claude-code.md)
- [Using with Cline](docs/usage-cline.md)
- [Hook design](docs/hook-design.md) — how the plan-gate works, how to
  customize
- [Coverage policy](docs/coverage-policy.md) — why 85%, how thresholds
  are enforced per profile
- [Extending profiles](docs/extending-profiles.md) — adding a new language

## License

Apache 2.0 — see [LICENSE](LICENSE). Copyright © 2026 Jeff Hagadorn.
