param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("measure", "optimize", "validate", "config-check")]
    [string]$Action,
    [string]$WorkspaceRoot = "."
)

$ErrorActionPreference = "Stop"
$configPath = Join-Path $WorkspaceRoot "config/system-prompt-optimization.json"
$opencodeJsonPath = Join-Path $WorkspaceRoot "opencode.json"

function Load-Config {
    if (-not (Test-Path $configPath)) {
        Write-Warn "Config not found: $configPath"
        return $null
    }
    return Get-Content $configPath -Raw | ConvertFrom-Json
}

function Estimate-Tokens($Text) {
    $ratio = if ($Text -match "```|function|class") { 3 } else { 4 }
    return [Math]::Ceiling($Text.Length / $ratio)
}

function Measure-File($Path) {
    if (-not (Test-Path $Path)) { return @{ Exists = $false; Tokens = 0 } }
    $content = Get-Content $Path -Raw
    return @{ Exists = $true; Tokens = (Estimate-Tokens $content); Lines = ($content -split "`n").Count }
}

function Measure-CurrentState {
    $results = @{ TotalTokens = 0; TotalLines = 0; Files = @{} }
    $files = @("CLAUDE.md", "docs/AGENTS.md")
    foreach ($file in $files) {
        $measure = Measure-File -Path (Join-Path $WorkspaceRoot $file)
        if ($measure.Exists) {
            $results.Files[$file] = $measure
            $results.TotalTokens += $measure.Tokens
            $results.TotalLines += $measure.Lines
        }
    }
    return $results
}

$config = Load-Config

switch ($Action) {
    "measure" {
        $m = Measure-CurrentState
        Write-Host "`nSystem Prompt Measurements" -ForegroundColor Cyan
        Write-Host "Total: $($m.TotalTokens) tokens, $($m.TotalLines) lines" -ForegroundColor Yellow
        if ($m.TotalTokens -gt 5000) {
            Write-Host "WARNING: Exceeds 5K tokens!" -ForegroundColor Red
        }
    }
    "optimize" {
        $m = Measure-CurrentState
        if ($config) {
            $target = $config.targetTokens
            Write-Host "Target: $target tokens | Current: $($m.TotalTokens) tokens" -ForegroundColor Cyan
        }
        Write-Host "Optimization: $($m.TotalTokens) tokens in $($m.TotalLines) lines" -ForegroundColor Green
    }
    "validate" {
        $issues = @()
        if (-not $config) {
            $issues += "MISSING: config/system-prompt-optimization.json"
        } else {
            if (-not $config.enabled) { $issues += "DISABLED: prompt optimization is off" }
            if ($config.targetTokens -gt $config.maxTokens) {
                $issues += "INVALID: targetTokens ($($config.targetTokens)) > maxTokens ($($config.maxTokens))"
            }
        }
        if (Test-Path $opencodeJsonPath) {
            $oc = Get-Content $opencodeJsonPath -Raw | ConvertFrom-Json
            if ($oc.PSObject.Properties.Name -contains "systemPromptOptimization") {
                $issues += "BREAKS OPENCODE: 'systemPromptOptimization' found in opencode.json — remove it!"
            }
        }
        if ($issues.Count -eq 0) {
            Write-Host "VALID: All checks passed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "ISSUES:" -ForegroundColor Yellow
            $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            return $false
        }
    }
    "config-check" {
        if ($config) {
            Write-Host "Config: $configPath" -ForegroundColor Cyan
            Write-Host "Enabled: $($config.enabled)" -ForegroundColor Green
            Write-Host "Target/Max: $($config.targetTokens)/$($config.maxTokens) tokens"
            Write-Host "Compression: $($config.compression)"
            Write-Host "Cache: $(if($config.cache.enabled){'enabled'}else{'disabled'}) | TTL: $($config.cache.ttl)s"
            Write-Host "Versioning: $(if($config.versioning.enabled){'enabled'}else{'disabled'})"
            Write-Host "Security scan: $(if($config.security.scanOnLoad){'on'}else{'off'})"
            $abbrevCount = ($config.abbreviations.PSObject.Properties).Count
            Write-Host "Abbreviations: $abbrevCount patterns"
            return $true
        } else {
            Write-Host "ERROR: No config found at $configPath" -ForegroundColor Red
            return $false
        }
    }
}
