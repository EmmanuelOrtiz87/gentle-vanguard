## Test Naming

```
Go:     TestSubject_Scenario_ExpectedBehavior
        TestHandleMetrics_ValidToken_ReturnsMetrics

JS/TS:  should_subject_expectedBehavior
        it('should return metrics for valid request')
```

## Test File Location

```
Go:
  internal/web/
   server.go
   server_test.go          # Same package

Angular:
  src/app/core/services/
   api.service.ts
   api.service.spec.ts
```

## Quick Reference

| Task             | Command                           |
| ---------------- | --------------------------------- |
| Go tests         | `go test ./...`                   |
| Go coverage      | `go test -coverprofile=out ./...` |
| Angular tests    | `npm test -- --watch=false`       |
| Angular coverage | `npm test -- --coverage`          |
| Run single file  | `npm test -- file.spec.ts`        |
| Watch mode       | `npm test`                        |
