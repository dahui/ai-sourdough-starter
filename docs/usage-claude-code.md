# Using ai-sourdough-starter with Claude Code

Claude Code is the primary target of the starter's enforcement primitives.
This guide covers what you get out of the box, what to expect day-to-day,
and how to customize.

## What gets loaded automatically

When you open a starter-bootstrapped project in Claude Code:

1. **`CLAUDE.md`** loads as the session's primary context. It contains a
   `@AGENTS.md` line, which inlines the canonical rules.
2. **`.claude/settings.json`** registers hooks (plan-gate, secrets-block,
   formatter, Stop-lint) and a permission denylist.
3. **`.claude/commands/*.md`** become available as `/plan`, `/research-lib`,
   `/architect`, `/adr`, `/review`, `/ci-bootstrap`, `/ship-it`, `/unblock`.
4. **`.claude/agents/*.md`** become available as subagents — they don't
   activate automatically; the main agent invokes them via task delegation.

## Day-to-day workflow

```
1. /plan <slug>            # write the plan first
2. (review and refine)     # populate Problem, Approach, Test strategy, etc.
3. /research-lib <pkg>     # ONLY if adding a new dependency
4. (implement)             # main agent does the work; plan-gate is satisfied
5. /review                 # reviewer subagent checks against AGENTS.md
6. /ship-it                # full pre-flight: tests, coverage, lint, security
7. git commit              # follow Conventional Commits; reference the plan
```

## What the plan-gate does

The `PreToolUse` hook on `Write|Edit` runs `require-plan.sh`. It:

- **Allows** edits to whitelisted paths: `plans/`, `docs/adr/`, `tests/`,
  `README*`, `AGENTS.md`, `CLAUDE.md`, `.clinerules*`, `scripts/`
- **Allows** any edit if `/plans/_unblock` exists
- **Allows** any edit if at least one non-template plan file exists in
  `/plans/`
- **Blocks** with `exit 2` otherwise. The block message tells you exactly
  what to do.

The `Bash` matcher runs `require-plan-bash.sh`, which catches
file-creating commands (`touch`, redirection, `tee`, `cp`, `mv`, `mkdir`).
`git` commands and read-only shell commands are not gated.

## The secrets denylist

`block-secrets.sh` runs alongside the plan-gate and refuses:

- Writes to `.env`, `.env.*`, `*.pem`, `*.key`, `id_rsa*`, `credentials.json`
- Content that matches AWS access keys, GitHub tokens, Slack tokens, or
  full PEM private-key blocks (BEGIN + END)

You can extend the content patterns in `.claude/hooks/block-secrets.sh`.

## The Stop-lint hook

At the end of every agent turn, `stop-lint.sh` runs the profile's linter:

- Go: `golangci-lint run`
- Python: `ruff check`
- NodeJS-TS: `pnpm lint`
- Java: `mvn checkstyle:check`

Output goes to stderr and is visible to the agent. It does NOT block — the
agent can see and address issues on the next turn.

## Customizing

### Add an allowed write path

Edit `.claude/hooks/require-plan.sh` and add a case to the whitelist:

```bash
case "$FILE_PATH" in
  ... existing ... |*/custom-config/*) exit 0 ;;
esac
```

### Disable the Stop-lint hook

Edit `.claude/settings.json` and remove the `Stop` hook block. Or set
`stop-lint.sh` to exit 0 immediately for your profile.

### Allow a permanent unblock

Don't. The `_unblock` file is intentionally tracked by git and visible in
`git status`. If you find yourself wanting to make it permanent, that's a
signal the plan-gate is wrong for your workflow — file an issue or fork
the starter.

### Disable hooks entirely

Set `disableAllHooks` to `true` in `.claude/settings.json`, or rename the
hook scripts. We don't recommend this — at that point you don't have a
sourdough starter; you have plain markdown.

## Limitations

- **Hooks fire only on Write/Edit/Bash.** A model can still call WebFetch,
  read code, or chat freely without triggering the plan-gate. That's
  intentional — reading and discussion don't need plans.
- **The plan-gate doesn't validate plan content.** It only checks
  existence. Writing a one-line plan and editing freely is technically
  allowed; we rely on `/review` and `/ship-it` to catch shallow plans
  later.
- **`bypassPermissions` mode does NOT skip hooks.** Hook `exit 2` deny
  beats `--dangerously-skip-permissions`. This is by design.
