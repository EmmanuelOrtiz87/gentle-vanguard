# Gentle-Vanguard - Uso Agnóstico

## Resumen Ejecutivo

El stack Gentle-Vanguard ahora es **completamente agnóstico**. Funciona con OpenCode, Claude, Cursor, o cualquier herramienta AI sin dependencias específicas.

## Problema Resuelto

### Antes (Dependiente de OpenCode)
- ❌ Delegación con `task()` fallaba: "Model not found: inherit-from-session"
- ❌ Skills solo accesibles vía `.opencode/skills/`
- ❌ Agentes solo funcionaban en entorno OpenCode

### Ahora (Agnóstico)
- ✅ Delegación nativa via `npx tsx src/agent-delegator.ts`
- ✅ Skills nativos en `/skills/` accesibles desde cualquier herramienta
- ✅ 11 agentes nativos funcionando en cualquier entorno

## Arquitectura Agnóstica

```
Stack Gentle-Vanguard (v2.0 - Agnóstico)
├── config/agents.json           ← Definiciones portables
├── src/
│   ├── skill-loader.ts          ← Carga skills nativos
│   ├── agent-delegator.ts       ← Orquestador de agentes
│   └── agents/
│       ├── sdd-explore.ts       ← BA exploration ✅
│       ├── sdd-design.ts        ← Architecture ✅
│       ├── sdd-apply.ts         ← DEV implementation ✅
│       └── sdd-verify.ts        ← QA verification ✅
│       ├── doc-agent.ts         ← Documentation ✅
│       ├── ops-agent.ts         ← Operations ✅
│       ├── gov-agent.ts         ← Governance ✅
│       ├── session-agent.ts     ← Session management ✅
│       ├── self-diag-agent.ts   ← Self-diagnosis ✅
│       ├── premortem-agent.ts   ← Risk analysis ✅
│       └── maintenance-agent.ts ← Maintenance ✅
└── skills/                      ← 135+ skills nativos
    └── [skill-name]/SKILL.md
```

## Uso en Cualquier Herramienta AI

### 1. Cargar Skills

**OpenCode:**
```bash
# Automático - opencode detecta .opencode/skills/
```

**Claude/Cursor/Genérico:**
```bash
# Listar skills disponibles
npx tsx src/skill-loader.ts --list

# Cargar skill específico
npx tsx src/skill-loader.ts --load code-review-skill
```

### 2. Delegar a Agentes

**OpenCode (fallback):**
```bash
# Si task() falla con "inherit-from-session", usar delegador nativo
npx tsx src/agent-delegator.ts --agent sdd-apply --task "implement feature"
```

**Claude/Cursor/Genérico:**
```bash
# Delegar directamente
npx tsx src/agents/sdd-apply.ts --task "fix bug" --context "auth.ts"

# O usar el delegador
npx tsx src/agent-delegator.ts --agent sdd-explore --task "analyze requirements"
```

### 3. Ejecutar Verificaciones

**Cualquier herramienta:**
```bash
# Health check completo
npm run watchtower:health

# TypeScript + Lint
npm run typecheck && npm run lint

# Tests
npm run test:config
npm run test:workflows
```

## Guía Rápida por Herramienta

### OpenCode

```json
// .opencode/agents/*.md ya no son necesarios
// Usar config/agents.json como fuente de verdad

// Si task() falla, fallback automático a delegador nativo
```

### Claude (claude.ai)

1. **Subir proyecto** a Claude
2. **Ejecutar:** `npm run watchtower:health`
3. **Delegar tareas:**
   ```
   Assistant: Voy a delegar a sdd-apply...
   npx tsx src/agents/sdd-apply.ts --task "implementar feature X"
   ```

### Cursor (cursor.sh)

1. **Abrir proyecto** en Cursor
2. **En terminal:**
   ```bash
   npx tsx src/agent-delegator.ts --agent sdd-design --task "diseñar API"
   ```
3. **Usar resultados** en el chat

### VS Code + Copilot

1. **Abrir proyecto**
2. **Ejecutar en terminal integrado:**
   ```bash
   npx tsx src/skill-loader.ts --match "code review"
   npx tsx src/agents/sdd-verify.ts --task "verify build"
   ```

## Configuración del Modelo

### Variables de Entorno

```bash
# Modelo por defecto para agentes
export AGENT_MODEL="opencode/deepseek-v4-flash-free"

# Temperatura por defecto
export AGENT_TEMPERATURE="0.3"

# Ejecutar agente
npx tsx src/agents/sdd-apply.ts --task "test"
```

### Configuración por Agente (config/agents.json)

```json
{
  "sdd-apply": {
    "model": "opencode/deepseek-v4-flash-free",
    "temperature": 0.15,
    "maxTokens": 6000,
    "executionCommand": "npx tsx src/agents/sdd-apply.ts"
  }
}
```

## Migración de Skills

### Skills Migrados (.opencode/skills/ → /skills/)

| Skill | Estado |
|-------|--------|
| validate-stack | ✅ Migrated |
| ab-testing | ✅ Migrated |
| api-and-interface-design | ✅ Migrated |
| ci-cd-and-automation | ✅ Migrated |
| code-review-and-quality | ✅ Migrated |
| code-simplification | ✅ Migrated |
| debugging-and-error-recovery | ✅ Migrated |
| documentation-and-adrs | ✅ Migrated |
| doubt-driven-development | ✅ Migrated |
| frontend-ui-engineering | ✅ Migrated |
| git-workflow-and-versioning | ✅ Migrated |
| planning-and-task-breakdown | ✅ Migrated |
| test-driven-development | ✅ Migrated |
| web-research | ✅ Migrated |

**Total:** 14 skills de prioridad migrados (49 restantes en backlog)

### Migrar Skills Manualmente

```bash
# Un skill específico
npx tsx src/skill-migrator.ts --migrate "skill-name"

# Todos los skills
npx tsx src/skill-migrator.ts --migrate-all
```

## Troubleshooting

### "Model not found: inherit-from-session"

**Causa:** OpenCode intenta heredar modelo del orquestador.

**Solución:** Usar delegador nativo:
```bash
npx tsx src/agent-delegator.ts --agent <name> --task "..."
```

### Skill no encontrado

**Verificar ubicación:**
```bash
# Debe estar en /skills/ (no .opencode/skills/)
ls skills/<skill-name>/SKILL.md
```

**Migrar si es necesario:**
```bash
npx tsx src/skill-migrator.ts --migrate "skill-name"
```

### TypeScript/Lint errors

**Verificar:**
```bash
npm run typecheck
npm run lint
```

**Auto-fix:**
```bash
npm run lint -- --fix
```

## Checklist de Verificación

- [ ] `npm run typecheck` - 0 errores
- [ ] `npm run lint` - 0 errores
- [ ] `npx tsx src/skill-loader.ts --list` - Muestra skills
- [ ] `npx tsx src/agent-delegator.ts --list` - Muestra agentes
- [ ] `npx tsx src/agents/sdd-explore.ts --task "test"` - Funciona
- [ ] `npm run watchtower:health` - PASS

## Recursos

- **Skills:** `/skills/`
- **Agentes:** `/src/agents/`
- **Configuración:** `/config/agents.json`
- **Documentación:** `/docs/MIGRATION-AGNOSTIC-STACK.md`

## Soporte

Para reportar issues de portabilidad:
1. Verificar con `npm run health:check`
2. Documentar herramienta AI usada
3. Incluir comandos ejecutados
4. Adjuntar output de error

---

**Estado:** ✅ Stack Agnóstico v2.0 - Operativo
**Última actualización:** 2026-08-08
**Agentes nativos:** 11/11 ✅
**Skills nativos:** 135+ (14 migrados de opencode)
