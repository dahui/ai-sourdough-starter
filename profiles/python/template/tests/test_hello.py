"""Tests for the sample hello module."""

from __future__ import annotations

import pytest

from {{ python_module }}.hello import EmptyNameError, greet


def test_greet_returns_formatted_greeting() -> None:
    assert greet("world") == "Hello, world!"


def test_greet_strips_whitespace() -> None:
    assert greet("  Ada  ") == "Hello, Ada!"


def test_greet_empty_raises() -> None:
    with pytest.raises(EmptyNameError):
        greet("")


def test_greet_whitespace_only_raises() -> None:
    with pytest.raises(EmptyNameError):
        greet("   \t\n")


def test_empty_name_error_is_value_error() -> None:
    assert issubclass(EmptyNameError, ValueError)


def test_empty_name_error_message() -> None:
    err = EmptyNameError()
    assert str(err) == "name must not be empty"
