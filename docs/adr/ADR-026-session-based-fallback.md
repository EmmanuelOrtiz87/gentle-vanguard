# ADR-026: Session-Based Fallback para Herencia Dinámica de Modelo

## Status
**Accepted** - Implementado y verificado

## Contexto

El problema crítico identificado era que los subagentes no heredaban el modelo del orquestador (kimi-2-5). En su lugar, opencode asignaba automáticamente el modelo gratuito (`opencode/deepseek-v4-flash-free`) que no tiene créditos disponibles, causando fallos en la delegación.

### Problema Original
- El orquestador corre en **kimi-2-5** (con crédito en littellmott-nuevo)
- Al delegar a subagentes, opencode fuerza **deepseek-v4-flash-free** (sin crédito)
- Resultado: todas las delegaciones fallaban con "quota exceeded"

## Decisión

Implementar **Session-Based Fallback** con las siguientes características:

### 1. Herencia Dinámica del Modelo del Orquestador
- El subagente intenta usar el mismo modelo que el orquestador (kimi-2-5)
- Detectado desde `opencode.json` → `agent.orchestrator.model`
- Solo hace fallback al modelo gratuito si el modelo del orquestador no está disponible

### 2. Fallback Automático por Sesión
Si el modelo del orquestador falla al delegar:
1. Intentar otros modelos en la cadena de fallback
2. Si todos fallan: El orquestador ejecuta directamente la tarea
3. Persistencia: Una vez activado el modo fallback, persiste durante toda la sesión

### 3. Reset en Nueva Sesión
Al iniciar una nueva sesión:
- Se detecta automáticamente (cambio de `sessionId`)
- Todo el estado se resetea a normalidad
- Se intenta nuevamente la delegación estándar

## Consecuencias

### Positivas
- **Resiliencia**: Las tareas nunca se bloquean; siempre hay fallback
- **Consistencia**: El orquestador completa el trabajo si los subagentes fallan
- **Transparencia**: El usuario sabe cuándo se activó el modo fallback
- **Recuperación**: Nueva sesión = limpieza automática del estado

### Trade-offs
- **Sin paralelización**: Cuando el orquestador ejecuta directamente, pierde paralelismo
- **Mayor carga en orquestador**: El orquestador hace trabajo de subagente
- **Complejidad añadida**: Se agregan estados y lógica de sesión

## Implementación

### Archivos Modificados

```typescript
// src/gga.ts
interface GGAState {
  sessionId?: string;
  sessionFallbackMode?: boolean;
  consecutiveFailures?: number;
  lastFailureAt?: string;
}

function getCurrentSessionId(): string
function detectNewSession(state: GGAState): boolean
function activateSessionFallbackMode(state: GGAState, reason: string): void

// GuardianAngel con fallback final
export async function GuardianAngel(options: GGADelegationOptions) {
  // ... intentar todos los modelos ...
  // Si todos fallan: fallback al orquestador
  const fallbackResult = await executeWithProvider(
    { ...options, preferredModel: orchestratorModel },
    orchestratorModel,
    chain.length + 1
  );
}
```

```typescript
// src/model-enforcer.ts
function detectOrchestratorModel(): { model: string; provider: string } | null {
  const cfg = JSON.parse(readFileSync('opencode.json', 'utf-8'));
  return { 
    model: cfg.agent?.orchestrator?.model, 
    provider: cfg.agent?.orchestrator?.provider 
  };
}
```

## Verificación

### Tests Realizados

```bash
# Typecheck limpio
$ npx tsc --noEmit
exit 0

# Lint limpio
$ npm run lint
exit 0

# Delegación exitosa con modelo correcto
$ npx tsx src/gga.ts delegate --agent sdd-explore --task "test"
✓ Success with provider: kimi-2-5
```

### Estado Actual del Stack

| Componente | Estado |
|------------|--------|
| Typecheck | exit 0 |
| Lint | exit 0 |
| Modelo detectado | kimi-2-5 |
| Delegación | Funcionando |
| Session Fallback | Implementado |
| Reset por sesión | Auto-detectado |

## Referencias

- Memoria Engram: `decision/session-based-fallback-implementado-herencia-din-mica-de-modelo`
- Fecha: 2026-08-11

## Autor
Agente Orquestador (kimi-2-5)
