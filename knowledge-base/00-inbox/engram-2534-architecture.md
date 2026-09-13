---
created: 2026-08-04 20:18:09
tags: [engram, architecture]
engram_id: 2534
type: architecture
---

# Session Close Guardian - Sistema de protección integrado contra cierres informales

**What**: Implementado sistema Guardian para prevenir cierres de sesión manuales/informales
**Why**: Violación reiterada de SESSION-CLOSE-NORMATIVA.md por cierres manuales con mem_session_end
**Where**:
- src/session-close-guardian.ts (motor de protección)
- src/session-close-orchestrator.ts (integración en fase PRE-CLOSE)
- .session/.informal-close-attempt (marker de detección)
- .session/guardian-warnings.log (auditoría)

**Architecture**:
  1. guardianCheck() - detecta intentos previos al iniciar orquestador
  2. blockAndRedirect() - bloquea cierres manuales y redirige automáticamente
  3. learnFromMistake() - registra contexto para evitar repetición
  4. Marker system - archivo .informal-close-attempt para tracking histórico

**Integration**:
- Importado en session-close-orchestrator.ts línea ~27
- Llamada en main() detecta intentos informales
- Fase PRE-CLOSE (1.2) verifica marker y reporta en resultado
- learnFromMistake() invocado cuando orquestador detecta redirección

**Learned**:
- Una solución integrada > dos sistemas separados
- Detección temprana (PRE-CLOSE) permite corregir sin romper flujo
- Autoredirección evita intervención humana = mejor UX
- Patrón reusable para otros protocolos críticos
  
**Commands**:
- npm run guardian:check
- npx tsx src/session-close-guardian.ts

---
*Imported from Engram on 2026-09-06*
