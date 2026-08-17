# ADR-0015: SLSA Provenance Signing (Native DSSE + Ed25519, Build L2/L3)

## Status

Accepted

## Date

2026-08-17

## Context

El ADR-0014 implementó generación de provenance SLSA v1.0 nativa en TypeScript
(`src/slsa-provenance.ts`), alcanzando **Build L1** (provenance generation). La limitación
documentada era la ausencia de **firma criptográfica**: sin firma, el provenance no es
falsificable y no alcanza los niveles L2/L3 de SLSA (provenance no falsificable requiere
identidad de firma del build service).

Las herramientas estándar para firmar attestations (cosign, slsa-verifier) no están disponibles
en el entorno local (Windows, sin Docker, sin binarios Go). El patrón del stack es **capacidades
nativas en TypeScript puro** — y Node.js incluye `crypto` con soporte **Ed25519** nativo.

El formato DSSE (Dead Simple Signing Envelope, de secure-systems-lab) es el estándar que usan
in-toto y sigstore para envolver attestations firmadas:

```json
{
  "payload": "<base64 del statement>",
  "payloadType": "application/vnd.in-toto+json",
  "signatures": [{ "keyid": "<sha256 de la clave pública>", "sig": "<base64>" }]
}
```

### Opciones consideradas

| Opción | Pros | Cons | Decisión |
| --- | --- | --- | --- |
| cosign attest-blob | Estándar de la industria, integración sigstore | No disponible en el entorno, dependencia Go | ❌ Rechazada |
| GitHub Actions sigstore | Firma automática en CI | Solo aplica a releases GitHub, no a builds locales | ❌ Rechazada (parcial) |
| **Firma nativa TS (DSSE + Ed25519)** | Cero dependencias externas, Node crypto nativo, patrón del stack | Gestión de claves manual (no sigstore/Rekor) | ✅ **CHOSEN** |

## Decision

**Implementar un firmador de provenance nativo en TypeScript puro** (`src/slsa-signer.ts`) que
envuelve el statement in-toto v1 en un **envelope DSSE** firmado con **Ed25519** (Node `crypto`),
alcanzando los requisitos de **SLSA Build L2/L3** (provenance no falsificable con identidad de
firma) sin tooling externo.

### Características

- **Formato**: DSSE envelope (`payload` base64 + `payloadType` + `signatures[]` con `keyid` y
  `sig` base64) — compatible con el ecosistema in-toto/sigstore.
- **Criptografía**: Ed25519 (Node `crypto.generateKeyPairSync('ed25519')`), firma y verificación
  con `crypto.sign`/`crypto.verify`.
- **Keyid**: SHA-256 del SPKI DER de la clave pública (estable y verificable).
- **Gestión de claves**:
  - Privada: `.runtime/provenance/private-key.pem` (gitignored, nunca se commitea).
  - Pública: `provenance/public-key.pem` (intencionalmente pública para verificación).
  - `genkey` genera el par; `sign` firma; `verify` valida.
- **Verificación robusta**: detecta tamper del payload, keyid mismatch, claves incorrectas y
  envelopes malformados.
- **CLI**: `genkey`, `sign`, `verify` con `parseSignerArgs()`.

### Comandos

```bash
npm run provenance:genkey        # generar par de claves (una vez)
npm run provenance:sign          # firmar provenance → .signed.json
npm run provenance:verify-sig    # verificar firma con clave pública
npx tsx --test tests/unit/slsa-signer.test.ts   # tests (10)
```

### Integración RDD (release workflow)

El flujo RDD (`src/rdd/rdd-core.ts`) firma automáticamente el provenance tras generarlo cuando
existe la clave privada (best-effort, no bloquea el completado). Verificado con
`tests/unit/rdd/rdd-provenance.test.ts` (3 tests).

## Consequences

### Positive

- ✅ SLSA Build L2/L3: provenance no falsificable con identidad de firma (Ed25519)
- ✅ Cero dependencias externas (Node `crypto` nativo) — patrón del stack
- ✅ Formato DSSE estándar: interoperable con verifiers in-toto/sigstore
- ✅ Verificación robusta (tamper, keyid, wrong-key, malformed)
- ✅ Clave pública commiteada → cualquiera puede verificar; privada nunca expuesta
- ✅ Integración automática en el release workflow RDD

### Negative

- ⚠️ Gestión de claves manual (sin sigstore/Rekor transparency log) — la rotación de claves es
  responsabilidad del operador
- ⚠️ La clave privada vive en `.runtime/` local — para CI multi-máquina se necesita un secret
  manager (o mover la firma a GitHub Actions sigstore)
- ⚠️ No hay re-verificación de digests de artifacts contra el filesystem en `verify` (solo
  estructura + firma)

### Mitigation

- Documentar la rotación de claves en `docs/security/` (procedimiento genkey + re-firma)
- Para CI: usar GitHub Actions sigstore para releases públicos, manteniendo la firma local para
  builds de desarrollo
- Añadir re-verificación de digests si se requiere (extensiones `gentle_vanguard_*`)

## Related

- **Supersedes**: nada (extiende ADR-0014)
- **Related**: ADR-0014 (SLSA provenance generation), ADR-0006 (code coverage), ADR-0011
  (dependency updates), ADR-0010 (knowledge absorption — patrón nativo TS)
- **Roadmap**: `docs/guides/STACK-OPTIMIZATION-ROADMAP.md` — item "supply-chain attestation
  (SLSA L3)" ahora cubierto por firma nativa

## References

- [DSSE — Dead Simple Signing Envelope](https://github.com/secure-systems-lab/dsse)
- [SLSA v1.0 Provenance](https://slsa.dev/spec/v1.0/provenance)
- [in-toto Attestation](https://github.com/in-toto/attestation)
- `src/slsa-signer.ts` — implementación
- `tests/unit/slsa-signer.test.ts` — 10 tests

---

**Review Date**: Q1 2027
**Reviewers**: Security/DevOps Team