---
name: golang-api-skill
description: >
  Go backend API patterns: REST endpoints, JSON responses, middleware, SPA serving.
  Trigger: "Go API", "Go backend", "REST endpoint Go", "Go JSON", "Go SPA", "Go HTTP handler".
---

## When to Use

- Creating new Go API endpoints
- Building REST JSON APIs
- Serving SPA from Go backend
- Converting templates to JSON API
- Go middleware (CORS, auth, logging)

## Project Structure

```
cmd/server/
 main.go
internal/
 web/
    server.go      # Handlers, routes
    middleware.go  # CORS, auth, logging
 domain/
    entities.go   # Domain models
 config/
    config.go      # Configuration
 external/          # External API clients
     client.go
web/                  # Frontend SPA
 dist/
```

## API Standards

### Versioning
- Prefix: `/api/v1/`
- Example: `/api/v1/metrics`, `/api/v1/users`

### JSON Response
```go
func renderJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}
```

### Error Response
```go
type APIError struct {
    Error string `json:"error"`
    Code  int    `json:"code"`
}

func renderError(w http.ResponseWriter, code int, msg string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(code)
    json.NewEncoder(w).Encode(APIError{Error: msg, Code: code})
}
```

### HTTP Status Codes
| Code | Use |
|------|-----|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Internal Error |

## Handler Pattern

```go
func handleMetrics(cfg Config, factory HandlerFactory, auth *AuthManager) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        workspace, token, ok := resolveAuth(r, cfg, auth)
        if !ok {
            renderError(w, http.StatusUnauthorized, "Unauthorized")
            return
        }

        repo := r.URL.Query().Get("repo")
        if repo == "" {
            overview, err := client.FetchWorkspaceOverview(ctx, timeframe)
            if err != nil {
                renderError(w, http.StatusInternalServerError, "Failed to fetch")
                return
            }
            renderJSON(w, http.StatusOK, overview)
            return
        }

        metrics, err := client.FetchMetrics(ctx, repo, timeframe)
        if err != nil {
            renderError(w, http.StatusInternalServerError, "Failed to fetch metrics")
            return
        }
        renderJSON(w, http.StatusOK, metrics)
    }
}
```

## SPA Handler Pattern

```go
func spaHandler(distPath string) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        filePath := filepath.Join(distPath, r.URL.Path)
        
        if info, err := os.Stat(filePath); err == nil && !info.IsDir() {
            http.ServeFile(w, r, filePath)
            return
        }
        http.ServeFile(w, r, filepath.Join(distPath, "index.html"))
    }
}
```

## Middleware Pattern

### CORS
```go
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
        
        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusNoContent)
            return
        }
        next.ServeHTTP(w, r)
    })
}
```

### Security Headers
```go
func secureHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
        w.Header().Set("Content-Security-Policy", "default-src 'self'")
        next.ServeHTTP(w, r)
    })
}
```

## Nested Response Structures

When consuming external APIs, handle nested objects properly:
```go
type Author struct {
    Username string `json:"username"`
    Nickname string `json:"nickname"`
    Avatar   string `json:"avatar"`
}

type PullRequestSummary struct {
    ID            int     `json:"id"`
    Title         string  `json:"title"`
    Author        Author  `json:"author"` // Nested object
    SourceBranch  string  `json:"sourceBranch"`
    TargetBranch  string  `json:"targetBranch"`
    State         string  `json:"state"`
}
```

## Testing

```go
func TestHandleMetrics(t *testing.T) {
    req, _ := http.NewRequest("GET", "/api/v1/metrics?workspace=test", nil)
    rr := httptest.NewRecorder()
    
    handler := handleMetrics(cfg, factory, auth)
    handler.ServeHTTP(rr, req)
    
    if rr.Code != http.StatusOK {
        t.Errorf("Expected 200, got %d", rr.Code)
    }
    
    if ct := rr.Header().Get("Content-Type"); ct != "application/json" {
        t.Errorf("Expected application/json, got %s", ct)
    }
}
```

## Docker Multi-Stage Build

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o server ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/server .
COPY --from=builder /app/web/dist ./web/dist
EXPOSE 8080
CMD ["./server"]
```

## Quick Reference

| Pattern | Code |
|---------|------|
| JSON response | `renderJSON(w, 200, data)` |
| JSON error | `renderError(w, 400, "msg")` |
| SPA handler | `mux.Handle("/", spaHandler("./web/dist"))` |
| CORS | `corsMiddleware(handler)` |
| Test endpoint | `httptest.NewRecorder()` |
