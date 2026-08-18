# Gentle-Vanguard Content Operations

## Objetivo

Consolidar las capacidades existentes de `src/marketing-agent.ts`, `src/social-poster.ts` y `docs/presentations/resources-index.html` en un flujo operativo único para contenido.

```text
Plan → Manifest → Validate → Package → Review → Approve → Publish → Measure → Learn
```

## Decisión arquitectónica

No crear otro framework de publicación. El Content Operations Engine es una capa de dominio que reutiliza los servicios existentes del stack.

### Componentes existentes reutilizados

- `src/marketing-agent.ts`: generación de copy multilingüe y por plataforma.
- `src/social-poster.ts`: plantillas, plataformas y tracking básico.
- `docs/presentations/resources-index.html`: CMS local y punto de interacción humano.
- `src/cli/gv.ts`: CLI principal.
- health/watchtower, seguridad, auditoría, base de datos y dashboard: infraestructura transversal existente.

## Fuente de verdad

`content/operations/master-manifest.json`

Un `ContentJob` representa una pieza concreta para una plataforma y fecha.

Estados:

```text
DRAFT → VALIDATED → PACKAGED → REVIEW → APPROVED → PUBLISHED → MEASURED
                    ↖ FAILED ↗
```

`APPROVED` es un gate obligatorio para publicación remota.

### Transiciones válidas (state machine)

| Desde      | Hacia                          |
| ---------- | ------------------------------ |
| DRAFT      | VALIDATED, FAILED              |
| VALIDATED  | PACKAGED, FAILED               |
| PACKAGED   | REVIEW, FAILED                 |
| REVIEW     | APPROVED, FAILED               |
| APPROVED   | PUBLISHED, FAILED              |
| PUBLISHED  | MEASURED                       |
| MEASURED   | —                              |
| FAILED     | DRAFT                          |

`transition()` es inmutable: devuelve un nuevo job sin mutar el original. `canTransition()` permite validar antes de ejecutar.

## Plataformas

El contrato contempla (registry en `config/content-operations/platforms.json`):

- linkedin (adapter, media, approvalRequired)
- x (adapter, media, approvalRequired)
- instagram (adapter, media, approvalRequired)
- youtube (adapter, media, approvalRequired)
- tiktok (adapter, media, approvalRequired)
- whatsapp_channel (adapter, media, approvalRequired)
- whatsapp_status (manual, media, approvalRequired)
- github (native-repo, sin media, approvalRequired)
- devto (adapter, media, approvalRequired)
- producthunt (adapter, media, approvalRequired)
- discord (adapter, media, approvalRequired)

La disponibilidad real de publicación automática depende de APIs oficiales, scopes, OAuth, políticas y elegibilidad de cada plataforma.

## Principios

1. Local-first: preparar paquetes funciona sin Internet.
2. Human-in-the-loop: la publicación remota requiere aprobación explícita.
3. Adapter boundary: cada proveedor se aísla detrás de un contrato.
4. Idempotencia: un job no debe publicarse dos veces por reintentos.
5. Auditabilidad: cada transición debe poder reconstruirse.
6. Sin secretos en Git.
7. El contenido se deriva de una fuente común y se adapta por plataforma.
8. El sistema debe poder operar sin IA; la IA mejora generación, variaciones y análisis, pero no es una dependencia única del workflow.

## Offline continuity

El repositorio debe incluir los manifiestos, templates, documentación y scripts necesarios para preparar publicaciones sin conexión. Las operaciones que dependan de una API remota deben fallar de forma explícita y dejar el paquete listo para publicación manual.

## CLI y scripts npm

```bash
npm run content:list      # listar jobs (--date, --platform, --id, --status)
npm run content:validate  # validar jobs contra manifest + registry
npm run content:prepare   # empaquetar jobs validados offline
npm run content:status    # resumen de estados del pipeline
npm run content:report    # reporte markdown del pipeline
npm run content:export    # exportar kit offline ZIP (Windows)
npm run content:test      # tests unitarios del engine (15)
```

## Contenido real (sprint de lanzamiento)

El manifest contiene el calendario real de lanzamiento `GROWTH-EXPERIMENT-001` (15 días, 18/08 → 01/09/2026, 21 publicaciones):

| Fecha      | Plataforma        | Tema                          |
| ---------- | ----------------- | ----------------------------- |
| 2026-08-18 | LinkedIn          | Presentación / construcción   |
| 2026-08-18 | X                 | Presentación                  |
| 2026-08-18 | Instagram         | Presentación visual           |
| 2026-08-19 | X                 | Pregunta                      |
| 2026-08-20 | LinkedIn          | Problema + solución           |
| 2026-08-20 | X                 | Problema + solución           |
| 2026-08-21 | YouTube           | Primer tutorial / demo        |
| 2026-08-21 | LinkedIn          | Anuncio de demo               |
| 2026-08-22 | Discord           | Llamado a testers             |
| 2026-08-23 | LinkedIn          | Construcción en público       |
| 2026-08-24 | X                 | Caso de uso                   |
| 2026-08-25 | Instagram         | Beneficio visual              |
| 2026-08-26 | LinkedIn          | Memoria / contexto            |
| 2026-08-27 | YouTube           | Tutorial / workflow           |
| 2026-08-27 | X                 | Hilo / aprendizaje            |
| 2026-08-28 | Discord           | Feedback                      |
| 2026-08-29 | LinkedIn          | Visión de negocio             |
| 2026-08-30 | X                 | Comunidad / invitación        |
| 2026-08-31 | Instagram         | Resumen 2 semanas             |
| 2026-09-01 | LinkedIn          | Cierre del sprint             |
| 2026-09-01 | X                 | Cierre del sprint             |

Los assets (21 PNGs dimensionados por plataforma) viven en `docs/presentations/social-assets/` y se copian al paquete durante `prepare`.

## Evolución

Fase 1: manifest + validator + packet builder + audit local. ✅ (implementada)
Fase 2: integración con CMS y CLI.
Fase 3: scheduler/queue y notificaciones.
Fase 4: adapters oficiales por plataforma.
Fase 5: métricas y feedback loop.
Fase 6: uso de Gentle-Vanguard como orquestador del propio sistema.