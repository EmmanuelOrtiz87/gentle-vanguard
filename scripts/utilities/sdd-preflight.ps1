param(
    [switch]$Interactive,
    [switch]$Quiet,
    [string]$SessionDir = ""
)

$ErrorActionPreference = "Stop"

if (-not $SessionDir) {
    $SessionDir = Join-Path (Resolve-Path ".") "scripts" ".session"
}
if (-not (Test-Path $SessionDir)) { New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null }

$preflightFile = Join-Path $SessionDir "sdd-preflight.json"

# --- Defaults ---
$defaults = @{
    Version = "1.0"
    CreatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    ExecutionMode = "interactive"   # interactive | auto
    ArtifactStore = "openspec"      # openspec | engram | both
    PRStrategy = "ask-always"       # auto-forecast | ask-always | single-pr-default | force-chained
    ReviewBudget = 400              # max changed lines before recommending chained PRs
    StrictTDD = $true
}

# --- Check if already exists (session reuse) ---
if (Test-Path $preflightFile) {
    $existing = Get-Content $preflightFile -Raw | ConvertFrom-Json
    $sessionAge = [DateTime]::Now - [DateTime]::Parse($existing.CreatedAt)
    if ($sessionAge.TotalHours -lt 12) {
        if (-not $Quiet) {
            Write-Host "[SDD-PREFLIGHT] Reusing session preflight from $($existing.CreatedAt)"
            Write-Host "[SDD-PREFLIGHT] Mode: $($existing.ExecutionMode) | Store: $($existing.ArtifactStore) | PR: $($existing.PRStrategy) | Budget: $($existing.ReviewBudget) lines"
        }
        return $existing
    } else {
        Write-Host "[SDD-PREFLIGHT] Session preflight expired ($([Math]::Round($sessionAge.TotalHours, 1))h old) — refreshing"
    }
}

# --- Interactive mode ---
if ($Interactive) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗"
    Write-Host "║      SDD Preflight Configuration     ║"
    Write-Host "╚══════════════════════════════════════╝"
    Write-Host ""

    $mode = Read-Host "Execution mode [interactive/auto] (default: $($defaults.ExecutionMode))"
    if (-not $mode) { $mode = $defaults.ExecutionMode }

    $store = Read-Host "Artifact store [openspec/engram/both] (default: $($defaults.ArtifactStore))"
    if (-not $store) { $store = $defaults.ArtifactStore }

    $prStrategy = Read-Host "PR strategy [auto-forecast/ask-always/single-pr-default/force-chained] (default: $($defaults.PRStrategy))"
    if (-not $prStrategy) { $prStrategy = $defaults.PRStrategy }

    $budgetStr = Read-Host "Review budget (max lines per PR) (default: $($defaults.ReviewBudget))"
    $budget = if ($budgetStr) { [int]$budgetStr } else { $defaults.ReviewBudget }

    $tddStr = Read-Host "Strict TDD [y/n] (default: y)"
    $tdd = $tddStr -ne "n"

    $config = @{
        Version = $defaults.Version
        CreatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        ExecutionMode = $mode
        ArtifactStore = $store
        PRStrategy = $prStrategy
        ReviewBudget = $budget
        StrictTDD = $tdd
    }
} else {
    $config = $defaults
}

$config | ConvertTo-Json | Set-Content -Path $preflightFile -Encoding UTF8

if (-not $Quiet) {
    Write-Host "[SDD-PREFLIGHT] Saved: $preflightFile"
    Write-Host "[SDD-PREFLIGHT] Mode: $($config.ExecutionMode) | Store: $($config.ArtifactStore) | PR: $($config.PRStrategy) | Budget: $($config.ReviewBudget) lines"
    if ($config.StrictTDD) { Write-Host "[SDD-PREFLIGHT] Strict TDD: ENABLED" }
}

return $config
