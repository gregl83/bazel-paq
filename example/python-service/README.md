# Python Service

Example [Python Flask](https://github.com/pallets/flask) service using `bazel-paq`.

Uses [rules_python](https://github.com/bazel-contrib/rules_python) module.

## Requirements Lock File

Build expects [requirements_lock.txt](https://pip.pypa.io/en/stable/reference/requirements-file-format/) to exist in source.

Generated from [pyproject.toml](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/) using:
```bash
python -m piptools compile pyproject.toml -o requirements_lock.txt
```

> **Note:** Requires `pip-tools` to compile requirements_lock.txt.
