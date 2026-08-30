# Tests

Organized by category:

| Category    | Directory            | Pattern     | Count     |
| ----------- | -------------------- | ----------- | --------- |
| Unit        | `tests/unit/`        | `*.test.ts` | node:test |
| Integration | `tests/integration/` | `*.test.ts` | node:test |
| Security    | `tests/security/`    | `*.test.ts` | node:test |
| Smoke       | `tests/smoke/`       | `*.test.ts` | node:test |

Run all: `npm test`

Smoke tests: `npm run test:smoke` and `npm run test:scripts-smoke`.
