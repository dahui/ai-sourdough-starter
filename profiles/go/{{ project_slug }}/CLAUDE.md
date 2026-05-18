# {{ project_name }}

@AGENTS.md

> The rules above apply to every AI-assisted project (universal discipline).
> The sections below are SPECIFIC to this project and should be kept current
> as the codebase evolves.

## Project Overview

{{ project_description }}

## Architecture

```
{{ project_slug }}/
├── cmd/{{ project_slug }}/           # binary entry point
├── internal/                         # private packages (not importable)
│   └── hello/                        # sample package; replace with real code
├── docs/adr/                         # architecture decision records
├── plans/                            # plan files (plan-gate hook reads these)
├── scripts/                          # helper scripts (coverage gate, etc.)
└── .github/workflows/                # CI: ci.yml, security.yml
```

## Conventions

- **Module path**: `{{ module_path }}` — full import path of every internal
  package
- **Naming**: package names are short, lowercase, single-word where possible
- **Error wrapping**: `fmt.Errorf("doing X: %w", err)` — never lose context
- **Context**: every blocking function takes `ctx context.Context` first
- **Logging**: `log/slog` from stdlib; structured logs only

## Build, Test, Run

```bash
make build           # go build ./...
make run             # go run ./cmd/{{ project_slug }}
make test            # go test -race -coverprofile=cover.out ./...
make coverage        # ./scripts/check-coverage.sh
make lint            # golangci-lint run
make vuln            # govulncheck ./...
make ship-check      # everything; matches CI

# Single test
go test -run TestHello ./internal/hello
```

## Current Focus

_Active workstreams (link to /plans/*.md). Update as work progresses._

- See `/plans/`

## Gotchas

_Surprises that bit a previous contributor. Update as you discover them._

- _None yet._

## Key Files

- `cmd/{{ project_slug }}/main.go` — binary entry point
- `Makefile` — canonical build/test commands
- `.golangci.yml` — lint configuration
- `scripts/check-coverage.sh` — 85% threshold enforcer
- `.github/workflows/ci.yml` — the source of truth for what "green" means

## External References

_Dashboards, runbooks, design docs._
