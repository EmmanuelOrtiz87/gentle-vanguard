@pytest.mark.parametrize("input,expected", [ ("hello", "HELLO"), ("world", "WORLD"), ("pytest",
"PYTEST"), ]) def test_uppercase(input, expected): assert input.upper() == expected

@pytest.mark.parametrize("email,is_valid", [ ("user@example.com", True), ("invalid-email", False),
("", False), ("user@.com", False), ]) def test_email_validation(email, is_valid): assert
validate_email(email) == is_valid

````

## Markers

```python
# pytest.ini or pyproject.toml
[tool.pytest.ini_options]
markers = [
    "slow: marks tests as slow",
    "integration: marks integration tests",
]

# Usage
@pytest.mark.slow
def test_large_data_processing():
    ...

@pytest.mark.integration
def test_database_connection():
    ...

@pytest.mark.skip(reason="Not implemented yet")
def test_future_feature():
    ...

@pytest.mark.skipif(sys.platform == "win32", reason="Unix only")
def test_unix_specific():
    ...

# Run specific markers
# pytest -m "not slow"
# pytest -m "integration"
````

## Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_fetch_data()
    assert result is not None
```

## Commands

```bash
pytest                          # Run all tests
pytest -v                       # Verbose output
pytest -x                       # Stop on first failure
pytest -k "test_user"           # Filter by name
pytest -m "not slow"            # Filter by marker
pytest --cov=src                # With coverage
pytest -n auto                  # Parallel (pytest-xdist)
pytest --tb=short               # Short traceback
```

## Keywords

pytest, python, testing, fixtures, mocking, parametrize, markers
