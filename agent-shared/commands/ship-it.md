---
description: Pre-flight check — tests, coverage, lint, security, commits, ADRs
argument-hint:
---

Pre-flight check before opening a PR or merging. Verifies all AGENTS.md
shipping requirements are met.

Usage: `/ship-it`

Checks performed (in order; stop on first failure):

1. **Plan exists** for the active work. There must be at least one
   non-template plan file in `/plans/` referenced by the current branch's
   commits.
2. **Tests pass**: run the profile's test command. Must exit 0.
3. **Coverage ≥85%**: run the profile's coverage gate script. Must exit 0.
4. **Lint clean**: run the profile's linter. Must exit 0.
5. **Format clean**: run the profile's formatter in check mode. Must report
   no diff.
6. **Security scan clean**: run the profile's vulnerability scanner
   (`govulncheck`, `pip-audit`, `npm audit --audit-level=high`, OWASP
   dep-check). Must exit 0.
7. **No secrets in diff**: run `gitleaks detect --staged` (or against the
   current branch's diff vs main).
8. **Commits follow Conventional Commits**: parse commit messages on the
   current branch against the regex
   `^(feat|fix|chore|refactor|docs|test|build|ci|perf)(\(.+\))?:`. Report
   non-conforming commits.
9. **ADR required check**: if the diff touches files matching ADR-trigger
   patterns (build config, schema files, public API exports, auth
   middleware), verify a new ADR exists in `/docs/adr/` referenced by a
   commit on this branch.

Output: a checkbox report. If everything passes, print "READY TO SHIP" and
the command for opening the PR. If anything fails, list the failures and
the commands to address each.

This command MUST NOT auto-fix issues. The user fixes them.
