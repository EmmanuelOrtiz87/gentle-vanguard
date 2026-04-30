# PowerShell Script Standards & Governance

## Propsito
Este documento establece los estndares obligatorios para todos los scripts PowerShell en el proyecto. El orquestador utilizar estas reglas para validar, generar y revisar scripts automticamente.

---

## 1. Estructura Bsica Requerida

### 1.1 Encabezado del Script
```powershell
#!/usr/bin/env pwsh
# script-name.ps1
# Descripcin breve de qu hace el script
# Uso: .\script-name.ps1 -Parameter "value"
```

### 1.2 Parmetros
```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ParameterName,
    
    [Parameter(Mandatory=$false)]
    [int]$OptionalParameter = 1,
    
    [switch]$Flag
)
```

**Reglas:**
- Cada parmetro debe estar en su propia lnea
- Usar `[Parameter(Mandatory=$true)]` explcitamente
- Proporcionar valores por defecto para parmetros opcionales
- Cerrar parntesis de `param()` correctamente

### 1.3 Configuracin Inicial
```powershell
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'  # Opcional, para debugging
```

---

## 2. Errores Comunes y Cmo Evitarlos

###  ERROR: Parntesis Desbalanceados
```powershell
# INCORRECTO - Falta parntesis de cierre
function Invoke-PrismaMigrate {
    param([string]$DbAction, [int]$DbSteps
    # ... cdigo
}

# CORRECTO
function Invoke-PrismaMigrate {
    param([string]$DbAction, [int]$DbSteps)
    # ... cdigo
}
```

###  ERROR: Operador && No Vlido en PowerShell
```powershell
# INCORRECTO - && no existe en PowerShell
'fresh' { & npx typeorm schema:drop && & npx typeorm migration:run }

# CORRECTO - Usar ; para encadenar comandos
'fresh' { & npx typeorm schema:drop; & npx typeorm migration:run }

# ALTERNATIVA - Usar -and para lgica
if ($condition1 -and $condition2) { }
```

###  ERROR: Comillas Escapadas Incorrectamente
```powershell
# INCORRECTO - Comillas dobles sin cerrar
$TriggerList | ForEach-Object { ""$_"" }

# CORRECTO - Usar comillas simples o backticks
$TriggerList | ForEach-Object { "'$_'" }
# O con backticks para escapar
$TriggerList | ForEach-Object { "`"$_`"" }
```

###  ERROR: Duplicacin de Contenido
```powershell
# INCORRECTO - Archivo duplicado dentro de comillas
$template = @"
---
name: $SkillName
...
"@
# ... luego el mismo contenido se repite

# CORRECTO - Usar here-strings correctamente
$template = @"
---
name: $SkillName
description: >
  $Desc
---
"@
# Cerrar con "@
```

###  ERROR: Here-Strings Desbalanceados
```powershell
# INCORRECTO - @" sin cerrar con "@
$content = @"
This is a multiline string
but never closes

# CORRECTO
$content = @"
This is a multiline string
that closes properly
"@
```

---

## 3. Funciones Auxiliares Estndar

### 3.1 Logging/Output
```powershell
function Write-Step { 
    param([string]$Message) 
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan 
}

function Write-Success { 
    param([string]$Message) 
    Write-Host "[OK] $Message" -ForegroundColor Green 
}

function Write-Error { 
    param([string]$Message) 
    Write-Host "[ERROR] $Message" -ForegroundColor Red 
}

function Write-Warning { 
    param([string]$Message) 
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow 
}
```

### 3.2 Validacin de Directorios
```powershell
function Ensure-Directory {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Success "Created directory: $Path"
    }
}
```

### 3.3 Validacin de Comandos
```powershell
function Test-CommandExists {
    param([string]$CommandName)
    
    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    return [bool]$command
}
```

---

## 4. Manejo de Errores

### 4.1 Try-Catch Correcto
```powershell
try {
    # Cdigo que puede fallar
    & some-command
}
catch {
    Write-Error "Failed to execute command: $_"
    exit 1
}
finally {
    # Limpieza opcional
    Write-Verbose "Cleanup completed"
}
```

### 4.2 Validacin de Parmetros
```powershell
if ([string]::IsNullOrWhiteSpace($ParameterName)) {
    Write-Error "ParameterName is required"
    exit 1
}

if ($ParameterValue -lt 0) {
    Write-Error "ParameterValue must be positive"
    exit 1
}
```

---

## 5. Convenciones de Nombres

### 5.1 Funciones
```powershell
# Usar Verb-Noun en PascalCase
function Invoke-Migration { }
function Get-Configuration { }
function Test-Connection { }
function Install-Package { }
function Remove-OldFiles { }
```

### 5.2 Variables
```powershell
# Usar camelCase para variables locales
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir '..')

# Usar UPPERCASE para constantes
$MAX_RETRIES = 3
$DEFAULT_TIMEOUT = 30
```

### 5.3 Archivos
```powershell
# Usar kebab-case para nombres de archivos
create-skill.ps1
migrate-database.ps1
validate-workspace.ps1
```

---

## 6. Estructura de Funciones

### 6.1 Plantilla Estndar
```powershell
function Invoke-MyFunction {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RequiredParam,
        
        [Parameter(Mandatory=$false)]
        [string]$OptionalParam = 'default'
    )
    
    Write-Step "Starting MyFunction with $RequiredParam"
    
    try {
        # Validacin
        if ([string]::IsNullOrWhiteSpace($RequiredParam)) {
            throw "RequiredParam cannot be empty"
        }
        
        # Lgica principal
        $result = Do-Something -Input $RequiredParam
        
        # Retornar resultado
        return $result
    }
    catch {
        Write-Error "Error in MyFunction: $_"
        return $null
    }
}
```

---

## 7. Validacin Automtica (Orquestador)

El orquestador verificar automticamente:

### 7.1 Sintaxis
-  Parntesis balanceados
-  Comillas balanceadas
-  Here-strings cerrados correctamente
-  Llaves balanceadas en funciones

### 7.2 Operadores
-  No usar `&&` (reemplazar con `;`)
-  No usar `||` (reemplazar con `-or`)
-  Usar `-and` en lugar de `&&`
-  Usar `-or` en lugar de `||`

### 7.3 Estructura
-  Parmetros con `[Parameter(...)]`
-  `$ErrorActionPreference = 'Stop'` presente
-  Funciones con nombres Verb-Noun
-  Documentacin en encabezado

### 7.4 Convenciones
-  Nombres de variables en camelCase
-  Nombres de funciones en Verb-Noun
-  Nombres de archivos en kebab-case
-  Indentacin consistente (4 espacios)

---

## 8. Checklist para Crear Scripts

Antes de crear un script nuevo, verificar:

- [ ] Encabezado con descripcin
- [ ] Parmetros con `[Parameter(...)]`
- [ ] `$ErrorActionPreference = 'Stop'`
- [ ] Funciones auxiliares (Write-Step, Write-Success, Write-Error)
- [ ] Try-catch para manejo de errores
- [ ] Validacin de parmetros
- [ ] Nombres en convencin correcta
- [ ] Parntesis y comillas balanceados
- [ ] No usar `&&` o `||`
- [ ] Here-strings cerrados correctamente

---

## 9. Validacin del Orquestador

### 9.1 Comando para Validar Script
```powershell
# El orquestador ejecutar automticamente:
Invoke-ScriptAnalyzer -Path "script.ps1" -Severity Error, Warning
```

### 9.2 Reglas Personalizadas
```powershell
# Verificar operadores no vlidos
if ($content -match '\s&&\s' -or $content -match '\s\|\|\s') {
    Write-Error "Script contains invalid operators && or ||"
    exit 1
}

# Verificar parntesis balanceados
$openParens = [regex]::Matches($content, '\(').Count
$closeParens = [regex]::Matches($content, '\)').Count
if ($openParens -ne $closeParens) {
    Write-Error "Unbalanced parentheses: $openParens open, $closeParens closed"
    exit 1
}
```

---

## 10. Ejemplos Completos

### 10.1 Script Simple Correcto
```powershell
#!/usr/bin/env pwsh
# validate-config.ps1
# Valida la configuracin del workspace

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

function Write-Step { 
    param([string]$m) 
    Write-Host "`n=== $m ===" -ForegroundColor Cyan 
}

function Write-Success { 
    param([string]$m) 
    Write-Host "[OK] $m" -ForegroundColor Green 
}

Write-Step "Validating configuration"

try {
    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }
    
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    Write-Success "Configuration is valid"
}
catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}
```

### 10.2 Script con Funciones Correcto
```powershell
#!/usr/bin/env pwsh
# setup-project.ps1
# Configura un nuevo proyecto

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = './projects'
)

$ErrorActionPreference = 'Stop'

function Write-Step { 
    param([string]$m) 
    Write-Host "`n=== $m ===" -ForegroundColor Cyan 
}

function Write-Success { 
    param([string]$m) 
    Write-Host "[OK] $m" -ForegroundColor Green 
}

function Ensure-Directory {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

Write-Step "Setting up project: $ProjectName"

try {
    Ensure-Directory -Path $ProjectPath
    
    $projectDir = Join-Path $ProjectPath $ProjectName
    if (Test-Path $projectDir) {
        throw "Project already exists: $projectDir"
    }
    
    Ensure-Directory -Path $projectDir
    Write-Success "Project created at $projectDir"
}
catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}
```

---

## 11. Integracin con el Orquestador

El orquestador ejecutar estas validaciones automticamente cuando:

1. **Se cree un nuevo script**  Validar estructura
2. **Se modifique un script**  Validar sintaxis
3. **Antes de hacer commit**  Pre-commit hook
4. **En CI/CD pipeline**  Validacin automtica

### Comando para Forzar Validacin Manual
```powershell
.\scripts\diagnostics\validate-script-governance.ps1 -ScriptPath "path/to/script.ps1"
```

---

## 12. Referencias

- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/00-introduction)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [Approved Verbs for PowerShell Commands](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)