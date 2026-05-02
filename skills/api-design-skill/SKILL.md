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
|--------|---------|--------------|------------|
| GET | Read | 200 | Yes |
| POST | Create | 201 | No |
| PUT | Replace | 200/204 | Yes |
| PATCH | Update | 200/204 | No |
| DELETE | Remove | 204 | Yes |

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Validation Error |
| 429 | Rate Limited |
| 500 | Server Error |

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
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Must be at least 8 characters"
      }
    ]
  },
  "meta": {
    "requestId": "req_abc123"
  }
}
```

## versióning

```
/v1/users
/v2/users
```

```http
Accept: application/vnd.api+json; versión=2
```

## Pagination Patterns

### Offset-based
```
GET /users?page=1&limit=20
```

### Cursor-based (recommended for large datasets)
```
GET /users?cursor=eyJpZCI6MTAwfQ&limit=20
```

### Time-based
```
GET /users?after=2024-01-01T00:00:00Z&limit=20
```

## Filtering & Sorting

```
GET /users?status=active&role=admin&sort=name:asc,createdAt:desc
GET /users?search=john
GET /users?createdAfter=2024-01-01
```

## Field Selection

```
GET /users?fields=id,name,email
GET /users?include=orders,profile
```

## Rate Limiting

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1642000000
Retry-After: 3600
```

## Authentication

### Bearer Token
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### API Key
```http
X-API-Key: your-api-key-here
```

## API Design Checklist

- [ ] Resources named as nouns (plural)
- [ ] HTTP methods used correctly
- [ ] Appropriate status codes
- [ ] Consistent error format
- [ ] Pagination implemented
- [ ] Rate limiting documented
- [ ] versióning strategy defined
- [ ] Authentication required
- [ ] Input validation
- [ ] OpenAPI spec updated

## GraphQL Alternative

When to use GraphQL:
- Complex nested queries
- Mobile apps (bandwidth optimization)
- Multiple clients with different needs

```graphql
type User {
  id: ID!
  name: String!
  email: String!
  orders: [Order!]!
}

type Query {
  user(id: ID!): User
  users(filter: UserFilter, limit: Int, offset: Int): [User!]!
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!
}
```

## Documentation Example

```yaml
/users:
  get:
    summary: List users
    description: Returns a paginated list of users
    tags:
      - Users
    parameters:
      - name: page
        in: query
        schema:
          type: integer
          default: 1
      - name: limit
        in: query
        schema:
          type: integer
          default: 20
          maximum: 100
    responses:
      '200':
        description: Success
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserList'
      '401':
        $ref: '#/components/responses/Unauthorized'
```

