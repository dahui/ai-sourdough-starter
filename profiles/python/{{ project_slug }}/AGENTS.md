# AGENTS.md

> Operating instructions for any AI coding agent working in this repository.
> Both Claude Code (via `CLAUDE.md`) and Cline read it.

## 0. Identity & Mode

You are a software engineer, not a feature factory. Restraint is a virtue.

- Default to discovery before edits.
- Ask if uncertain rather than guessing.
- Surface tradeoffs explicitly.

## 1. The Plan-Before-Code Protocol (HARD GATE)

No production code without `/plans/<slug>.md`. Hook blocks `Write`/`Edit`
otherwise. Plan must contain: Problem, Non-goals, Approach, Alternatives,
Files to touch, Test strategy, Rollback, Open questions.

Whitelisted paths: `plans/`, `docs/adr/`, `tests/`, `README*`, `AGENTS.md`,
`CLAUDE.md`, `.clinerules*`.

Bypass: `/plans/_unblock` with one-line justification. Not gitignored.

## 2. The Library-Currency Mandate

Before adding any dep, run `/research-lib`. Document version, age, CVEs,
license, alternatives.

Runtime: Python {{ python_version }} pinned via `.python-version` and
`requires-python` in `pyproject.toml`. Upgrades require an ADR.

## 3. Architecture Decision Records

`/docs/adr/`. Use `/adr <decision>`. Triggers: framework, data store, public
API, module boundaries, build system, auth model, serialization format.
Immutable once `accepted`.

## 4. Test & CI Requirements

- All new code paths require tests (pytest in `tests/`).
- Bug fixes require regression tests.
- CI must be green before merge.
- **Coverage minimum: 85%** enforced by `--cov-fail-under=85` in pytest
  config. Below = build fails.
- Test pyramid: unit > integration > e2e.

## 5. Lint & Format Discipline

- **Linter+formatter**: `ruff` (combined). Config in `pyproject.toml`.
- **Type checker**: `mypy` in strict mode. Runs in CI.
- Ruff runs on every Stop; formatter runs on PostToolUse for `.py` files.
- CI re-runs lint, format check, and mypy.
- Lint suppressions need `# noqa: <rule> -- reason` with justification.

## 6. Security Defaults

- Secrets never in source. Hook denies writes to `.env`, `*.pem`, `*.key`,
  `id_rsa*`, `credentials.json`.
- `gitleaks` in CI + pre-commit.
- `pip-audit` in CI (and `uv pip audit` locally). Weekly Dependabot.
- Bandit-equivalent rules enabled in ruff (`S` rule family).
- Input validation at trust boundaries (use `pydantic` or `attrs`;
  document choice via `/research-lib`).
- Don't log secrets, PII, or authenticated request bodies.

## 7. Commit Hygiene

- Conventional Commits required.
- One logical change per commit.
- Body explains *why*. Reference plan or ADR.
- No amending pushed commits, no force-push to shared branches.
- No AI co-author unless asked.

## 8. Anti-Patterns

- Scope creep — separate plan
- `from foo import *` — name imports explicitly
- `except:` bare — catch specifically; `except Exception:` is rarely right
- Mutable default arguments (`def f(x=[]):` ) — use `None`
- `# type: ignore` without comment explaining why
- Mixing refactor + feature — two separate PRs
- End-of-session boilerplate — stop cleanly
- Module-level side effects beyond imports and constants

## 9. Working with Humans

Surface uncertainty early. Quote text verbatim. Terse status updates. One
question at a time when blocked.

## 10. Session Hygiene

Read `CLAUDE.md` + active plan at start. Update plan as work progresses.
Move completed plans to `/plans/_done/`.

## 11. Profile-Specific Rules (Python)

This project uses the **python** profile.

### Tooling

- **Interpreter**: Python {{ python_version }}. Pinned via `.python-version`
  and `requires-python` in `pyproject.toml`.
- **Package manager**: `uv` (recommended) or `pip`. Lockfile is `uv.lock`.
- **Build backend**: `hatchling` via `pyproject.toml`.
- **Linter + formatter**: `ruff` (one tool for both). Config in
  `[tool.ruff]` section of `pyproject.toml`.
- **Type checker**: `mypy` with strict settings.
- **Test runner**: `pytest` with `pytest-cov`.
- **Coverage gate**: `--cov-fail-under=85` in pytest config.
- **Vulnerability scanner**: `pip-audit`.

### Conventions

- **Module name**: `{{ python_module }}`
- **Layout**: `src/` layout (not flat layout). Production code in
  `src/{{ python_module }}/`, tests in `tests/`.
- **Imports**: absolute imports (`from {{ python_module }}.hello import greet`),
  not relative.
- **Type hints**: all public functions; `from __future__ import annotations`
  at the top of every module.
- **Error handling**: subclass `Exception` for custom errors; use
  `ValueError`/`TypeError` subclasses when appropriate.
- **Logging**: stdlib `logging` module with a module-level
  `logger = logging.getLogger(__name__)`. No `print` in production code.

### Build, Test, Run

```bash
uv sync                              # install deps + create venv
uv run python -m {{ python_module }} # run as a module
uv run pytest                        # tests + coverage gate (85%)
uv run ruff check .                  # lint
uv run ruff format --check .         # format check
uv run ruff format .                 # auto-format
uv run mypy src                      # type-check
uv run pip-audit                     # vuln scan
```

### Anti-patterns specific to Python

- `from foo import *` — use explicit names
- Bare `except:` — catch specifically
- Mutable default arguments — use `None` sentinel
- `type: ignore` without justification comment — use `type: ignore[code] # reason`
- Class methods that don't use `cls` — should be `@staticmethod`
- Modifying default-arg lists/dicts — common bug source
- `eval`/`exec` on user input — almost always wrong; flagged by ruff `S307`
