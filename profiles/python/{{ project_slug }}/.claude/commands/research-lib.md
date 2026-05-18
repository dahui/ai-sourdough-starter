---
description: Dossier on a package — version, age, CVEs, license, alternatives
argument-hint: <package-name>
---

Produce a currency-and-suitability dossier for a third-party library before
it is added to the project.

Usage: `/research-lib <package-name>` (e.g. `/research-lib zod`, `/research-lib testify`)

Delegate this work to the `library-currency` subagent. Provide the package
name and the project's profile language. The subagent must return:

1. **Current stable version** and release date
2. **Maintenance status**: active / dormant / archived / EOL
   - Commit frequency over last 90 days
   - Open vs closed issue ratio
   - Number of maintainers
3. **Security**: open CVEs, last security advisory date, severity
4. **License**: SPDX identifier, compatibility with this project's license
5. **Adoption signals**: download counts, dependent projects (only as
   tiebreakers, never as primary justification)
6. **Top 3 alternatives** with a one-line tradeoff for each
7. **Recommendation**: adopt / use alternative / defer (with reason)

The output must be appended to the active plan file under a
"Library Decisions" section, OR written to a new ADR if the choice is
architecturally significant (framework, data store, serialization format).

Never add the dependency to `go.mod` / `package.json` / `pyproject.toml` /
`pom.xml` in the same turn as the research. The user reviews the dossier
first.