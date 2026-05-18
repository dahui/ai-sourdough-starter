# Philosophy

## Why "sourdough starter"?

A sourdough starter isn't bread. It's a small, living culture of yeast and
bacteria that, *added* to flour and water, becomes bread. The starter is the
forcing function — it has structure, opinions, and momentum. Without it, you
can still bake bread, but it takes more time and ends up flatter.

This project is a starter culture for AI-assisted software development. The
"culture" is a set of rules (`AGENTS.md`) and enforcement primitives (hooks)
that, once dropped into a project, change how AI coding tools behave there.

## What we're optimizing for

We're optimizing for **long-lived, well-architected codebases that survive
AI assistance** — not for one-shot speed. Most existing AI tooling
optimizes for "ship the next feature, fast." This is fine for prototypes
and dangerous for production code.

Concretely, we want:

1. **Decisions to leave traces.** Architecture choices live in ADRs.
   Implementation choices live in plan files. Both are versioned with the
   code.

2. **Library picks to be defensible.** "Pick the popular one" is a smell
   that hides stale training data and missed CVEs. Currency checks are
   mandatory.

3. **CI to be authoritative from day zero.** Day-zero red CI gets ignored
   forever. Every profile ships with a working CI workflow and a green
   Hello-World.

4. **Discipline to be enforced, not requested.** Asking an agent nicely to
   "remember to add tests" is not a strategy. The plan-gate hook blocks
   edits when no plan exists. The coverage gate fails the build under 85%.

5. **Cross-tool compatibility.** Teams use multiple AI tools, sometimes the
   same engineer in the same week. `AGENTS.md` is the single source of
   truth; Claude Code and Cline both consume it.

## What this is *not*

- **Not a framework.** No runtime, no library to import. Just files and
  hooks.
- **Not a one-shot generator.** Use `copier update` to pull in starter
  improvements over the project's lifetime.
- **Not opinionated about your application code.** It's opinionated about
  *process*: planning, testing, dependency hygiene, commit hygiene.
- **Not magical.** The rules in `AGENTS.md` are explicit; the hooks are
  ~50 lines of bash each; the slash commands are markdown.

## Tradeoffs we accept

- **Friction at the start of every change.** You must write a plan before
  you write code. For tiny edits this feels excessive; the `_unblock`
  escape hatch exists for that case. We believe the alternative — plans
  written after-the-fact or never — is worse.

- **Cline can't enforce hooks.** The plan-gate is hard-enforced in Claude
  Code and advisory in Cline. We accept this because the alternative is
  fragmenting `AGENTS.md` per tool.

- **Profile choices may not match yours.** The Python profile uses `uv`,
  not `poetry`. The TS profile uses `pnpm` + `biome`, not `npm` + `eslint`.
  These are explicit picks. If you disagree, fork the profile — that's
  cheaper than parameterizing every choice.

- **The starter is itself a single point of failure.** A bug in
  `require-plan.sh` could either block all edits (annoying) or silently
  fail-open (dangerous). Hence the rigorous test-rendering CI: every
  release must render every profile cleanly and pass its own CI.

## Borrowed wisdom

- **ADRs**: Michael Nygard's 2011 [blog post](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- **Plan-before-code**: long tradition in design-first organizations; the
  pinch point is making it default-on
- **Conventional Commits**: [conventionalcommits.org](https://www.conventionalcommits.org/)
- **AGENTS.md cross-tool spec**: [agents.md](https://agents.md/)
- **Copier's update story**: [copier.readthedocs.io](https://copier.readthedocs.io/)
