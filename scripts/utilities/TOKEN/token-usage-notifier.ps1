param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("show","accumulate","summary","toggle","status","auto")]
    [string]$Action,
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [int]$ContextChars = 0,
    [string]$SessionId = "",
    [string]$Model = "",
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Get-Location }

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $candidate = $scriptRoot
    for ($i = 0; $i -le 10; $i++) {
        if (Test-Path (Join-Path $candidate "config\orchestrator.json")) { $candidate; break }
        $parent = Split-Path -Parent $candidate
        if (-not $parent -or $parent -eq $candidate) { break }
        $candidate = $parent
    }
}
if (-not $repoRoot -or -not (Test-Path (Join-Path $repoRoot "config\orchestrator.json"))) { $repoRoot = (Get-Location).Path }

$stateDir = Join-Path $repoRoot ".runtime"
$stateFile = Join-Path $stateDir "token-notifier-state.json"

if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }

function Get-State {
    $default = Create-DefaultState
    if (Test-Path $stateFile) {
        try {
            $loaded = Get-Content -Path $stateFile -Raw | ConvertFrom-Json
            foreach ($prop in $default.PSObject.Properties) {
                if (-not $loaded.PSObject.Properties.Name.Contains($prop.Name)) {
                    $loaded | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
                }
            }
            return $loaded
        } catch { Write-Warning "Failed to read state: $($_.Exception.Message)" }
    }
    return $default
}

function Save-State($state) {
    try { $state | ConvertTo-Json | Set-Content -Path $stateFile -Force } catch { Write-Warning "Failed to save state: $($_.Exception.Message)" }
}

function Create-DefaultState {
    return [PSCustomObject]@{
        TotalInputTokens = 0
        TotalOutputTokens = 0
        TotalCost = 0.0
        ResponseCount = 0
        SessionStart = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        LastUpdate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Enabled = $true
        SessionId = ""
        Model = ""
    }
}

function Get-InputCost($tokens) { return [math]::Round(($tokens / 1000) * 0.03, 4) }
function Get-OutputCost($tokens) { return [math]::Round(($tokens / 1000) * 0.06, 4) }

function Show-Usage {
    Write-Host "`n[Token Usage]" -ForegroundColor Cyan
    Write-Host "  Input tokens:  $InputTokens  (cost: $(Get-InputCost $InputTokens) USD)" -ForegroundColor Green
    Write-Host "  Output tokens: $OutputTokens  (cost: $(Get-OutputCost $OutputTokens) USD)" -ForegroundColor Green
    if ($ContextChars -gt 0) { Write-Host "  Context chars: $ContextChars" -ForegroundColor Cyan }
    $totalCost = (Get-InputCost $InputTokens) + (Get-OutputCost $OutputTokens)
    if ($totalCost -gt 0) {
        Write-Host "  Estimated cost: $([math]::Round($totalCost, 4)) USD" -ForegroundColor Yellow
    }
    if ($Model) { Write-Host "  Model: $Model" -ForegroundColor Cyan }
    Write-Host ""
}

function Accumulate-Usage {
    $state = Get-State
    $state.TotalInputTokens += $InputTokens
    $state.TotalOutputTokens += $OutputTokens
    $inputCost = Get-InputCost $InputTokens
    $outputCost = Get-OutputCost $OutputTokens
    $state.TotalCost = [math]::Round($state.TotalCost + $inputCost + $outputCost, 4)
    $state.ResponseCount += 1
    $state.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($SessionId) { $state.SessionId = $SessionId }
    if ($Model) { $state.Model = $Model }
    Save-State $state
    if (-not $Silent) { Show-Usage }
}

function Show-Summary {
    $state = Get-State
    Write-Host "`n[Token Usage Summary]" -ForegroundColor Cyan
    Write-Host "  Session start:    $($state.SessionStart)" -ForegroundColor Gray
    Write-Host "  Last update:      $($state.LastUpdate)" -ForegroundColor Gray
    Write-Host "  Total responses:  $($state.ResponseCount)" -ForegroundColor Green
    Write-Host "  Total input:      $($state.TotalInputTokens) tokens" -ForegroundColor Green
    Write-Host "  Total output:     $($state.TotalOutputTokens) tokens" -ForegroundColor Green
    $avgInput = if ($state.ResponseCount -gt 0) { [math]::Round($state.TotalInputTokens / $state.ResponseCount, 0) } else { 0 }
    $avgOutput = if ($state.ResponseCount -gt 0) { [math]::Round($state.TotalOutputTokens / $state.ResponseCount, 0) } else { 0 }
    Write-Host "  Avg input/req:    $avgInput tokens" -ForegroundColor Gray
    Write-Host "  Avg output/req:   $avgOutput tokens" -ForegroundColor Gray
    Write-Host "  Total cost:       $($state.TotalCost) USD" -ForegroundColor Yellow
    if ($state.ResponseCount -gt 0) {
        $avgCost = [math]::Round($state.TotalCost / $state.ResponseCount, 4)
        Write-Host "  Avg cost/req:     $avgCost USD" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Show-Status {
    $state = Get-State
    Write-Host "`n[Token Notifier Status]" -ForegroundColor Cyan
    Write-Host "  State file:       $stateFile" -ForegroundColor Gray
    Write-Host "  Enabled:          $($state.Enabled)" -ForegroundColor Green
    Write-Host "  Session:          $(if ($state.SessionId) { $state.SessionId } else { 'default' })" -ForegroundColor Cyan
    Write-Host "  Responses logged: $($state.ResponseCount)" -ForegroundColor Green
    Write-Host "  Total cost:       $($state.TotalCost) USD" -ForegroundColor Yellow
    if (Test-Path $stateFile) {
        $size = (Get-Item $stateFile).Length
        Write-Host "  State file size:  $size bytes" -ForegroundColor Gray
    }
    Write-Host ""
}

function Toggle-Enabled {
    $state = Get-State
    $state.Enabled = -not $state.Enabled
    $state.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-State $state
    $msg = if ($state.Enabled) { "enabled" } else { "disabled" }
    Write-Host "Token notification $msg" -ForegroundColor Cyan
}

switch ($Action) {
    "show"       { Show-Usage }
    "accumulate" { Accumulate-Usage }
    "summary"    { Show-Summary }
    "status"     { Show-Status }
    "toggle"     { Toggle-Enabled }
    "auto"       { Accumulate-Usage; Show-Summary }
}
