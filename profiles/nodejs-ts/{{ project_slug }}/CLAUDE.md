# {{ project_name }}

@AGENTS.md

> Universal rules above; project-specific context below.

## Project Overview

{{ project_description }}

## Architecture

```
{{ project_slug }}/
├── package.json           # scripts, deps, engines, packageManager pinning
├── tsconfig.json          # strict mode + noUncheckedIndexedAccess
├── biome.json             # combined linter + formatter config
├── vitest.config.ts       # test runner + coverage thresholds (85%)
├── src/                   # production code (ESM, .ts source)
│   ├── index.ts           # entry point
│   └── hello.ts           # sample; replace with real code
├── tests/                 # cross-module tests
├── docs/adr/              # architecture decision records
├── plans/                 # plan files
└── .github/workflows/     # CI: ci.yml, security.yml
```

## Conventions

- **Pure ESM**: `"type": "module"`, imports use `.js` extension even for
  `.ts` source files
- **No default exports** — named exports only
- **Strict TS**: don't loosen `tsconfig.json` without an ADR
- **Error classes**: subclass `Error`, set `this.name`, narrow with
  `instanceof`

## Build, Test, Run

```bash
pnpm install
pnpm build               # tsc
pnpm start               # node dist/index.js
pnpm test                # vitest run
pnpm coverage            # vitest run --coverage with thresholds
pnpm lint                # biome lint
pnpm typecheck           # tsc --noEmit
pnpm ship-check          # full pre-flight (matches CI)

# Single test
pnpm vitest run -t "greet returns formatted greeting"
```

## Current Focus

- See `/plans/`

## Gotchas

- _None yet._

## Key Files

- `src/index.ts` — entry point
- `package.json` scripts — canonical commands
- `biome.json` — lint + format rules
- `vitest.config.ts` — coverage thresholds (the 85% gate)

## External References

_Dashboards, runbooks, design docs._
