---
created: 2026-08-04 17:56:11
tags: [engram, decision]
engram_id: 2522
type: decision
---

# Quick Start Nativo - npm run start

**What**: Creado script de inicio rápido 100% TypeScript nativo, sin dependencias de batch files.

**Why**: Los archivos batch tenían problemas de ejecución en ciertos entornos. El script TypeScript es más robusto y portable.

**Where**:
- src/quick-start.ts - Script unificado de inicio
- package.json - Agregado "start": "npx tsx src/quick-start.ts"
- Dashboard iniciado y funcionando (PID 35540)

**Features**:
- ✅ Limpia procesos zombie automáticamente
- ✅ Verifica si ya está corriendo
- ✅ Mensajes claros de progreso
- ✅ Sin bloquear terminal
- ✅ Compatible con npm run start

**Uso**:

```
npm run start              # Inicio rápido
npm run start:complete     # Con verificaciones completas
```

---
*Imported from Engram on 2026-09-06*
