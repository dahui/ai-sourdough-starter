# Plan: Fix copier subdirectory invocation across CI and docs

## Problem statement

CI's `test-rendering` workflow fails: `copier copy --trust ... -a profiles/go . /tmp/render/go`
incorrectly uses `-a profiles/go` as if it selected a subdirectory. `-a` is
copier's `--answers-file` flag — it writes the answers file to that path
and has nothing to do with picking which sub-template to render.

The actual template ref in the command is `.` (the starter repo root),
which has no `copier.yml`. Copier falls back to rendering every file in
the repo, hitting `profiles/java/{{ project_slug }}/src/main/java/{{ java_package | replace('.', '/') }}/`
where the apostrophe inside the Jinja path fails to parse outside an
expression context (the path itself, not its rendered output, is being
fed to Jinja).

Same misuse appears in:
- `.github/workflows/test-rendering.yml` (4 profile render jobs)
- `README.md` (the documented `copier` quick-start)
- `profiles/go/copier.yml` (header comment with example invocation)

Cookiecutter examples in the same files are correct because cookiecutter
has a real `--directory` flag.

## Non-goals

- Restructuring to a single top-level `copier.yml` with `_subdirectory`
  (would require a profile-selection question and one mega-template)
- Adding a `_subdirectory: "{{ project_slug }}"` indirection to flatten
  the rendered output (separate decision; covered in Open Questions)
- Fixing the doctor's untracked-files false-positive (separate concern;
  flagged previously)
- Adding a NOTICE file for Apache-2.0 (separate, deferred)

## Proposed approach

Copier doesn't have a CLI subdirectory selector. To render from a
sub-template, pass the sub-template's path as the template ref.

Replace
```
copier copy ... -a profiles/go . /tmp/render/go
```
with
```
copier copy ... profiles/go /tmp/render/go
```

The rendered output then lands at `/tmp/render/go/<project_slug>/...`
because `profiles/go/{{ project_slug }}/` is the template's root tree.
Subsequent CI steps that operated on `/tmp/render/go` now need to use
`/tmp/render/go/demo-project` (because the test passes
`project_slug=demo-project`).

For the README's remote-source example, the cleanest approach is to
clone the starter first and then render from the local subpath, because
copier's CLI can't navigate into a subdirectory of a remote template the
way `cookiecutter --directory=` can.

## Alternatives considered

1. **Add `_subdirectory: "{{ project_slug }}"` to each profile's `copier.yml`**:
   this would flatten the output so the rendered files land directly at
   `/tmp/render/go/` (no nested `demo-project/`). Less surgery on CI step
   working directories, but `_subdirectory` evaluation order with Jinja
   expressions varies by copier version and historically has been
   fragile. Defer; see Open Questions.

2. **Top-level `copier.yml` with a `profile` question + `_subdirectory: profiles/{{ profile }}/{{ project_slug }}`**:
   single entry point at the starter root. Bigger architectural change
   than the bug warrants. Separate plan if we want it.

3. **Clone-first for everyone (CI and humans)**: makes `gh:` shortcuts
   unusable. Cookiecutter's `--directory=` flag works for remote sources
   so we'd lose the parity. Rejected for CI; keep `gh:` for the
   cookiecutter quick-start in the README.

## Files to touch

- `.github/workflows/test-rendering.yml` — fix 4 render commands and
  all dependent `working-directory:` paths
- `README.md` — replace the broken copier quick-start with a
  clone-and-render pattern; cookiecutter example is already correct
- `profiles/go/copier.yml` — fix the example invocation in the header
  comment

## Test strategy

- Push the fix; the `test-rendering` workflow runs all 4 profile matrix
  jobs (go, java, nodejs-ts, python) plus the starter self-checks
- Each render must produce a green CI inside the rendered project
- Verify by reading the workflow logs: the render step must produce a
  `demo-project/` subdirectory under the destination

## Rollback strategy

Single PR. Revert the workflow + README + copier.yml changes with
`git revert`.

## Open questions

- **Should we add `_subdirectory: "{{ project_slug }}"` to flatten output?**
  Pro: cleaner CI step paths, no nested directory; matches what most
  users expect ("render into the destination, not into a child of it").
  Con: requires verifying copier evaluates `_subdirectory` after answer
  collection; deferred to a follow-up plan once this fix unblocks CI.
