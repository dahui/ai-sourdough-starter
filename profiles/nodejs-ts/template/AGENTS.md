# AGENTS.md

> Operating instructions for any AI coding agent working in this repository.
> Both Claude Code (via `CLAUDE.md`) and Cline read it.

## 0. Identity & Mode

You are a software engineer, not a feature factory. Restraint is a virtue.

- Default to discovery before edits.
- Ask if uncertain rather than guessing.
- Surface tradeoffs explicitly.

## 1. The Plan-Before-Code Protocol (HARD GATE)

No production code without `/plans/<slug>.md`. Hook blocks `Write`/`Edit`
otherwise. Plan must contain: Problem, Non-goals, Approach, Alternatives,
Files to touch, Test strategy, Rollback, Open questions.

Whitelisted paths: `plans/`, `docs/adr/`, `tests/`, `README*`, `AGENTS.md`,
`CLAUDE.md`, `.clinerules*`.

Bypass: `/plans/_unblock` with one-line justification. Not gitignored.

## 2. The Library-Currency Mandate

Before adding or upgrading any npm dependency, run `/research-lib`.
Document version, age, CVEs, license, maintenance, alternatives.

Node runtime: pinned via `.nvmrc` and `engines.node` in `package.json`.
pnpm version pinned via `packageManager` field. Upgrades require an ADR.

## 3. Architecture Decision Records

ADRs in `/docs/adr/`. Use `/adr <decision>`. Triggers: framework choice,
data store, public API, module boundaries, build system, auth model,
serialization format. Immutable once `accepted`.

## 4. Test & CI Requirements

- All new code paths require tests (vitest in `tests/` or `src/**/*.test.ts`).
- Bug fixes require regression tests.
- CI must be green before merge.
- **Coverage minimum: 85% line + statement, 85% function, 80% branch**,
  enforced by `vitest.config.ts` thresholds. Below = build fails.
- Test pyramid: unit > integration > e2e.

## 5. Lint & Format Discipline

- **Linter+formatter**: Biome (combined). Config in `biome.json`. Runs in
  CI and on every Stop (`pnpm lint`).
- **Format on save**: `biome format --write` runs on PostToolUse for ts/js/json/md.
- **Type-check**: `tsc --noEmit` runs in CI as a separate step.
- Lint suppressions need inline justification (`// biome-ignore: ...`).

## 6. Security Defaults

- Secrets never in source. The `block-secrets.sh` hook denies writes to
  `.env`, `*.pem`, `*.key`, `id_rsa*`, `credentials.json`.
- `gitleaks` in CI + pre-commit.
- `pnpm audit --audit-level=high --prod` in CI; weekly Dependabot.
- Input validation at trust boundaries (use `zod` or similar; document
  choice via `/research-lib`).
- Don't log secrets, PII, or authenticated request bodies.

## 7. Commit Hygiene

- Conventional Commits required.
- One logical change per commit.
- Body explains *why*. Reference plan or ADR.
- No amending pushed commits, no force-push to shared branches.
- No AI co-author attribution unless asked.

## 8. Anti-Patterns

- Scope creep — separate plan
- Type assertions (`as`, `!`) to silence the compiler — fix the underlying
  type instead
- `any` as escape hatch — use `unknown` and narrow
- Swallowed promise rejections — always `await` or chain `.catch`
- `// @ts-ignore` without justification — use `// @ts-expect-error` with a
  comment
- Mixing refactor + feature — two separate PRs
- End-of-session boilerplate — stop cleanly

## 9. Working with Humans

- Surface uncertainty early. Quote text verbatim. Terse status updates.
  One question at a time when blocked.

## 10. Session Hygiene

- Read `CLAUDE.md` and active plan at session start.
- Update plan as work progresses.
- Move completed plans to `/plans/_done/`.

## 11. Profile-Specific Rules (NodeJS / TypeScript)

This project uses the **nodejs-ts** profile.

### Tooling

- **Runtime**: Node.js {{ node_version }} (LTS). Pinned via `.nvmrc` and
  `engines.node` in `package.json`.
- **Package manager**: pnpm {{ pnpm_version }}. Pinned via `packageManager`
  in `package.json`. Use `pnpm`, NOT `npm` or `yarn`.
- **Build / compiler**: TypeScript {{ '5.6+' }}. `tsconfig.json` uses strict mode
  + `noUncheckedIndexedAccess`.
- **Linter + formatter**: Biome (single tool for both). Config in
  `biome.json`. No ESLint, no Prettier.
- **Test runner**: vitest. Coverage via `@vitest/coverage-v8`.
- **Coverage gate**: thresholds in `vitest.config.ts` (lines: 85,
  functions: 85, branches: 80, statements: 85).
- **Vulnerability scanner**: `pnpm audit`.

### Conventions

- **Module type**: ESM (`"type": "module"` in `package.json`). Imports use
  `.js` extensions even for `.ts` source files (TS convention for ESM).
- **Layout**:
  - `src/` — production code
  - `tests/` — integration / cross-module tests
  - `src/**/*.test.ts` — colocated unit tests
  - `dist/` — build output (gitignored)
- **Strict TypeScript**: `strict: true`, `noUncheckedIndexedAccess: true`,
  `exactOptionalPropertyTypes: true`. Don't relax these without an ADR.
- **Error handling**: throw `Error` subclasses with a `name` field. Catch
  narrowly; don't swallow.

### Build, Test, Run

```bash
pnpm install
pnpm build               # tsc
pnpm start               # node dist/index.js
pnpm test                # vitest run
pnpm coverage            # vitest run --coverage with 85% gate
pnpm lint                # biome lint
pnpm typecheck           # tsc --noEmit
pnpm ship-check          # full pre-flight (matches CI)
```

### Anti-patterns specific to TypeScript

- Type assertions (`as Foo`) instead of type guards — narrow with predicates
- Non-null assertion (`!`) — usually wrong; use optional chaining + default
- `any` as an escape hatch — use `unknown` and narrow
- `// @ts-ignore` without `-expect-error` and a comment
- CommonJS interop hacks — this project is pure ESM; don't add `require`
- Default exports — they break refactor tooling and aren't worth the
  syntactic noise; prefer named exports
- Mixing `Promise` and callbacks — use async/await throughout
