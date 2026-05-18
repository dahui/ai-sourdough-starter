# Hook design

This doc explains *why* the hooks are shaped the way they are, what
tradeoffs exist, and how to customize them safely.

## Hook inventory

| Hook                       | Event                       | Purpose                                                         |
|----------------------------|-----------------------------|-----------------------------------------------------------------|
| `require-plan.sh`          | `PreToolUse` (Write\|Edit)  | Block edits without a plan file in `/plans/`                    |
| `require-plan-bash.sh`     | `PreToolUse` (Bash)         | Same gate, applied to file-creating shell commands              |
| `block-secrets.sh`         | `PreToolUse` (Write\|Edit)  | Block secret-bearing paths + secret-shaped content              |
| `post-edit-format.sh`      | `PostToolUse` (Write\|Edit) | Run profile formatter on the just-edited file                   |
| `stop-lint.sh`             | `Stop`                      | Run profile linter at end of every agent turn                   |
| `SessionStart` (inline)    | `SessionStart`              | Print reminder to read AGENTS.md + active plan                  |

Plus `permissions.deny` in `settings.json` provides a complementary
denylist for secret-bearing files and dangerous git operations.

## The plan-gate, in detail

The plan-gate is the most consequential hook. It blocks the model from
making production edits unless a plan exists. Its design choices:

### Why "any plan file", not "a plan that matches the current edit"?

A stricter design would check that the plan file's "Files to touch"
section references the file being edited. We rejected this because:

- Renames, refactors, and deletes would all need exceptions
- Plan files are not machine-readable structured data
- The starter would have to parse Markdown ASTs to extract the file list
- False negatives would erode trust in the hook ("why is it blocking me?")

Instead, we trust that if the user writes a plan, the plan reflects the
work. Cheating (writing a one-line plan and editing freely) is possible
but caught by `/review` and `/ship-it`.

### Why whitelisted paths?

Plans themselves need editing. ADRs need writing. Tests need adding for
regression coverage of bugs that the plan describes. Forcing a plan to
exist before you can edit `/plans/<slug>.md` would be a chicken-and-egg
problem.

The whitelist: `plans/`, `docs/adr/`, `tests/`, `README*`, `AGENTS.md`,
`CLAUDE.md`, `.clinerules*`, `scripts/`.

`scripts/` is whitelisted because helper scripts (like the coverage gate)
are infrastructure, not application code, and tend to be edited reactively
rather than from a plan. If your `scripts/` directory holds critical
production logic, remove it from the whitelist.

### Why the `_unblock` escape hatch?

Some edits are genuinely trivial — a typo, a comment, a formatting fix.
Writing a plan file for "fix typo in error message" is theater.

`/plans/_unblock` exists to acknowledge this. The file:
- Is **not** gitignored — appears in `git status` as a visible reminder
- Should contain a one-line justification (the `/unblock` command enforces
  this)
- Should be removed promptly after the trivial edit

If you see `_unblock` lingering across multiple commits, that's a smell —
either someone's abusing it, or the plan-gate is mis-calibrated for the
workflow.

### Why exit 2, not exit 1?

Claude Code's hook contract: `exit 2` is "block with stderr visible to
the model." `exit 1` is "error, hook itself failed." The model needs to
see the block reason to react, so we use `exit 2`.

## Stop-lint cost analysis

`stop-lint.sh` runs the profile linter at the end of every agent turn.
Costs:

- Go: ~1-5s for `golangci-lint run` on a small project; grows with project size
- Python: ~0.5-2s for `ruff check`; among the fastest linters
- TS: 3-15s for `pnpm lint` depending on project size
- Java: 5-30s for `mvn checkstyle:check` (Maven is slow to start)

For larger projects, Java's overhead may dominate. Options:
1. Replace `mvn checkstyle:check` with a faster invocation (skip Maven
   download checks, use the daemon)
2. Disable the Stop hook for Java profiles and rely on CI

We ship with Stop-lint on by default because **fast feedback is the
primary value**. CI feedback is too late — the model has already moved
on. Local lint after every turn keeps the diff clean as it grows.

## Customizing

### Adding a new hook

In `.claude/settings.json`, append to the relevant event:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/your-hook.sh" }
        ]
      }
    ]
  }
}
```

Hook scripts:
- Must exit 0 (allow), 2 (block with stderr), or 1 (error)
- Receive JSON on stdin with `tool_input`, `cwd`, `tool_name`
- Should be fast (<500ms ideally); slow hooks make every Write feel laggy

### Disabling a hook temporarily

Comment out the relevant block in `.claude/settings.json`. Or rename the
script (the hook will fail to find it and Claude Code logs the error).
Don't delete — you'll want it back.

### Changing the secret-detection patterns

Edit `.claude/hooks/block-secrets.sh`. The current patterns deliberately
favor low false-positive rates:
- Full PEM key blocks (BEGIN + END markers required)
- AWS access key prefix `AKIA[0-9A-Z]{16}`
- GitHub PAT prefixes `ghp_`, `github_pat_`
- Slack tokens `xox[abprs]-`

Patterns to consider adding for your context:
- API keys with provider-specific prefixes (Stripe `sk_live_`, OpenAI `sk-`)
- JWT-shaped strings (`eyJ` prefix, three dot-separated base64 segments)
- Generic high-entropy strings (risky — high false positives)

## When to NOT use these hooks

- **Tiny prototypes** where every minute counts and you'll delete the code
  next week. The plan-gate overhead doesn't pay back.
- **Codegen sessions** where you're producing volumes of mechanically-
  generated boilerplate. Disable temporarily; re-enable after the bulk
  generation.
- **Read-only audits** where you're using the agent to explore and document
  existing code without modifying it. The hooks won't fire on Read anyway.
