# {{ project_name }}

{{ project_description }}

Bootstrapped from [ai-sourdough-starter](https://github.com/dahui/ai-sourdough-starter)
v{{ starter_version }}. See [AGENTS.md](AGENTS.md) for the rules every AI
coding agent (and human) follows in this repo.

## Quick start

```bash
# Build, test, and run
make build
make run
make test

# Pre-flight before shipping
make ship-check
```

## Project structure

```
{{ project_slug }}/
├── cmd/{{ project_slug }}/    # binary entry point
├── internal/                  # private packages
├── docs/adr/                  # architecture decision records
├── plans/                     # plan files (required by plan-gate hook)
├── scripts/                   # helper scripts
└── .github/workflows/         # CI workflows
```

## Working with AI

This project enforces AI-assisted development discipline via the rules in
`AGENTS.md`:

- **No code without a plan**: every non-trivial change starts with a file
  in `/plans/`
- **Library currency**: new deps require a `/research-lib` dossier
- **ADRs for constraining choices**: see `/docs/adr/`
- **85% coverage minimum**: enforced in CI by `scripts/check-coverage.sh`
- **Lint on every turn**: profile linter runs at the end of every agent
  session

The hooks in `.claude/settings.json` enforce these for Claude Code users.
Cline users follow the same rules via `.clinerules/` and `AGENTS.md`.

## Pulling starter updates

```bash
copier update
```

This pulls improvements from the starter (new hooks, refreshed CI config,
new slash commands) without overwriting your project's customizations.

## License

{{ license }} — see [LICENSE](LICENSE).
