#!/usr/bin/env python3
"""Post-generation hook for cookiecutter compatibility (NodeJS/TS profile)."""
from __future__ import annotations

import os
import stat
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path.cwd()


def chmod_plus_x(path: Path) -> None:
    if not path.exists():
        return
    mode = path.stat().st_mode
    path.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def main() -> int:
    hooks_dir = PROJECT_ROOT / ".claude" / "hooks"
    if hooks_dir.is_dir():
        for script in hooks_dir.glob("*.sh"):
            chmod_plus_x(script)

    if not (PROJECT_ROOT / ".git").exists():
        try:
            subprocess.run(["git", "init", "-q"], cwd=PROJECT_ROOT, check=True)
            subprocess.run(["git", "add", "."], cwd=PROJECT_ROOT, check=True)
            print("Initialized git repo (no commit yet — review staged files).")
        except (FileNotFoundError, subprocess.CalledProcessError) as exc:
            print(f"Skipped git init: {exc}", file=sys.stderr)

    print("Bootstrap complete.")
    print("Next steps:")
    print("  - Review staged files: git status")
    print("  - Read AGENTS.md and plans/README.md")
    print("  - Install deps:  pnpm install")
    print("  - Run tests:     pnpm test")
    return 0


if __name__ == "__main__":
    sys.exit(main())
