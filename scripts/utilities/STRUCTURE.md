#  CONVENCIONES DE NOMBRES

**Versin:** 2.0.0  
**ltima actualizacin:** 2026-04-22  
**Estado:**  PRODUCCIN

Gua completa de convenciones de nombres para scripts, funciones, variables y archivos en el directorio `scripts/utilities/`.

---

##  Tabla de Contenidos

- [Descripcin General](#descripcin-general)
- [Convenciones de Scripts](#convenciones-de-scripts)
- [Convenciones de Funciones](#convenciones-de-funciones)
- [Convenciones de Variables](#convenciones-de-variables)
- [Convenciones de Parmetros](#convenciones-de-parmetros)
- [Convenciones de Archivos](#convenciones-de-archivos)
- [Convenciones de Directorios](#convenciones-de-directorios)
- [Ejemplos Prcticos](#ejemplos-prcticos)
- [Checklist](#checklist)

---

##  Descripcin General

Las convenciones de nombres son esenciales para:

-  Consistencia en el proyecto
-  Facilitar bsqueda y descubrimiento
-  Mejorar legibilidad del cdigo
-  Reducir confusin
-  Facilitar mantenimiento

**Principios Generales:**
- Nombres descriptivos y claros
- Evitar abreviaturas innecesarias
- Usar ingls en cdigo
- Ser consistente en todo el proyecto

---

##  Convenciones de Scripts

### Formato General

```
verb-noun.ps1
verb-noun.sh
```

### Reglas

| Regla | Descripcin | Ejemplo |
|-------|-------------|---------|
| **Caso** | minsculas con guiones | `optimize-performance.ps1` |
| **Verbo** | Accin clara (verb-first) | `generate-`, `optimize-`, `clean-` |
| **Sustantivo** | Objeto de la accin | `-report`, `-memory`, `-runtime` |
| **Longitud** | 10-40 caracteres | Evitar muy corto o muy largo |
| **Extensin** | .ps1 (PowerShell) o .sh (Bash) | Segn el lenguaje |

### Verbos Comunes

| Verbo | Uso | Ejemplos |
|-------|-----|----------|
| `generate` | Crear/producir | `generate-report.ps1` |
| `optimize` | Mejorar/optimizar | `optimize-performance.ps1` |
| `clean` | Limpiar/eliminar | `clean-runtime.ps1` |
| `compact` | Compactar/consolidar | `compact-memory.ps1` |
| `deploy` | Desplegar/instalar | `deploy-application.ps1` |
| `monitor` | Monitorear/vigilar | `monitor-system.ps1` |
| `validate` | Validar/verificar | `validate-config.ps1` |
| `sync` | Sincronizar | `sync-data.ps1` |
| `backup` | Respaldar | `backup-database.ps1` |
| `restore` | Restaurar | `restore-backup.ps1` |
| `migrate` | Migrar/mover | `migrate-data.ps1` |
| `export` | Exportar | `export-report.ps1` |
| `import` | Importar | `import-config.ps1` |
| `run` | Ejecutar | `run-tests.ps1` |
| `start` | Iniciar | `start-service.ps1` |
| `stop` | Detener | `stop-service.ps1` |

### Sustantivos Comunes

| Sustantivo | Uso | Ejemplos |
|-----------|-----|----------|
| `report` | Reportes | `generate-report.ps1` |
| `performance` | Rendimiento | `optimize-performance.ps1` |
| `memory` | Memoria | `compact-memory.ps1` |
| `runtime` | Runtime | `clean-runtime.ps1` |
| `database` | Base de datos | `backup-database.ps1` |
| `config` | Configuracin | `validate-config.ps1` |
| `log` | Logs | `rotate-log.ps1` |
| `backup` | Respaldo | `restore-backup.ps1` |
| `session` | Sesin | `manage-session.ps1` |
| `agent` | Agente | `deploy-agent.ps1` |
| `workflow` | Flujo de trabajo | `orchestrate-workflow.ps1` |
| `metric` | Mtrica | `aggregate-metric.ps1` |
| `audit` | Auditora | `generate-audit.ps1` |

### Ejemplos Correctos

 **BIEN:**
```
optimize-performance.ps1
generate-audit-report.ps1
clean-runtime.ps1
compact-memory.ps1
deploy-application.ps1
monitor-system-health.ps1
validate-configuration.ps1
sync-data-sources.ps1
```

 **MAL:**
```
OptimizePerformance.ps1          # CamelCase (usar kebab-case)
opt_perf.ps1                     # Abreviado (ser descriptivo)
script1.ps1                      # Genrico (ser especfico)
generateAuditReport.ps1          # Mezcla de casos
optimize_performance.ps1         # snake_case (usar kebab-case)
```

---

##  Convenciones de Funciones

### Formato General

```powershell
function Verb-Noun {
    # Implementacin
}
```

### Reglas

| Regla | Descripcin | Ejemplo |
|-------|-------------|---------|
| **Caso** | PascalCase (Verb-Noun) | `Optimize-Performance` |
| **Verbo** | Accin clara | `Get-`, `Set-`, `New-`, `Remove-` |
| **Sustantivo** | Objeto de la accin | `-Performance`, `-Report`, `-Config` |
| **Aprobado** | Usar verbos aprobados de PowerShell | Ver tabla de verbos |

### Verbos Aprobados de PowerShell

| Categora | Verbos |
|-----------|--------|
| **Common** | Get, Set, Add, Remove, Clear, Close, Copy, Enter, Exit, Find, Format, Get, Hide, Join, Lock, Move, New, Open, Pop, Push, Read, Rename, Reset, Resize, Search, Select, Set, Show, Skip, Split, Step, Stop, Submit, Suspend, Switch, Undo, Unlock, Watch, Wait, Write |
| **Communication** | Connect, Disconnect, Read, Receive, Send, Write |
| **Data** | Backup, Checkpoint, Compare, Compress, Convert, ConvertFrom, ConvertTo, Dismount, Edit, Expand, Export, Group, Import, Initialize, Limit, Merge, Mount, Out, Publish, Restore, Save, Split, Sync, Unpublish |
| **Lifecycle** | Approve, Assert, Build, Complete, Confirm, Deny, Deploy, Disable, Enable, Install, Invoke, Register, Request, Restart, Resume, Start, Stop, Submit, Suspend, Uninstall, Unregister, Update, Wait |
| **Diagnostic** | Debug, Measure, Ping, Repair, Resolve, Test, Trace |
| **Security** | Block, Grant, Protect, Revoke, Unblock |

### Ejemplos Correctos

 **BIEN:**
```powershell
function Get-Performance { }
function Set-Configuration { }
function New-Report { }
function Remove-OldFiles { }
function Test-Connection { }
function Invoke-Deployment { }
```

 **MAL:**
```powershell
function OptimizePerformance { }      # No es verb-noun
function get_performance { }          # snake_case
function getPerformance { }           # camelCase
function Optimize_Performance { }     # Mezcla de casos
```

---

##  Convenciones de Variables

### Formato General

```powershell
$variableName
$VariableName (para variables globales)
$script:variableName (para variables de script)
```

### Reglas

| Regla | Descripcin | Ejemplo |
|-------|-------------|---------|
| **Caso** | camelCase o PascalCase | `$reportPath`, `$ConfigFile` |
| **Prefijo** | Scope si es necesario | `$script:`, `$global:` |
| **Descriptivo** | Nombre claro | `$reportPath` no `$rp` |
| **Longitud** | 5-30 caracteres | Evitar muy corto o muy largo |

### Prefijos Comunes

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `$` | Variable normal | `$reportPath` |
| `$script:` | Variable de script | `$script:globalConfig` |
| `$global:` | Variable global | `$global:appVersion` |
| `$env:` | Variable de entorno | `$env:PATH` |

### Tipos de Variables

| Tipo | Convencin | Ejemplo |
|------|-----------|---------|
| **String** | Descriptivo | `$reportPath`, `$userName` |
| **Array** | Plural | `$reports`, `$users`, `$items` |
| **Boolean** | is/has/can prefix | `$isValid`, `$hasError`, `$canExecute` |
| **Number** | Descriptivo | `$count`, `$timeout`, `$retryCount` |
| **Hash** | Descriptivo | `$config`, `$parameters`, `$options` |

### Ejemplos Correctos

 **BIEN:**
```powershell
$reportPath = "C:\reports\report.txt"
$isValid = $true
$retryCount = 3
$users = @("admin", "user1", "user2")
$config = @{ Timeout = 300; Verbose = $true }
$script:globalConfig = $null
```

 **MAL:**
```powershell
$rp = "C:\reports\report.txt"        # Muy corto
$ReportPath = "C:\reports\report.txt" # PascalCase (usar camelCase)
$report_path = "C:\reports\report.txt" # snake_case (usar camelCase)
$REPORTPATH = "C:\reports\report.txt"  # SCREAMING_SNAKE_CASE
```

---

##  Convenciones de Parmetros

### Formato General

```powershell
param(
    [string]$ParameterName,
    [int]$Count,
    [switch]$Verbose
)
```

### Reglas

| Regla | Descripcin | Ejemplo |
|-------|-------------|---------|
| **Caso** | PascalCase | `$ParameterName`, `$OutputPath` |
| **Tipo** | Especificar tipo | `[string]`, `[int]`, `[switch]` |
| **Descriptivo** | Nombre claro | `$OutputPath` no `$out` |
| **Documentado** | Incluir descripcin | Usar comentarios o help |

### Tipos de Parmetros

| Tipo | Uso | Ejemplo |
|------|-----|---------|
| `[string]` | Texto | `[string]$Path` |
| `[int]` | Nmero entero | `[int]$Timeout` |
| `[bool]` | Booleano | `[bool]$Force` |
| `[switch]` | Bandera | `[switch]$Verbose` |
| `[array]` | Arreglo | `[array]$Items` |
| `[hashtable]` | Diccionario | `[hashtable]$Config` |
| `[object]` | Objeto genrico | `[object]$Data` |

### Ejemplos Correctos

 **BIEN:**
```powershell
param(
    [string]$InputPath,
    [string]$OutputPath,
    [int]$Timeout = 300,
    [switch]$Verbose,
    [switch]$Force,
    [array]$Items
)
```

 **MAL:**
```powershell
param(
    $inputPath,                    # Sin tipo
    [string]$input_path,           # snake_case
    [string]$in,                   # Muy corto
    [string]$path,                 # Ambiguo (input o output?)
    [string]$InputPath = ""        # Valor por defecto vaco
)
```

---

##  Convenciones de Archivos

### Archivos de Script

```
verb-noun.ps1
verb-noun.sh
```

**Ejemplos:**
- `optimize-performance.ps1`
- `generate-report.ps1`
- `clean-runtime.ps1`

### Archivos de Documentacin

```
DOCUMENT-NAME.md
README.md
STANDARDS.md
```

**Ejemplos:**
- `README.md`
- `NAMING-CONVENTIONS.md`
- `BEST-PRACTICES.md`

### Archivos de Configuracin

```
config.json
settings.yaml
.env
```

**Ejemplos:**
- `config.json`
- `settings.yaml`
- `.env`

### Archivos de Datos

```
data-type-YYYY-MM-DD.csv
report-YYYY-MM-DD.json
backup-YYYY-MM-DD-HHmmss.zip
```

**Ejemplos
{
  "prompt_tokens": 50562,
  "prompt_unit_price": "0",
  "prompt_price_unit": "0",
  "prompt_price": "0",
  "completion_tokens": 8096,
  "completion_unit_price": "0",
  "completion_price_unit": "0",
  "completion_price": "0",
  "total_tokens": 58658,
  "total_price": "0",
  "currency": "USD",
  "latency": 46.863,
  "time_to_first_token": 2.019,
  "time_to_generate": 44.844
}