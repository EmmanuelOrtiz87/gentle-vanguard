## Naming

**Rules:**

- **Boolean variables**: Use positive names (`isActive`, `hasPermission`, `shouldRetry`). Avoid
  negated names like `isNotDisabled`.
- **Functions/methods**: Verbs or verb phrases (`calculateTotal()`, `validateInput()`,
  `fetchUser()`).
- **Classes/types**: Nouns or noun phrases (`UserAccount`, `PaymentProcessor`, `HttpClient`).
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_MS`).

```python
# Bad
def proc(d):
    r = []
    for i in d:
        if i.get('a') == True:
            r.append(i.get('n'))
    return r

# Good
def extract_active_user_names(users):
    active_users = [user for user in users if user['is_active']]
    return [user['name'] for user in active_users]
```

**Searchable names**: Avoid single-letter variables except in trivial loops. Use names that can be
found with grep.
