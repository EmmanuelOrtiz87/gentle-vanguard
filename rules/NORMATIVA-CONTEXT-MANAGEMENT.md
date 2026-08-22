# NORMATIVA: Context Management y Token Optimization

> **Status**: Active (aprobada tras investigación 2026-08-13) **Scope**: Todas las sesiones con
> consumo de tokens >10K promedio **Referencia**: docs/reference/OPENCODE-CONTEXT-CONFIG.md

---

## 1. Principio Fundamental

**Siempre verificar configuración nativa antes de considerar fork.**

La experiencia con el problema de millones de tokens demostró que:

- Las herramientas modernas tienen optimización nativa
- Está desactivada por defecto (trade-off: conservar historial vs eficiencia)
- El 80% de problemas se resuelven con `compaction.prune: true`
- Forks requieren 1-2 semanas de trabajo + mantenimiento continuo

---

## 2. Checklist de Investigación (Obligatorio)

Antes de proponer fork o cambio arquitectural:

### Fase 1: Análisis de Datos (15 min)

- [ ] Query Nexus: top sesiones por token consumption
- [ ] Calcular ratio input/output (target: 5:1)
- [ ] Identificar patrón: ¿tool outputs? ¿acumulación? ¿cada tool call?

### Fase 2: Documentación Oficial (30 min)

- [ ] Buscar en docs oficiales: "compaction", "context", "window"
- [ ] Buscar configuración disponible
- [ ] Verificar experimental features
- [ ] Check `.well-known/opencode` endpoints

### Fase 3: Ecosistema (45 min)

- [ ] Buscar forks con feature similar
- [ ] Check plugins existentes
- [ ] Revisar issues de GitHub upstream
- [ ] Buscar community solutions

### Fase 4: Configuración (15 min)

- [ ] Implementar native config solution
- [ ] A/B test vs baseline
- [ ] Documentar expected behavior

**Si después de Fase 4 el problema persiste**: Entonces considerar fork.

---

## 3. Configuración Estándar (Mandatorio para todos los proyectos)

Para **cualquier** proyecto usando OpenCode V2:

### Archivos Requeridos

**opencode.json**:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "compaction": {
    "auto": true,
    "prune": true,
    "keep": { "tokens": 15000 },
    "buffer": 20000
  }
}
```

**tui.json** (opcional pero recomendado):

```json
{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "auto"
}
```

### Justificación

Sin `prune: true`:

- Tool outputs acumulan linealmente (40K+ cada tool)
- 10 tool calls = 400K tokens en contexto
- Esto causa overflow incluso con context windows grandes

Con `prune: true`:

- Old tool outputs eliminados (>40K tokens liberados)
- Contexto summarizado automáticamente
- 60-80% reducción en token consumption

---

## 4. Patrones de Session Management

### Pattern A: Sesión Corta (< 20 turns)

- Standard config suficiente
- No requiere intervención manual

### Pattern B: Sesión Media (20-50 turns)

- Monitorear indicador de compaction
- Usar `/compact` manual si necesario
- Considerar checkpoint

### Pattern C: Sesión Larga (> 50 turns)

- Usar `/compact` cada ~20 turns
- Crear checkpoint antes de operaciones críticas
- Considerar split en múltiples sesiones

---

## 5. Triggers de Acción

| Condición                 | Acción                                      |
| ------------------------- | ------------------------------------------- |
| Tokens/turno > 20K        | Investigar + aplicar config                 |
| Overflow error            | Reiniciar con `prune: true`                 |
| Contexto > 80% en sidebar | Run `/compact` manual                       |
| Sesión > 100 turns        | Create checkpoint + considerar nueva sesión |

---

## 6. Documentación Obligatoria

Para **cada** sesión de investigación de tokens:

1. **Session summary** en engram con:
   - Root cause identificado
   - Solución aplicada
   - Métricas antes/después
   - Archivos creados/modificados

2. **Archivos de referencia** en `docs/reference/`:
   - Configuración aplicada
   - Guía de investigación
   - Checklist de validación

3. **Observaciones** en memoria:
   - Policy (si aplica nueva normativa)
   - Pattern (si descubierto reusable)
   - Decision (si cambio arquitectural)

---

## 7. Prohibiciones

❌ **NO** ignorar la compaction nativa y crear solución custom ❌ **NO** fork de herramienta sin
agotar native config first ❌ **NO** dejar sesiones sin context management documentado ❌ **NO**
usar defaults sin verificar impacto en sesiones largas

---

## 8. Referencias

- **Config**: opencode.json (este repo)
- **Docs**: docs/reference/OPENCODE-CONTEXT-CONFIG.md
- **Checklist**: docs/reference/POST-RESTART-CHECKLIST.md
- **Investigation**: docs/reference/CONTEXT-MANAGEMENT-STRATEGY.md
- **User Guide**: docs/reference/CONTEXT-OPTIMIZATION-GUIDE.md
- **Official**: https://opencode.ai/v2/docs/compaction

---

**Aprobada por**: Investigación sistema 2026-08-13 **Revisión**: Review engram memo #2798
