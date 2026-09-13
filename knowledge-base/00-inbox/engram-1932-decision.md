---
created: 2026-07-24 17:35:40
tags: [engram, decision]
engram_id: 1932
type: decision
---

# Stack Gentle-Vanguard v8.0.0 - Revisión Completa Finalizada

**What**: Se completó la revisión, validación y optimización completa del stack Gentle-Vanguard v8.0.0. Todas las tareas críticas han sido ejecutadas exitosamente.

**Why**: El usuario solicitó una revisión exhaustiva del stack para identificar gaps, optimizar componentes y asegurar que todas las herramientas estén operativas al 100%.

**Where**:
- Directorios renombrados: src/core, src/security, src/skills, src/mcp, src/infrastructure, src/convergence, src/multitenant, src/autonomous-review, src/mcp-native, src/trust-layer
- Archivos actualizados: 20+ archivos con referencias corregidas
- Configuraciones: config/mcp-config.sd.json, config/skill-mcp.json
- Documentación: docs/STACK-DOCUMENTATION.md

**Learned**:
- La nomenclatura de directorios debe seguir kebab-case (minúsculas, guiones)
- MCP requiere configuración explícita en mcp-config.sd.json
- Los embeddings se generan en skill-embeddings.json, no ml-index.json
- El dashboard WS usa puerto 8080, no 5173 (que es el dev server de Vite)
- Maintenance Watchtower es más confiable que health-check.ts para verificación global

---
*Imported from Engram on 2026-09-06*
