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
                    ↘ FAILED ↗
```

`APPROVED` es un gate obligatorio para publicación remota.

## Plataformas

El contrato contempla:

- linkedin
- x
- instagram
- youtube
- tiktok
- whatsapp_channel
- whatsapp_status
- github
- devto
- producthunt
- discord

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

## Evolución

Fase 1: manifest + validator + packet builder + audit local.
Fase 2: integración con CMS y CLI.
Fase 3: scheduler/queue y notificaciones.
Fase 4: adapters oficiales por plataforma.
Fase 5: métricas y feedback loop.
Fase 6: uso de Gentle-Vanguard como orquestador del propio sistema.
