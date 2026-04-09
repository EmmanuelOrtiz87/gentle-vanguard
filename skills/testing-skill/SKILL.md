---
name: testing-skill
description: Use when writing tests, setting up test coverage, choosing test frameworks, or improving test quality. Triggers: "write test", "add test", "test coverage", "unit test", "integration test", "e2e test", "testing framework", "test setup".
---

# Testing Skill

## Purpose

Guide test creation, framework selection, and coverage improvement for all project types.

## When to Use

Activate this skill when:
- Writing new tests (unit, integration, e2e)
- Setting up test infrastructure
- Improving test coverage
- Choosing testing frameworks
- Debugging failing tests

## Core Principles

1. **Test behavior, not implementation** - Test what the code does, not how it does it
2. **Arrange-Act-Assert (AAA)** - Clear test structure
3. **One assertion per test** - When practical, test one thing per test
4. **Meaningful names** - Test names describe the expected behavior
5. **Fast feedback** - Keep unit tests fast (<100ms)
6. **Independence** - Tests should not depend on each other

## Test Pyramid

```
        ┌─────────┐
        │   E2E   │  ← Few, slow, expensive (Playwright, Cypress)
       ┌─────────┐
       │Integration│ ← Some, moderate (API tests, component tests)
      ┌─────────┐
      │  Unit   │  ← Many, fast, cheap (Vitest, Jest, Go test)
     └─────────┘
```

## Framework Selection

| Type | Stack | Recommended |
|------|-------|-------------|
| Unit | Node.js/TypeScript | Vitest, Jest |
| Unit | Go | testing package |
| Unit | Python | pytest |
| Integration | Node.js | Supertest, MSW |
| E2E | React/Vue | Playwright, Cypress |
| API | Any | REST Client, Postman |
| Component | React | React Testing Library |
| Component | Vue | Vue Test Utils |

## Test File Naming

```
src/
├── components/
│   └── Button/
│       ├── Button.tsx
│       └── Button.test.tsx      ← Unit tests
│       └── Button.e2e.spec.ts   ← E2E tests
├── services/
│   └── api.ts
│       └── api.test.ts          ← Integration tests
│       └── api.mock.ts          ← Mock data
└── __tests__/
    └── setup.ts                 ← Test setup
```

## Test Structure (AAA Pattern)

```typescript
// ❌ Bad
test('test', () => {
  const user = { name: 'John', age: 30 };
  user.age = 31;
  expect(user.age).toBe(31);
});

// ✅ Good
describe('User', () => {
  describe('age', () => {
    it('should update age when birthday is called', () => {
      // Arrange
      const user = createUser({ name: 'John', age: 30 });
      
      // Act
      user.birthday();
      
      // Assert
      expect(user.age).toBe(31);
    });
  });
});
```

## Mocking Best Practices

```typescript
// Mock external dependencies
vi.mock('./external-service', () => ({
  fetchUser: vi.fn()
}));

// Mock time for consistent tests
vi.useFakeTimers();

// Reset mocks between tests
afterEach(() => {
  vi.clearAllMocks();
});
```

## Coverage Targets

| Coverage Type | Minimum | Recommended |
|---------------|---------|-------------|
| Statements | 70% | 80% |
| Branches | 60% | 70% |
| Functions | 70% | 80% |
| Lines | 70% | 80% |

## CI/CD Integration

```yaml
# GitHub Actions
- name: Run tests
  run: npm run test:coverage
- name: Upload coverage
  uses: codecov/codecov-action@v3
```

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
