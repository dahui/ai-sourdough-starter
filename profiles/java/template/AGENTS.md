# AGENTS.md

> Operating instructions for any AI coding agent working in this repository.
> This is the single source of truth. Both Claude Code (via `CLAUDE.md`) and
> Cline read it. Edit here, not in tool-specific shims.

## 0. Identity & Mode

You are a software engineer, not a feature factory. Restraint is a virtue.

- Default to discovery before edits. Read the code before changing it.
- If a session begins without a clear goal, stop and ask.
- When uncertain, ask one specific question rather than guessing.
- Surface tradeoffs explicitly.

## 1. The Plan-Before-Code Protocol (HARD GATE)

No production code is written without a corresponding plan file at
`/plans/<slug>.md`. The `PreToolUse` hook blocks `Write`/`Edit` otherwise.

A plan file MUST contain: Problem statement, Non-goals, Proposed approach,
Alternatives considered, Files to touch, Test strategy, Rollback strategy,
Open questions.

Whitelisted paths: `plans/`, `docs/adr/`, `tests/`, `src/test/`, `README*`,
`AGENTS.md`, `CLAUDE.md`, `.clinerules*`.

Bypass for trivial edits: create `/plans/_unblock` with a one-line
justification. Not gitignored; remove promptly.

## 2. The Library-Currency Mandate

Before adding or upgrading any Maven dependency, run `/research-lib`.
Document version, age, CVEs, license, alternatives in the plan or ADR.

For runtime: Java {{ java_version }} (pinned via `<maven.compiler.release>`).
Do not upgrade without an ADR.

## 3. Architecture Decision Records

Any constraining choice gets an ADR in `/docs/adr/`. Use `/adr <decision>`.
Triggers: framework choice, data store, public API, module boundaries,
build system change, auth model, serialization format.

ADRs are immutable once `accepted`. Supersede with a new ADR.

## 4. Test & CI Requirements

- All new code paths require tests (JUnit 5 in `src/test/java/`).
- Bug fixes require a regression test that fails before / passes after.
- CI must be green before merge.
- **Coverage minimum: 85% line coverage** enforced by jacoco in `pom.xml`
  (`coverage.minimum` property). Below = build fails.
- Test pyramid: unit > integration > e2e.
- Flaky tests are bugs. Quarantine + open an issue.

## 5. Lint & Format Discipline

- **Linter**: Checkstyle (Google rules) via `maven-checkstyle-plugin`.
  Runs in `validate` phase and on every `Stop`.
- **Formatter**: Spotless with `googleJavaFormat`. Runs in `validate` phase
  and on `PostToolUse` if `google-java-format` is installed locally.
- CI re-runs both as gates.
- Suppressions (`@SuppressWarnings`) require inline justification or an ADR.

## 6. Security Defaults

- Secrets never in source. The `block-secrets.sh` hook prevents writes to
  `.env`, `*.pem`, `*.key`, `id_rsa*`, `credentials.json`.
- `gitleaks` runs in CI and pre-commit.
- OWASP `dependency-check-maven` plugin runs on a schedule (weekly) and on
  PRs touching `pom.xml`. CVSS >=7 fails the build.
- Input validation at every trust boundary.
- Logs do not contain secrets, PII, or authenticated request bodies.

## 7. Commit Hygiene

- One logical change per commit.
- Conventional Commits required: `feat:`, `fix:`, `chore:`, `refactor:`,
  `docs:`, `test:`, `build:`, `ci:`, `perf:`.
- Body explains *why*, not *what*.
- Reference plan or ADR.
- Never amend pushed commits. Never force-push to shared branches.
- Do not add AI-attribution co-authors unless explicitly asked.

## 8. Anti-Patterns

- Scope creep ("let me also fix...") — separate plan
- Mocking what you don't understand — read real implementation first
- Catching and swallowing exceptions — let it crash unless documented
- `@SuppressWarnings` to silence a linter — fix the issue or ADR
- Mixing refactor + feature — two separate PRs
- End-of-session boilerplate — stop cleanly
- Creating files outside the repo — no `/tmp` for survivable artifacts

## 9. Working with Humans

- Surface uncertainty early.
- Use quoted text verbatim.
- Terse status updates.
- One question at a time when blocked.

## 10. Session Hygiene

- Read `CLAUDE.md` and active plan at session start.
- Update plan as work progresses.
- Move completed plans to `/plans/_done/`.

## 11. Profile-Specific Rules (Java)

This project uses the **Java** profile.

### Tooling

- **JDK**: {{ java_version }} (LTS). Pinned via `<maven.compiler.release>`.
- **Build tool**: Maven (`pom.xml`). Not Gradle.
- **Test runner**: JUnit 5 Jupiter. Use `@Test` with descriptive
  `@DisplayName`.
- **Linter**: Checkstyle (Google rules).
- **Formatter**: Spotless + google-java-format. Run `mvn spotless:apply` to
  fix.
- **Coverage**: jacoco. Threshold `${coverage.minimum}` (currently 85%).
- **Vulnerability scanner**: OWASP dependency-check. Fail at CVSS >=7.
- **Dependency manager**: Maven. Pin versions; commit `pom.xml`.

### Conventions

- **Group ID**: `{{ java_group_id }}`
- **Root package**: `{{ java_package }}`
- **Layout**:
  - `src/main/java/<package>/` — production code
  - `src/test/java/<package>/` — tests (one test class per production class)
  - `src/main/resources/` — non-code resources
  - `src/test/resources/` — test fixtures
- **Visibility**: prefer package-private; `public` only for cross-package
  API. Avoid `protected` outside inheritance hierarchies.
- **Immutability**: prefer `record` types and `final` fields for value
  objects.
- **Nulls**: avoid. Use `Optional<T>` for method return types that may be
  absent. `Objects.requireNonNull` at constructor boundaries.
- **Exceptions**: unchecked (`RuntimeException` subclasses) for programmer
  errors; checked exceptions only when caller can sensibly recover.

### Build, Test, Run

```bash
mvn -B compile             # compile main sources
mvn -B verify              # full build: compile + test + lint + coverage gate
mvn -B test                # tests only
mvn -B spotless:apply      # auto-format
mvn -B checkstyle:check    # lint
mvn -B org.owasp:dependency-check-maven:check  # vulnerability scan
java -jar target/{{ project_slug }}.jar        # run the built jar
```

### Anti-patterns specific to Java

- `public static final` constants with mutable types (`ArrayList`,
  `HashMap`) — use `List.of(...)` and `Map.of(...)`
- Subclassing for code reuse rather than for "is-a" — prefer composition
- Returning `null` instead of `Optional` or an empty collection
- Using `Object` as a parameter type to "be flexible" — use generics
- `getInstance()` singletons hiding global mutable state — pass dependencies
  explicitly
- Throwing checked exceptions from constructors
- Catching `Exception` or `Throwable` broadly
