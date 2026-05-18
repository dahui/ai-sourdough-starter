---
description: Multi-step architectural design; produces plan and ADR drafts
argument-hint: <feature-or-system-name>
---

Run a multi-step architectural design pass for a non-trivial feature or
restructuring.

Usage: `/architect <feature-or-system-name>`

Delegate this to the `architect` subagent. The subagent produces:

1. **Problem framing**: what is being built and why, in 3-5 sentences
2. **Constraints**: SLAs, dependencies, team capacity, legacy interop,
   security/compliance requirements
3. **Options considered**: at least 3 viable approaches, each with:
   - One-paragraph description
   - Tradeoffs (pros, cons, risks)
   - Rough complexity estimate
4. **Recommendation**: chosen approach with explicit reasons over the
   alternatives
5. **Module / file decomposition**: which directories and files this adds
   or changes, public API surface
6. **Data model changes**: schema deltas, migration strategy
7. **Test strategy**: unit, integration, e2e split; what's hardest to test
   and how
8. **Rollout plan**: feature flag? phased? big-bang? rollback strategy
9. **Open questions**: what is still unknown; who decides

The output is delivered as:
- A new entry in `/plans/<slug>.md` if it doesn't already exist
- A draft ADR in `/docs/adr/` if any choice meets the ADR trigger criteria
  (framework, data store, public API surface, module boundary, build system,
  auth model)

The `architect` subagent NEVER writes production code. The user reviews the
plan + ADR draft, then a separate Act-mode session implements it.