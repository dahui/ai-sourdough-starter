# Plan: Fix CI render failures across all 4 profiles

## Problem statement

The `test-rendering` CI workflow failed on every profile after the
flattening + copier-only restructure. Local copier (9.15.1) was now
available, so I could iterate on actual renders instead of speculating.

Three independent bugs surfaced in sequence:

1. **`_tasks` clause used a non-existent `| exists` Jinja filter.**
   The clause `when: "{{ not (_copier_conf.dst_path + '/.git') | exists }}"`
   crashed every render with `TemplateAssertionError: No filter named
   'exists'`. Copier exposes no such filter; that was wishful thinking.

2. **`_templates_suffix` defaulted to `.jinja`.** When I dropped the
   explicit setting earlier, copier reverted to its default of only
   rendering files with `.jinja` extensions. Result: `go.mod` shipped to
   the rendered project with literal `{{ module_path }}` text. Same for
   every other un-suffixed file.

3. **Java's path-templated package directory was broken from day one.**
   The directory name on disk was `{{ java_package | replace('.', '/') }}`,
   but Unix paths can't contain `/` in a single segment. When I created
   it via the Write tool, the literal `/` inside the Jinja expression was
   interpreted as a path separator, splitting the name across two nested
   directories: `{{ java_package | replace('.', '` / `') }}`. The first
   segment is an unterminated Jinja string literal, so copier crashed
   parsing it.

## Non-goals

- Doctor improvements (separate fix; already landed)
- Adding the `bin/sync-profiles` mechanism (already landed)
- Restructuring profiles (architecture is settled)
- Adding language-specific runtime checks beyond what CI does

## Proposed approach

### Fix 1: Replace the broken `when:` clause

Drop the `| exists` filter entirely. `git init` is idempotent — the
shell-level `test -d .git || git init -q` check inside a string command
serves the same purpose, no Jinja filter required.

```yaml
_tasks:
  - "chmod +x {{ _copier_conf.dst_path }}/.claude/hooks/*.sh"
  - "cd '{{ _copier_conf.dst_path }}' && (test -d .git || git init -q) && git add -A ."
```

### Fix 2: Set `_templates_suffix: ""`

Explicit empty string disables the suffix requirement; every file's
content (and path) goes through Jinja. The earlier "rely on default"
approach was wrong — copier's default IS `.jinja`, which is the
opposite of what we want.

```yaml
_templates_suffix: ""
```

Files containing literal Jinja-conflicting syntax (Go `text/template`,
JSON Schema with `{{ }}`) wrap that content in `{% raw %}` blocks. The
Hello-Worlds in each profile don't contain such syntax.

### Fix 3: Static `_pkg/` for Java + post-render task

Java's package convention forces a directory hierarchy from a
dot-separated name. Since copier path-templates each segment
independently and can't produce a `/` inside one segment, the
"single-segment with `replace('.', '/')`" approach is impossible
on a normal filesystem.

Restructure: ship the .java files inside a static `_pkg/` placeholder,
add a `_tasks` step that moves them into the correct package directory
post-render.

```
profiles/java/template/src/main/java/_pkg/{App,Hello}.java
profiles/java/template/src/test/java/_pkg/HelloTest.java
```

```yaml
_tasks:
  - "chmod +x ..."
  - >-
    cd '{{ _copier_conf.dst_path }}' && pkg='{{ java_package }}' &&
    pkg_path="$(printf '%s' "$pkg" | tr '.' '/')" &&
    for tree in main test; do
      mkdir -p "src/$tree/java/$pkg_path" &&
      mv "src/$tree/java/_pkg/"* "src/$tree/java/$pkg_path/" &&
      rmdir "src/$tree/java/_pkg";
    done
  - "cd ... && git init ..."
```

The Java source files themselves still use Jinja for the `package`
statement (`package {{ java_package }};`) — that gets templated by the
`_templates_suffix: ""` setting in fix #2.

### Fix 4: Bump CI copier pin

Update CI from `copier==9.4.1` to `copier==9.15.1` to match what I
tested with locally. Reduces "works locally, fails in CI" risk.

## Alternatives considered

For fix 3:

1. **Use `_envops` with a custom Jinja extension** that registers a
   path-building filter. Too complex for v0.1.0; introduces a
   maintenance burden.
2. **Force users to answer one package segment at a time** (3 answers
   instead of 1). Surprises users; doesn't generalize to packages of
   different depths.
3. **Hardcode a `com.example.app` package** and document the rename
   step. Worse UX; users have to remember to rename.

The `_pkg/` placeholder + `_tasks` move is the smallest change that
preserves the desired UX (one `java_package` answer, correct package
path in output).

## Files to touch

- `profiles/{go,java,nodejs-ts,python}/copier.yml` — add
  `_templates_suffix: ""`, replace the broken `when:` clause with a
  shell-level idempotent command
- `profiles/java/copier.yml` — add the `_pkg/` relocation task
- `profiles/java/template/src/main/java/_pkg/{Hello,App}.java` — new
  location for the source files (moved from the broken nested dir)
- `profiles/java/template/src/test/java/_pkg/HelloTest.java` — same
- `.github/workflows/test-rendering.yml` — bump copier pin to 9.15.1

## Test strategy

Validated locally with copier 9.15.1:

```bash
copier copy --trust --defaults --data project_name='Demo' --data project_slug='demo' \
  --data module_path='github.com/test/demo' profiles/go /tmp/render-go
# Expect: go.mod contains `module github.com/test/demo` (templated correctly)

copier copy --trust --defaults --data project_name='Demo' --data project_slug='demo' \
  --data java_package='com.example.demo' profiles/java /tmp/render-java
# Expect: src/main/java/com/example/demo/Hello.java with `package com.example.demo;`

# Same for nodejs-ts and python.
```

All four profiles confirmed to:
- Render without copier errors
- Produce templated content (not literal Jinja in output files)
- Run the post-render `_tasks` cleanly (chmod hooks, git init, Java
  package relocation)
- Doctor still passes 24/24
- sync-profiles --check still passes

End-to-end build verification (go test, mvn verify, pnpm test, pytest)
runs in CI — local toolchains weren't installed.

## Rollback strategy

Per-fix granularity. Each change is in its own file or set of files:
- Fix 1: revert the `_tasks` block in each copier.yml
- Fix 2: revert `_templates_suffix` line in each copier.yml
- Fix 3: revert the Java template structure and copier.yml
- Fix 4: revert the version pin

## Open questions

None blocking. The Java `_pkg/` pattern is slightly unusual but
documented in the copier.yml comment for future maintainers.
