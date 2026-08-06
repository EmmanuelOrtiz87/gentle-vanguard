## Error Handling

**Patterns:**

```python
# Prefer specific exception types
def get_user(user_id):
    try:
        return database.fetch_user(user_id)
    except DatabaseConnectionError:
        logger.error(f"Database unavailable when fetching user {user_id}")
        raise ServiceUnavailableError("User service temporarily unavailable")
    except UserNotFoundError:
        logger.info(f"User {user_id} not found")
        return None  # Expected case, not exceptional
```

**Guidelines:**

- **Fail fast**: Validate inputs at boundaries. Don't let bad data propagate.
- **Return typed errors**: Use `Result[T, E]` types (Rust, Swift) or `Either` (functional languages)
  instead of exceptions for expected failures.
- **Never swallow exceptions**: Empty `catch` blocks are a code smell. At minimum, log and re-raise.
- **Use error codes sparingly**: HTTP status codes make sense at API boundaries. Inside your
  application, use typed errors.
