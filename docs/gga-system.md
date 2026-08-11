# GGA (Guardian Angel) - AI Provider Switcher

## Overview

GGA es un sistema nativo de **switching automático de proveedores de IA** inspirado en el componente
GGA de [gentle-ai](https://github.com/Gentleman-Programming/gentle-ai). Cuando un proveedor falla
(por ejemplo, "Free usage exceeded"), GGA automáticamente intenta con el siguiente proveedor en la
cadena de fallback.

## Why This Exists

**The Problem:**

- Los subagentes en OpenCode están configurados con `model: "opencode/deepseek-v4-flash-free"`
- Cuando se agota la cuota: `"Free usage exceeded, subscribe to Go"`, el subagente falla
- No existe mecanismo nativo de herencia de modelos en OpenCode's `task()`

**The Solution:**

- GGA intercepta las delegaciones y detecta errores de cuota
- Automáticamente cambia al siguiente proveedor disponible
- Persiste el estado de proveedores agotados
- Hereda el modelo del orquestador cuando es posible

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         ORQUESTADOR                              │
│                        (Model: kimi-2-5)                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    orchestrator-task-wrapper.ts                   │
│              (Drop-in replacement for task())                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          GGA (src/gga.ts)                        │
│                 Guardian Angel - AI Provider Switcher            │
│                                                                  │
│   Fallback Chain:                                                │
│   1. Requested/preferred model                                    │
│   2. Orchestrator model (auto-detected)                          │
│   3. kimi-2-5 (littellmott-nuevo)                               │
│   4. claude-haiku-4-5 (littellmott-nuevo)                       │
│   5. opencode/deepseek-v4-flash-free (opencode)                  │
│   6. ollama/qwen2.5-coder:14b (local)                          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      agent-delegator.ts                          │
│                   (With model override support)                  │
└─────────────────────────────────────────────────────────────────┘
```

## Installation

Los archivos ya están incluidos en el stack:

- `src/gga.ts` - Core GGA implementation
- `src/orchestrator-task-wrapper.ts` - task() replacement
- Scripts añadidos a `package.json`

## Usage

### As a Drop-in Replacement for task()

```typescript
// BEFORE:
import { task } from 'opencode';

// AFTER:
import { task } from './orchestrator-task-wrapper.js';

// Use normally - fallback happens automatically
const result = await task({
  subagent_type: 'sdd-apply',
  prompt: 'Implement feature',
  description: 'optional',
});
```

### Using GGA Directly

```typescript
import { GuardianAngel } from './gga.js';

const result = await GuardianAngel({
  agent: 'sdd-apply',
  task: 'Implement feature',
  preferredModel: 'kimi-2-5', // optional
  context: 'extra context', // optional
});

// Result includes:
// - success: boolean
// - output: string
// - model: string (which model actually executed)
// - switchOccurred: boolean (was fallback used?)
// - attempts: number
```

### CLI Commands

```bash
# Check GGA status
npm run gga:status

# Delegate with auto-fallback
npm run gga:delegate -- --agent sdd-apply --task "fix bug"

# Reset exhausted providers
npm run gga:reset

# Check health for specific provider
npx tsx src/gga.ts health kimi-2-5
```

## Error Detection

GGA detecta automáticamente estos errores y dispara fallback:

| Error Pattern           | Trigger      |
| ----------------------- | ------------ |
| `Free usage exceeded`   | ✅ Switch    |
| `subscribe to Go`       | ✅ Switch    |
| `quota exceeded`        | ✅ Switch    |
| `credits exhausted`     | ✅ Switch    |
| `429 Too Many Requests` | ✅ Switch    |
| `Model not found`       | ✅ Switch    |
| `timeout`               | ✅ Switch    |
| `APIConnectionError`    | ✅ Switch    |
| `unauthorized`          | ✅ Switch    |
| Other errors            | ❌ No switch |

## Configuration

### Environment Variables

```bash
# Override detected orchestrator model
export ORCHESTRATOR_MODEL=kimi-2-5
export GGA_MODEL=kimi-2-5
export AGENT_MODEL=kimi-2-5
export FORCE_MODEL=kimi-2-5
```

### Model Detection Priority

1. `FORCE_MODEL` environment variable
2. `AGENT_MODEL` environment variable
3. `.runtime/model-active.json`
4. `.session/session-current.json`
5. Default: `kimi-2-5`

### State Persistence

```
.runtime/
├── gga-state.json        # GGA state (exhausted providers, health)
└── model-active.json      # Currently active model

.logs/
└── gga.log               # Operation logs
```

## API Reference

### GuardianAngel(options)

Main delegation function with auto-switching.

**Parameters:**

- `agent` (string): Agent name (e.g., 'sdd-apply')
- `task` (string): Task description
- `context` (string, optional): Additional context
- `preferredModel` (string, optional): Preferred model
- `fallbackChain` (string[], optional): Explicit fallback chain
- `maxRetries` (number, optional): Max attempts (default: chain length)
- `timeout` (number, optional): Timeout in ms (default: 300000)

**Returns:** `Promise<GGADelegationResult>`

- `success`: boolean
- `output`: string
- `error`: string (if failed)
- `model`: string (actual model used)
- `originalModel`: string (initial model, if switched)
- `duration`: number (ms)
- `attempts`: number
- `switchOccurred`: boolean
- `exhaustedProviders`: string[]

### Utility Functions

```typescript
import {
  checkProviderHealth, // Check health for a provider
  getCurrentProvider, // Get current active provider
  getSwitchHistory, // Get recent switch history
  resetProviders, // Reset exhausted providers
} from './gga.js';
```

## Testing

```bash
# Test GGA status
npm run gga:status

# Test delegation
npm run gga:delegate -- --agent sdd-explore --task "test task"

# Check TypeScript compilation
npm run typecheck

# View logs
Get-Content .logs/gga.log -Tail 50
```

## Comparison with Gentle-AI

| Feature             | Gentle-AI GGA | Our Implementation |
| ------------------- | ------------- | ------------------ |
| Auto-switching      | ✅ Yes        | ✅ Yes             |
| Quota detection     | ✅ Yes        | ✅ Yes             |
| Multi-provider      | ✅ Yes        | ✅ Yes             |
| State persistence   | ✅ Yes        | ✅ Yes             |
| CLI interface       | ✅ Yes        | ✅ Yes             |
| Drop-in replacement | ✅ Yes        | ✅ Yes             |
| Model profiles      | ✅ Yes        | ✅ Basic           |
| Native integration  | Go            | TypeScript         |

## Troubleshooting

### Common Issues

**Issue:** `spawn EINVAL` on Windows  
**Solution:** Fixed in latest version - uses `shell: true` for Windows

**Issue:** Provider not switching  
**Solution:** Check `.logs/gga.log` for error patterns

**Issue:** All providers exhausted  
**Solution:** Run `npm run gga:reset` to clear exhausted list

### Debug Mode

Set `LOG_LEVEL=debug` for verbose logging:

```bash
$env:LOG_LEVEL="debug"
npm run gga:delegate -- --agent sdd-apply --task "test"
```

## Integration Status

✅ **Production Ready** - El sistema está completamente funcional y listo para usar en producción.

## Related Files

- `src/gga.ts` - Core implementation
- `src/orchestrator-task-wrapper.ts` - task() wrapper
- `src/agent-delegator.ts` - Enhanced delegator
- `config/model-health-registry.json` - Model configuration

## Credits

Inspired by [gentle-ai](https://github.com/Gentleman-Programming/gentle-ai)'s GGA (Gentleman
Guardian Angel) component.

## License

MIT - Parte de Gentle-Vanguard Stack
