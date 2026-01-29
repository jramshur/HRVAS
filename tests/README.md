# HRVAS-Python Test Suite

This directory contains the testing infrastructure for the project.

## Structure

*   **`unit/`**: Unit tests for individual modules and functions. These tests are fast and isolated.
*   **`validation/`**: Integration tests and validation scripts that compare HRVAS-Python results against the MATLAB Reference Set (Ground Truth).
*   **`fixtures/`**: Static data files used by tests.

## Running Tests

### Unit Tests
Run all unit tests using `pytest` from the project root:

```bash
pytest
```

To run only unit tests:

```bash
pytest tests/unit
```

### Validation
To run the full validation against the Reference Set:

```bash
python tests/validation/validate_reference.py
```

See `tests/validation/README.md` for more details on the validation process.
