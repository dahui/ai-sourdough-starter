"""Sample module shipped with the starter. Replace once real code lives here."""

from __future__ import annotations


class EmptyNameError(ValueError):
    """Raised when ``greet`` is called with an empty or whitespace-only name."""

    def __init__(self) -> None:
        super().__init__("name must not be empty")


def greet(name: str) -> str:
    """Return a greeting for the given name.

    Args:
        name: target of the greeting. Whitespace is stripped.

    Returns:
        ``"Hello, <name>!"``.

    Raises:
        EmptyNameError: if ``name`` is empty or whitespace-only.
    """
    trimmed = name.strip()
    if not trimmed:
        raise EmptyNameError
    return f"Hello, {trimmed}!"
