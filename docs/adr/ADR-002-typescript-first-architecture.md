# ADR-002: TypeScript-First Architecture

## Status

**Accepted** — Supersedes ADR-0001 (Foundation) and ADR-0012 (PowerShell Language Choice)

## Context

ADR-0001 (Foundation) established TypeScript with multi-language support as the primary
implementation direction for Gentle-Vanguard. This decision was made in early 2026
when the ecosystem had:

- Heavy investment in TypeScript automation (390+ scripts)
- Windows-centric development environment
- Pester testing framework for infrastructure validation

However, several factors emerged that challenged this decision:

1. **Cross-platform compatibility**: TypeScript required explicit handling for Windows vs.
   Linux/macOS path separators, environment variables, and process spawning
2. **Developer experience**: TypeScript tools (type checking, IntelliSense, refactoring) proved more
   effective at codebase scale
3. **Performance**: Node.js execution of compiled TypeScript matched or exceeded TypeScript startup
   times
4. **Ecosystem alignment**: Modern AI tooling and CI/CD platforms have first-class
   TypeScript/Node.js support
5. **Maintenance burden**: Keeping 390+ TypeScript scripts synchronized with evolving patterns
   required disproportionate effort

## Decision

**Migrate the entire stack from PowerShell to TypeScript.**

All new code MUST be written in TypeScript. Existing PowerShell scripts are to be migrated
incrementally following TypeScript-first patterns.

### Implementation Details

| Aspect              | Before (PowerShell)        | After (TypeScript)                   |
| ------------------- | -------------------------- | ------------------------------------ |
| **Entry Point**     | `scripts/utilities/*.ps1`  | `src/*.ts`                           |
| **Execution**       | `npx tsx src/cli/gv.ts`    | `npx tsx src/script.ts`              |
<!-- REF-OBSOLETA: src/script.ts no existe (ruta migrada o eliminada) -->
| **Package Manager** | None / PowerShell Gallery  | `pnpm`                               |
| **Testing**         | Pester                     | `node:test` via `tsx --test`         |
| **Type Safety**     | Runtime checks             | TypeScript compiler (`tsc --noEmit`) |
| **Linting**         | PSScriptAnalyzer           | ESLint + security plugin             |
| **Autostart**       | `session-autostart.ps1`    | `npx tsx src/session-autostart.ts`   |

### Migration Rules

1. **Feature Freeze**: No new PowerShell scripts after 2026-07-01
2. **Critical Path First**: Session lifecycle, routing, and orchestration migrated first
3. **Parity Testing**: Each TypeScript replacement must pass identical integration tests
4. **Documentation Sync**: All references updated via `src/migrate-docs.ts`
5. **Archive**: Original PowerShell scripts archived in `archive/scripts/` for reference

## Consequences

### Positive

- **Single source of truth**: One language for 99% of the codebase
- **Better IDE support**: TypeScript Language Server provides superior IntelliSense
- **CI/CD simplification**: Single `npm install` vs. multiple runtime installations
- **Security**: `eslint-plugin-security` provides SAST capabilities
- **Performance**: V8 JIT compilation vs. PowerShell interpreter overhead
- **Hiring**: Larger pool of TypeScript/Node.js developers

### Negative

- **Migration effort**: 390 scripts required porting (completed July 2026)
- **Learning curve**: Team proficient in PowerShell needed TypeScript training
- **External dependencies**: More npm packages vs. PowerShell Gallery modules
- **Breaking changes**: Existing user workflows referencing `.ps1` scripts

### Mitigations

- **Compat layer**: `npx tsx src/*.ts` provides semantic compatibility with old commands
- **Documentation**: Automated migration via `src/migrate-docs.ts`
- **Archive preserved**: Old scripts available in `archive/` for 12 months

## Migration Completion

**Status**: ✅ **COMPLETE** (as of 2026-07-30)

```
Scripts migrated: 390 → 0 (100%)
TypeScript modules: 0 → 269
Test suites passing: 19/19
TypeScript strict mode: ✅ Enabled
Lint/coverage: ✅ Configured
```

## Related

- **Supersedes**: ADR-0012 (PowerShell Language Choice)
- **Related**: ADR-0004 (NPX Offline Hardening)
- **Tools**: `src/migrate-docs.ts` for documentation synchronization
- **CI/CD**: `.github/workflows/ci.yml` — TypeScript-only pipeline

## References

- `rules/TYPESCRIPT-FIRST-POLICY.md`
- `config/orchestrator.json` — routing configuration
- `src/session-autostart.ts` — entry point
