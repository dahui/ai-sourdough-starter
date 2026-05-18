# Plan: Fix license-choice bug across all four profiles

## Problem statement

Each profile's `copier.yml` offers `license: [MIT, Apache-2.0, none]` as a
choice, but every profile's `{{ project_slug }}/LICENSE` file ships a
hardcoded MIT license text. The user's answer is silently ignored: pick
Apache-2.0 and you still get MIT.

Found while updating the starter's own base LICENSE; flagged but not
fixed inline because it touched multiple files and was unrelated to that
change.

## Non-goals

- Cleaning up the unused `profiles/_common/LICENSE.MIT.tmpl` file (was
  leftover from an earlier design; separate concern, separate PR)
- Adding new license choices beyond MIT / Apache-2.0 / none
- Adding `NOTICE` files for Apache-2.0 (not strictly required without
  third-party attributions; defer to v0.2.0 if it becomes needed)
- Touching the starter's own `LICENSE` file (already correctly set to
  Apache 2.0 with Jeff Hagadorn)
- A `bin/sync-profiles` script to keep these in lockstep going forward
  (already noted in `docs/extending-profiles.md` as a deferred item)

## Proposed approach

Replace each profile's `{{ project_slug }}/LICENSE` with a Jinja-templated
file that branches on the `license` answer:

```
{%- if license == "MIT" -%}
  [MIT text with Copyright (c) 2026 {{ copyright_holder }}]
{%- elif license == "Apache-2.0" -%}
  [full Apache 2.0 text with Copyright 2026 {{ copyright_holder }} in appendix]
{%- else -%}
  [brief "All rights reserved" notice]
{%- endif %}
```

This works identically in copier and cookiecutter (both render Jinja in
file contents). One file per profile, three branches, no post-gen
juggling.

## Alternatives considered

1. **Separate `LICENSE.<spdx>.tmpl` files + post-gen rename**: more files,
   more places for things to drift, requires both copier `_tasks` and
   cookiecutter `post_gen_project.py` to be touched. Rejected.
2. **Skip LICENSE file entirely for `license == "none"`**: requires copier
   conditional file-skip (clean) but cookiecutter would need post-gen
   delete (ugly). The "All rights reserved" stub is small enough that
   shipping it is simpler than conditionally suppressing the file.
   Rejected.
3. **Hardcode MIT and remove the choice from `copier.yml`**: loses user
   flexibility, surprises anyone reading the existing copier prompts.
   Rejected.

## Files to touch

- `profiles/go/{{ project_slug }}/LICENSE`
- `profiles/java/{{ project_slug }}/LICENSE`
- `profiles/nodejs-ts/{{ project_slug }}/LICENSE`
- `profiles/python/{{ project_slug }}/LICENSE`

All four files end up with identical content. The Go file is written
canonically; the other three are copied via Bash `cp`.

## Test strategy

- The CI test-rendering workflow (`.github/workflows/test-rendering.yml`)
  renders each profile with the default `MIT` license. After this change
  the rendered `LICENSE` must still be valid MIT text — same as before,
  no behavior change in the default path.
- Manual verification (covered by the test-rendering matrix once pushed):
  pre-render inspection — `grep "{{ copyright_holder }}"` against each
  template should match (proves placeholder is wired). `grep "MIT License"`
  and `grep "Apache License"` should both find content in the same file
  (proves both branches exist).
- A future test that explicitly renders with Apache-2.0 and verifies the
  output is out of scope for v0.1.0.

## Rollback strategy

Each LICENSE file is a single-file change with no dependencies. Revert
with `git checkout HEAD -- profiles/<lang>/{{ project_slug }}/LICENSE` per
profile, or `git revert` the whole commit.

## Open questions

None blocking. The "should we ship a NOTICE for Apache-2.0?" question is
flagged in non-goals and deferred.
