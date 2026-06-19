#Requires -Version 7.0
<#
.SYNOPSIS
    API Documentation Generator — Scans PowerShell scripts and TypeScript files
    to auto-generate OpenAPI/Swagger docs and SDK stubs

.DESCRIPTION
    Extracts .SYNOPSIS, .PARAMETER, and function signatures from .ps1 and .ts files.
    Generates OpenAPI 3.0 specs, Markdown API reference, and SDK stubs.

.NOTES
    Part of Phase 4 — API Documentation v4.0
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('openapi', 'markdown', 'sdk', 'all')]
    [string]$Output = 'all',

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = 'docs/api',

    [Parameter(Mandatory = $false)]
    [string[]]$IncludePaths = @('scripts/utilities/ops', 'scripts/adaptive', 'scripts/security', 'apps/web-dashboard/server'),

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if (-not $Quiet) { Write-Host "[$t] [APIDOCS] [$Level] $Message" -ForegroundColor Blue }
}

function Extract-Params {
    param([string[]]$Lines)
    $params = @()
    $inParams = $false
    foreach ($line in $lines) {
        if ($line -match '\.PARAMETER\s+(\S+)') {
            $inParams = $true
            $params += @{ name = $Matches[1]; description = '' }
        } elseif ($inParams -and $line -match '^\s*#\s*(.*)') {
            if ($params.Count -gt 0) { $params[-1].description += $Matches[1] + ' ' }
        } else { $inParams = $false }
    }
    return $params
}

function Extract-PSScript {
    param([string]$Path)
    $content = Get-Content $Path -Raw
    $lines = Get-Content $Path

    $endpoint = @{
        file        = $Path
        name        = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        description = ''
        parameters  = @()
        paramBlock  = @()
    }

    if ($content -match '\.SYNOPSIS\s*\n\s*#\s*(.+?)(?:\n|$)') { $endpoint.description = $Matches[1].Trim() }

    $endpoint.parameters = Extract-Params -Lines $lines

    $inBlock = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*param\s*\(') { $inBlock = $true }
        if ($inBlock) {
            $endpoint.paramBlock += $line
            if ($line -match '^\s*\)') { break }
        }
    }

    return $endpoint
}

function Extract-TSEndpoint {
    param([string]$Path)
    $content = Get-Content $Path -Raw
    $lines = Get-Content $Path

    $routes = @()
    $currentRoute = $null

    foreach ($line in $lines) {
        if ($line -match "url\.pathname\s*===\s*'([^']+)'") {
            if ($currentRoute) { $routes += $currentRoute }
            $currentRoute = @{ path = $Matches[1]; method = 'GET'; description = '' }
            if ($line -match 'req\.method\s*===\s*''(\w+)''') { $currentRoute.method = $Matches[1] }
        } elseif ($line -match 'url\.pathname\.startsWith\(([^)]+)\)') {
            if ($currentRoute) { $routes += $currentRoute }
            $currentRoute = @{ path = $Matches[1].Trim("'"); method = 'GET'; description = 'Dynamic route' }
        }
    }
    if ($currentRoute) { $routes += $currentRoute }

    return @{ file = $Path; name = [System.IO.Path]::GetFileNameWithoutExtension($Path); routes = $routes }
}

function New-OpenApiSpec {
    param([array]$PsEndpoints, [array]$TsEndpoints)
    $spec = @{
        openapi = '3.0.3'
        info = @{
            title = 'Gentle-Vanguard API'
            version = '4.0.0'
            description = 'API for Gentle-Vanguard orchestrator — cloud connectors, state persistence, security, and monitoring'
        }
        servers = @(@{ url = '/api'; description = 'Dashboard API' })
        paths = @{}
    }

    foreach ($ep in $PsEndpoints) {
        $cleanPath = "/$($ep.name)".Replace('\', '/').ToLower()
        $spec.paths[$cleanPath] = @{
            get = @{
                summary = $ep.description
                parameters = $ep.parameters | ForEach-Object { @{ name = $_.name; in = 'query'; required = $false; schema = @{ type = 'string' } } }
                responses = @{ '200' = @{ description = 'Successful response' } }
            }
        }
    }

    foreach ($ep in $TsEndpoints) {
        foreach ($route in $ep.routes) {
            $method = $route.method.ToLower()
            if ($method -eq 'options') { continue }
            $spec.paths[$route.path] = @{
                $method = @{
                    summary = $route.description
                    responses = @{ '200' = @{ description = 'Successful response' } }
                }
            }
        }
    }

    return $spec
}

function New-MarkdownDocs {
    param([array]$PsEndpoints, [array]$TsEndpoints)
    $md = @"
# Gentle-Vanguard API Reference

**Version:** 4.0.0  
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## PowerShell Scripts

| Script | Description | Parameters |
|--------|-------------|------------|
"@

    foreach ($ep in $PsEndpoints) {
        $params = ($ep.parameters | ForEach-Object { "``$($_ | ConvertTo-Json -Compress)``" }) -join ', '
        $md += "`n| $($ep.name) | $($ep.description) | $params |"
    }

    $md += "`n`n## API Endpoints`n`n| Route | Method | Description |`n|-------|--------|-------------|`n"

    $seen = @{}
    foreach ($ep in $TsEndpoints) {
        foreach ($route in $ep.routes) {
            $key = "$($route.method):$($route.path)"
            if (-not $seen[$key]) {
                $seen[$key] = $true
                $md += "| $($route.path) | $($route.method) | $($route.description) |`n"
            }
        }
    }

    return $md
}

function New-SdkStubs {
    param([array]$PsEndpoints)
    $sdk = @"
// Gentle-Vanguard SDK v4.0 — Auto-generated
// Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

export class GentleVanguardClient {
  private baseUrl: string;

  constructor(baseUrl: string = '/api') {
    this.baseUrl = baseUrl;
  }

  private async request<T>(path: string, options?: RequestInit): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      headers: { 'Content-Type': 'application/json' },
      ...options,
    });
    if (!res.ok) throw new Error(`API error: ${res.status} ${res.statusText}`);
    return res.json() as Promise<T>;
  }

"@

    foreach ($ep in $PsEndpoints) {
        $methodName = $ep.name -replace '[^a-zA-Z0-9]', '_'
        $comment = $ep.description -replace '\n', ' '
        $params = ($ep.parameters | ForEach-Object { $_.name }) -join ', '

        $sdk += @"

  /**
   * $comment
   */
  async $methodName($($params | ForEach-Object { "$_: string" }) -join ', '): Promise<any> {
    return this.request('/$($ep.name)');
  }

"@
    }

    $sdk += @'
}

export const client = new GentleVanguardClient();
export default client;
'@

    return $sdk
}

# ===== MAIN =====

$outDir = Join-Path $root $OutputDir
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$psEndpoints = @()
$tsEndpoints = @()

foreach ($path in $IncludePaths) {
    $fullPath = Join-Path $root $path
    if (-not (Test-Path $fullPath)) { Write-Log "Path not found: $fullPath" 'WARN'; continue }

    Write-Log "Scanning $fullPath..." 'INFO'

    foreach ($file in (Get-ChildItem -Path $fullPath -Recurse -File | Where-Object { $_.Extension -in '.ps1', '.ts' })) {
        try {
            if ($file.Extension -eq '.ps1') {
                $ep = Extract-PSScript -Path $file.FullName
                if ($ep.description) { $psEndpoints += $ep }
            } elseif ($file.Extension -eq '.ts') {
                $ep = Extract-TSEndpoint -Path $file.FullName
                if ($ep.routes.Count -gt 0) { $tsEndpoints += $ep }
            }
        } catch {
            Write-Log "Failed to parse $($file.Name): $_" 'WARN'
        }
    }
}

Write-Log "Found $($psEndpoints.Count) PowerShell scripts and $($tsEndpoints.Count) TS files with routes" 'INFO'

if ($Output -in 'openapi', 'all') {
    $spec = New-OpenApiSpec -PsEndpoints $psEndpoints -TsEndpoints $tsEndpoints
    $specPath = Join-Path $outDir 'openapi.json'
    $spec | ConvertTo-Json -Depth 10 | Set-Content $specPath
    Write-Log "OpenAPI spec: $specPath" 'SUCCESS'
}

if ($Output -in 'markdown', 'all') {
    $md = New-MarkdownDocs -PsEndpoints $psEndpoints -TsEndpoints $tsEndpoints
    $mdPath = Join-Path $outDir 'API-REFERENCE.md'
    $md | Set-Content $mdPath
    Write-Log "Markdown docs: $mdPath" 'SUCCESS'
}

if ($Output -in 'sdk', 'all') {
    $sdk = New-SdkStubs -PsEndpoints $psEndpoints
    $sdkPath = Join-Path $outDir 'gentle-vanguard-sdk.ts'
    $sdk | Set-Content $sdkPath
    Write-Log "SDK stubs: $sdkPath" 'SUCCESS'
}

Write-Log "API documentation generation complete" 'SUCCESS'
return @{ openapi = (Join-Path $outDir 'openapi.json'); markdown = (Join-Path $outDir 'API-REFERENCE.md'); sdk = (Join-Path $outDir 'gentle-vanguard-sdk.ts') }
