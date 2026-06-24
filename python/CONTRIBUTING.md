# Contributing

Thank you for your interest in contributing to `cucumber-expressions`, a simpler alternative to regular expressions! This guide will help you get set up and understand our development workflow.

## 🚀 Quick Start

Using [`uv`](https://docs.astral.sh/uv/) is recommended for contributing with this project, though you can also install dependencies via `pip` (use `pip install . --group dev` with v25.1+) or your preferred tool.

First change to the directory containing the Python implementation and install development dependencies.

```console
cd python
uv sync
```

At the root of the repository, install pre-commit hooks to automatically validate linting and formatting of your Python code with every commit.

```console
cd ..
uv run pre-commit install
```

Unit tests can run via `pytest`.

```console
uv run pytest
```
