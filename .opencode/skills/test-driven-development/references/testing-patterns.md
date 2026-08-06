# Testing Patterns

## The Test Pyramid

Invest testing effort according to the pyramid — most tests should be small and fast, with
progressively fewer tests at higher levels.

### Test Sizes (Resource Model)

Beyond the pyramid levels, classify tests by what resources they consume:

| Size       | Constraints                                            | Speed        | Example                                                |
| ---------- | ------------------------------------------------------ | ------------ | ------------------------------------------------------ |
| **Small**  | Single process, no I/O, no network, no database        | Milliseconds | Pure function tests, data transforms                   |
| **Medium** | Multi-process OK, localhost only, no external services | Seconds      | API tests with test DB, component tests                |
| **Large**  | Multi-machine OK, external services allowed            | Minutes      | E2E tests, performance benchmarks, staging integration |

Small tests should make up the vast majority of your suite.

### Decision Guide

```
Is it pure logic with no side effects?
  → Unit test (small)

Does it cross a boundary (API, database, file system)?
  → Integration test (medium)

Is it a critical user flow that must work end-to-end?
  → E2E test (large) — limit these to critical paths
```

## Writing Good Tests

### Test State, Not Interactions

Assert on the _outcome_ of an operation, not on which methods were called internally.

```typescript
// Good: Tests what the function does (state-based)
it('returns tasks sorted by creation date, newest first', async () => {
  const tasks = await listTasks({ sortBy: 'createdAt', sortOrder: 'desc' });
  expect(tasks[0].createdAt.getTime()).toBeGreaterThan(tasks[1].createdAt.getTime());
});

// Bad: Tests how the function works internally (interaction-based)
it('calls db.query with ORDER BY created_at DESC', async () => {
  await listTasks({ sortBy: 'createdAt', sortOrder: 'desc' });
  expect(db.query).toHaveBeenCalledWith(expect.stringContaining('ORDER BY created_at DESC'));
});
```

### DAMP Over DRY in Tests

In production code, DRY (Don't Repeat Yourself) is usually right. In tests, **DAMP (Descriptive And
Meaningful Phrases)** is better.

```typescript
// DAMP: Each test is self-contained and readable
it('rejects tasks with empty titles', () => {
  const input = { title: '', assignee: 'user-1' };
  expect(() => createTask(input)).toThrow('Title is required');
});

it('trims whitespace from titles', () => {
  const input = { title: '  Buy groceries  ', assignee: 'user-1' };
  const task = createTask(input);
  expect(task.title).toBe('Buy groceries');
});

// Over-DRY: Shared setup obscures what each test actually verifies
// (Don't do this just to avoid repeating the input shape)
```

### Prefer Real Implementations Over Mocks

Use the simplest test double that gets the job done.

```
Preference order (most to least preferred):
1. Real implementation  → Highest confidence, catches real bugs
2. Fake                 → In-memory version of a dependency (e.g., fake DB)
3. Stub                 → Returns canned data, no behavior
4. Mock (interaction)   → Verifies method calls — use sparingly
```

**Use mocks only when:** the real implementation is too slow, non-deterministic, or has side effects
you can't control (external APIs, email sending). Over-mocking creates tests that pass while
production breaks.

### Use the Arrange-Act-Assert Pattern

```typescript
it('marks overdue tasks when deadline has passed', () => {
  // Arrange: Set up the test scenario
  const task = createTask({
    title: 'Test',
    deadline: new Date('2025-01-01'),
  });

  // Act: Perform the action being tested
  const result = checkOverdue(task, new Date('2025-01-02'));

  // Assert: Verify the outcome
  expect(result.isOverdue).toBe(true);
});
```

### One Assertion Per Concept

```typescript
// Good: Each test verifies one behavior
it('rejects empty titles', () => { ... });
it('trims whitespace from titles', () => { ... });
it('enforces maximum title length', () => { ... });

// Bad: Everything in one test
it('validates titles correctly', () => {
  expect(() => createTask({ title: '' })).toThrow();
  expect(createTask({ title: '  hello  ' }).title).toBe('hello');
  expect(() => createTask({ title: 'a'.repeat(256) })).toThrow();
});
```

### Name Tests Descriptively

```typescript
// Good: Reads like a specification
describe('TaskService.completeTask', () => {
  it('sets status to completed and records timestamp', ...);
  it('throws NotFoundError for non-existent task', ...);
  it('is idempotent — completing an already-completed task is a no-op', ...);
  it('sends notification to task assignee', ...);
});

// Bad: Vague names
describe('TaskService', () => {
  it('works', ...);
  it('handles errors', ...);
  it('test 3', ...);
});
```

## Test Anti-Patterns to Avoid

| Anti-Pattern                          | Problem                                                    | Fix                                                                                                                        |
| ------------------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Testing implementation details        | Tests break when refactoring even if behavior is unchanged | Test inputs and outputs, not internal structure                                                                            |
| Flaky tests (timing, order-dependent) | Erode trust in the test suite                              | Use deterministic assertions, isolate test state                                                                           |
| Testing framework code                | Wastes time testing third-party behavior                   | Only test YOUR code                                                                                                        |
| Snapshot abuse                        | Large snapshots nobody reviews, break on any change        | Use snapshots sparingly and review every change                                                                            |
| No test isolation                     | Tests pass individually but fail together                  | Each test sets up and tears down its own state                                                                             |
| Mocking everything                    | Tests pass but production breaks                           | Prefer real implementations > fakes > stubs > mocks. Mock only at boundaries where real deps are slow or non-deterministic |

## Common Rationalizations

| Rationalization                                    | Reality                                                                                                                                                  |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "I'll write tests after the code works"            | You won't. And tests written after the fact test implementation, not behavior.                                                                           |
| "This is too simple to test"                       | Simple code gets complicated. The test documents the expected behavior.                                                                                  |
| "Tests slow me down"                               | Tests slow you down now. They speed you up every time you change the code later.                                                                         |
| "I tested it manually"                             | Manual testing doesn't persist. Tomorrow's change might break it with no way to know.                                                                    |
| "The code is self-explanatory"                     | Tests ARE the specification. They document what the code should do, not what it does.                                                                    |
| "It's just a prototype"                            | Prototypes become production code. Tests from day one prevent the "test debt" crisis.                                                                    |
| "Let me run the tests again just to be extra sure" | After a clean test run, repeating the same command adds nothing unless the code has changed since. Run again after subsequent edits, not as reassurance. |

## Red Flags

- Writing code without any corresponding tests
- Tests that pass on the first run (they may not be testing what you think)
- "All tests pass" but no tests were actually run
- Bug fixes without reproduction tests
- Tests that test framework behavior instead of application behavior
- Test names that don't describe the expected behavior
- Skipping tests to make the suite pass
- Running the same test command twice in a row without any intervening code change

## Verification

After completing any implementation:

- [ ] Every new behavior has a corresponding test
- [ ] All tests pass: `npm test`
- [ ] Bug fixes include a reproduction test that failed before the fix
- [ ] Test names describe the behavior being verified
- [ ] No tests were skipped or disabled
- [ ] Coverage hasn't decreased (if tracked)

**Note:** Run each test command after a change that could affect the result. After a clean run,
don't repeat the same command unless the code has changed since — re-running on unchanged code adds
no confidence.
