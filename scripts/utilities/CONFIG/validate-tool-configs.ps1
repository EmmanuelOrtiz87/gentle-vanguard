param(
    [switch]$Fix,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$exitCode = 0

# ── Schema definitions ──────────────────────────────────────────────
$schemas = @{
    "opencode.json" = @(
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
    ".windsurf/config.json" = @(
        'name', 'description', 'version', 'rules', 'customRules', 'handle'
    )
    ".continue/config.json" = @(
        'name', 'description', 'version', 'models', 'modelProviders',
        'tabAutocompleteModel', 'contextProviders', 'slashCommands',
        'docs', 'experimental', 'allowAnonymousTelemetry', 'disableIndexing',
        'mcpServers'
    )
}

# ── Cline rules sections that are silently ignored ─────────────────
$clineIgnoredSections = @(
    'system_prompt', 'system_prompt_optimization'
)

# ── Helper ──────────────────────────────────────────────────────────
function Test-ConfigFile {
    param($Path, $ValidProps, $Label)
    if (-not (Test-Path $Path)) {
        if (-not $Quiet) { Write-Host "SKIP: $Label ($Path not found)" -ForegroundColor DarkYellow }
        return $true
    }
    try {
        $raw = Get-Content $Path -Raw
        $config = $raw | ConvertFrom-Json
        $props = $config.PSObject.Properties.Name
        $unknown = $props | Where-Object { $_ -notin $ValidProps }
        if ($unknown.Count -gt 0) {
            Write-Host "FAIL: $Label — propiedades no estándar:" -ForegroundColor Red
            foreach ($u in $unknown) {
                Write-Host "  - $u" -ForegroundColor Yellow
            }
            if ($Fix) {
                $lines = $raw -split "`n"
                $filtered = $lines | Where-Object {
                    $trimmed = $_.Trim()
                    $bad = $false
                    foreach ($u in $unknown) {
                        if ($trimmed -match "^`"$u`"") { $bad = $true; break }
                    }
                    -not $bad
                }
                $filtered -join "`n" | Set-Content $Path
                Write-Host "  → FIXED: removed from $Path" -ForegroundColor Green
            }
            return $false
        }
        if (-not $Quiet) { Write-Host "PASS: $Label" -ForegroundColor Green }
        return $true
    } catch {
        Write-Host "ERR: $Label — $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-Clinerules {
    param($Path)
    if (-not (Test-Path $Path)) {
        if (-not $Quiet) { Write-Host "SKIP: .clinerules (not found)" -ForegroundColor DarkYellow }
        return $true
    }
    try {
        $content = Get-Content $Path -Raw
        $ok = $true
        foreach ($section in $clineIgnoredSections) {
            if ($content -match "^$($section):") {
                Write-Host "WARN: .clinerules contiene sección '$section' que Cline ignora silenciosamente" -ForegroundColor Yellow
                if ($Fix) {
                    $pat = "(?ms)^$($section):.*?(?=\n^[a-z_]|\z)"
                $content = $content -replace $pat, "# [REMOVED] $section — ver config/system-prompt-optimization.json"
                    Set-Content -Path $Path -Value $content
                    Write-Host "  → FIXED: removed '$section' from .clinerules" -ForegroundColor Green
                }
                $ok = $false
            }
        }
        if ($ok -and -not $Quiet) { Write-Host "PASS: .clinerules" -ForegroundColor Green }
        return $ok
    } catch {
        Write-Host "ERR: .clinerules — $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ── Run validations ─────────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════════════╗"
Write-Host "║  validate-tool-configs — Multi-Tool Validator   ║"
Write-Host "╚══════════════════════════════════════════════════╝"
Write-Host ""

$results = @()
foreach ($entry in $schemas.GetEnumerator()) {
    $r = Test-ConfigFile -Path $entry.Key -ValidProps $entry.Value -Label $entry.Key
    $results += $r
    if (-not $r) { $exitCode = 1 }
}

$clineOk = Test-Clinerules -Path ".clinerules"
if (-not $clineOk) { $exitCode = 1 }

# ── Summary ─────────────────────────────────────────────────────────
Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "RESULT: ALL PASS — todos los tool configs cumplen schemas oficiales" -ForegroundColor Green
} else {
    Write-Host "RESULT: FAIL — algunos tool configs contienen props no estándar" -ForegroundColor Red
    Write-Host "INFO: Las props no estándar son ignoradas silenciosamente por las herramientas."
    Write-Host "      Usa -Fix para removerlas automáticamente." -ForegroundColor Cyan
}

exit $exitCode
