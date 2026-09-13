---
created: 2026-07-29 02:51:52
tags: [engram, architecture]
engram_id: 2219
type: architecture
---

# Session managers consolidation analysis

**What**: Análisis completo de los 3 componentes de session management: session-autostart.config.json, session-cleanup-start.ts, session-close-orchestrator.ts

**Why**: El usuario pidió revisar antes de consolidar/deprecar para no romper nada

**Where**:
- config/session-autostart.config.json (líneas 24-40, 195-211)
- src/session-cleanup-start.ts (326 líneas)
- src/session-close-orchestrator.ts (769 líneas)
- src/session-manager.ts (68 líneas, reescrito con mejor documentación)

**Learned**:
1. NO son redundantes — son complementarios en direcciones opuestas del lifecycle:
   - cleanup-start (START): Prepara entorno para NUEVA sesión (crea files, resetea counters)
   - orchestrator (END): Cierra sesión ACTUAL (persiste métricas, backup, mata procesos, verifica)
2. El orchestrator también corre como lazy step al START para cerrar estado de la sesión anterior
3. orchestrator REUTILIZA cleanup-start en fase 5 (línea 555, con -SkipOrphanCleanup) para cache flush
4. La dependencia es intencional: orchestrator → cleanup-start (no al revés)
5. session-manager.ts es un proxy delgado que delega a cleanup-start — está bien así
6. Se agregó flag --lightweight al orchestrator para cierres rápidos opcionales

---
*Imported from Engram on 2026-09-06*
