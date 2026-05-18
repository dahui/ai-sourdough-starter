# Plan: Add bin/sync-profiles to keep universal files in lockstep across profiles

## Problem statement

When a "universal" file changes at the starter root (e.g. a hook script
in `.claude/hooks/`, the Cline addenda in `.clinerules/`, or the ADR
seed in `profiles/_common/docs/adr/`), it must be hand-copied into each
profile's `template/` tree. Currently 4 profiles, so any edit to a
universal file is 4 silent places where drift can creep in.

Flagged as a "known papercut" in `docs/extending-profiles.md` and
recommended as a future tool in earlier plans. With v0.1.0 stabilized
and four profiles in place, the cost-benefit now favors building it.

## Non-goals

- Syncing profile-specific files (AGENTS.md §11, CLAUDE.md, README.md,
  go.mod, package.json, etc.) — those are intentionally different
- Two-way sync — canonical sources are one-way (root → profile)
- Building a generic "sync any files" framework — a small concrete
  script is enough
- Renaming `profiles/_common/LICENSE.MIT.tmpl` (orphan from an earlier
  design; separate cleanup)

## Proposed approach

A shell script at `bin/sync-profiles` that:

1. Reads a hardcoded list of source→dest mappings (relative to the
   repo root and to each profile's `template/`)
2. For each (source, dest) pair, copies into all 4 profile template
   trees if the destination differs from the source
3. Supports `--check` mode that exits non-zero if any sync would
   modify files (for CI)
4. Prints a one-line summary per file changed

**What gets synced** (canonical source → relative dest under each
`profiles/<lang>/template/`):

| Source | Dest under `template/` |
|---|---|
| `.claude/settings.json` | `.claude/settings.json` |
| `.claude/hooks/*.sh` | `.claude/hooks/*.sh` |
| `.claude/agents/*.md` | `.claude/agents/*.md` |
| `.claude/commands/*` (incl. `.synced.sha256` sidecars) | `.claude/commands/*` |
| `.clinerules/00-cline-addenda.md` | `.clinerules/00-cline-addenda.md` |
| `.clinerules/workflows/*` | `.clinerules/workflows/*` |
| `profiles/_common/docs/adr/0000-record-architecture-decisions.md` | `docs/adr/0000-record-architecture-decisions.md` |
| `profiles/_common/plans/_template.md` | `plans/_template.md` |
| `profiles/_common/plans/README.md` | `plans/README.md` |
| `profiles/_common/.gitattributes` | `.gitattributes` |
| `profiles/_common/.editorconfig` | `.editorconfig` |
| `profiles/_common/.pre-commit-config.yaml.base` | `.pre-commit-config.yaml` (note: rename) |
| `profiles/go/template/LICENSE` (canonical first profile) | `LICENSE` (synced to java/nodejs-ts/python) |

**What does NOT get synced** (profile-specific by design):
- `AGENTS.md` (§11 differs per profile)
- `CLAUDE.md` (different architecture sections)
- `README.md` (different quick-start commands)
- `.gitignore` (profile-specific entries)
- `.github/dependabot.yml` (profile-specific ecosystems)
- `.github/workflows/{ci,security}.yml` (profile-specific toolchains)
- `.starter-manifest.json` (profile-specific fields)
- Source code (go.mod, pom.xml, package.json, pyproject.toml, src/, tests/)

## Alternatives considered

1. **Symlinks from each profile to canonical files**: clean but
   git-on-Windows compat is iffy, and many editors resolve symlinks
   surprisingly. Rejected.
2. **Single shared `template/` with per-profile overlays via copier
   `_extends`**: bigger restructure; not justified by the current
   amount of duplication. Rejected for v0.1.0.
3. **Pre-commit hook that calls sync-profiles automatically**: nice
   but couples committing to the sync tool. Better to keep sync-profiles
   explicit and let CI enforce. Rejected.
4. **Make sync-profiles also call sync-commands first**: implicit
   dependency. Better to document the order ("run sync-commands then
   sync-profiles"). Rejected.

## Files to touch

**New:**
- `bin/sync-profiles` — the script (executable)

**Modified:**
- `bin/doctor` — add a drift check for sync-profiles, symmetric to the
  existing sync-commands check
- `.github/workflows/test-rendering.yml` — add `bin/sync-profiles
  --check` to the `starter-self-checks` job so CI catches profile drift
- `docs/extending-profiles.md` — mention `bin/sync-profiles` in the
  "Synced files" pitfall section; remove the "future" framing
- `CLAUDE.md` — list `bin/sync-profiles` in Key Files / Architecture

## Test strategy

- **Initial run**: in the current repo state, `bin/sync-profiles`
  should produce no output (all universal files are already in sync
  from earlier work).
- **Synthetic drift test**: modify a hook script at the starter root,
  run `bin/sync-profiles --check` → expect exit 1 with the affected
  paths listed. Run `bin/sync-profiles` (no flag) → expect the 4
  profile copies to update. Re-run `--check` → expect exit 0.
- **Doctor integration**: after the change, `bin/doctor` should run
  both sync checks and pass.
- **CI integration**: the test-rendering workflow's `starter-self-checks`
  job will exercise sync-profiles --check on every PR.

## Rollback strategy

- The script is additive; remove it and revert doctor + CI changes if
  needed.
- No file structure changes; sync targets are existing files.

## Discovered during implementation

- **`.claude/settings.local.json` is a per-user override** (Claude Code's
  convention) — it accumulates permission grants tied to the local user's
  paths. It must NOT be propagated into profile templates and should NOT
  be committed to the starter repo either. Two small adjacent fixes
  added to this plan:
  1. Skip `settings.local.json` in `sync-profiles`' `.claude/` tree walk
  2. Create a starter-root `.gitignore` that excludes
     `.claude/settings.local.json` and a few other ephemeral files
     (`.copier-answers.yml.tmp`, editor swap files)

## Open questions

- **Should we sync `LICENSE`?** It's identical across the 4 profiles
  today (the conditional Jinja template). Syncing keeps it that way.
  But canonical source is `profiles/go/template/LICENSE` rather than
  starter root or `_common/` — slightly asymmetric. Decision: yes,
  sync it; document the asymmetry in the script comment.
- **`profiles/_common/LICENSE.MIT.tmpl` orphan**: still in repo, still
  unused. Delete in a separate cleanup PR (not in scope here).
