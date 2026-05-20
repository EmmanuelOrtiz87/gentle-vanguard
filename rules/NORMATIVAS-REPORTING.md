# NORMATIVAS-REPORTING.md — Metrics, Audit & Reporting Standards

Version: 1.0.0 | Last updated: 2026-05-19

## 1. PROPOSITO

Define los estándares para la recolección, almacenamiento, generación y nomenclatura de todas las
métricas, auditorías, telemetría y reportes del stack Gentle-Vanguard.

## 2. PRINCIPIOS RECTORES

1. **LOCAL-FIRST**: Toda métrica, auditoría y reporte generado es un artefacto runtime. Nunca se
   commitea al repo. Solo la configuración del pipeline (schemas, queries, templates) va al repo.
2. **SINGLE SOURCE OF TRUTH**: `.runtime/metrics/` es el store único. Todo reporte/dashboard se
   genera desde ahí.
3. **AUTOMATED**: La recolección se dispara por hooks (post-sesión, pre-cierre) o por demanda
   (`scripts/metrics/collector.ps1`). No hay ingesta manual.
4. **REAL-TIME BY DEFAULT**: El dashboard HTML tiene auto-refresh (30s). El live-feed corre en
   background para datos continuos.
5. **TRACEABLE**: Cada snapshot tiene timestamp y session ID. Los reportes referencian su fuente
   de datos y fecha de generación.

## 3. ARQUITECTURA

```
session/*.json ─┐
logs/*.json ────┤
.token-state ───┤──► collector.ps1 ──► .runtime/metrics/ ──► dashboard-render.ps1 ──► reports/dashboard.html
live-obs.json ──┘                      ├── consolidated.json   └── live-feed.ps1 (loop)
                                       ├── sessions.json
                                       ├── token.json
                                       ├── live.json
                                       ├── snapshots/
                                       └── live/feed.json
```

### Flujo de datos

| Capa       | Componente               | Descripción                                       |
| ---------- | ------------------------ | ------------------------------------------------- |
| Fuentes    | `session/*.json` etc.    | Datos crudos de sesiones, tokens, observabilidad  |
| Collector  | `collector.ps1`          | Pipeline ETL: extrae, transforma, consolida       |
| Store      | `.runtime/metrics/`      | Único store de métricas procesadas                |
| Live Feed  | `live-feed.ps1`          | Loop continuo que actualiza feed.json cada N seg  |
| Renderer   | `dashboard-render.ps1`   | Genera dashboard HTML desde el store              |
| Salida     | `reports/dashboard.html` | Dashboard vivo con auto-refresh 30s               |

## 4. NOMENCLATURA DE REPORTES

Todos los reportes generados deben seguir este formato:

```
{tipo}-{contexto}-{fecha}-{version}.{ext}
```

| Componente | Valores                     | Ejemplo                         |
| ---------- | --------------------------- | ------------------------------- |
| tipo       | `dashboard`, `exec-report`, `tech-report`, `audit`, `cost`, `session-summary` |
| contexto   | `gv` (stack), o nombre proyecto |
| fecha      | `YYYY-MM-DD`                |
| version    | `v1`, `v2`, o sufijo hora   |
| ext        | `html`, `json`, `csv`, `md` |

**Ejemplos:**

| Correcto                          | Incorrecto                     |
| --------------------------------- | ------------------------------ |
| `dashboard-gv-2026-05-19-v1.html` | `dashboard.html` (sin contexto) |
| `exec-report-gv-2026-05-19-v1.md` | `informe-ejecutivo.md` (sin fecha) |
| `audit-gv-2026-05-19-v1.md`      | `audit_2026-04-17-154743.md` (formato inconsistente) |
| `cost-gv-2026-05-v1.csv`          | `MANAGEMENT-REPORT-2026-04.csv` (mayúsculas) |
| `session-summary-gv-2026-05-19-v1.json` | `session-2026-05-19-06.json` (son archivos de sesión, no reportes) |

## 5. UBICACIONES

| Contenido                    | Ruta                          | Git      |
| ---------------------------- | ----------------------------- | -------- |
| Pipeline de métricas         | `scripts/metrics/`            | ✅ Sí    |
| Normativa                    | `rules/NORMATIVAS-REPORTING.md` | ✅ Sí  |
| Config dashboard             | `config/telemetry-dashboard-v2.json` | ✅ Sí |
| Store de métricas            | `.runtime/metrics/`           | ❌ No    |
| Dashboard HTML               | `reports/dashboard.html`      | ❌ No*   |
| Snapshots históricos         | `.runtime/metrics/snapshots/` | ❌ No    |
| Live feed                    | `.runtime/metrics/live/`      | ❌ No    |
| Reportes archivados          | `.local/reports-archive/`     | ❌ No    |

*\* `reports/dashboard.html` es generado, no fuente. Se puede ignorar o trackear según necesidad.*

## 6. CICLO DE VIDA DE MÉTRICAS

### 6.1 Disparadores de recolección

| Evento                     | Acción                                    | Automático |
| -------------------------- | ----------------------------------------- | ---------- |
| Inicio de sesión           | `collector.ps1 -Scope live`               | Hook       |
| Durante sesión activa      | `live-feed.ps1` (loop cada 15-30s)        | Manual     |
| Cierre de sesión           | `collector.ps1 -Scope full` + snapshot    | Hook       |
| Demanda del usuario        | `collector.ps1 -Scope full` + render      | Manual     |
| Pre-commit hook            | Validar que no hay métricas en staged     | Hook       |

### 6.2 Retención

| Data                    | Retención | Acción                           |
| ----------------------- | --------- | -------------------------------- |
| Snapshots diarios       | 30 días   | Limpieza automática por script   |
| Live feed               | 7 días    | Rotación de archivos             |
| Dashboard HTML          | 1 archivo | Sobrescritura en cada generación |
| Reportes exportados     | Indefinido en `.local/reports-archive/` | Archivado manual |

## 7. DASHBOARD EN VIVO

El dashboard (`reports/dashboard.html`) tiene:

- **Auto-refresh** cada 30 segundos vía `<meta http-equiv="refresh">`
- **4 pestañas**: Overview, Sessions, Costs, Health
- **Datos desde** `.runtime/metrics/` (no hardcodeados)
- **Live feed** opcional: `scripts/metrics/live-feed.ps1 -RefreshSeconds 30 -Open`

### Cómo usar

```powershell
# Recolectar métricas una vez
.\scripts\metrics\collector.ps1 -Scope full

# Generar/actualizar dashboard
.\scripts\metrics\dashboard-render.ps1

# Live feed continuo (loop)
.\scripts\metrics\live-feed.ps1 -RefreshSeconds 30 -Open
```

## 8. COMPLIANCE CHECKS

1. ✅ `git status` no muestra archivos de métricas/reportes en staged
2. ✅ `.runtime/metrics/` es el único store de métricas
3. ✅ Los reportes generados siguen el formato `{tipo}-{contexto}-{fecha}-{version}.{ext}`
4. ✅ El dashboard HTML tiene auto-refresh
5. ✅ No hay archivos de telemetría/auditoría trackeados en git
6. ✅ Los snapshots tienen timestamp en el nombre
7. ✅ El live-feed puede ejecutarse como proceso background

---

_Version: 1.0.0 — Status: ACTIVE_
