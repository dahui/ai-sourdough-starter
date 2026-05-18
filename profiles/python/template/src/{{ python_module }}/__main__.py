"""Entry point for ``python -m {{ python_module }}`` and the console script."""

from __future__ import annotations

import sys

from {{ python_module }}.hello import greet


def main() -> int:
    print(greet("world"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
