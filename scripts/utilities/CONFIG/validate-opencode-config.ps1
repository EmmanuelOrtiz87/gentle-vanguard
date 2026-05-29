param(
    [string]$ConfigPath = "opencode.json",
    [switch]$Fix
)

$ErrorActionPreference = "Stop"

$validProps = @(
    '$schema', 'agent', 'attachment', 'autoshare', 'autoupdate',
    'command', 'compaction', 'default_agent',
    'disabled_providers', 'enabled_providers', 'enterprise', 'experimental',
    'formatter', 'instructions', 'layout', 'logLevel', 'lsp',
    'mcp', 'mode', 'model',
    'permission', 'plugin', 'provider',
    'reference', 'server', 'share', 'shell', 'skills',
    'small_model', 'snapshot',
    'tools', 'tool_output',
    'username', 'watcher'
)

if (-not (Test-Path $ConfigPath)) {
    Write-Host "ERROR: $ConfigPath not found" -ForegroundColor Red
    exit 1
}

$raw = Get-Content $ConfigPath -Raw
$config = $raw | ConvertFrom-Json
$props = $config.PSObject.Properties.Name

$unknown = @()
foreach ($prop in $props) {
    if ($prop -notin $validProps) {
        $unknown += $prop
    }
}

$hasUnknown = $unknown.Count -gt 0

if ($hasUnknown) {
    Write-Host "FAIL: opencode.json contiene propiedades NO reconocidas por OpenCode:" -ForegroundColor Red
    foreach ($u in $unknown) {
        Write-Host "  - $u" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "OpenCode rechaza propiedades desconocidas al iniciar. Mover a config/ separado." -ForegroundColor Red

    if ($Fix) {
        $lines = $raw -split "`n"
        $filtered = $lines | Where-Object {
            $trimmed = $_.Trim()
            $isUnknown = $false
            foreach ($u in $unknown) {
                if ($trimmed -match "^`"$u`"") { $isUnknown = $true; break }
            }
            -not $isUnknown
        }
        $filtered -join "`n" | Set-Content $ConfigPath
        Write-Host "FIXED: Removed unknown properties from $ConfigPath" -ForegroundColor Green
    }

    exit 1
} else {
    Write-Host "PASS: opencode.json solo contiene propiedades válidas" -ForegroundColor Green
    exit 0
}
