# Common Pitfalls

## Rationalizations

| Rationalization                            | Reality                                                                                                          |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| "We'll document the API later"             | The types ARE the documentation. Define them first.                                                              |
| "We don't need pagination for now"         | You will the moment someone has 100+ items. Add it from the start.                                               |
| "PATCH is complicated, let's just use PUT" | PUT requires the full object every time. PATCH is what clients actually want.                                    |
| "We'll version the API when we need to"    | Breaking changes without versioning break consumers. Design for extension from the start.                        |
| "Nobody uses that undocumented behavior"   | Hyrum's Law: if it's observable, somebody depends on it. Treat every public behavior as a commitment.            |
| "We can just maintain two versions"        | Multiple versions multiply maintenance cost and create diamond dependency problems. Prefer the One-Version Rule. |
| "Internal APIs don't need contracts"       | Internal consumers are still consumers. Contracts prevent coupling and enable parallel work.                     |

## Red Flags

- Endpoints that return different shapes depending on conditions
- Inconsistent error formats across endpoints
- Validation scattered throughout internal code instead of at boundaries
- Breaking changes to existing fields (type changes, removals)
- List endpoints without pagination
- Verbs in REST URLs (`/api/createTask`, `/api/getUsers`)
- Third-party API responses used without validation or sanitization

## Verification Checklist

After designing an API:

- [ ] Every endpoint has typed input and output schemas
- [ ] Error responses follow a single consistent format
- [ ] Validation happens at system boundaries only
- [ ] List endpoints support pagination
- [ ] New fields are additive and optional (backward compatible)
- [ ] Naming follows consistent conventions across all endpoints
- [ ] API documentation or types are committed alongside the implementation
