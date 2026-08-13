# Monitor de Auto-Curación de Servicios

## Descripción

Herramienta nativa de Gentle-Vanguard para monitorear y auto-curar servicios críticos.

## Comandos

```bash
# Ejecutar una vez
npx tsx src/tools/auto-heal-monitor.ts
<!-- REF-OBSOLETA: src/tools/auto-heal-monitor.ts no existe (ruta migrada o eliminada) -->

# Modo daemon (monitoreo continuo)
npx tsx src/tools/auto-heal-monitor.ts --daemon
<!-- REF-OBSOLETA: src/tools/auto-heal-monitor.ts no existe (ruta migrada o eliminada) -->

# Ver estado
npx tsx src/tools/auto-heal-monitor.ts --status
<!-- REF-OBSOLETA: src/tools/auto-heal-monitor.ts no existe (ruta migrada o eliminada) -->
```

## Servicios Monitoreados

- Dashboard WebSocket (port 8080)
- Dashboard Dev (port 5173)
- MCP Server (build verification)

## Capacidades

- ✅ Detección automática de servicios caídos
- ✅ Reinicio automático con cooldown
- ✅ Límite de reinicios (max 5)
- ✅ Persistencia de estado
- ✅ Logging completo

## Archivos

- Estado: `.runtime/auto-heal-state.json`
- Logs: `.runtime/auto-heal.log`
