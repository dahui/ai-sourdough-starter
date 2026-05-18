# Coverage policy

The starter enforces an **85% line coverage minimum** for all profiles, as
a CI gate. Below this number, the build fails.

## Why 85%?

- **>95%** chases diminishing returns. The last 5% are often impossible
  to cover without intrusive test seams (mocking `time.Now`, the
  filesystem, the network) that themselves become a maintenance burden.
- **<80%** allows entire significant code paths to be untested. A
  fast-moving team can let untested error branches accumulate; 80% is
  loose enough that this is invisible.
- **85%** forces tests for the happy path *and* the obvious error
  branches, while leaving room for legitimately-untestable
  initialization code, glue code, and bootstrap.

It's a forcing function, not a virtue. Hitting 85% with bad tests is
worse than missing 85% with good tests; the policy exists to keep an
honest team honest, not to substitute for code review.

## Per-profile enforcement

| Profile     | Tool                                          | How threshold is enforced                       |
|-------------|-----------------------------------------------|-------------------------------------------------|
| Go          | `go test -coverprofile` + `scripts/check-coverage.sh` | Script parses `go tool cover -func`, fails if total <85% |
| Python      | `pytest-cov`                                  | `pytest --cov-fail-under=85` (built-in)         |
| NodeJS-TS   | `vitest --coverage` + `c8`                    | `c8 --lines=85 --check-coverage`                |
| Java        | Maven + jacoco                                | `<minimum>0.85</minimum>` in jacoco plugin config |

All profiles' CI workflows run the coverage gate *after* tests. A test
failure short-circuits the build before coverage is checked.

## What counts as "covered"?

- **Line coverage** — was each executable line of source code executed at
  least once by tests?

Branch coverage is more rigorous but not enforced by default because:
- Tooling support is inconsistent across languages
- Threshold tuning becomes per-project
- The marginal value over good line coverage is modest for most code

If a project wants branch coverage, override the profile's coverage tool
configuration. Document the change in an ADR.

## Excluded paths

Generated code, mocks, and `main` functions are excluded from coverage in
each profile's gate script:

- Go: paths matching `/mock_`, `_mock.go`, `.pb.go`, `_generated.go`
- Python: `# pragma: no cover` markers + `tool.coverage.run.omit` in
  `pyproject.toml`
- TS: `c8.exclude` patterns in `package.json`
- Java: jacoco `<excludes>` patterns in `pom.xml`

If you add a generated-code path to your project, extend the relevant
exclude list.

## Lowering the threshold

We strongly recommend you don't. But if you must:

1. Open an ADR documenting *why* — what's the project context that makes
   85% inappropriate?
2. Change the threshold in **one** place per profile:
   - Go: `scripts/check-coverage.sh` second arg
   - Python: `pyproject.toml` `[tool.pytest.ini_options]` →
     `--cov-fail-under=N`
   - TS: `package.json` → `c8.lines`
   - Java: `pom.xml` jacoco config
3. Commit the change with a Conventional Commit referencing the ADR

The starter intentionally does NOT make this a single project-wide knob.
Per-profile control means the decision is visible in the diff.

## Raising the threshold

This is encouraged. Bump to 90% or 95% if the team is consistently meeting
85% with good tests. Same ADR + commit discipline applies.

## Coverage gaming

Coverage is gameable. Bad tests can hit 100% without proving anything.
The defense is code review, not the coverage tool. `/review` includes
test-quality checks; the reviewer subagent looks for:

- Tests with no assertions
- Tests that only assert "no error returned"
- Tests with massive setup and trivial verification
- Tests that mock the function under test (yes, this happens)

If you see these patterns, the project has a quality problem that 85%
coverage is masking. Fix the tests, not the threshold.
