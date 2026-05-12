# NORMATIVAS-API-DESIGN.md — API Design Standards

Version: 1.0.0
Framework: RESTful API Maturity Model (Richardson) + GraphQL best practices + OpenAPI 3.1
Last updated: 2026-05-11

---

## 1. PROPOSITO

Define los estandares de diseno de API para el stack Foundation. Aplica a todas las APIs REST, GraphQL, y WebSocket desarrolladas o consumidas por el framework.

---

## 2. PRINCIPIOS DE DISENO

| Principio | Descripcion |
|-----------|-------------|
| Resource-oriented | URLs representan recursos, no acciones |
| Stateless | Cada request contiene toda la informacion necesaria |
| Consistent | Mismas convenciones en todas las APIs |
| Versioned | Cambios backward-compatible via versionado |
| Self-descriptive | HATEOAS solo donde aplica; siempre metadata suficiente |

---

## 3. REST API STANDARDS

### 3.1 URL Structure

| Pattern | Ejemplo |
|---------|---------|
| /api/v1/{resource} | /api/v1/users |
| /api/v1/{resource}/{id} | /api/v1/users/123 |
| /api/v1/{resource}/{id}/{subresource} | /api/v1/users/123/roles |

1. **MUST** usar plurales para resources
2. **MUST** usar kebab-case para multi-word resources
3. **MUST** versionar la API desde el primer release (v1)
4. **MUST NOT** incluir verbos en URLs (no /api/getUsers)
5. **SHOULD** mantener nesting maximo 2 niveles

### 3.2 HTTP Methods

| Method | Accion | Idempotent | Safe | Ejemplo |
|--------|--------|------------|------|---------|
| GET | Read | Yes | Yes | GET /api/v1/users/123 |
| POST | Create | No | No | POST /api/v1/users |
| PUT | Replace | Yes | No | PUT /api/v1/users/123 |
| PATCH | Partial update | No | No | PATCH /api/v1/users/123 |
| DELETE | Delete | Yes | No | DELETE /api/v1/users/123 |

### 3.3 Request/Response Format

#### Request
`json
{
    "email": "user@example.com",
    "name": "John Doe"
}
`

#### Success Response (200)
`json
{
    "data": {
        "id": "usr_abc123",
        "email": "user@example.com",
        "name": "John Doe",
        "createdAt": "2026-05-11T10:00:00Z"
    },
    "meta": {
        "requestId": "req_xyz789"
    }
}
`

#### Error Response
`json
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Email format is invalid",
        "details": [
            {
                "field": "email",
                "reason": "must be a valid email address",
                "code": "INVALID_FORMAT"
            }
        ],
        "requestId": "req_xyz789"
    }
}
`

### 3.4 HTTP Status Codes

| Code | Uso | Cuando |
|------|-----|--------|
| 200 | OK | GET, PUT, PATCH exitoso |
| 201 | Created | POST exitoso |
| 204 | No Content | DELETE exitoso |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Auth missing/invalid |
| 403 | Forbidden | Auth insuficiente |
| 404 | Not Found | Resource no existe |
| 409 | Conflict | Duplicate / state conflict |
| 422 | Unprocessable | Business rule violation |
| 429 | Too Many Requests | Rate limit |
| 500 | Internal Error | Server error (nunca mostrar detalles) |
| 503 | Service Unavailable | Temporal outage |

1. **MUST** usar codigos HTTP correctos (no 200 para errores)
2. **MUST** retornar requestId en cada error para debugging
3. **MUST NOT** exponer stack traces en production
4. **SHOULD** incluir documentation URL en errores

### 3.5 Pagination

`json
{
    "data": [...],
    "pagination": {
        "page": 1,
        "pageSize": 20,
        "total": 142,
        "totalPages": 8,
        "hasNext": true,
        "hasPrev": false
    }
}
`

1. **MUST** usar cursor-based pagination para listas grandes
2. **MUST** limitar pageSize a maximo 100
3. **MUST** incluir metadata de paginacion en responses
4. **SHOULD** usar Link headers para navegacion

---

## 4. ERROR STANDARDS

### 4.1 Error Codes

| Code | HTTP | Significado |
|------|------|-------------|
| VALIDATION_ERROR | 400 | Input invalido |
| AUTHENTICATION_REQUIRED | 401 | Token faltante/invalido |
| INSUFFICIENT_PERMISSIONS | 403 | No autorizado |
| RESOURCE_NOT_FOUND | 404 | Resource no existe |
| RESOURCE_CONFLICT | 409 | State conflict |
| RATE_LIMIT_EXCEEDED | 429 | Demasiados requests |
| INTERNAL_ERROR | 500 | Error no esperado |
| SERVICE_UNAVAILABLE | 503 | Mantenimiento/outage |

---

## 5. SECURITY

1. **MUST** usar HTTPS en produccion
2. **MUST** autenticar con Bearer tokens (JWT)
3. **MUST** rate limiting por endpoint y usuario
4. **MUST** validar input en todos los endpoints
5. **MUST** CORS configurado restrictivamente
6. **MUST** Content-Security-Policy headers
7. **SHOULD** implementar Idempotency-Key para POST/PATCH

---

## 6. COMPLIANCE CHECKPOINTS

1. [ ] URLs usan plurales y kebab-case
2. [ ] HTTP methods correctos para cada operacion
3. [ ] Status codes correctos (no 200 para errores)
4. [ ] Error response con formato estandar
5. [ ] Pagination implementada para listas
6. [ ] Rate limiting configurado
7. [ ] Auth/autz en todos los endpoints
8. [ ] Input validation en todos los endpoints
9. [ ] OpenAPI spec mantenida y actualizada
10. [ ] CORS configurado restrictivamente
11. [ ] HTTPS enforced
12. [ ] Request ID en cada response

---

## 7. REFERENCIAS

| Resource | Path |
|----------|------|
| OpenAPI 3.1 Spec | spec.openapis.org/oas/v3.1.0 |
| JSON:API Standard | jsonapi.org |
| Error Handling | rules/NORMATIVAS-ERROR-HANDLING.md |
| Security Normatives | docs/NORMATIVAS-SEGURIDAD.md |
| Code Standards | rules/NORMATIVAS-CODIGO.md |

---

_Version: 1.0.0 - 2026-05-11 - Status: ACTIVE_
