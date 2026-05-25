---
name: golang-api-skill
description: >
  Go backend API patterns: REST endpoints, JSON responses, middleware, SPA serving. Trigger: "Go
  API", "Go backend", "REST endpoint Go", "Go JSON", "Go SPA", "Go HTTP handler".
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

### versióning

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

| Code | Use            |
| ---- | -------------- |
| 200  | OK             |
| 201  | Created        |
| 204  | No Content     |
| 400  | Bad Request    |
| 401  | Unauthorized   |
| 403  | Forbidden      |
| 404  | Not Found      |
| 500  | Internal Error |

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

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
