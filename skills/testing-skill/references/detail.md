fetchUser: vi.fn(), }));

// Mock time for consistent tests vi.useFakeTimers();

// Reset mocks between tests afterEach(() => { vi.clearAllMocks(); });

````

## Coverage Targets

| Coverage Type | Minimum | Recommended |
| ------------- | ------- | ----------- |
| Statements    | 70%     | 80%         |
| Branches      | 60%     | 70%         |
| Functions     | 70%     | 80%         |
| Lines         | 70%     | 80%         |

## CI/CD Integration

```yaml
# GitHub Actions
- name: Run tests
  run: npm run test:coverage
- name: Upload coverage
  uses: codecov/codecov-action@v3
````

## Anti-Patterns to Avoid

1. **Don't test private methods** - Test public interfaces
2. **Don't assert on timestamps** - Mock time
3. **Don't make tests order-dependent** - Reset state
4. **Don't skip flaky tests** - Fix them or mark as known issue
5. **Don't test third-party code** - Mock external services

## Quick Reference

```bash
# Run tests
npm test

# Run with coverage
npm run test:coverage

# Run specific file
npm test -- Button.test.tsx

# Run in watch mode
npm run test:watch

# Run E2E
npx playwright test
```
