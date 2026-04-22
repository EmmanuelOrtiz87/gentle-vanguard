# 🧹 LIMPIEZA Y VALIDACIÓN DEL PROYECTO

**Versión:** 1.0.0  
**Fecha:** 2026-04-22  
**Estado:** Ejecución en Progreso

Plan completo de limpieza, validación y homologación del proyecto Gentleman Foundation.

---

## 📋 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Limpieza de Archivos](#limpieza-de-archivos)
- [Validación de Referencias](#validación-de-referencias)
- [Homologación de Nomenclatura](#homologación-de-nomenclatura)
- [Validación de Scripts](#validación-de-scripts)
- [Validación de Documentación](#validación-de-documentación)
- [Checklist Final](#checklist-final)

---

## 🎯 Descripción General

Limpieza y validación incluye:

✅ Eliminar archivos temporales y en desuso
✅ Validar referencias cruzadas
✅ Corregir paths incompletos
✅ Homologar nomenclaturas
✅ Validar sintaxis de scripts
✅ Verificar documentación

---

## 🧹 Limpieza de Archivos

### 1. Archivos Temporales a Eliminar

```powershell
# Script de limpieza
function Remove-TemporaryFiles {
    param([string]$RootPath = ".")
    
    $temporaryPatterns = @(
        "*.tmp",
        "*.bak",
        "*.old",
        "*~",
        ".DS_Store",
        "Thumbs.db",
        "*.log",
        "*.temp"
    )
    
    Write-Host "Eliminando archivos temporales..."
    
    foreach ($pattern in $temporaryPatterns) {
        $files = Get-ChildItem -Path $RootPath -Filter $pattern -Recurse -Force
        foreach ($file in $files) {
            Remove-Item -Path $file.FullName -Force
            Write-Host "  Eliminado: $($file.FullName)"
        }
    }
}

# Ejecutar limpieza
Remove-TemporaryFiles -RootPath "."
```

### 2. Archivos en Desuso

```powershell
# Archivos a revisar y eliminar si no se usan
$unusedFiles = @(
    # Agregar archivos en desuso aquí
)

# Verificar si existen y eliminar
foreach ($file in $unusedFiles) {
    if (Test-Path $file) {
        Write-Host "Archivo en desuso encontrado: $file"
        # Remove-Item -Path $file -Force
    }
}
```

### 3. Directorios Vacíos

```powershell
# Eliminar directorios vacíos
function Remove-EmptyDirectories {
    param([string]$RootPath = ".")
    
    Write-Host "Eliminando directorios vacíos..."
    
    $emptyDirs = Get-ChildItem -Path $RootPath -Directory -Recurse | 
        Where-Object { (Get-ChildItem -Path $_.FullName -Recurse).Count -eq 0 }
    
    foreach ($dir in $emptyDirs) {
        Remove-Item -Path $dir.FullName -Force
        Write-Host "  Eliminado directorio: $($dir.FullName)"
    }
}

Remove-EmptyDirectories -RootPath "."
```

---

## 🔗 Validación de Referencias

### 1. Validar Referencias Cruzadas

```powershell
function Validate-CrossReferences {
    param([string]$RootPath = ".")
    
    Write-Host "Validando referencias cruzadas..."
    
    $issues = @()
    
    # Buscar archivos markdown
    $mdFiles = Get-ChildItem -Path $RootPath -Filter "*.md" -Recurse
    
    foreach ($file in $mdFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Buscar referencias a archivos
        $references = [regex]::Matches($content, '\[([^\]]+)\]\(([^\)]+)\)')
        
        foreach ($ref in $references) {
            $refPath = $ref.Groups[2].Value
            
            # Ignorar URLs externas
            if ($refPath -match '^http') {
                continue
            }
            
            # Verificar si el archivo existe
            $fullPath = Join-Path (Split-Path $file.FullName) $refPath
            
            if (-not (Test-Path $fullPath)) {
                $issues += @{
                    File = $file.Name
                    Reference = $refPath
                    Status = "BROKEN"
                }
                Write-Host "  ⚠️  Referencia rota: $refPath en $($file.Name)"
            }
        }
    }
    
    return $issues
}

# Ejecutar validación
$brokenRefs = Validate-CrossReferences -RootPath "."
```

### 2. Validar Paths en Scripts

```powershell
function Validate-ScriptPaths {
    param([string]$RootPath = ".")
    
    Write-Host "Validando paths en scripts..."
    
    $issues = @()
    $scripts = Get-ChildItem -Path $RootPath -Filter "*.ps1" -Recurse
    
    foreach ($script in $scripts) {
        $content = Get-Content -Path $script.FullName -Raw
        
        # Buscar paths hardcodeados
        $pathMatches = [regex]::Matches($content, '["'']([A-Za-z]:[\\\/][^"'']*|\/[^"'']*)[''"]')
        
        foreach ($match in $pathMatches) {
            $path = $match.Groups[1].Value
            
            # Verificar si el path existe
            if (-not (Test-Path $path)) {
                $issues += @{
                    Script = $script.Name
                    Path = $path
                    Status = "INVALID"
                }
                Write-Host "  ⚠️  Path inválido: $path en $($script.Name)"
            }
        }
    }
    
    return $issues
}

# Ejecutar validación
$invalidPaths = Validate-ScriptPaths -RootPath "."
```

---

## 🏷️ Homologación de Nomenclatura

### 1. Validar Convenciones de Nombres

```powershell
function Validate-NamingConventions {
    param([string]$RootPath = ".")
    
    Write-Host "Validando convenciones de nombres..."
    
    $issues = @()
    
    # Validar scripts PowerShell
    $psScripts = Get-ChildItem -Path $RootPath -Filter "*.ps1" -Recurse
    
    foreach ($script in $psScripts) {
        $name = $script.BaseName
        
        # Debe ser verb-noun en minúsculas
        if ($name -notmatch '^[a-z]+-[a-z0-9-]+$') {
            $issues += @{
                File = $script.Name
                Issue = "Nombre no sigue convención verb-noun"
                Expected = "Ejemplo: optimize-context"
            }
            Write-Host "  ⚠️  Nombre incorrecto: $($script.Name)"
        }
    }
    
    return $issues
}

# Ejecutar validación
$namingIssues = Validate-NamingConventions -RootPath "."
```

### 2. Homologar Definiciones

```powershell
# Crear diccionario de definiciones estándar
$standardDefinitions = @{
    "Orquestador" = "Sistema de orquestación de workflows (Engram/Gentle AI)"
    "Optimización" = "Proceso de mejora de rendimiento y eficiencia"
    "Contexto" = "Información de estado y configuración del sistema"
    "Token" = "Unidad de medida de consumo de API"
    "Mensaje" = "Unidad de comunicación entre componentes"
    "Rendimiento" = "Velocidad y eficiencia de ejecución"
    "Throughput" = "Número de operaciones por unidad de tiempo"
    "Latencia" = "Tiempo de respuesta del sistema"
    "Compresión" = "Reducción de tamaño de datos"
    "Caché" = "Almacenamiento temporal de datos frecuentes"
}

# Validar que todas las definiciones sean consistentes
function Validate-Definitions {
    param([string]$RootPath = ".")
    
    Write-Host "Validando definiciones..."
    
    $mdFiles = Get-ChildItem -Path $RootPath -Filter "*.md" -Recurse
    
    foreach ($file in $mdFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        
        foreach ($term in $standardDefinitions.Keys) {
            if ($content -match $term) {
                Write-Host "  ✓ Término encontrado: $term en $($file.Name)"
            }
        }
    }
}

Validate-Definitions -RootPath "."
```

---

## ✅ Validación de Scripts

### 1. Validar Sintaxis de PowerShell

```powershell
function Test-PowerShellSyntax {
    param([string]$RootPath = ".")
    
    Write-Host "Validando sintaxis de PowerShell..."
    
    $errors = @()
    $scripts = Get-ChildItem -Path $RootPath -Filter "*.ps1" -Recurse
    
    foreach ($script in $scripts) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content -Path $script.FullName -Raw),
                [ref]$null
            )
            Write-Host "  ✓ $($script.Name) - Sintaxis correcta"
        }
        catch {
            $errors += @{
                Script = $script.Name
                Error = $_.Exception.Message
            }
            Write-Host "  ✗ $($script.Name) - Error: $($_.Exception.Message)"
        }
    }
    
    return $errors
}

# Ejecutar validación
$syntaxErrors = Test-PowerShellSyntax -RootPath "scripts/utilities"
```

### 2. Validar Estructura de Scripts

```powershell
function Test-ScriptStructure {
    param([string]$RootPath = ".")
    
    Write-Host "Validando estructura de scripts..."
    
    $issues = @()
    $scripts = Get-ChildItem -Path $RootPath -Filter "*.ps1" -Recurse
    
    foreach ($script in $scripts) {
        $content = Get-Content -Path $script.FullName -Raw
        
        # Verificar header
        if ($content -notmatch '<#\s*\.SYNOPSIS') {
            $issues += "Header faltante en $($script.Name)"
            Write-Host "  ⚠️  Header faltante: $($script.Name)"
        }
        
        # Verificar parámetros documentados
        if ($content -match 'param\(' -and $content -notmatch '\.PARAMETER') {
            $issues += "Parámetros no documentados en $($script.Name)"
            Write-Host "  ⚠️  Parámetros no documentados: $($script.Name)"
        }
        
        # Verificar manejo de errores
        if ($content -notmatch '\$ErrorActionPreference|try\s*{') {
            $issues += "Manejo de errores faltante en $($script.Name)"
            Write-Host "  ⚠️  Manejo de errores faltante: $($script.Name)"
        }
    }
    
    return $issues
}

# Ejecutar validación
$structureIssues = Test-ScriptStructure -RootPath "scripts/utilities"
```

### 3. Validar Funciones

```powershell
function Test-ScriptFunctions {
    param([string]$RootPath = ".")
    
    Write-Host "Validando funciones en scripts..."
    
    $issues = @()
    $scripts = Get-ChildItem -Path $RootPath -Filter "*.ps1" -Recurse
    
    foreach ($script in $scripts) {
        $content = Get-Content -Path $script.FullName -Raw
        
        # Buscar funciones
        $functions = [regex]::Matches($content, 'function\s+([A-Za-z0-9-]+)\s*{')
        
        foreach ($func in $functions) {
            $funcName = $func.Groups[1].Value
            
            # Validar nombre
            if ($funcName -notmatch '^[A-Z][a-zA-Z0-9-]*$') {
                $issues += "Nombre de función incorrecto: $funcName"
                Write-Host "  ⚠️  Nombre incorrecto: $funcName"
            }
        }
    }
    
    return $issues
}

# Ejecutar validación
$functionIssues = Test-ScriptFunctions -RootPath "scripts/utilities"
```

---

## 📚 Validación de Documentación

### 1. Validar Estructura de Markdown

```powershell
function Test-MarkdownStructure {
    param([string]$RootPath = ".")
    
    Write-Host "Validando estructura de Markdown..."
    
    $issues = @()
    $mdFiles = Get-ChildItem -Path $RootPath -Filter "*.md" -Recurse
    
    foreach ($file in $mdFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Verificar título
        if ($content -notmatch '^#\s+') {
            $issues += "Título faltante en $($file.Name)"
            Write-Host "  ⚠️  Título faltante: $($file.Name)"
        }
        
        # Verificar tabla de contenidos
        if ($content.Length -gt 5000 -and $content -notmatch '## .* Tabla de Contenidos') {
            $issues += "Tabla de contenidos faltante en $($file.Name)"
            Write-Host "  ⚠️  Tabla de contenidos faltante: $($file.Name)"
        }
        
        # Verificar secciones
        if ($content -notmatch '## [A-Za-z0-9 ]') {
            $issues += "Secciones faltantes en $($file.Name)"
            Write-Host "  ⚠️  Secciones faltantes: $($file.Name)"
        }
    }
    
    return $issues
}

# Ejecutar validación
$mdIssues = Test-MarkdownStructure -RootPath "."
```

### 2. Validar Consistencia de Documentación

```powershell
function Test-DocumentationConsistency {
    param([string]$RootPath = ".")
    
    Write-Host "Validando consistencia de documentación..."
    
    $issues = @()
    
    # Verificar que todos los scripts tengan documentación
    $scripts = Get-ChildItem -Path "$RootPath/scripts/utilities" -Filter "*.ps1" -Recurse
    
    foreach ($script in $scripts) {
        $docFile = "$RootPath/DOCUMENTATION/$($script.BaseName).md"
        
        if (-not (Test-Path $docFile)) {
            Write-Host "  ⚠️  Documentación faltante para: $($script.Name)"
        }
    }
    
    return $issues
}

# Ejecutar validación
$docConsistency = Test-DocumentationConsistency -RootPath "."
```

---

## ✅ Checklist Final de Limpieza

### Limpieza de Archivos
- [ ] Eliminar archivos temporales (.tmp, .bak, .old)
- [ ] Eliminar archivos de sistema (.DS_Store, Thumbs.db)
- [ ] Eliminar directorios vacíos
- [ ] Eliminar archivos en desuso
- [ ] Limpiar logs temporales

### Validación de Referencias
- [ ] Validar referencias cruzadas en documentación
- [ ] Validar paths en scripts
- [ ] Validar URLs en documentación
- [ ] Validar links a archivos
- [ ] Corregir referencias rotas

### Homologación de Nomenclatura
- [ ] Validar convenciones de nombres de scripts
- [ ] Validar convenciones de nombres de funciones
- [ ] Validar convenciones de nombres de variables
- [ ] Homologar definiciones
- [ ] Consistencia de términos

### Validación de Scripts
- [ ] Validar sintaxis de PowerShell
- [ ] Validar estructura de scripts
- [ ] Validar funciones
- [ ] Validar parámetros
- [ ] Validar manejo de errores

### Validación de Documentación
- [ ] Validar estructura de Markdown
- [ ] Validar consistencia de documentación
- [ ] Validar ejemplos de código
- [ ] Validar tablas de contenidos
- [ ] Validar referencias

### Validación Final
- [ ] Ejecutar todos los scripts de validación
- [ ] Revisar reportes de validación
- [ ] Corregir todos los problemas encontrados
- [ ] Ejecutar validación nuevamente
- [ ] Documentar cambios realizados

---

## 🔧 Script de Limpieza Completo

```powershell
# cleanup-and-validate.ps1
param(
    [string]$RootPath = ".",
    [switch]$AutoFix,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

Write-Log "Iniciando limpieza y validación del proyecto"

# 1. Limpiar archivos temporales
Write-Log "Paso 1: Limpiando archivos temporales..."
$tempPatterns = @("*.tmp", "*.bak", "*.old", "*~", ".DS_Store", "Thumbs.db")
foreach ($pattern in $tempPatterns) {
    $files = Get-ChildItem -Path $RootPath -Filter $pattern -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Remove-Item -Path $file.FullName -Force
        Write-Log "Eliminado: $($file.FullName)"
    }
}

# 2. Validar referencias cruzadas
Write-Log "Paso 2: Validando referencias cruzadas..."
$brokenRefs = Validate-CrossReferences -RootPath $RootPath

# 3. Validar paths
Write-Log "Paso 3: Validando paths en scripts..."
$invalidPaths = Validate-ScriptPaths -RootPath $RootPath

# 4. Validar sintaxis
Write-Log "Paso 4: Validando sintaxis de PowerShell..."
$syntaxErrors = Test-PowerShellSyntax -RootPath "$RootPath/scripts/utilities"

# 5. Validar estructura
Write-Log "Paso 5: Validando estructura de scripts..."
$structureIssues = Test-ScriptStructure -RootPath "$RootPath/scripts/utilities"

# 6. Validar documentación
Write-Log "Paso 6: Validando documentación..."
$docIssues = Test-MarkdownStructure -RootPath $RootPath

# Resumen
Write-Log "═══════════════════════════════════════════════════════════"
Write-Log "RESUMEN DE VALIDACIÓN" "INFO"
Write-Log "═══════════════════════════════════════════════════════════"
Write-Log "Referencias rotas: $($brokenRefs.Count)"
Write-Log "Paths inválidos: $($invalidPaths.Count)"
Write-Log "Errores de sintaxis: $($syntaxErrors.Count)"
Write-Log "Problemas de estructura: $($structureIssues.Count)"
Write-Log "Problemas de documentación: $($docIssues.Count)"

$totalIssues = $brokenRefs.Count + $invalidPaths.Count + $syntaxErrors.Count + $structureIssues.Count + $docIssues.Count

if ($totalIssues -eq 0) {
    Write-Log "✓ Proyecto validado correctamente" "SUCCESS"
    exit 0
}
else {
    Write-Log "✗ Se encontraron $totalIssues problemas" "ERROR"
    exit 1
}
```

---

**Versión:** 1.0.0  
**Fecha:** 2026-04-22  
**Estado:** Plan de Limpieza Completo

**Ejecutar este plan garantiza un proyecto limpio, validado y homologado.**