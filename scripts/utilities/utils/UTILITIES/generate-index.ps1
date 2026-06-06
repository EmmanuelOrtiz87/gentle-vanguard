<#
.SYNOPSIS
    Generates and updates INDEX.md automatically

.DESCRIPTION
    Scans all scripts in utilities directory and generates/updates INDEX.md
    with complete list, categories, and dependencies

.PARAMETER Path
    Root path to scan (default: current directory)

.PARAMETER OutputFile
    Output file path (default: INDEX.md)

.PARAMETER Verbose
    Show detailed messages

.EXAMPLE
    .\generate-index.ps1 -Path "scripts\utilities" -Verbose

.NOTES
    Author: Gentle-Vanguard Team
    Version: 1.0.0
    Last Updated: 2026-04-22
#>

param(
    [string]$Path = ".",
    [string]$OutputFile = "INDEX.md",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if ($Verbose -or $Level -ne "DEBUG") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

function Get-ScriptInfo {
    param([string]$ScriptPath)
    
    $content = Get-Content -Path $ScriptPath -Raw
    $name = Split-Path -Leaf $ScriptPath
    
    # Extract SYNOPSIS
    $synopsis = ""
    if ($content -match '\.SYNOPSIS\s+([^\n]+)') {
        $synopsis = $matches[1].Trim()
    }
    
    # Extract parameters
    $parameters = @()
    $paramMatches = [regex]::Matches($content, '\.PARAMETER\s+(\w+)\s+([^\n]+)')
    foreach ($match in $paramMatches) {
        $parameters += @{
            Name = $match.Groups[1].Value
            Description = $match.Groups[2].Value
        }
    }
    
    return @{
        Name = $name
        Path = $ScriptPath
        Synopsis = $synopsis
        Parameters = $parameters
        Type = if ($ScriptPath -match '\.ps1$') { "PowerShell" } else { "Bash" }
    }
}

function Get-DirectoryScripts {
    param([string]$DirectoryPath)
    
    $scripts = @()
    
    if (Test-Path $DirectoryPath) {
        $items = Get-ChildItem -Path $DirectoryPath -Filter "*.ps1" -File
        foreach ($item in $items) {
            $scripts += Get-ScriptInfo -ScriptPath $item.FullName
        }
    }
    
    return $scripts
}

function Generate-IndexContent {
    param([hashtable]$ScriptsByCategory)
    
    $content = @"
# [DOC] NDICE COMPLETO DE SCRIPTS

**Versin:** 2.0.0  
**ltima actualizacin:** $(Get-Date -Format 'yyyy-MM-dd')  
**Total de Scripts:** $($ScriptsByCategory.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum)

ndice maestro de todos los scripts disponibles en el directorio `scripts/utilities/`. Generado automticamente.

---

## [LIST] Tabla de Contenidos

- [Scripts por Categora](#scripts-por-categora)
- [Bsqueda Rpida](#bsqueda-rpida)

---

## [SEARCH] Bsqueda Rpida

### Por Directorio

| Directorio | Scripts | Descripcin |
|-----------|---------|-------------|
"@

    foreach ($category in $ScriptsByCategory.Keys | Sort-Object) {
        $count = $ScriptsByCategory[$category].Count
        $content += "`n| $category | $count | Consultar abajo |"
    }
    
    $content += "`n`n---`n`n##  Scripts por Categora`n`n"
    
    foreach ($category in $ScriptsByCategory.Keys | Sort-Object) {
        $scripts = $ScriptsByCategory[$category]
        $content += "`n### $category`n`n"
        $content += "| Script | Descripcin | Tipo |`n"
        $content += "|--------|-------------|------|`n"
        
        foreach ($script in $scripts | Sort-Object -Property Name) {
            $content += "| ``$($script.Name)`` | $($script.Synopsis) | $($script.Type) |`n"
        }
    }
    
    return $content
}

try {
    Write-Log "Starting INDEX.md generation"
    
    # Scan directories
    $scriptsByCategory = @{}
    $directories = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -match '^[A-Z]' }
    
    foreach ($dir in $directories) {
        Write-Log "Scanning directory: $($dir.Name)" "DEBUG"
        $scripts = Get-DirectoryScripts -DirectoryPath $dir.FullName
        if ($scripts.Count -gt 0) {
            $scriptsByCategory[$dir.Name] = $scripts
        }
    }
    
    Write-Log "Found $($scriptsByCategory.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum) scripts in $($scriptsByCategory.Count) categories"
    
    # Generate content
    $indexContent = Generate-IndexContent -ScriptsByCategory $scriptsByCategory
    
    # Write to file
    $outputPath = Join-Path -Path $Path -ChildPath $OutputFile
    Set-Content -Path $outputPath -Value $indexContent -Encoding UTF8
    
    Write-Log "INDEX.md generated successfully: $outputPath" "SUCCESS"
    exit 0
}
catch {
    Write-Log "Error generating INDEX.md: $_" "ERROR"
    exit 1
}

