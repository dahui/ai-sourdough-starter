
Run a code review pass over uncommitted changes or a specific set of files.

Usage:
- `/review` — review all uncommitted changes (staged + unstaged + untracked)
- `/review <path>` — review a specific file or directory

Delegate to the `reviewer` subagent. The subagent checks:

1. **AGENTS.md compliance**:
   - Is there a plan file in `/plans/` covering this change?
   - Are anti-patterns (§8) present? Scope creep, blind mocking, exception
     swallowing, lint suppressions without justification, mixed-concern
     diffs.
2. **Profile lint and format**: run the profile's linter and formatter; report
   findings.
3. **Test coverage**: do new code paths have tests? Are bug fixes accompanied
   by regression tests?
4. **Security**: any secrets in the diff? Any new external network calls
   without input validation at the boundary?
5. **Commit hygiene**: Conventional Commit prefix correct? Body explains why,
   not what? References plan or ADR?
6. **Dependencies**: any new third-party imports? Was `/research-lib` run for
   each?

The subagent produces a structured report:

```
PASS / FAIL: <one-line summary>
Blocking issues (must fix):
  - ...
Recommended improvements (should fix):
  - ...
Nits (optional):
  - ...
```

The reviewer never makes edits directly. The user decides what to fix.