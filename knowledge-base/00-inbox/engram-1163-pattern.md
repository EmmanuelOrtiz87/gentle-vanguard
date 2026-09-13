---
created: 2026-05-26 16:23:40
tags: [engram, pattern]
engram_id: 1163
type: pattern
---

# JSON Validator - Validación estricta agnóstica

**What**: Implementado validador JSON estricto y agnóstico para prevenir errores de sintaxis en llamadas a herramientas

**Why**: El error original `Invalid input for tool engram_mem_context: JSON parsing failed` ocurría porque el agente enviaba JSON malformado. PowerShell's `ConvertFrom-Json` es demasiado permisivo y acepta JSON inválido.

**Where**:
- `scripts/utilities/json-validator.ps1` - Validador principal
- `scripts/utilities/pre-process-input.ps1` - Integración con pipeline
- `scripts/utilities/tests/json-validator.tests.ps1` - Tests (10 casos, 100% pass)
- `docs/AGENTS.md` - Documentación

**Learned**:
- Validación manual de balance de braces/brackets/quotes es necesaria para ser estricto
- Orden de reparaciones: quotes → brackets → braces → trailing commas
- Tests deben validar tanto el resultado como el número de fixes reportados
- El validador funciona en Windows/Linux/macOS sin dependencias externas

---
*Imported from Engram on 2026-09-06*
