---
name: testing-strategy-skill
description: >
  Testing strategy: when to test, what to test, test pyramid, coverage targets.
  Trigger: "testing strategy", "test pyramid", "what to test", "coverage target", "unit test", "integration test".
---

## When to Use

- Setting up test infrastructure
- Deciding what to test
- Choosing test levels
- Improving coverage
- Debugging test failures

## Test Pyramid

```
         /E2E\         <- 10% (Playwright, Cypress)
        /Int\          <- 20% (API tests, component tests)
       /Unit\          <- 70% (Vitest, Jest, Go test, pytest)
```

## What to Test

### Always Test

| Category | Examples |
|----------|----------|
| Business logic | Calculations, transformations, validations |
| API handlers | HTTP responses, error handling |
| Critical paths | Auth, payments, data mutations |
| Edge cases | Empty inputs, null values, boundaries |

### Consider Testing

| Category | Notes |
|----------|-------|
| UI components | If complex logic, not styling |
| Utility functions | Pure functions with business rules |
| Error paths | What happens when things fail |

### Never Test

| Category | Reason |
|----------|--------|
| Framework code | Angular, React internals |
| Trivial getters | `getName() { return this.name }` |
| Configuration | Environment setup |
| Third-party code | Already tested |

## Test Levels by Stack

### Go

```go
// Test file: *_test.go
func TestHandleMetrics(t *testing.T) {
    req, _ := http.NewRequest("GET", "/api/v1/metrics", nil)
    rr := httptest.NewRecorder()

    handler := handleMetrics(cfg, factory, auth)
    handler.ServeHTTP(rr, req)

    if rr.Code != http.StatusOK {
        t.Errorf("Expected 200, got %d", rr.Code)
    }

    if ct := rr.Header().Get("Content-Type"); ct != "application/json" {
        t.Errorf("Expected application/json")
    }
}

// Table-driven test
func TestTimeframeDays(t *testing.T) {
    cases := []struct {
        name  string
        input string
        want  int
    }{
        {"empty", "", 7},
        {"7d", "7d", 7},
        {"30d", "30d", 30},
    }

    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            if got := timeframeDays(tc.input); got != tc.want {
                t.Errorf("got %d, want %d", got, tc.want)
            }
        })
    }
}
```

### Angular/Vitest

```typescript
// Model/Interface tests
describe('RepoMetrics', () => {
  it('should have correct structure', () => {
    const metrics: RepoMetrics = {
      RepoName: 'test',
      OpenPRs: 5,
      PullRequests: []
    };
    expect(metrics.OpenPRs).toBe(5);
  });
});

// URL construction tests
describe('API URLs', () => {
  it('should construct metrics endpoint', () => {
    const url = `/api/v1/metrics?workspace=test&repo=my-repo`;
    expect(url).toContain('workspace=test');
    expect(url).toContain('repo=my-repo');
  });
});

// Signal tests
describe('Signals', () => {
  it('should update signal', () => {
    const data = signal<string>('initial');
    data.set('updated');
    expect(data()).toBe('updated');
  });
});
```

## Coverage Targets

| Level | Minimum | Target | Focus |
|-------|---------|--------|-------|
| Statements | 60% | 80% | Core logic |
| Branches | 50% | 70% | Conditionals |
| Functions | 70% | 90% | Public APIs |
| Lines | 60% | 80% | Overall |

## Test Naming

```
# Go: TestSubject_Scenario_ExpectedBehavior
TestHandleMetrics_ValidToken_ReturnsMetrics
TestTimeframeDays_EmptyInput_Returns7Days

# JS/TS: should_subject_expectedBehavior
it('should return metrics for valid request')
it('should handle API error gracefully')
```

## Arrange-Act-Assert

```typescript
describe('UserService', () => {
  it('should update user age on birthday', () => {
    // Arrange
    const user = createUser({ name: 'John', age: 30 });

    // Act
    user.birthday();

    // Assert
    expect(user.age).toBe(31);
  });
});
```

## Mocking

### Go
```go
// Use interfaces for testability
type DashboardService interface {
    FetchMetrics(ctx context.Context, repo, timeframe string) (*RepoMetrics, error)
}

// Mock in test
type mockService struct{}
func (m *mockService) FetchMetrics(ctx context.Context, repo, tf string) (*RepoMetrics, error) {
    return &RepoMetrics{RepoSlug: repo}, nil
}
```

### Angular
```typescript
// HttpClientTestingModule
beforeEach(() => {
  TestBed.configureTestingModule({
    imports: [HttpClientTestingModule],
    providers: [ApiService]
  });
  httpMock = TestBed.inject(HttpTestingController);
});

it('should call API', () => {
  service.getData().subscribe();
  const req = httpMock.expectOne('/api/v1/data');
  req.flush(mockData);
});
```

## CI Integration

```yaml
# GitHub Actions
- name: Run tests
  run: |
    go test ./... -coverprofile=coverage.out
    cd web && npm test -- --watch=false

- name: Upload coverage
  uses: actions/upload-artifact@v7
  with:
    name: coverage
    path: coverage.out
```

## Test File Location

```
Go:
  internal/web/
   server.go
   server_test.go     # Same package

Angular:
  src/app/
   core/services/
      api.service.ts
      api.service.spec.ts
   features/
       dashboard/
           dashboard.ts
           dashboard.spec.ts
```

## Anti-Patterns

| Anti-pattern | Solution |
|--------------|----------|
| Test private methods | Test public interface |
| Assert on timestamps | Mock time |
| Order-dependent tests | Reset state |
| Test third-party code | Mock external services |
| Brittle selectors | Use semantic queries |

## Quick Reference

| Task | Command |
|------|---------|
| Go tests | `go test ./...` |
| Go coverage | `go test -coverprofile=out ./...` |
| Angular tests | `npm test -- --watch=false` |
| Angular coverage | `npm test -- --coverage` |
| Run file | `npm test -- file.spec.ts` |
| Watch mode | `npm test` |

