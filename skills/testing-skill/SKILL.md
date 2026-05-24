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

           E2E      Few, slow, expensive (Playwright, Cypress)

       Integration  Some, moderate (API tests, component tests)

        Unit      Many, fast, cheap (Vitest, Jest, Go test)

```

## Framework Selection

| Type        | Stack              | Recommended           |
| ----------- | ------------------ | --------------------- |
| Unit        | Node.js/TypeScript | Vitest, Jest          |
| Unit        | Go                 | testing package       |
| Unit        | Python             | pytest                |
| Integration | Node.js            | Supertest, MSW        |
| E2E         | React/Vue          | Playwright, Cypress   |
| API         | Any                | REST Client, Postman  |
| Component   | React              | React Testing Library |
| Component   | Vue                | Vue Test Utils        |

## Test File Naming

```
src/
 components/
    Button/
        Button.tsx
        Button.test.tsx       Unit tests
        Button.e2e.spec.ts    E2E tests
 services/
    api.ts
        api.test.ts           Integration tests
        api.mock.ts           Mock data
 __tests__/
     setup.ts                  Test setup
```

## Test Structure (AAA Pattern)

```typescript
// BAD
test('test', () => {
  const user = { name: 'John', age: 30 };
  user.age = 31;
  expect(user.age).toBe(31);
});

// GOOD
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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)