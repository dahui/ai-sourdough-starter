# Plan: Flatten render output, drop unverified cookiecutter compat

## Problem statement

Two related issues:

1. **Nested output.** `copier copy profiles/go ./my-app` produces
   `./my-app/<project_slug>/...` because the template tree has a
   literal `{{ project_slug }}/` directory at its root. Surprising UX;
   doesn't match modern scaffolders (`cargo new`, `npm create`, etc.)
   where the destination IS the project root.

2. **Cookiecutter compat was never functional.** The templates use
   copier's variable syntax (`{{ project_slug }}`), but cookiecutter
   expects `{{ cookiecutter.project_slug }}`. The `cookiecutter.json`
   files, `hooks/post_gen_project.py` files, and README example for
   cookiecutter are all aspirational. No test exercises the cookiecutter
   path. Documenting an unverified scaffolder as "compatible" is worse
   than honestly supporting one well.

## Non-goals

- Adding cookiecutter compat for real (a future v0.2.x can revisit if a
  user actually asks)
- Restructuring to a single top-level `copier.yml` with a profile
  question (still a valid future direction, separate plan)
- Fixing the doctor's untracked-files false-positive (separate concern,
  separate plan)
- Adding a `bin/sync-profiles` (separate, deferred)

## Proposed approach

Commit to copier-only. Concretely:

1. **Rename** `profiles/<lang>/{{ project_slug }}/` → `profiles/<lang>/template/`
   in all four profiles. Static name; copier finds it via `_subdirectory`.
2. **Add** `_subdirectory: template` to each profile's `copier.yml`.
3. **Delete** the cookiecutter scaffolding:
   - `profiles/<lang>/cookiecutter.json` (×4)
   - `profiles/<lang>/hooks/post_gen_project.py` (×4)
   - `profiles/<lang>/hooks/` (×4, will become empty)
4. **Update docs** to remove cookiecutter examples and explain the
   copier-only pattern. Clone-first is still required for remote
   sources because copier's CLI can't navigate into a subdirectory of
   a remote repo.
5. **Update CI** to drop the `/<project_slug>` suffix from every
   `working-directory:` and inline `cd`.

After these changes, the destination path is flat:

```
copier copy --trust profiles/go ./my-app --data project_slug=my-app
# Result: ./my-app/AGENTS.md, ./my-app/cmd/..., ./my-app/go.mod
```

## Alternatives considered

1. **Status quo (do nothing)**: papercut every render; broken cookiecutter
   compat keeps misleading users. Rejected.
2. **Symlink `{{ cookiecutter.project_slug }}` → `template/`**: makes
   cookiecutter see a template tree, but the templates themselves still
   use copier variable namespace. False security. Rejected.
3. **Maintain dual-syntax templates (copier + cookiecutter)**: every
   variable reference becomes `{{ x }}` AND `{{ cookiecutter.x }}` via
   Jinja conditionals, OR two parallel template trees. High effort,
   ongoing burden, no current user demand. Rejected.
4. **Mark cookiecutter as best-effort, fix only the flatten**: keeps
   broken files in the repo with apologetic doc note. Still misleading.
   Rejected.

## Files to touch

**Renames (4):**
- `profiles/go/{{ project_slug }}/` → `profiles/go/template/`
- `profiles/java/{{ project_slug }}/` → `profiles/java/template/`
- `profiles/nodejs-ts/{{ project_slug }}/` → `profiles/nodejs-ts/template/`
- `profiles/python/{{ project_slug }}/` → `profiles/python/template/`

**Edits to add `_subdirectory: template` (4):**
- `profiles/go/copier.yml`
- `profiles/java/copier.yml`
- `profiles/nodejs-ts/copier.yml`
- `profiles/python/copier.yml`

**Deletes (8 files + 4 dirs):**
- `profiles/<lang>/cookiecutter.json` × 4
- `profiles/<lang>/hooks/post_gen_project.py` × 4
- `profiles/<lang>/hooks/` × 4 (will become empty after the file delete)

**Doc updates:**
- `README.md` — drop cookiecutter example; simplify copier quick-start;
  note that destination is now the project root (flat)
- `CLAUDE.md` — drop cookiecutter mentions; update copier example
- `docs/extending-profiles.md` — remove "cookiecutter.json" from the
  profile-anatomy section and the "Steps to add a new profile"; update
  local-test command to point at the profile path; remove
  `hooks/post_gen_project.py` from the anatomy
- `docs/philosophy.md` — check for cookiecutter mentions (if any),
  reframe as "copier is the actively-maintained scaffolder"
- `profiles/go/copier.yml` — header comment: drop cookiecutter line

**CI updates:**
- `.github/workflows/test-rendering.yml` — for each of the 4 render jobs:
  - Drop `/demo-project` or `/demo-service` from the `cd` after render
  - Drop the same suffix from every `working-directory:` line

## Test strategy

- Push the change; the existing `test-rendering` workflow exercises all
  4 profiles. With the flatten in place, the verify-executables and
  build-test steps should find files directly at `/tmp/render/<lang>/`,
  not at `/tmp/render/<lang>/<project_slug>/`.
- Manual smoke test (no local copier installed):
  - `find profiles/<lang> -maxdepth 2 -type d` should show `template/` and
    no `{{ project_slug }}/`
  - `grep -n cookiecutter profiles/<lang>/*` should return nothing
  - `bin/doctor` should still pass (no checks depend on cookiecutter files)

## Rollback strategy

Single commit. `git revert` restores the previous structure entirely.
The renames are reversible; the deleted files are recoverable from git
history.

## Open questions

None blocking. Future work that's now easier to motivate:
- `bin/sync-profiles` to keep universal files (AGENTS.md, hooks, etc.) in
  sync across each profile's `template/` directory
- A top-level `copier.yml` with `profile` as the first question, making
  `copier copy gh:dahui/ai-sourdough-starter ./my-app` work directly
  without a clone-first step
