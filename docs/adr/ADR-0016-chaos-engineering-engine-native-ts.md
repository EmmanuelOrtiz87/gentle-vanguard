# ADR-0016: Chaos Engineering Engine (Native TS, Controlled Experiments)

## Status

Accepted

## Date

2026-08-17

## Context

El roadmap de resiliencia (`docs/guides/STACK-OPTIMIZATION-ROADMAP.md`) identificaba como gap **"No
chaos testing (resilience under failure)"**. La normativa
`docs/governance/normatives/NORMATIVAS-CHAOS-ENGINEERING.md` (basada en Principles of Chaos
Engineering, LitmusChaos y Chaos Mesh) definía los estándares y la madurez objetivo (L0-L5), pero
**no había implementación**: el stack no tenía forma de inyectar fallos controlados y verificar su
auto-recuperación.

Las herramientas estándar de chaos engineering (Chaos Mesh, LitmusChaos, Toxiproxy, stress-ng)
requieren Kubernetes, Docker o binarios externos — no disponibles en el entorno local (Windows, sin
Docker). El patrón del stack es **capacidades nativas en TypeScript puro** (secret-scanner,
structural-compression, coverage-runner, slsa-provenance, slsa-signer).

### Opciones consideradas

| Opción                                         | Pros                                                                   | Cons                                                 | Decisión      |
| ---------------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------- | ------------- |
| Chaos Mesh / LitmusChaos                       | Estándar de la industria, rico en experimentos                         | Requiere Kubernetes/Docker, no disponible            | ❌ Rechazada  |
| Toxiproxy / stress-ng                          | Latencia, packet loss, resource exhaustion                             | Binarios externos, instalación manual                | ❌ Rechazada  |
| **Motor nativo TS (experimentos controlados)** | Cero dependencias externas, seguro (restaura estado), patrón del stack | Alcance limitado a procesos/archivos/configs locales | ✅ **CHOSEN** |

## Decision

**Implementar un motor de Chaos Engineering nativo en TypeScript puro** (`src/tools/chaos-engineering.ts`)
que inyecta fallos controlados en componentes reales del stack, verifica la respuesta (detección,
auto-heal, degradación graceful) y **siempre restaura el estado original** (try/finally + backup
`.chaos-bak`).

### Principios de diseño

- **Seguridad primero**: cada experimento inyecta un fallo y devuelve una función de restauración
  que se ejecuta SIEMPRE en `finally` — el estado original se restaura incluso si el experimento
  falla.
- **Blast radius limitado**: los experimentos solo tocan componentes no críticos (configs,
  manifests, procesos del dashboard) — nunca datos de usuario ni el core del stack.
- **Dry-run mode**: `--dry-run` muestra qué haría cada experimento sin inyectar nada.
- **Precondiciones**: si el componente no está corriendo (ej. dashboard WS), el experimento se salta
  (`skipped`) en vez de fallar.
- **Resultados persistidos**: `.session/chaos/results.json` con timestamp y estado por experimento.

### Experimentos (3)

| Experimento                   | Componente   | Fallo inyectado                                          | Verificación                                                 |
| ----------------------------- | ------------ | -------------------------------------------------------- | ------------------------------------------------------------ |
| `config-corruption`           | configs      | Corrompe `session-autostart.config.json` (JSON inválido) | JSON.parse falla (detección) + restauración                  |
| `session-manifest-corruption` | session      | Corrompe `.session/session-current.json`                 | JSON.parse falla (detección) + restauración                  |
| `dashboard-ws-kill`           | dashboard-ws | Mata el proceso WS del dashboard (por puerto)            | Watchdog lo reinicia (ventana 15s) — se salta si WS no corre |

### Comandos

```bash
npm run chaos:list        # listar experimentos
npm run chaos:run-all     # ejecutar todos (restaura estado)
npm run chaos:run-all -- --dry-run   # simular sin inyectar
npm run chaos:report      # ver últimos resultados
npx tsx --test tests/unit/chaos-engineering.test.ts   # tests (10)
```

## Consequences

### Positive

- ✅ Gap de resiliencia del roadmap resuelto (L190, L656)
- ✅ Cero dependencias externas (patrón nativo TS del stack)
- ✅ Seguro por diseño: restauración garantizada, blast radius limitado, dry-run
- ✅ Verifica la auto-recuperación real del stack (watchdog del dashboard WS)
- ✅ Resultados persistidos y consultables (`chaos:report`)
- ✅ Extensible: añadir experimentos = añadir entradas al array `EXPERIMENTS`

### Negative

- ⚠️ Alcance limitado a fallos locales (procesos, archivos, configs) — sin red/CPU/mem
- ⚠️ `dashboard-ws-kill` requiere que el WS esté corriendo (si no, se salta)
- ⚠️ La verificación de corrupción usa JSON.parse (detección estructural) — no valida recuperación
  del pipeline completo (los daemons lazy del pipeline no terminan en spawnSync)

### Mitigation

- Para red/CPU/mem: documentar el uso de Toxiproxy/stress-ng como extensión opcional si se instalan
  (el motor acepta experimentos externos vía el array `EXPERIMENTS`)
- Para validación de recuperación completa: usar el detached launcher (`session:autostart:detached`)
  que retorna en ~1.3s sin colgar
- Madurez objetivo: L3 (Game Days) alcanzado con `chaos:run-all` manual; **L4 (automated en CI/CD)
  alcanzado (2026-08-18)** — job `chaos` en `.github/workflows/scheduled.yml` ejecuta
  `chaos:run-all --json` semanal (cron `0 6 * * 0`) y falla si algún experimento reporta FAILED. El
  CLI soporta `--json` para salida máquina-legible en CI.

## Related

- **Supersedes**: nada (nueva capacidad)
- **Related**: ADR-0015 (SLSA signing), ADR-0014 (SLSA provenance), ADR-0009 (watchtower — auto-heal
  verificado por `dashboard-ws-kill`), ADR-0010 (knowledge absorption — patrón nativo TS)
- **Normativa**: `docs/governance/normatives/NORMATIVAS-CHAOS-ENGINEERING.md` (madurez L0-L5)
- **Roadmap**: `docs/guides/STACK-OPTIMIZATION-ROADMAP.md` — items "No chaos testing" y "Consider:
  chaos testing" marcados completados

## References

- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [LitmusChaos](https://litmuschaos.io/) / [Chaos Mesh](https://chaos-mesh.org/) — referencias de la
  normativa (no usadas directamente)
- `src/tools/chaos-engineering.ts` — implementación
- `tests/unit/chaos-engineering.test.ts` — 10 tests

---

**Review Date**: Q1 2027 **Reviewers**: Security/DevOps Team
