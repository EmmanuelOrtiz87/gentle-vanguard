---
created: 2026-07-08 05:20:58
tags: [engram, architecture]
engram_id: 1498
type: architecture
---

# Stack improvement master plan — 10/10 roadmap

**What**: Plan maestro para llevar Gentle Vanguard stack de 7.5/10 a 10/10. 8 fases de mejora priorizadas.
**Why**: El stack tiene deuda técnica en PowerShell monoculture (~200 scripts), config sprawl (~100 files), APIs keys expuestas, tests insuficientes, CI/CD ausente.
**Where**: Todo el repositorio C:\Workspace_local\gentle-vanguard

## Plan de 8 Fases

### Fase 1 — CRÍTICO: API Key Security

- Mover API key de littellmott de `opencode.json` a `.env` file
- Usar variable de entorno en lugar de hardcode
- Archivos: opencode.json, .env.example

### Fase 2 — ALTA: Consolidar Config Files

- Unificar `config/model-router.json` + `config/model-routing.json`
- Unificar configs de seguridad duplicados
- Crear schema registry con Zod

### Fase 3 — ALTA: Limpiar Scripts Duplicados

- Consolidar github_search.py → github_search5.py en un solo script parametrizable
- Eliminar skills-archive/ (skills obsoletos)
- Eliminar deprecated/presentation-v6/
- Limpiar scripts root Python duplicados

### Fase 4 — ALTA: Sincronizar TypeScript

- Dashboard TS 5.2 → 6.0 (como el root)
- Unificar tsconfig en todo el proyecto

### Fase 5 — MEDIA: Mejorar Tests

- Agregar tests para scripts PS1 core
- Aumentar cobertura general

### Fase 6 — MEDIA: CI/CD Pipeline

- GitHub Actions: lint → typecheck → test → build
- Docker build automático

### Fase 7 — ALTA: Migrar PS1 Core a TypeScript

- maintenance-watchtower.ps1 → TypeScript
- session-autostart.ps1 → TypeScript
- health-check.ps1 → TypeScript

### Fase 8 — BAJA: Unificar Engram + CodeGraph

- Evaluar overlap entre sistemas de indexación
- Decidir si consolidar

## Progreso

- Fase 1: PENDING
- Fase 2: PENDING
- Fase 3: PENDING
- Fase 4: PENDING
- Fase 5: PENDING
- Fase 6: PENDING
- Fase 7: PENDING
- Fase 8: PENDING

---
*Imported from Engram on 2026-09-06*
