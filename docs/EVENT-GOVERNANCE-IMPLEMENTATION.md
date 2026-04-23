# Event Governance Implementation Guide

## Overview

Sistema completo de Governance para el Event Bus mejorado con validación de esquemas, políticas de seguridad, auditoría completa y rate limiting.

## Architecture

```
Event Bus Enhanced
├── Event Registry (config/event-registry.json)
│   ├── Event definitions
│   ├── Schemas
│   ├── Permissions
│   └── Policies
├── Governance Layer (event-governance-layer.ps1)
│   ├── Schema validation
│   ├── Permission checking
│   ├── Rate limiting
│   └── Audit logging
├── Enhanced Bus (event-bus-enhanced.ps1)
│   ├── Subscribe/Emit/Unsubscribe
│   ├── Governance integration
│   └── History tracking
└── Orchestrator Integration (orchestrator-governance-integration.ps1)
    ├── Passive monitoring
    ├── Health checks
    └── Reporting
```

## Components

### 1. Event Registry (`config/event-registry.json`)

Define todos los eventos permitidos, esquemas, permisos y políticas.

**Características:**
- Definición de eventos estándar
- Esquemas JSON para validación
- Permisos por actor (qué puede emitir/escuchar)
- Políticas de rate limiting
- Niveles de severidad

**Eventos incluidos:**
- `dispatch.started` - Inicio de dispatch paralelo
- `dispatch.completed` - Finalización de dispatch
- `agent.dispatched` - Despacho de agente
- `agent.completed` - Finalización de agente
- `session.started` - Inicio de sesión
- `session.ended` - Finalización de sesión
- `security.violation` - Violación de seguridad
- `audit.event` - Evento de auditoría

### 2. Governance Configuration (`config/event-governance-config.json`)

Configuración de políticas de seguridad, rate limiting y auditoría.

**Secciones:**
- **Security**: Políticas de autorización
- **Rate Limiting**: Límites por evento
- **Audit**: Configuración de auditoría
- **Alerts**: Configuración de alertas
- **Monitoring**: Métricas y monitoreo

### 3. Governance Layer (`event-governance-layer.ps1`)

Capa de validación y enforcement de políticas.

**Acciones:**
- `validate` - Valida evento contra políticas
- `enforce` - Aplica políticas y bloquea si es necesario
- `audit` - Genera reporte de auditoría
- `check-policy` - Verifica política de evento
- `report` - Reporte completo de governance

**Validaciones:**
- Validación de esquemas JSON
- Verificación de permisos
- Rate limiting
- Auditoría completa

### 4. Enhanced Event Bus (`event-bus-enhanced.ps1`)

Event Bus mejorado con integración de governance.

**Acciones:**
- `list` - Lista eventos y suscripciones
- `subscribe` - Suscribe handler a evento
- `emit` - Emite evento (con validación)
- `handlers` - Lista handlers activos
- `history` - Historial de eventos
- `governance-status` - Estado de governance

### 5. Orchestrator Integration (`orchestrator-governance-integration.ps1`)

Integración del Orchestrator con governance.

**Acciones:**
- `initialize` - Inicializa integración
- `check-health` - Verifica salud de governance
- `monitor` - Monitorea eventos recientes
- `report` - Genera reporte para Orchestrator

## Usage Examples

### Emitir evento con validación

```powershell
.\event-bus-enhanced.ps1 -Action emit `
  -Event "dispatch.started" `
  -Payload '{"execution_id":"dispatch-20260423","mode":"parallel","agents":["DEV","QA"]}' `
  -Actor "orchestrator"
```

### Verificar política de evento

```powershell
.\event-governance-layer.ps1 -Action check-policy -EventName "dispatch.started"
```

### Obtener reporte de governance

```powershell
.\orchestrator-governance-integration.ps1 -Action report
```

### Monitorear eventos

```powershell
.\orchestrator-governance-integration.ps1 -Action monitor
```

## Automation

El sistema está completamente automatizado:

1. **Inicialización automática** - Se ejecuta en session-autostart.cmd
2. **Validación automática** - Cada emit valida contra governance
3. **Auditoría automática** - Todos los eventos se registran
4. **Rate limiting automático** - Se aplica sin intervención
5. **Monitoreo pasivo** - Orchestrator supervisa sin interferir

## Security Policies

### Permission Model

Cada actor tiene permisos específicos:

```json
{
  "orchestrator": {
    "can_emit": ["dispatch.started", "dispatch.completed", ...],
    "can_listen": ["session.started", "session.ended", ...],
    "trust_level": "high"
  }
}
```

### Rate Limiting

Por evento:
- `dispatch.started`: 10/min, 100/hora
- `agent.dispatched`: 50/min, 500/hora
- `session.started`: 5/min, 50/hora

### Schema Validation

Cada evento tiene esquema JSON requerido:
- Campos obligatorios
- Tipos de datos
- Patrones regex
- Enumeraciones

## Audit Trail

Auditoría completa en `.event-bus/governance/audit/`:

```json
{
  "timestamp": "2026-04-23T14:30:00-03:00",
  "action": "validation",
  "actor": "orchestrator",
  "resource": "dispatch.started",
  "result": "success",
  "details": {...}
}
```

## Monitoring & Alerts

### Metrics Collected

- Conteo de eventos
- Latencia de eventos
- Tasa de errores
- Violaciones de rate limit
- Violaciones de seguridad

### Alert Levels

- **Critical** - Notificar y escalar
- **High** - Notificar
- **Medium** - Registrar
- **Low** - Registrar silenciosamente

## Integration with Orchestrator

El Orchestrator supervisa pero NO interfiere:

1. **Modo Pasivo** - Solo monitorea
2. **Conocimiento** - Acceso a políticas y auditoría
3. **Alertas** - Notificación de violaciones
4. **Reportes** - Visibilidad completa

## File Structure

```
.event-bus/
├── subscriptions.json          # Suscripciones activas
├── history.json                # Historial de eventos
└── governance/
    ├── rate-limits.json        # Estado de rate limiting
    ├── policy-state.json       # Violaciones y alertas
    ├── orchestrator-supervision.json
    ├── audit/
    │   └── audit-YYYY-MM-DD.json
    └── metrics/
        └── metrics-YYYY-MM-DD.json
```

## Best Practices

1. **Validar siempre** - Usar governance layer para todas las emisiones
2. **Monitorear regularmente** - Revisar reportes de governance
3. **Escalar violaciones** - Actuar sobre violaciones críticas
4. **Mantener auditoría** - Conservar logs para compliance
5. **Actualizar políticas** - Ajustar según necesidades

## Troubleshooting

### Evento bloqueado

Verificar:
- Permisos del actor en event-registry.json
- Esquema del payload
- Rate limits

### Validación fallida

Revisar:
- Campos obligatorios presentes
- Tipos de datos correctos
- Patrones regex coinciden

### Rate limit excedido

Soluciones:
- Esperar a que se reinicie la ventana
- Aumentar límite en governance-config.json
- Distribuir carga en tiempo

## Maintenance

### Daily

- Revisar alertas críticas
- Monitorear violaciones

### Weekly

- Generar reporte de governance
- Revisar auditoría
- Actualizar políticas si es necesario

### Monthly

- Archivar logs de auditoría
- Revisar métricas
- Optimizar rate limits