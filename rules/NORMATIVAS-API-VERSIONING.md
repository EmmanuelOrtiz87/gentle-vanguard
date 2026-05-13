# API Versioning Normatives — Foundation

Canonical standards for API versioning, deprecation, and backward compatibility.
Last updated: 2026-05-12 | Version: 1.0.0

---

## 1. Semantic Versioning (SemVer 2.0.0)

All APIs **MUST** follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
  ^      ^      ^
  |      |      └─ Patch: bug fixes, no API changes
  |      └────────── Minor: new features, backward compatible
  └───────────────── Major: breaking changes
```

### Version Increment Rules

| Scenario | Example | Action |
|----------|---------|--------|
| **Breaking change** | Remove parameter, rename endpoint | `1.x.x` → `2.0.0` |
| **New feature** | Add optional parameter | `1.2.x` → `1.3.0` |
| **Bug fix** | Fix response data type | `1.2.x` → `1.2.(x+1)` |
| **Pre-release** | Beta features | Append `-beta.1`, `-rc.1` |

### Version Declaration

All API versioning MUST be declared in:
1. `/package.json` — `version` field (canonical)
2. `/VERSION` file — single line, e.g., `2.1.0`
3. API headers — `X-API-Version: 2.1.0`
4. OpenAPI/Swagger — `info.version: 2.1.0`
5. Changelog — `CHANGELOG.md#[2.1.0]` entry

---

## 2. URL Versioning Strategy

**RECOMMENDED**: Path-based versioning (resource-scoped):

```
GET /api/v1/users          # v1 endpoint (legacy)
GET /api/v2/users          # v2 endpoint (current)
GET /api/v3/users/accounts # v3 with new structure
```

**ALTERNATIVE**: Accept header versioning:

```
GET /api/users
  Accept: application/vnd.foundation+json; version=2
```

**DO NOT USE**: Query parameter versioning (`?api=v2`) — difficult to cache, route, and monitor.

---

## 3. Deprecation Policy (6-Month Window)

### Phase 1: Announcement (Week 1)
- [ ] Create GitHub issue: `deprecation: <feature-name> in v1.x will be removed in v3.0`
- [ ] Add `DEPRECATED` flag in code comments
- [ ] Document migration guide (see below)
- [ ] Release as `MINOR` version bump

```powershell
# Example:
Write-Warning "Endpoint GET /api/v1/users is DEPRECATED and will be removed on 2026-11-12 (6 months from announcement). Migrate to GET /api/v2/users."
```

### Phase 2: Support Period (Months 1-6)
- [ ] Both old (v1) and new (v2) endpoints active
- [ ] Logs include deprecation warnings
- [ ] Support team directs users to v2
- [ ] No new features added to v1 (bug fixes only)

### Phase 3: Sunset (Month 6)
- [ ] Remove v1 endpoint
- [ ] Release as `MAJOR` version bump
- [ ] Changelog: `BREAKING: Removed GET /api/v1/users, use v2`

### Documentation Requirements

Every deprecation MUST include:
1. **Why** it was deprecated (design flaw, performance, etc.)
2. **When** it will be removed (specific date: Month X)
3. **How** to migrate (code examples, step-by-step)
4. **Support** channels (Slack, email, issues)

---

## 4. Backward Compatibility Guarantees

### Additive-Only Changes (GUARANTEED compatible)

✅ **ALLOWED** in MINOR/PATCH releases:
- New optional parameters (with sensible defaults)
- New optional fields in responses
- New endpoints
- Additional enum values (in responses only)
- New HTTP headers

### Breaking Changes (MAJOR version required)

🚫 **BREAKING** — requires new MAJOR version:
- Remove parameters or fields
- Change parameter/field types (e.g., `userId: number` → `userId: string`)
- Change response structure
- Rename endpoints or fields
- Remove endpoints
- Change HTTP status codes
- Change authentication scheme

### Compatibility Declaration

Every endpoint MUST declare its compatibility window:

```typescript
/**
 * @deprecated 2026-11-12 | Migrate to GET /api/v2/users
 * @compatibility v1.0.0 - v2.5.0 (6-month deprecation window)
 * @replacement GET /api/v2/users
 */
```

---

## 5. Migration Guides

### Mandatory Sections

Each migration guide MUST include:

```markdown
# Migration: v1 → v2

## What Changed
- [x] Endpoint: `/api/v1/users` → `/api/v2/users`
- [x] Response: `{ id, name }` → `{ userId, fullName, email }`

## Before (v1)
\`\`\`
GET /api/v1/users/123
→ { "id": "123", "name": "John" }
\`\`\`

## After (v2)
\`\`\`
GET /api/v2/users/123
→ { "userId": "123", "fullName": "John Doe", "email": "john@example.com" }
\`\`\`

## Step-by-Step Migration
1. Update import: `from 'api/v1'` → `from 'api/v2'`
2. Change endpoint: `GET /v1/users/ID` → `GET /v2/users/ID`
3. Update response parsing: `user.id` → `user.userId`
4. Test: `npm run test:migration`
5. Deploy: Create new environment variable `API_VERSION=v2`

## Rollback Plan
If issues occur:
- Feature flag: `USE_V1_API=true` (fallback to v1 temporarily)
- Support window: v1 supported until 2026-11-12
```

---

## 6. API Contract & Schema Validation

### OpenAPI/Swagger Declaration

All APIs MUST publish OpenAPI 3.0+ spec:

```yaml
# api-contract.yaml
openapi: 3.0.0
info:
  title: Foundation API
  version: 2.1.0
  description: "Breaking changes from v1: ..."

paths:
  /api/v2/users/{userId}:
    get:
      deprecated: false
      parameters:
        - name: userId
          in: path
          required: true
          schema:
            type: string
      responses:
        200:
          description: User object
          content:
            application/json:
              schema:
                type: object
                required: [userId, fullName]
                properties:
                  userId: { type: string }
                  fullName: { type: string }
```

### Schema Validation (Zod)

Use [Zod v4](https://zod.dev) for runtime validation:

```typescript
import { z } from 'zod';

const UserV2Schema = z.object({
  userId: z.string().uuid(),
  fullName: z.string().min(1),
  email: z.string().email(),
});

// Validate incoming requests
const validateUserV2 = (data) => UserV2Schema.parse(data);
```

---

## 7. Versioning in Code

### Skill/Plugin Versioning

Each skill MUST declare its API version:

```powershell
# skill-metadata.json
{
  "name": "user-service-skill",
  "apiVersion": "2.1.0",
  "compatibility": {
    "min": "2.0.0",
    "max": "2.9.9",
    "breaking": ["2.0.0"],  # Breaking versions this skill requires
    "deprecated": ["1.x"]    # Versions no longer supported
  }
}
```

### Changelog Entry Format

```markdown
## [2.1.0] - 2026-05-12

### Added
- New field `email` in User response (v2 only)
- New endpoint `GET /api/v2/users/{id}/activity`

### Changed
- Field `name` renamed to `fullName` in User object

### Deprecated
- Endpoint `GET /api/v1/users` (will be removed 2026-11-12)

### Removed
- Support for `GET /api/v0/users` (removed in v2.0.0)

### Fixed
- User response now includes proper UTF-8 encoding

### Security
- Added input validation for userId parameter

### Migration Guide
See release notes in [CHANGELOG.md](../CHANGELOG.md) and maintain migration steps in the API PR description.
```

---

## 8. Versioning Policy Governance

### Quality Gates (for version bumps)

```json
{
  "gates": [
    {
      "name": "version-bump-requires-changelog",
      "severity": "CRITICAL",
      "rule": "If MAJOR or MINOR bump detected, CHANGELOG.md must be updated"
    },
    {
      "name": "breaking-change-requires-migration-guide",
      "severity": "CRITICAL",
      "rule": "Breaking changes MUST include migration guide in docs/"
    },
    {
      "name": "deprecation-requires-6-month-notice",
      "severity": "HIGH",
      "rule": "Deprecated features must not be removed before 6 months + version bump"
    },
    {
      "name": "semver-compliance",
      "severity": "MEDIUM",
      "rule": "Version bumps must follow SemVer 2.0.0 rules"
    }
  ]
}
```

### Audit Trail

Every API version change must be logged:

```json
{
  "timestamp": "2026-05-12T19:55:00Z",
  "event": "api-version-bump",
  "from": "2.0.0",
  "to": "2.1.0",
  "changeType": "MINOR",
  "breaking": false,
  "deprecations": [],
  "author": "dev-team",
  "pr": "https://github.com/...",
  "changeLog": "docs/CHANGELOG.md"
}
```

---

## 9. Testing Versioning Changes

### Test Structure

```
tests/
├── versioning/
│   ├── backward-compatibility.tests.ps1      # v1 ↔ v2 interop
│   ├── deprecation-warnings.tests.ps1        # Warnings emit correctly
│   ├── migration-guide-examples.tests.ps1    # Migration docs are valid
│   └── schema-validation.tests.ps1           # OpenAPI ↔ Zod consistency
```

### Example Test (Pester 3.4.0)

```powershell
Describe "API Versioning" {
  It "v2 endpoint returns required fields" {
    $response = Invoke-RestMethod "GET /api/v2/users/123"
    $response.userId | Should Not BeNullOrEmpty
    $response.fullName | Should Not BeNullOrEmpty
  }

  It "v1 endpoint returns deprecated warning" {
    $response = Invoke-WebRequest "GET /api/v1/users/123" -WarningVariable warn
    $warn | Should Contain "DEPRECATED"
  }

  It "deprecation window is enforced" {
    $sunsetDate = Get-Date "2026-11-12"
    (Get-Date) | Should BeLessThan $sunsetDate
  }
}
```

---

## 10. Communication Template

### For Breaking Changes

```markdown
📢 **BREAKING CHANGE NOTICE**

**Version**: 2.0.0 (released 2026-05-12)
**Severity**: BREAKING — updates required

**What changed**:
- Endpoint: `/api/v1/users` → `/api/v2/users`
- Response structure: `{ id, name }` → `{ userId, fullName, email }`

**Action required**:
- ✅ Update your client before 2026-11-12 (6 months)
- ✅ Follow migration steps documented in [CHANGELOG.md](../CHANGELOG.md)
- ✅ Test on staging first

**Support**:
- Questions? Post in Slack: #api-support
- Issues? File at: github.com/.../issues
```

---

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [API Versioning Best Practices](https://cloud.google.com/architecture/versioning-apis-consistently)
- [Zod Schema Validation](https://zod.dev/)
- [OpenAPI 3.0 Specification](https://spec.openapis.org/oas/v3.0.3)
- Project: [config/auto-delegation.json](../config/auto-delegation.json)
- Related: [NORMATIVAS-CODIGO.md](NORMATIVAS-CODIGO.md)
