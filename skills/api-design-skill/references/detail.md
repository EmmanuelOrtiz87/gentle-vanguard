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