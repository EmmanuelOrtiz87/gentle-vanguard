## Testing

**The Testing Trophy** (not pyramid):

```
     E2E Tests  (few)
    Integration (some)
   Unit Tests   (many)
  Static Analysis (all code)
```

**Guidelines:**

- Test behavior, not implementation. Your tests should pass after a refactor if the behavior didn't
  change.
- One assertion concept per test. Use multiple `it()` blocks rather than multiple asserts in one.
- Use realistic test data. `"foo"` and `123` don't catch edge cases.
- For AI-generated code: always verify with tests. The AI writes the code, you write the tests.

```python
# Bad: Tests implementation details
def test_get_user():
    mock_db = MagicMock()
    service = UserService(mock_db)
    result = service._fetch_and_transform_user(42)
    assert mock_db.execute.called_once_with("SELECT * FROM users WHERE id=42")

# Good: Tests behavior
def test_get_user_returns_user_when_found():
    user_repo = InMemoryUserRepository([User(id=42, name="Alice")])
    service = UserService(user_repo)
    result = service.get_user(42)
    assert result.name == "Alice"

def test_get_user_returns_none_when_not_found():
    user_repo = InMemoryUserRepository([])
    service = UserService(user_repo)
    result = service.get_user(99)
    assert result is None
```
