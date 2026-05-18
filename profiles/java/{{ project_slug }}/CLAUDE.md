# {{ project_name }}

@AGENTS.md

> The rules above apply to every AI-assisted project (universal discipline).
> The sections below are SPECIFIC to this project and should be kept current.

## Project Overview

{{ project_description }}

## Architecture

```
{{ project_slug }}/
├── pom.xml                                    # Maven build (lint, test, coverage, security)
├── src/main/java/{{ java_package | replace('.', '/') }}/
│   ├── App.java                               # entry point (main)
│   └── Hello.java                             # sample; replace with real code
├── src/test/java/{{ java_package | replace('.', '/') }}/
│   └── HelloTest.java                         # JUnit 5 tests
├── docs/adr/                                  # architecture decision records
├── plans/                                     # plan files
└── .github/workflows/                         # CI: ci.yml, security.yml
```

## Conventions

- **Group ID**: `{{ java_group_id }}`
- **Root package**: `{{ java_package }}`
- **Records over POJOs** for value objects; final fields where possible
- **`Optional<T>`** for absent return values; avoid `null` in API surfaces
- **`Objects.requireNonNull`** for constructor and method parameter null
  checks

## Build, Test, Run

```bash
mvn -B verify              # full build (matches CI)
mvn -B test                # tests only
mvn -B spotless:apply      # auto-format
mvn -B checkstyle:check    # lint
java -jar target/{{ project_slug }}.jar

# Single test
mvn -B test -Dtest=HelloTest#greetReturnsGreeting
```

## Current Focus

- See `/plans/`

## Gotchas

- _None yet._

## Key Files

- `pom.xml` — build, dependency, plugin configuration
- `src/main/java/{{ java_package | replace('.', '/') }}/App.java` — entry point
- `.github/workflows/ci.yml` — source of truth for "green"

## External References

_Dashboards, runbooks, design docs._
