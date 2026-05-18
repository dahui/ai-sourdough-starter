# ADR-0000: Record architecture decisions

- **Status**: accepted
- **Date**: project inception

## Context

We need to record the architectural decisions made on this project so that
contributors and future maintainers understand *why* the system looks the
way it does, not just *what* it looks like.

Code shows what; comments rot; commit messages are easily lost in
chronological noise. A durable, immutable record of major decisions —
sitting in the repo, versioned with the code — is the cheapest way to
preserve institutional context.

## Decision

We will keep Architecture Decision Records in `/docs/adr/`, one file per
decision, numbered sequentially with a 4-digit prefix.

Each ADR contains:
- **Status**: proposed → accepted → superseded (one-way; never reversed)
- **Date**: ISO 8601
- **Context**: what forces are at play
- **Decision**: what we're doing
- **Consequences**: positive, negative, and neutral effects
- **Alternatives Considered**: what we rejected and why

ADRs are **immutable once accepted**. To change a decision, write a new ADR
that supersedes the old one. The old ADR's status flips to `superseded` and
gains a link to the successor.

Triggers for writing an ADR (per AGENTS.md §3):
- Choosing a framework
- Choosing a data store
- Defining a public API surface
- Changing module boundaries
- Changing the build system
- Choosing an auth model
- Picking a serialization format

## Consequences

**Positive**:
- New contributors can rapidly understand load-bearing decisions without
  archaeology
- We can re-evaluate decisions with full context when conditions change
- Reviewers can ask "is there an ADR for this?" as a forcing function for
  intentionality

**Negative**:
- Writing ADRs costs time at the moment of decision (mitigated by the
  `/adr` slash command's template)
- Risk of ritual: ADRs for trivial choices, or ADRs after-the-fact for
  decisions already locked in

**Neutral**:
- ADRs live alongside code, not in a wiki — survives repo migration, dies
  if the repo dies

## Alternatives considered

- **Wiki / Notion / shared docs**: rejected — drifts from code, doesn't
  survive contributor turnover, no version control alongside the code it
  describes
- **Long-form commit messages**: rejected — discoverability is poor; ADRs
  need to be findable years later
- **No formal record (rely on code review notes)**: rejected — review
  context evaporates after the PR closes; no durable record

## References

- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) — Michael Nygard, 2011
- [adr-tools](https://github.com/npryce/adr-tools) — for the tooling lineage
