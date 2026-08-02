# RDD — Receipt-Driven Development (Normativa)

## Identidad

**Nombre**: RDD (Receipt-Driven Development)  
**Tipo**: Sistema de autorización de code review con prueba criptográfica  
**Versión**: 1.0.0  
**Origen**: Implementación nativa Gentle-Vanguard (no depende de gentle-ai CLI)  

---

## Propósito

Garantizar que todo cambio de código:
1. **Se clasifique** por riesgo basado en evidencia (no tamaño)
2. **Se revise** con el nivel apropiado (0/1/4 lenses)
3. **Obtenga** un receipt ligado al contenido (SHA-256 + Git SHA)
4. **Valide** en 5 gates antes de entrega

---

## Principios

### 1. Risk-Based (no Size-Based)
- El riesgo se determina por la **naturaleza** del cambio
- Número de archivos/líneas NO importa
- Factores: seguridad, auth, DB, breaking changes

### 2. Content-Bound Receipts
- El receipt está ligado al hash del contenido
- No se puede reutilizar para código diferente
- Previene scope drift e identity drift

### 3. Immutable Review
- Una vez emitido, el receipt no cambia
- Los gates validan el mismo receipt
- Audit trail permanente

### 4. Safety First
- Kill switch para emergencias
- Break-glass con razón auditada
- Siempre puede deshabilitarse en caso crítico

---

## Tiers de Riesgo

| Tier | Score | Review | Lenses | Auto-approve |
|------|-------|--------|--------|-------------|
| Low | 0-39 | Estructural | 0 | Sí |
| Standard | 40-69 | Enfocado | 1 | No |
| High | 70-100 | 4R Completo | 4 | No |

---

## Categorías de Riesgo

| Categoría | Score Base | Ejemplos |
|-----------|-----------|----------|
| auth | 90 | Login, JWT, OAuth, permisos |
| security | 85 | Encriptación, hashing, XSS |
| core-logic | 70 | Business logic, workflows |
| external-api | 60 | Integraciones, webhooks |
| database | 55 | Migrations, schema, queries |
| config | 40 | Settings, secrets, env |
| ui | 30 | Components, CSS, templates |
| test | 20 | Tests, specs |
| docs | 10 | README, guías |
| build | 25 | CI/CD, webpack, scripts |

---

## 4R Review Lenses

### RISK (Seguridad)
- Input validation
- Sin injection vulnerabilidades
- Sin secretos hardcodeados
- Auth/authz checks
- Encriptación correcta

### READABILITY (Claridad)
- Nombres descriptivos
- Comentarios explicativos
- Sin magic numbers
- Estilo consistente
- Código muerto eliminado

### RELIABILITY (Correctitud)
- Tests cubren paths
- Tipos TypeScript correctos
- Sin race conditions
- Manejo de null/undefined
- Build pasa (typecheck, lint)

### RESILIENCE (Recuperación)
- Errores manejados
- Degradación graceful
- Timeouts en llamadas externas
- Circuit breakers
- Plan de rollback

---

## 5 Delivery Gates

| Gate | Cuándo | Qué valida |
|------|--------|-----------|
| post-apply | Después de implementar | Receipt existe |
| pre-commit | Antes de commit | SHA match |
| pre-push | Antes de push | SHA en history |
| pre-pr | Antes de PR | Tree hash match |
| release | Antes de release | Exact match + approved |

---

## Comandos

```bash
# Workflow completo
npm run rdd:start      # Iniciar
npm run rdd:risk       # Clasificar
npm run rdd:4r         # Revisar
npm run rdd:receipt    # Emitir
npm run rdd:gate <g>   # Validar
npm run rdd:status     # Estado

# Kill switch
npm run rdd:disable -- --reason="..."
npm run rdd:enable
npm run rdd:kill-status

# Git hooks
npm run rdd:install-hooks
```

---

## Archivos

| Archivo | Propósito |
|---------|-----------|
| `src/rdd/rdd-core.ts` | Coordinador principal |
| `src/rdd/risk-classifier.ts` | Clasificación de riesgo |
| `src/rdd/rdd-4r-review.ts` | Sistema 4R |
| `src/rdd/rdd-gates.ts` | 5 gates |
| `src/rdd/rdd-kill-switch.ts` | Kill switch |
| `.session/receipts/*.json` | Receipts |
| `.session/rdd/*.json` | Workflows |
| `.session/rdd/DISABLED` | Flag de kill switch |

---

## Kill Switch

### Deshabilitar (emergencia)
```bash
npm run rdd:disable -- --reason="Emergency hotfix"
```

Crea `.session/rdd/DISABLED` con:
- Timestamp
- Razón
- Usuario

### Habilitar
```bash
npm run rdd:enable
```

### Limitaciones de seguridad
- Log permanente en `disable-log.jsonl`
- Alerta si >24h deshabilitado
- Requiere razón explícita

---

## Break-Glass Bypass

En caso CRÍTICO, bypass con commit message:
```bash
git commit -m "RDD-BYPASS: Emergency fix for production"
```

Requisitos:
- Razón en mensaje
- Log automático
- Review fácil de 2do reviewer

---

## Integración con SDD

```
SDD Explore → SDD Design → [Freeze Candidate] → RDD Classify → RDD Review → RDD Receipt → RDD Gates → APPROVED
```

SDD = Planificación (qué construir)
RDD = Autorización (cuándo entregar)

---

## Diagrama de Flujo

```
Autor inicia cambio
        ↓
Freeze Candidate (Git SHA)
        ↓
Classificar Riesgo
 ├─ Low (0) → Auto-approve
 ├─ Standard (1) → 1 reviewer
 └─ High (4) → 4R review
        ↓
Emitir Receipt (content-bound)
        ↓
Validar Gates
 ├─ post-apply
 ├─ pre-commit ← Git hook
 ├─ pre-push ← Git hook
 ├─ pre-pr
 └─ release
        ↓
   APPROVED ✅
```

---

## Referencias

- `.opencode/skills/review-driven-development/SKILL.md`
- `rules/REVIEW-AUTHORITY-THREAT-MODEL.md`
- `docs/reference/GENTLE-AI-ALIGNMENT-PROPOSAL.md`

---

## Decisiones de Diseño

### ¿Por qué no usar gentle-ai CLI?
- **Independencia**: No depender de servicios externos
- **Control**: Stack propio, evolución propia
- **Natividad**: Mejor integración con dashboard, Nexus, etc.
- **Licencias**: Sin dependencias de terceros

### ¿Por qué 5 gates?
- **post-apply**: Catch temprano
- **pre-commit**: Antes de frozen
- **pre-push**: Antes de compartir
- **pre-pr**: Antes de review formal
- **release**: Antes de producción

### ¿Por qué evidencia sobre tamaño?
- 1 línea en auth puede ser crítica
- 1000 líneas en docs son seguras
- Número de archivos no indica riesgo

---

## Guardias

1. **Nunca** deshabilitar RDD sin razón documentada
2. **Siempre** usar break-glass con mensaje explícito
3. **Auditar** logs de disable/enable
4. **Capacitar** equipo en uso correcto

---

## Historial

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0.0 | 2026-01-08 | Implementación nativa inicial |

---

## Mantenedor

Gentle-Vanguard Architecture Team  
Email: architecture@gentle-vanguard.local
