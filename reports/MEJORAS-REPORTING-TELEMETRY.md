# 📋 Plan de Mejora: Sistema de Reporting y Telemetría

**Fecha**: 2026-04-26  
**Proyecto**: workspace_gentle_vanguard  
**Objetivo**: Habilitar informes gerenciales completos bajo demanda

---

## 🎯 Estado Actual

### ✅ Lo que ya existe:

| Componente                 | Estado                 | Ubicación                                   |
| -------------------------- | ---------------------- | ------------------------------------------- |
| Auto-delegation            | ✅ Configurado         | `config/auto-delegation.json`               |
| Sesiones                   | ✅ Grabadas            | `.session/session-*.json`                   |
| Telemetry inicialización   | ✅ Grabada             | `.telemetry/initialization-*.json`          |
| Token Guard config         | ✅ Configurado         | `scripts/utilities/token-guard-config.json` |
| Context Efficiency         | ✅ Configurado         | `config/context-efficiency.json`            |
| Business Telemetry Schema  | ✅ Definido (sin usar) | `skills/business-telemetry-skill/SKILL.md`  |
| Context Engineering Skills | ✅ Definidos           | `skills/context-engineering-skill/SKILL.md` |
| Scripts de métricas        | ✅ Existentes          | `scripts/utilities/*metrics*.ps1`           |

### ❌ Lo que FALTA:

| Dato                       | Estado            | Prioridad |
| -------------------------- | ----------------- | --------- |
| Tokens consumed por sesión | ❌ No se registra | 🔴 ALTA   |
| Costo estimado (USD)       | ❌ No se calcula  | 🔴 ALTA   |
| Contexto usado (chars)     | ❌ No se mide     | 🔴 ALTA   |
| Duración real              | ❌ No se calcula  | 🟡 MEDIA  |
| Tool calls count           | ❌ No se cuenta   | 🟡 MEDIA  |
| Files read/edited          | ❌ No se cuenta   | 🟡 MEDIA  |
| Telemetry consolidación    | ❌ No se ejecuta  | 🔴 ALTA   |

---

## 🔧 Acciones Requeridas

### Fase 1: Captura de Datos (Inmediata)

#### 1.1 Mejorar Session State File

**Archivo**: `.session/session-{id}.json`

```json
{
  "status": "active",
  "sessionId": "session-2026-04-26-01",
  "startTime": "2026-04-26T00:49:49Z",
  "endTime": null, // ← AGREGAR
  "durationSeconds": 0, // ← AGREGAR
  "metrics": {
    // ← AGREGAR
    "inputTokens": 0,
    "outputTokens": 0,
    "totalTokens": 0,
    "estimatedCostUsd": 0.0,
    "contextChars": 0,
    "toolCalls": 0,
    "filesRead": 0,
    "filesEdited": 0,
    "filesCreated": 0
  }
}
```

**Responsable**: Session workflow / Token Guard

#### 1.2 Instrumentar Tool Calls

Cada tool call (read, write, edit, glob, grep, etc.) debe:

- Incrementar contador correspondiente
- Acumular caracteres/leías escritos

**Responsable**: session-lifecycle skill

---

### Fase 2: Consolidación (Corto plazo)

#### 2.1 Ejecutar business-telemetry-skill

El skill ya tiene el schema definido en `docs/management/telemetry-master.csv`:

| Column           | Descripción        | Fuente        |
| ---------------- | ------------------ | ------------- |
| Timestamp        | ISO 8601           | System        |
| User_ID          | Developer          | Git config    |
| Session_ID       | Session identifier | WFS           |
| Task_Scope       | Descripción        | Session brief |
| Tokens_Estimated | Uso estimado       | Token Guard   |
| Judgment_Result  | PASS/FAIL          | Judgment      |
| Review_Issues    | Issues encontrados | Review        |
| Duration_Min     | Duración           | Start/End     |
| Efficiency_Score | Tokens vs Output   | AGENT-GOV     |

**Acción**: Hacer que el workflow ejecute este consolidado al final del día.

#### 2.2 Crear Reporte Diario Automático

```powershell
# Al final de cada día:
.\scripts\utilities\session-summary-report.ps1 -Day YYYY-MM-DD
```

---

### Fase 3: Reporting On Demand (Mediano plazo)

#### 3.1 Auto-Delegation

Ya configurado en `config/auto-delegation.json`:

- Keywords: "informe", "report", "métricas", "gerencia", "tokens", "costos"
- Delegate a: skill adecuado (reporting o delegation)

#### 3.2 Skill de Reporting

**Trigger**: "genera informe", "create report", "métricas", "dashboard"

**Funciones**:

1. Parsear período solicitado (hoy, ayer, últimos N días)
2. Agregar datos de sesiones
3. Calcular métricas consolidadas
4. Generar markdown estructurado

#### 3.3 CLI de Reporting

```powershell
# Ejemplos de uso:
gv report today
gv report yesterday
gv report "24-26 abr"
gv report --period 2026-04-24:2026-04-26
gv metrics --sessions --tokens --costs
```

---

## 📊 Métricas a Implementar

### Por Sesión

```
┌─────────────────────────────────────────┐
│  INPUT TOKENS     │ Prompt + contexto      │
│  OUTPUT TOKENS  │ Respuestas + código │
│  TOTAL         │ input + output     │
│  ESTIMATED $   │ USD (modelo actual)│
│  CONTEXT CHARS │ Ventana de contexto │
│  TOOL CALLS   │ read/edit/write   │
│  FILES READ   │ archivos leídos  │
│  FILES EDITED  │ archivos modify │
└─────────────────────────────────────────┘
```

### Por Período

```
┌─────────────────────────────────────────┐
│  SESIONES       │ Total del período    │
│  DURACIÓN      │ Tiempo activo   │
│  TOKENS total  │ Consumo total  │
│  COSTO total  │ USD estimado   │
│  PROMEDIO     │tokens/sesión   │
│  TENDENCIA    │ vs período ant. │
└─────────────────────────────────────────┘
```

---

## 📅 Roadmap

| Fase | Descripción      | Entregable             |
| ---- | ---------------- | ---------------------- |
| 1    | Captura de datos | Session state mejorado |
| 2    | Consolidación    | telemetry-master.csv   |
| 3    | On-demand        | CLI + skill            |

---

## ✅ Checklist de Implementación

- [ ] Agregar `metrics` al session state JSON
- [ ] Instrumentar tool calls para contar Usage
- [ ] Calcular duración real (endTime - startTime)
- [ ] Estimar costo USD (input + output tokens)
- [ ] Ejecutar consolidación giornaliera
- [ ] Poblar telemetry-master.csv
- [ ] Crear skill de reporting
- [ ] Agregar CLI `gv report`
- [ ] Probar flujo on-demand

---

_Documento generado: 2026-04-26_  
_Próxima revisión: cuando se implemente Fase 1_

