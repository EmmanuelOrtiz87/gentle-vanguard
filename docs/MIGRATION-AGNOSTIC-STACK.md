# Plan de Migración - Stack Agnóstico

## Problema Identificado

La función `task()` de OpenCode **NO soporta herencia de modelo**. Todos los subagentes fallan con:
```
Model not found: inherit-from-session/.
```

Esto afecta a **TODOS** los subagentes, no solo los SDD:
- sdd-explore, sdd-design, sdd-apply, sdd-verify ❌
- doc-agent, ops-agent, gov-agent ❌
- self-diag-agent, session-agent, premortem-agent ❌
- Todos los demás ❌

## Solución: Sistema Nativo Agnóstico

### Fase 1: Crear Sistema de Skills Nativo

**Objetivo**: Migrar todo de `.opencode/skills/` a `/skills/` con estructura nativa

1. **Identificar skills faltantes**: 64 skills en `.opencode/skills/`, 141 en `/skills/`
2. **Migrar los únicos** de opencode a estructura nativa
3. **Crear `src/skill-loader.ts`** - loader nativo que funcione sin opencode

### Fase 2: Crear Sistema de Delegación Nativo

**Objetivo**: Reemplazar `task()` con sistema propio

1. **Crear `config/agents.json`** - definiciones de agentes portables
2. **Crear `src/agent-delegator.ts`** - orquestador de agentes nativo
3. **Crear `src/agents/*.ts`** - implementaciones de cada agente:
   - sdd-explore.ts
   - sdd-design.ts
   - sdd-apply.ts
   - sdd-verify.ts
   - doc-agent.ts
   - ops-agent.ts
   - etc.

### Fase 3: Homologar Configuraciones

**Archivos a migrar de opencode a nativo**:

| Archivo Actual | Destino Nativo | Estado |
|----------------|----------------|--------|
| .opencode/opencode.json | config/agents.json | 🔲 Pendiente |
| .opencode/agents/*.md | src/agents/*.ts | 🔲 Pendiente |
| config/chatmodes/ | config/chatmodes.json | 🔲 Pendiente |
| MCP servers en opencode.json | config/mcp.json | 🔲 Pendiente |

### Fase 4: Documentación y Normativas

1. **Crear `AGNOSTIC-STACK.md`** - guía de portabilidad
2. **Actualizar `AGENTS.md`** - instrucciones sin opencode
3. **Crear `MIGRATION-GUIDE.md`** - pasos para migrar a otras herramientas

## Análisis de Skills

### Skills en `.opencode/skills/` (64 total)

Skills exclusivos de opencode que deben migrarse:
- ab-testing, api-and-interface-design
- browser-testing-with-devtools
- ci-cd-and-automation
- code-review-and-quality
- code-simplification
- debugging-and-error-recovery
- documentation-and-adrs
- doubt-driven-development
- frontend-ui-engineering
- gentle-ai-monitor
- hr-talent-acquisition
- idea-refine
- incremental-implementation
- interview-me
- issue-creation
- knowledge-base
- legal-compliance-officer
- marketing-content-writer
- observability-and-instrumentation
- office-hours
- performance-optimization
- planning-and-task-breakdown
- product-marketing
- qa-lead
- retro
- sales-account-executive
- validate-stack
- web-research
- work-unit-commits
- validation: sistemático de todo el stack
- (y otros 30+)

### Estructura de Skill Nativo

```yaml
---
name: skill-name
aliases: ["alias1", "alias2"]
description: Description for any AI tool
triggers:
  - keyword1
  - keyword2
context: When to activate this skill
tools:
  - bash
  - read
  - edit
---

## /skill-name

### Usage
...

### Instructions
...
```

## Implementación Propuesta

### 1. src/skill-loader.ts
```typescript
export class SkillLoader {
  loadSkills(): Skill[] { /* scan /skills/ */ }
  matchSkill(input: string): Skill | null { /* match triggers */ }
  getSkillContent(name: string): string { /* return markdown */ }
}
```

### 2. src/agent-delegator.ts
```typescript
export class AgentDelegator {
  async delegate(agent: string, task: string): Promise<Result> {
    // Call via npx tsx src/agents/${agent}.ts
    // NOT via opencode task()
  }
}
```

### 3. src/agents/sdd-apply.ts
```typescript
// Standalone agent implementation
// Reads task from CLI args
// Returns JSON result
// Independent of opencode
```

## Checklist de Implementación

- [ ] Crear src/skill-loader.ts
- [ ] Crear src/agent-delegator.ts
- [ ] Migrar skills de .opencode/skills/ a /skills/
- [ ] Crear src/agents/sdd-explore.ts
- [ ] Crear src/agents/sdd-design.ts
- [ ] Crear src/agents/sdd-apply.ts
- [ ] Crear src/agents/sdd-verify.ts
- [ ] Migrar otros agentes (doc, ops, gov, etc.)
- [ ] Crear config/agents.json
- [ ] Actualizar AGENTS.md
- [ ] Crear AGNOSTIC-STACK.md
- [ ] Probar en simulador de Claude/Cursor
- [ ] Verificar health completo
- [ ] Documentar migración

## Comandos de Verificación

```bash
# Health check
npm run health:check

# TypeScript
npm run typecheck
npm run lint

# Verificar skills nativos
npx tsx src/skill-loader.ts --list

# Probar delegación
npx tsx src/agent-delegator.ts --agent sdd-apply --task "test"
```

## Conclusión

El framework OpenCode tiene limitaciones fundamentales que hacen imposible la herencia de modelo y la delegación real. Es necesario migrar a un sistema nativo completamente agnóstico que funcione en cualquier herramienta AI.

El stack actual está **operativo** (88/90 health checks pasan), pero la **delegación está rota** por limitaciones del framework.

---
**Estado**: Plan de migración creado, pendiente implementación
**Próximo paso**: Aprobación y asignación de tareas
