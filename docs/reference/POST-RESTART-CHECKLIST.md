# Checklist de Validación Post-Restart

> **Uso**: Ejecutar estas validaciones después de reiniciar OpenCode con la nueva configuración

---

## ✅ Pre-Restart Checklist

- [ ] Backup de config actual (opencode.json existe)
- [ ] Nueva config (opencode.json + tui.json) en lugar
- [ ] Documentación completa
- [ ] Session summary guardado en memoria

---

## ✅ Post-Restart Checklist

### 1. Configuración Cargada

```bash
# Verificar config activa
opencode debug config | grep -A 5 "compaction"
```

**Esperado:**
```json
"compaction": {
  "auto": true,
  "prune": true,
  "keep": { "tokens": 15000 },
  "buffer": 20000
}
```

- [ ] `prune: true` está presente
- [ ] `auto: true` está presente
- [ ] Buffer es 20000

### 2. Identificador de Compaction Visible

**En TUI:**
- [ ] Buscar indicador `/compact` en la interfaz
- [ ] Verificar % de contexto en sidebar

### 3. Primer Tool Call (Prueba)

**Pide a OpenCode:**
```
"Crea un archivo de prueba temporal"
```

**Verifica:**
- [ ] Tool ejecuta correctamente
- [ ] No hay error de contexto

### 4. Multi-Tool Session (Simulación)

**Pide:**
```
"Lee package.json, luego crea un archivo nuevo, luego verifica con ls"
```

**Verifica:**
- [ ] Múltiples tools ejecutan sin overflow
- [ ] Sesión continúa operativa después de 5+ tools

### 5. Validación de Pruning Automático

**Pide una tarea larga:**
```
"Busca en todo el codebase referencias a 'FIXME' y reporta los resultados"
```

**Verifica:**
- [ ] Después de ~10 tool calls, el % de contexto no sube indefinidamente
- [ ] El pruning se activa (indicador visual)
- [ ] Tool outputs antiguos son removidos

---

## ✅ Métricas de Éxito

### Antes vs Después (Benchmark)

| Métrica | Antes (default) | Después (prune: true) | Validación |
|---------|----------------|----------------------|------------|
| Tokens por tool output | ~40K | ~5-10K | Verificar en logs |
| Contexto después de 10 tools | ~400K | ~100-150K | ver en TUI % |
| Overflow errors | Frecuentes | Raros | Obs. comportamiento |
| Duración de sesión | ~20 turns | ~50+ turns | Contar mensajes |

### Token Session Banner

Al iniciar sesión, verificar:

```
╔══════════════════════════════════════════╗
║  Context Management: prune=enabled         ║
║  Buffer: 20000 tokens                      ║
║  Keep: 15000 tokens recent                 ║
╚══════════════════════════════════════════╝
```

- [ ] Mensaje visible en inicio
- [ ] Config correctamente reportada

---

## ⚠️ Si Algo Falla

### Problem: `prune: false` aún

**Diagnóstico:**
```bash
# Verificar config está cargada
opencode debug config | grep prune
```

**Solución:**
1. Detener OpenCode completamente
2. Verificar opencode.json está en directorio correcto
3. Verificar formato JSON válido
4. Reiniciar OpenCode

### Problem: Compaction no visible

**Diagnóstico:**
- Verificar modelo tiene suficiente contexto (>200K tokens)
- Buffer de 20K necesita modelo con al menos 100K context

**Solución:**
Si usando modelo pequeño (32K context):
```json
{
  "compaction": {
    "buffer": 8000,
    "keep": { "tokens": 10000 }
  }
}
```

---

## 📊 Referencias

- docs/reference/OPENCODE-CONTEXT-CONFIG.md
- opencode.json (configuración activa)
- https://opencode.ai/v2/docs/compaction

---

## 🎯 Valoración Exitosa

**Sesión considerada exitosa si:**
- ✅ Config `prune: true` está cargada
- ✅ Contexto no crece indefinidamente con tool calls
- ✅ Puedes ejecutar >20 turns sin overflow
- ✅ Token consumption por turno <15K promedio

**Si NO cumple:**
→ Revisar: https://opencode.ai/v2/docs/compaction
→ Contactar: soporte opencode con logs
