## Go Tests

```go
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

## Angular/Vitest Tests

```typescript
describe('RepoMetrics', () => {
  it('should have correct structure', () => {
    const metrics: RepoMetrics = {
      RepoName: 'test',
      OpenPRs: 5,
      PullRequests: [],
    };
    expect(metrics.OpenPRs).toBe(5);
  });
});

describe('API URLs', () => {
  it('should construct metrics endpoint', () => {
    const url = `/api/v1/metrics?workspace=test&repo=my-repo`;
    expect(url).toContain('workspace=test');
    expect(url).toContain('repo=my-repo');
  });
});

describe('Signals', () => {
  it('should update signal', () => {
    const data = signal<string>('initial');
    data.set('updated');
    expect(data()).toBe('updated');
  });
});
```

## Mocking

### Go

```go
type DashboardService interface {
    FetchMetrics(ctx context.Context, repo, timeframe string) (*RepoMetrics, error)
}

type mockService struct{}
func (m *mockService) FetchMetrics(ctx context.Context, repo, tf string) (*RepoMetrics, error) {
    return &RepoMetrics{RepoSlug: repo}, nil
}
```

### Angular

```typescript
beforeEach(() => {
  TestBed.configureTestingModule({
    imports: [HttpClientTestingModule],
    providers: [ApiService],
  });
  httpMock = TestBed.inject(HttpTestingController);
});

it('should call API', () => {
  service.getData().subscribe();
  const req = httpMock.expectOne('/api/v1/data');
  req.flush(mockData);
});
```

## Arrange-Act-Assert

```typescript
describe('UserService', () => {
  it('should update user age on birthday', () => {
    const user = createUser({ name: 'John', age: 30 });
    user.birthday();
    expect(user.age).toBe(31);
  });
});
```
