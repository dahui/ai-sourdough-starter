# Plan: Fix release workflow tag-conflict failure

## Problem statement

The release workflow at [.github/workflows/release.yml](../.github/workflows/release.yml)
triggers on `push: tags: [v*.*.*]`. When v0.1.0 was pushed, the workflow
failed at the first changelog step:

```
git pull --tags --ff-only
! [rejected] v0.1.0  ->  v0.1.0  (would clobber existing tag)
```

Root cause: `TriPSs/conventional-changelog-action@v5` runs `git pull --tags
--ff-only` early in its execution. It's designed to be run on a branch
push, where it inspects commits since the last tag and *creates* the new
tag. On a tag-push event the local checkout already has the tag, and the
pull refuses to clobber it. The `skip-tag: true` flag we passed doesn't
skip this preflight pull — it only skips the tag-creation step at the end.

## Non-goals

- Switching the whole release model (e.g., to release-please) — overkill
  for a v0.x.x starter
- Generating per-commit changelogs at this stage — the project has one
  release; no history to summarize beyond the commit graph
- Auto-incrementing version files — `skip-version-file: true` was already
  set; we don't track versions in `package.json` for the starter itself

## Proposed approach

Drop the `TriPSs/conventional-changelog-action` step entirely. Rely on
`softprops/action-gh-release@v2` with `generate_release_notes: true`,
which uses GitHub's native API to produce release notes grouped by PR
label and listing contributors. For a starter with all v0.1.0 work
landing in one batch, GitHub's auto-generated output is comparable to
what the changelog action would have produced — and it works correctly
on tag-push events.

The replacement workflow becomes a single `gh-release` step that creates
the GitHub Release with auto-generated notes.

## Alternatives considered

1. **Trigger the workflow on `workflow_dispatch` only** and have the user
   manually invoke it after pushing tags. Avoids the bug but loses
   automation. Rejected.
2. **Trigger on `push: branches: [main]`** and have the action create
   the tag from there. Works for the action but doesn't match the
   intuitive "I tag, you release" mental model. Rejected.
3. **Use `release-please-action`** (Google's release automation). Solid
   choice for larger projects; manages versioning, changelogs, and
   release PRs. Heavier than this starter needs; introduces a release-PR
   workflow. Rejected for v0.1.0.
4. **Use `mikepenz/release-changelog-builder-action`** instead — it's
   built for tag-push events. Decent option but adds a dependency we
   don't need given GitHub's native API is sufficient.

## Files to touch

- `.github/workflows/release.yml` — drop the changelog step, remove the
  `body:` reference to its output, keep `generate_release_notes: true`

## Test strategy

- v0.1.0 is already tagged but has no GitHub Release because the workflow
  failed. Two recovery paths the user can take after this fix lands:
  1. Delete the v0.1.0 tag locally and on GitHub
     (`git tag -d v0.1.0 && git push --delete origin v0.1.0`), push the
     workflow fix, then re-tag and re-push v0.1.0. The workflow runs
     against the fixed code and creates the Release.
  2. Push the workflow fix, then create the v0.1.0 Release manually via
     `gh release create v0.1.0 --generate-notes` (or the GitHub UI).
     Future tags (v0.2.0, etc.) auto-release via the fixed workflow.
- Path 2 is simpler if no one's already pulled v0.1.0 — no destructive
  tag operations.

## Rollback strategy

Workflow is additive infrastructure; revert restores the broken behavior
but doesn't break anything that was working.

## Open questions

- **Want richer release notes per release than GitHub's defaults?** Can
  add `release-please-action` later if the project grows. Out of scope
  for this fix.
