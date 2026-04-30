# Event Bus Governance System

## Quick Start

Initialize:
```powershell
.\event-governance-layer.ps1 -Action initialize
.\orchestrator-governance-integration.ps1 -Action initialize
```

Check Status:
```powershell
.\orchestrator-governance-integration.ps1 -Action check-health
```

Emit Event:
```powershell
.\event-bus-enhanced.ps1 -Action emit -Event "dispatch.started" `
  -Payload '{"execution_id":"dispatch-20260423","mode":"parallel","agents":["DEV"]}' `
  -Actor "orchestrator"
```

View Report:
```powershell
.\orchestrator-governance-integration.ps1 -Action report
```

## Components

- `event-governance-layer.ps1` - Validacin y enforcement
- `event-bus-enhanced.ps1` - Event Bus mejorado
- `orchestrator-governance-integration.ps1` - Integracin Orchestrator

## Configuration

- `config/event-registry.json` - Definicin de eventos
- `config/event-governance-config.json` - Polticas

## Features

 Validacin de esquemas  
 Polticas de seguridad  
 Rate limiting  
 Auditora completa  
 Monitoreo pasivo  
 Alertas automticas  

Ver `docs/EVENT-GOVERNANCE-IMPLEMENTATION.md` para detalles.