## **Lógica de Prioridad de Modelos (Documentada)**

### Orden de Resolución (de mayor a menor prioridad):

1. **🥇 Asignación MANUAL** (en .opencode/agents/*.md front-matter)
   - Si el agente tiene `model: xxx` explícito → USAR
   - Solo se ignora si el modelo está en estado "unavailable"
   
2. **🥈 Herencia del ORCHESTRATOR** (config/model-health-registry.json)
   - Si no hay manual → heredar del orchestrator activo
   - Controlado por `inheritFromOrchestrator: true`
   
3. **🥉 Fallback AUTOMÁTICO** (smart-model-router.ts)
   - Si hay error → buscar siguiente modelo en fallbackChain
   - Registrar cambio y notificar

### Flujo de Decisión:
```
Inicio
  ↓
¿Tiene modelo MANUAL? → SÍ → ¿Está disponible? → SÍ → Usar manual
  ↓ NO                            ↓ NO
¿inheritFromOrchestrator? → SÍ → Usar modelo orchestrator
  ↓ NO
Usar default de registry
  ↓
¿Error? → SÍ → Buscar fallback → Usar fallback
```

### Compatibilidad Manual vs Automática:
- Config MANUAL en .opencode/agents/*.md → ✅ Respetada
- Config Herencia en registry → ✅ Si no hay manual
- Fallback automático → ✅ Solo en errores

**Nota:** El sistema intenta primero manual, luego herencia, y solo en error aplica fallback.

---

