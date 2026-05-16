<#
.SYNOPSIS
    Validates installed tools with hash-based caching to avoid repeated checks.
.DESCRIPTION
    Checks tool availability and versions. On first run, creates a cache file at
    ~/.gentle-vanguard/.tool-cache.json with version hashes. On subsequent runs, only
    re-verifies if a tool's version changed or the cache is stale (7+ days).
.PARAMETER Force
    Force re-verification of all tools regardless of cache.
.PARAMETER Install
    Attempt to install missing required tools.
.EXAMPLE
    .\verify-tools.ps1
    .\verify-tools.ps1 -Force
    .\verify-tools.ps1 -Install
#>
param(
    [switch]$Force,
    [switch]$Install
)

$ErrorActionPreference = 'Continue'

$cacheDir = Join-Path $HOME '.gentle-vanguard'
$cacheFile = Join-Path $cacheDir '.tool-cache.json'
$cacheTTL_DAYS = 7

function Write-Step { param([string]$Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

function Get-ToolVersion {
    param([string]$Name, [string]$Command)
    try {
        $cmd = if ($Command) { $Command } else { $Name }
        $result = & $cmd --version 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -ne 0 -and $result -match 'version') {
            $result = (& $cmd -v 2>&1 | Select-Object -First 1)
        }
        return ($result -replace '[^0-9.]','').Trim()
    } catch {
        try {
            $result = & $cmd -v 2>&1 | Select-Object -First 1
            return ($result -replace '[^0-9.]','').Trim()
        } catch {
            return 'unknown'
        }
    }
}

$tools = @(
    @{ Name = 'Git';         Command = 'git';       Version = '2.0';     Required = $true;  InstallCmd = 'winget install Git.Git' }
    @{ Name = 'Node.js';     Command = 'node';      Version = '20.0';   Required = $true;  InstallCmd = 'winget install OpenJS.NodeJS.LTS' }
    @{ Name = 'npm';         Command = 'npm';       Version = '10.0';   Required = $true;  InstallCmd = 'winget install OpenJS.NodeJS.LTS' }
    @{ Name = 'Go';          Command = 'go';        Version = '1.22';   Required = $false;  InstallCmd = 'winget install GoLang.Go' }
    @{ Name = 'PowerShell';  Command = 'pwsh';      Version = '7.0';    Required = $true;  InstallCmd = 'winget install Microsoft.PowerShell' }
    @{ Name = 'Bun';         Command = 'bun';       Version = '1.0';    Required = $false;  InstallCmd = 'powershell -c "irm bun.sh/install.ps1 | iex"' }
    @{ Name = 'GitHub CLI';  Command = 'gh';        Version = '2.0';    Required = $false;  InstallCmd = 'winget install GitHub.cli' }
    @{ Name = 'Engram';      Command = 'engram';    Version = '0.0';    Required = $false;  InstallCmd = 'go install github.com/gentle-vanguard/engram/cmd/engram@latest' }
    @{ Name = 'OpenCode';    Command = 'opencode';   Version = '0.0';   Required = $false;  InstallCmd = 'Download from https://opencode.ai' }
    @{ Name = 'lefthook';    Command = 'lefthook';  Version = '1.0';    Required = $true;   InstallCmd = 'npm install -g @evilmartians/lefthook' }
    @{ Name = 'Python';      Command = 'python';     Version = '3.10';  Required = $false;  InstallCmd = 'winget install Python.Python.3.12' }
    @{ Name = 'pip';         Command = 'pip';        Version = '23.0';  Required = $false;  InstallCmd = 'python -m ensurepip' }
    @{ Name = 'cairosvg';    Command = 'cairosvg';  Version = '2.0';   Required = $false;  InstallCmd = 'pip install cairosvg (requires Cairo native lib on Windows)' }
)

Write-Step 'Verificacion de herramientas (hash cache)'

$cache = @{}
$cacheValid = $false

if ((-not $Force) -and (Test-Path $cacheFile)) {
    try {
        $cacheData = Get-Content $cacheFile -Raw | ConvertFrom-Json
        $cacheAge = (Get-Date) - [DateTime]$cacheData.lastChecked
        if ($cacheAge.TotalDays -lt $cacheTTL_DAYS) {
            $cacheValid = $true
            foreach ($prop in $cacheData.tools.PSObject.Properties) {
                $cache[$prop.Name] = $prop.Value
            }
            Write-OK "Cache valido (verificado hace $([math]::Round($cacheAge.TotalHours, 1))h, TTL: ${cacheTTL_DAYS}d)"
        } else {
            Write-Warn "Cache expirado (edad: $([math]::Round($cacheAge.TotalDays, 1))d > ${cacheTTL_DAYS}d), re-verificando..."
        }
    } catch {
        Write-Warn "Cache corrupto, re-verificando..."
    }
} elseif ($Force) {
    Write-Warn 'Forzando re-verificacion completa...'
} else {
    Write-Info 'Primera ejecucion - verificando todas las herramientas...'
}

$results = @{ passed = @(); failed = @(); warned = @() }
$newCache = @{}

foreach ($tool in $tools) {
    $cmd = Get-Command $tool.Command -ErrorAction SilentlyContinue
    
    if ($null -ne $cmd) {
        $currentVersion = Get-ToolVersion -Name $tool.Name -Command $tool.Command
        $versionKey = "$($tool.Command)@$currentVersion"
        
        if ($cacheValid -and $cache.ContainsKey($versionKey)) {
            Write-OK "$($tool.Name) v$currentVersion (cache)"
            $newCache[$versionKey] = @{ status = 'ok'; version = $currentVersion; checkedAt = $cache[$versionKey].checkedAt }
            $results.passed += $tool.Name
        } else {
            Write-OK "$($tool.Name) v$currentVersion (verificado)"
            $newCache[$versionKey] = @{ status = 'ok'; version = $currentVersion; checkedAt = (Get-Date -Format 'o') }
            $results.passed += $tool.Name
        }
    } else {
        if ($tool.Required) {
            Write-Err "$($tool.Name) NO ENCONTRADO (requerido) - Instalar: $($tool.InstallCmd)"
            $results.failed += $tool.Name
        } else {
            Write-Warn "$($tool.Name) no encontrado (opcional) - Instalar: $($tool.InstallCmd)"
            $results.warned += $tool.Name
        }
    }
}

if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
}

$cacheOutput = @{
    lastChecked = (Get-Date -Format 'o')
    machine     = $env:COMPUTERNAME
    user        = $env:USERNAME
    tools       = $newCache
}
$cacheOutput | ConvertTo-Json -Depth 3 | Set-Content $cacheFile -Encoding UTF8

Write-Step 'Resumen'
Write-Host "  Pasaron:    $($results.passed.Count)" -ForegroundColor Green
Write-Host "  Faltan:     $($results.failed.Count)" -ForegroundColor Red
Write-Host "  Opcionales: $($results.warned.Count)" -ForegroundColor Yellow

if ($results.failed.Count -gt 0 -and $Install) {
    Write-Step 'Instalando herramientas faltantes'
    foreach ($tool in $tools | Where-Object { $results.failed -contains $_.Name }) {
        Write-Host "  Instalando $($tool.Name)..." -ForegroundColor Cyan
        try {
            Invoke-Expression $tool.InstallCmd
            Write-OK "$($tool.Name) instalado"
        } catch {
            Write-Err "Error instalando $($tool.Name): $_"
        }
    }
    Write-Host "`n  Ejecuta de nuevo para verificar." -ForegroundColor Yellow
}

if ($results.failed.Count -gt 0) {
    exit 1
}
exit 0
