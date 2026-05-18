# Extending profiles

Adding a new language profile (or modifying an existing one) is a regular
maintenance task. This doc walks through the steps.

## Anatomy of a profile

A profile lives in `profiles/<lang>/` and contains:

```
profiles/<lang>/
├── copier.yml                   # questions, tasks, _subdirectory: template
└── template/                    # template tree (rendered into destination)
    ├── AGENTS.md                # profile-flavored rules
    ├── CLAUDE.md                # project-specific stub
    ├── README.md
    ├── LICENSE
    ├── .gitignore               # base + language-specific
    ├── .editorconfig
    ├── .gitattributes
    ├── .pre-commit-config.yaml
    ├── .clinerules/             # base + workflows (synced from starter root)
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

`_subdirectory: template` in `copier.yml` makes copier render the
contents of `template/` directly into the destination. The destination
directory becomes the project root — no nested `<dest>/<project_slug>/`.

## Steps to add a new profile

1. **Copy from an existing profile** (Go is the canonical pattern).

   ```bash
   cp -r profiles/go profiles/<lang>
   ```

2. **Edit `copier.yml`**:
   - Keep `_subdirectory: template`
   - Change profile-specific defaults (no `go_version`, add appropriate
     toolchain version variable)
   - Adjust `_tasks` if the language needs different post-gen steps
     (chmod hooks, git init, etc. — see existing profiles)
   - The `profile` answer should be the directory name

3. **Replace the source tree under `template/`** with a Hello-World in
   the new language:
   - Entry point that prints a greeting
   - One non-trivial function with a clear contract
   - 5-6 tests exercising the happy path + error branches
   - Aim for >85% coverage on the Hello-World so CI is green on day zero

4. **Update `template/AGENTS.md` §11** to describe the new profile's
   tooling and conventions. Specifically:
   - Package manager
   - Linter and config file
   - Formatter
   - Test runner and assertion library
   - Coverage tool and how the 85% gate is enforced
   - Vulnerability scanner
   - Common anti-patterns specific to the language

5. **Write the CI workflow** (`template/.github/workflows/ci.yml`):
   - Pin the toolchain version
   - Run formatter check
   - Run linter
   - Run tests with race detection / strict mode
   - Enforce coverage threshold
   - Build

6. **Update `template/.github/dependabot.yml`** with the language's
   `package-ecosystem` value (e.g., `pip`, `maven`, `npm`, `gomod`,
   `cargo`).

7. **Write the coverage gate** (`template/scripts/check-coverage.sh` or
   equivalent). For languages where the test runner has a built-in
   threshold (Python's `pytest-cov`, jacoco), use that and skip the
   script.

8. **Adjust `template/.gitignore`** with language-specific entries (build
   directories, compiled artifacts, dependency caches).

9. **Add the profile to `.github/workflows/test-rendering.yml`**: add a
   new job mirroring the existing profile jobs. Render command points
   at the new `profiles/<lang>` path; subsequent steps operate directly
   on `/tmp/render/<lang>` (no inner project-slug directory thanks to
   `_subdirectory: template`).

10. **Add a row** to the README's profile table.

## Common pitfalls

### Jinja vs language template syntax

Copier renders all files in the template tree as Jinja. If your language
uses `{{ }}` in its source (Go `text/template`, Helm, JSP, JSX-with-doc-
comments), Jinja will try to interpret those tokens.

Mitigation: wrap problematic regions in `{% raw %}...{% endraw %}`. Or
add the file to `_exclude` in `copier.yml` and copy it verbatim
post-render.

### Synced files (commands, workflows, hooks, ADR seed, etc.)

The starter has two sync tools:

- **`bin/sync-commands`** — renders canonical slash commands from
  `agent-shared/commands/` into `.claude/commands/` and
  `.clinerules/workflows/` (at the starter root). Run after editing
  any canonical command body.
- **`bin/sync-profiles`** — propagates universal files (the `.claude/`
  tree, `.clinerules/` tree, ADR seed, plan templates, editor configs,
  LICENSE) from the starter root and `profiles/_common/` into each
  profile's `template/` tree. Run after editing any of those universal
  files.

Order matters: run `sync-commands` first (regenerates `.claude/commands/`
and `.clinerules/workflows/`), then `sync-profiles` (which propagates
those regenerated files into each profile).

Both tools support `--check` mode for CI. The `test-rendering` workflow's
`starter-self-checks` job runs both with `--check` on every PR, so drift
fails CI loudly.

Editing a profile's `template/<universal-file>` directly is wasted work
— the next `sync-profiles` run overwrites your edits. Make changes at
the canonical source (starter root or `profiles/_common/`) and re-sync.

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
# From the starter root. The template ref is the profile's path; copier
# has no CLI subdirectory flag.
copier copy --trust --defaults \
  --data project_name='Demo' --data project_slug='demo' \
  --data <other-required-data> \
  profiles/<lang> /tmp/demo-<lang>

cd /tmp/demo-<lang>           # destination IS the project root (flat)
# Run the profile's CI commands manually
# e.g. for python: uv sync && uv run pytest --cov-fail-under=85
```

If CI passes, push and watch `.github/workflows/test-rendering.yml`
verify the same on a clean GitHub runner.
