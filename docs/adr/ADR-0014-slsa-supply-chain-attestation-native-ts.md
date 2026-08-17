# ADR-0014: SLSA Supply-Chain Attestation (Native TS Provenance, Build L1)

## Status

Accepted

## Date

2026-08-17

## Context

El roadmap de seguridad (`docs/guides/STACK-OPTIMIZATION-ROADMAP.md`) identificaba como pendiente
la **supply-chain attestation (SLSA provenance)** — el stack tiene SBOM CycloneDX
(`sbom/gentle-vanguard-sbom.json`, 464 componentes) pero ningún statement de provenance que
atestigüe cómo se produjeron los artifacts.

Las herramientas estándar del ecosistema SLSA (cosign, slsa-verifier, GitHub Actions SLSA
generators) no están disponibles en el entorno local (Windows, sin Docker) y añaden dependencias
externas que contradicen el patrón del stack: **capacidades nativas en TypeScript puro** (secret-scanner,
structural-compression, coverage-runner, web-crawler).

### Opciones consideradas

| Opción | Pros | Cons | Decisión |
| --- | --- | --- | --- |
| cosign + slsa-verifier (binarios) | Estándar de la industria, firma criptográfica real | Requiere instalación externa, complejo en Windows, dependencia de Go | ❌ Rechazada |
| GitHub Actions SLSA generator | Provenance L3 nativo en CI | Solo aplica a releases GitHub, no a builds locales | ❌ Rechazada (parcial) |
| **Generador nativo TS (in-toto v1 + SLSA v1.0)** | Cero dependencias externas, verificable, patrón del stack | Sin firma criptográfica (Build L1, no L2/L3) | ✅ **CHOSEN** |

## Decision

**Implementar un generador de provenance nativo en TypeScript puro** (`src/slsa-provenance.ts`)
que produce statements in-toto v1 con predicado SLSA v1.0
(`https://slsa.dev/provenance/v1`), cumpliendo los requisitos de **SLSA Build L1**
(provenance generation) sin tooling externo.

### Características

- **Formatos**: in-toto Statement v1 (`https://in-toto.io/Statement/v1`) + SLSA provenance v1.0.
- **Subject**: digests SHA-256 de cada artifact atestiguado.
- **buildDefinition**: `buildType` (URI del template), `externalParameters` (repository, ref),
  `internalParameters` (environment), `resolvedDependencies` (repo + gitCommit digest).
- **runDetails**: `builder.id` (URI del pipeline CI), `metadata` (invocationId, startedOn,
  finishedOn RFC3339).
- **Detección automática**: git commit, branch y repo origin desde `.git/` (sin flags).
- **Validación**: `validateProvenance()` verifica los requisitos SLSA Build L1 (buildDefinition,
  runDetails, builder.id, subject digests) — usado por el CLI `verify` y por tests.
- **CLI**: `generate` (crea statement) y `verify` (valida existente).

### Comandos

```bash
npm run provenance:generate -- -a sbom/gentle-vanguard-sbom.json --repo <url>  # generar
npm run provenance:verify -- -f provenance/gentle-vanguard-provenance.json     # validar
npx tsx --test tests/unit/slsa-provenance.test.ts                               # tests (19)
```

### Integración RDD (release workflow)

El flujo RDD (`src/rdd/rdd-core.ts`) genera provenance automáticamente cuando el workflow se
completa (todos los 5 gates pasan): `generateReleaseProvenance()` atestigua `sbom.json` + el
receipt del workflow contra el git SHA actual, con `invocationId: rdd-<workflowId>`. Es
best-effort (no bloquea el completado si falla). Verificado con
`tests/unit/rdd/rdd-provenance.test.ts` (3 tests).

## Consequences

### Positive

- ✅ SLSA Build L1 provenance sin dependencias externas (patrón nativo TS del stack)
- ✅ Verificable localmente y en CI (validación estructural de campos requeridos)
- ✅ Complementa el SBOM: `sbom.json` (qué dependencias) + provenance (cómo se construyó)
- ✅ Extensible: el mismo statement puede firmarse después con cosign para subir a L2/L3
- ✅ Detección automática de commit/ref/repo desde `.git` — cero configuración

### Negative

- ⚠️ **Build L1 solamente**: sin firma criptográfica no alcanza L2/L3 (provenance no falsificable
  requiere un build service aislado con identidad de firma)
- ⚠️ `internalParameters.environment` está vacío por defecto (solo node version si no se pasa
  `--env`) — completar en CI con variables reales
- ⚠️ Los digests de artifacts no se re-verifican contra el filesystem en `verify` (solo estructura)
  — re-verificación es posible pero requiere conocer la ruta original

### Mitigation

- En CI, pasar `--env` con variables reales del pipeline para enriquecer `internalParameters`
- Para L2/L3 futuro: firmar el statement con cosign (`cosign attest-blob`) como paso post-build
- Añadir re-verificación de digests si se requiere (extensiones `gentle_vanguard_*`)

## Related

- **Supersedes**: nada (nueva capacidad)
- **Related**: ADR-0006 (code coverage — calidad verificable), ADR-0011 (dependency updates —
  supply-chain), ADR-0010 (knowledge absorption — patrón nativo TS)
- **Roadmap**: `docs/guides/STACK-OPTIMIZATION-ROADMAP.md` — item "supply-chain attestation (SLSA
  provenance)" marcado completado

## References

- [SLSA v1.0 Provenance](https://slsa.dev/spec/v1.0/provenance) — spec oficial absorbida
- [in-toto Statement](https://github.com/in-toto/attestation/blob/main/spec/v1/statement.md)
- `src/slsa-provenance.ts` — implementación
- `tests/unit/slsa-provenance.test.ts` — 19 tests

---

**Review Date**: Q1 2027
**Reviewers**: Security/DevOps Team
