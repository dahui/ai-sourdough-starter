# {{ project_name }}

@AGENTS.md

> Universal rules above; project-specific context below.

## Project Overview

{{ project_description }}

## Architecture

```
{{ project_slug }}/
├── pyproject.toml         # deps, build, tool config (ruff/mypy/pytest/coverage)
├── .python-version        # pinned Python version
├── src/{{ python_module }}/
│   ├── __init__.py
│   ├── __main__.py        # entry point
│   └── hello.py           # sample; replace with real code
├── tests/
│   └── test_hello.py
├── docs/adr/              # architecture decision records
├── plans/                 # plan files
└── .github/workflows/     # CI: ci.yml, security.yml
```

## Conventions

- **`src/` layout**: production code in `src/{{ python_module }}/`
- **Absolute imports** only (`from {{ python_module }}.hello import greet`)
- **Type hints required** on all public functions; `from __future__ import annotations`
  in every module
- **Strict mypy**: don't relax without an ADR
- **Custom errors**: subclass `ValueError`/`TypeError`/`Exception` and set
  a descriptive class name

## Build, Test, Run

```bash
uv sync                              # install + venv
uv run python -m {{ python_module }} # run
uv run pytest                        # tests + coverage gate
uv run ruff check .                  # lint
uv run ruff format --check .         # format check
uv run mypy src                      # type-check

# Single test
uv run pytest tests/test_hello.py::test_greet_returns_formatted_greeting
```

## Current Focus

- See `/plans/`

## Gotchas

- _None yet._

## Key Files

- `src/{{ python_module }}/__main__.py` — entry point
- `pyproject.toml` `[tool.ruff]` — lint + format config
- `pyproject.toml` `[tool.mypy]` — strict type-checking config
- `pyproject.toml` `[tool.pytest.ini_options]` — `--cov-fail-under=85`

## External References

_Dashboards, runbooks, design docs._
