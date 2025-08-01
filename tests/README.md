# Tests

## Overview
Contains unit, integration and end-to-end tests for all modules. The test suite
ensures API compatibility and verifies algorithm performance.

## Features
- Pytest based unit tests
- BDD scenarios and SQL fixtures
- Playwright end-to-end tests under `e2e-tests/`

## Usage
Run all tests:
```bash
pytest tests/
```
Run a specific suite:
```bash
pytest tests/algorithms/
```

## Related Documentation
- [Testing Guide](../docs/api/testing_guide.md)
- [Project README](../README.md)
