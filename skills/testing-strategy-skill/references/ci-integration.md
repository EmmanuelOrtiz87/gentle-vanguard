## CI Integration

```yaml
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
