# Extending profiles

Adding a new language profile (or modifying an existing one) is a regular
maintenance task. This doc walks through the steps.

## Anatomy of a profile

A profile lives in `profiles/<lang>/` and contains:

```
profiles/<lang>/
├── copier.yml                   # questions, tasks, render config
├── cookiecutter.json            # cookiecutter-compat translation
├── hooks/post_gen_project.py    # post-gen for cookiecutter path
└── {{ project_slug }}/          # template tree (rendered into destination)
    ├── AGENTS.md                # profile-flavored rules
    ├── CLAUDE.md                # project-specific stub
    ├── README.md
    ├── LICENSE
    ├── .gitignore               # base + language-specific
    ├── .editorconfig
    ├── .gitattributes
    ├── .pre-commit-config.yaml
    ├── .clinerules/             # base + workflows (synced)
    ├── .claude/                 # settings + hooks + agents + commands (synced)
    ├── .github/
    │   ├── dependabot.yml       # base + language-specific ecosystem
    │   └── workflows/
    │       ├── ci.yml           # lint + test + coverage + build
    │       └── security.yml     # gitleaks + CodeQL/equivalent
    ├── docs/adr/                # ADR seed
    ├── plans/                   # plan template + README
    ├── scripts/                 # coverage gate + other helpers
    ├── (language-specific source tree)
    └── .starter-manifest.json
```

## Steps to add a new profile

1. **Copy from an existing profile** (Go is the canonical pattern).

   ```bash
   cp -r profiles/go profiles/<lang>
   ```

2. **Edit `copier.yml`**:
   - Change profile-specific defaults (no `go_version`, add appropriate
     toolchain version variable)
   - Adjust `_tasks` if the language needs different post-gen steps
   - The `profile` answer should be the directory name

3. **Edit `cookiecutter.json`** to mirror the copier.yml questions.

4. **Update `hooks/post_gen_project.py`** if the post-gen logic differs
   from Go (e.g., Java's case-sensitive package names, Python's
   import-path validation).

5. **Replace the source tree** with a Hello-World in the new language:
   - Entry point that prints a greeting
   - One non-trivial function with a clear contract
   - 5-6 tests exercising the happy path + error branches
   - Aim for >85% coverage on the Hello-World so CI is green on day zero

6. **Update `AGENTS.md` §11** to describe the new profile's tooling and
   conventions. Specifically:
   - Package manager
   - Linter and config file
   - Formatter
   - Test runner and assertion library
   - Coverage tool and how the 85% gate is enforced
   - Vulnerability scanner
   - Common anti-patterns specific to the language

7. **Write the CI workflow** (`.github/workflows/ci.yml`):
   - Pin the toolchain version
   - Run formatter check
   - Run linter
   - Run tests with race detection / strict mode
   - Enforce coverage threshold
   - Build

8. **Update `.github/dependabot.yml`** with the language's
   `package-ecosystem` value (e.g., `pip`, `maven`, `npm`, `gomod`,
   `cargo`).

9. **Write the coverage gate** (`scripts/check-coverage.sh` or
   equivalent). For languages where the test runner has a built-in
   threshold (Python's `pytest-cov`, jacoco), use that and skip the
   script.

10. **Adjust `.gitignore`** with language-specific entries (build
    directories, compiled artifacts, dependency caches).

11. **Add the profile to `.github/workflows/test-rendering.yml`** matrix:

    ```yaml
    strategy:
      matrix:
        profile: [go, java, nodejs-ts, python, <your-new-one>]
    ```

    Add a step that runs the new profile's CI inside the rendered tree.

12. **Add a row** to the README's profile table.

## Common pitfalls

### Jinja vs language template syntax

Copier renders all files in the template tree as Jinja. If your language
uses `{{ }}` in its source (Go `text/template`, Helm, JSP, JSX-with-doc-
comments), Jinja will try to interpret those tokens.

Mitigation: wrap problematic regions in `{% raw %}...{% endraw %}`. Or
add the file to `_exclude` in `copier.yml` and copy it verbatim
post-render.

### Synced files (commands, workflows)

`bin/sync-commands` writes into `.claude/commands/` and
`.clinerules/workflows/`. The Go profile's template tree has copies of
these files baked in. **Re-run `bin/sync-commands` at the starter level
after editing canonical commands**, then re-copy into each profile's
template tree.

This is a known papercut. A future `bin/sync-profiles` will automate
copying universal files (including the synced commands) into every
profile's `{{ project_slug }}/` tree.

### Hook executability

Files copied through copier do **not** preserve the executable bit
on most platforms. The `_tasks` block in `copier.yml` runs `chmod +x` on
the hook scripts and coverage gate post-render. If you add a new
executable script, add it to the `_tasks` chmod list.

### CodeQL language

`.github/workflows/security.yml`'s CodeQL job needs a language string
that matches GitHub's supported list:
- `go`, `python`, `javascript` (covers TS), `java-kotlin`,
  `c-cpp`, `csharp`, `ruby`, `swift`

Make sure the profile's `security.yml` hard-codes the right value (the
universal `_common/.github/workflows/security.yml` uses a template
variable, but each profile overrides with the concrete value).

## Testing your new profile locally

```bash
# From the starter root
copier copy --trust -a profiles/<lang> --defaults \
  --data project_name='Demo' --data project_slug='demo' \
  --data <other-required-data> \
  . /tmp/demo-<lang>

cd /tmp/demo-<lang>
# Run the profile's CI commands manually
# e.g. for python: uv sync && uv run pytest --cov-fail-under=85
```

If CI passes, push and watch `.github/workflows/test-rendering.yml`
verify the same on a clean GitHub runner.
