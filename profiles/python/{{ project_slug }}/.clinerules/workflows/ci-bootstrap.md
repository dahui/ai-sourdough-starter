
Regenerate the project's CI workflow from the starter's templates for the
active profile.

Usage: `/ci-bootstrap`

Steps:

1. Read `.starter-manifest.json` to determine the active profile.
2. Delegate to the `ci-bootstrapper` subagent.
3. The subagent re-renders the profile's CI workflow files from the starter's
   templates, preserving any project-specific customizations marked with
   `# starter:preserve-begin` / `# starter:preserve-end` blocks.
4. The subagent writes:
   - `.github/workflows/ci.yml` (lint, test, coverage gate, security scan)
   - `.github/workflows/security.yml` (gitleaks, dependency scan, code scan)
   - `.github/dependabot.yml` (or `renovate.json` if configured)
   - Profile-specific: `.golangci.yml`, `pyproject.toml` ruff/mypy sections,
     `.eslintrc` or `biome.json`, `pom.xml` plugin section
5. The subagent reports a diff summary and asks the user to review before
   committing.

Use this command after pulling starter updates (`copier update`) or when CI
configuration has drifted from the template.