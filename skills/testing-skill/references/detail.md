# Testing Skill — Detailed Reference

Extracted sections from the main SKILL.md to keep it concise.

## Anti-Patterns to Avoid

1. **Don't test private methods** — Test public interfaces
2. **Don't assert on timestamps** — Mock time
3. **Don't make tests order-dependent** — Reset state
4. **Don't skip flaky tests** — Fix them or mark as known issue
5. **Don't test third-party code** — Mock external services

## Risk-Based Testing

1. **Identify risks** for each feature (data loss, security, UX, performance)
2. **Score** likelihood × impact
3. **Allocate test effort** proportionally to risk score
4. **Reassess** after each release

## Coverage Goals

| Type                | Target |
| ------------------- | ------ |
| Line coverage       | >80%   |
| Branch coverage     | >75%   |
| Mutation score      | >60%   |
| Critical path E2E   | 100%   |
| API endpoint tested | >90%   |

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
  components/Button/
    Button.tsx
    Button.test.tsx       Unit
    Button.e2e.spec.ts    E2E
  services/
    api.ts
    api.test.ts           Integration
    api.mock.ts           Mock
  __tests__/
    setup.ts              Setup
```

## Test Structure (AAA Pattern)

```typescript
describe('User', () => {
  describe('age', () => {
    it('should update age when birthday is called', () => {
      const user = createUser({ name: 'John', age: 30 });
      user.birthday();
      expect(user.age).toBe(31);
    });
  });
});
```

## Quick CLI Reference

```bash
npm test                  # Run all tests
npm run test:coverage     # Run with coverage
npm test -- Button.test.tsx # Run specific file
npm run test:watch        # Watch mode
npx playwright test       # Run E2E
```
