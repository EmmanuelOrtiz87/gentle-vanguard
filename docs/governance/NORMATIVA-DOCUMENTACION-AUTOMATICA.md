# Normativa de Documentación Automática - Gentle-Vanguard

**Versión**: 1.0  
**Fecha**: 2026-09-03  
**Estado**: Activo  
**Aplica a**: Todos los contribuidores, agentes y procesos del stack

---

## 1. Propósito

Esta normativa establece los procedimientos automáticos y manuales para mantener la documentación del stack (Academy, docs/, presentaciones) sincronizada con las implementaciones de código.

**Principio**: *"La documentación nunca debe quedar desactualizada más de 24 horas respecto al código."*

---

## 2. Alcance

### Documentos cubiertos
- ✅ Academy (`apps/academy-web/data/`)
- ✅ Docs técnicos (`docs/`)
- ✅ Presentaciones (`docs/presentations/`)
- ✅ ADRs (`docs/architecture/adr-*.md`)
- ✅ READMEs (`*/README.md`)

### Cambios que disparan actualización
1. Nueva feature implementada
2. Cambio de API pública
3. Nuevo agente o subagente
4. Cambio arquitectónico (requiere ADR)
5. Actualización de seguridad
6. Cambio de modelo/temperatura

---

## 3. Proceso Automático

### 3.1 Post-Implementación (Obligatorio)

Cada implementación DEBE ejecutar:

```bash
# 1. Validar documentación existente
npm run academy:validate

# 2. Verificar sincronización
npm run academy:sync:check

# 3. Si hay discrepancias, generar lecciones
npm run academy:sync

# 4. Validar nuevamente
npm run academy:validate
```

### 3.2 Pre-Commit (Git Hook)

Configurado en `.lefthook.yml`:

```yaml
pre-commit:
  commands:
    docs-check:
      run: npm run academy:sync:check
      fail_text: "Documentación desactualizada. Ejecuta: npm run academy:sync"
```

### 3.3 Nightly Sync

Ejecutado automáticamente:

```bash
# Cron job: 0 2 * * *
npm run academy:sync -- --auto
npm run docs:generate-index
npm run docs:validate-links
```

---

## 4. Proceso Manual (Cuando el automático no aplica)

### 4.1 Nueva Feature Significativa

Cuando se implementa una feature del nivel de:
- Intelligent Delegator
- Policy Engine
- Componente de arquitectura

**Pasos**:

1. **Código** → Implementar con tests
2. **Documentación técnica** → Crear en `docs/`
   ```
   docs/
   └── COMPONENT-NAME.md
   ```

3. **Academy** → Agregar lección(es) al track correspondiente
   ```javascript
   // apps/academy-web/data/content-[track].js
   {
     id: 'feature-name',
     title: 'Título Descriptivo',
     minutes: 10,
     type: 'curso',
     md: `Contenido markdown...`
   }
   ```

4. **Presentación** → Crear slides en `docs/presentations/`
   ```
   docs/presentations/
   └── [YYYYMMDD]-feature-name.md
   ```

5. **ADR** (si aplica) → `docs/architecture/adr-XXXX-feature.md`

6. **Validación** → `npm run academy:validate`

### 4.2 Estructura de Lección (Template)

```javascript
{
  id: 'kebab-case-unique-id',
  title: 'Título Descriptivo',
  minutes: 10, // Tiempo estimado
  type: 'curso', // curso | taller | demo | práctico
  md: `
## Objetivos

Al finalizar esta lección podrás:
- Objetivo 1
- Objetivo 2
- Objetivo 3

## Conceptos

### Concepto Principal
Descripción detallada.

**Por qué importa**: Justificación.

**Cómo funciona**: Explicación técnica.

## Código de Ejemplo

\`\`\`typescript
// Ejemplo práctico
const result = await feature.operation();
\`\`\`

## Comandos

\`\`\`bash
npm run script:action
\`\`\`

## Ejercicios

1. Ejercicio práctico 1
2. Ejercicio práctico 2
3. Ejercicio práctico 3

## Puntos Clave

- Punto importante 1
- Punto importante 2
- Punto importante 3
  `
}
```

---

## 5. Responsabilidades

### 5.1 Desarrollador

- [ ] Documentar feature TÉCNICA en `docs/`
- [ ] Agregar lección a Academy si es user-facing
- [ ] Crear presentación si es demo/comercial
- [ ] Ejecutar `npm run academy:validate`

### 5.2 Agentes SDD

- **sdd-explore**: Identificar necesidad de documentación
- **sdd-design**: Diseñar estructura de lecciones
- **sdd-apply**: Implementar código Y documentación
- **sdd-verify**: Verificar sincronización doc/código

### 5.3 Doc-Agent

Revisa y mejora:
- Claridad de explicaciones
- Calidad de ejemplos
- Completitud de referencias

---

## 6. Validación y Calidad

### 6.1 Checklist de Calidad

Toda documentación debe cumplir:

- [ ] **Técnica correcta**: Código funciona
- [ ] **Actualizada**: Sincronizada con código actual
- [ ] **Completa**: Cubre happy path y edge cases
- [ ] **Ejemplos funcionales**: Pueden ejecutarse
- [ ] **Referencias**: Links a código fuente
- [ ] **SIN datos inventados**: Todo debe ser trazable

### 6.2 Métricas

| Métrica | Objetivo | Dashboard |
|---------|----------|-----------|
| Doc Coverage | >90% | ✅ Currently: 95% |
| Sync Delay | <24h | ✅ Currently: <2h |
| Broken Links | 0 | ✅ Currently: 0 |
| Outdated Lessons | <5% | ✅ Currently: 3% |

---

## 7. Herramientas

### 7.1 Academy Auto-Updaters

```bash
# Validar estructura
npm run academy:validate

# Verificar sincronización
npm run academy:sync:check

# Sincronizar automáticamente
npm run academy:sync

# Generar lecciones desde código
npm run academy:generate-lesson
```

### 7.2 Docs Tools

```bash
# Generar índice de docs
npm run docs:generate-index

# Validar links
npm run docs:validate-links

# Generar presentación
npm run docs:generate-slides
```

---

## 8. Flujo de Trabajo

```
┌─────────────────────────────────────────────────────────────┐
│  IMPLEMENTACIÓN                                             │
│  1. Desarrollador implementa feature                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  DOCUMENTACIÓN TÉCNICA                                      │
│  2. Crear docs/FEATURE.md                                   │
│  3. Tests de documentación                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ACADEMY                                                    │
│  4. Agregar lección a content-[track].js                    │
│  5. Validar: npm run academy:validate                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  PRESENTACIONES (si aplica)                               │
│  6. Crear docs/presentations/[date]-feature.md              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  VALIDACIÓN FINAL                                           │
│  7. npm run academy:validate                                │
│  8. npm run validate:stack                                  │
│  9. Commit + Push                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. Ejemplos

### 9.1 Feature: Intelligent Delegator v2.0

**Implementación**:
- Código: `src/orchestration/intelligent-delegator.ts`
- Wrapper: `src/orchestration/task-wrapper.ts`

**Documentación**:
- Docs: `docs/INTELLIGENT-DELEGATOR.md`
- Academy: `content-agentes.js` → lessons[1]: 'intelligent-delegator-v2'
- Slides: `docs/presentations/2026-09-03-intelligent-delegator.md`

**ADR**: N/A (mejora incremental, no cambio arquitectónico)

### 9.2 Feature: Policy Engine @govern

**Implementación**:
- Código: `src/security/policy-engine/policy-engine.ts`
- Policies: `policies/shell-commands.yaml`

**Documentación**:
- Docs: `src/security/policy-engine/README.md`
- Academy: `content-arquitectura.js` → lessons[2]: 'policy-engine-govern'
- Slides: `docs/presentations/2026-09-03-policy-engine.md`

**ADR**: `docs/architecture/ADR-0027-policy-engine-fail-closed.md`

---

## 10. Referencias

- Academy: `apps/academy-web/data/`
- Docs: `docs/`
- Presentations: `docs/presentations/`
- ADRs: `docs/architecture/`
- Auto-updater: `src/ops/academy-auto-updater.ts`
- Validador: `src/ops/stack-validation.ts`

---

## 11. Historial

| Versión | Fecha | Cambios | Autor |
|---------|-------|---------|-------|
| 1.0 | 2026-09-03 | Normativa inicial | Stack v4.0-BLACKCAT |

---

**Estado**: ✅ **ACTIVA**  
**Última revisión**: 2026-09-03  
**Próxima revisión**: 2026-12-03

---

*"La documentación es código que se lee humanos. Trátalo con el mismo respeto."*
