---
name: api-design-skill
description: Use when designing REST APIs, GraphQL schemas, or API contracts. Triggers: "design API", "REST endpoint", "GraphQL", "OpenAPI", "API versióning", "pagination", "API documentation", "API error handling".
---

# API Design Skill

## Purpose

Design consistent, scalable, and developer-friendly APIs following REST best practices.

## REST Principles

1. **Resources** - Everything is a resource (nouns)
2. **HTTP Methods** - Use correct verbs
3. **Stateless** - Each request is independent
4. **Cacheable** - Leverage HTTP caching
5. **Layered** - Client doesn't know about layers

## URL Structure

```
https://api.example.com/v1/{resource}/{id}/{subresource}

GET    /users              # List users
GET    /users/123          # Get user
POST   /users              # Create user
PUT    /users/123          # Update user
PATCH  /users/123          # Partial update
DELETE /users/123          # Delete user
GET    /users/123/orders   # User's orders
```

## HTTP Methods & Status Codes

| Method | Purpose | Success Code | Idempotent |
| ------ | ------- | ------------ | ---------- |
| GET    | Read    | 200          | Yes        |
| POST   | Create  | 201          | No         |
| PUT    | Replace | 200/204      | Yes        |
| PATCH  | Update  | 200/204      | No         |
| DELETE | Remove  | 204          | Yes        |

| Code | Meaning          |
| ---- | ---------------- |
| 200  | OK               |
| 201  | Created          |
| 204  | No Content       |
| 400  | Bad Request      |
| 401  | Unauthorized     |
| 403  | Forbidden        |
| 404  | Not Found        |
| 409  | Conflict         |
| 422  | Validation Error |
| 429  | Rate Limited     |
| 500  | Server Error     |

## Response Format

### Success Response

```json
{
  "data": {
    "id": "123",
    "type": "user",
    "attributes": {
      "name": "John Doe",
      "email": "john@example.com",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  },
  "meta": {
    "requestId": "req_abc123"
  }
}
```

### List Response with Pagination

```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 150,
    "totalPages": 8
  },
  "links": {
    "self": "/users?page=1",
    "next": "/users?page=2",
    "prev": null,
    "first": "/users?page=1",
    "last": "/users?page=8"
  }
}
```

### Error Response

```json
{
  "error": {

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
