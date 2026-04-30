param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("status", "optimize", "reset")]
    [string]$Action = "status",

    [Parameter(Mandatory=$false)]
    [ValidateSet("session-start", "session-close", "manual")]
    [string]$Trigger = "manual",

    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$scalingDbPath = Join-Path $repoRoot ".session\scaling-db.json"

function Write-Scale { param([string]$msg) Write-Host "[SCALING]" -NoNewline -ForegroundColor Green; Write-Host " $msg" -ForegroundColor White }
function Write-ScaleOk { param([string]$msg) Write-Host "[SCALE-OK]" -NoNewline -ForegroundColor Green; Write-Host " $msg" -ForegroundColor Gray }
function Write-ScaleWarn { param([string]$msg) Write-Host "[SCALE-WARN]" -NoNewline -ForegroundColor Yellow; Write-Host " $msg" -ForegroundColor Gray }

function Get-ScalingDb {
    if (Test-Path $scalingDbPath) {
        try {
            $content = Get-Content $scalingDbPath -Raw -ErrorAction Stop
            return $content | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-ScaleWarn "Corrupted DB, creating new"
        }
    }
    
    return @{
        patterns = @{
            "code-fix" = @{ subagent = "sdd-apply"; success = 0; total = 0; confidence = "low" }
            "doc-update" = @{ subagent = "sdd-apply"; success = 0; total = 0; confidence = "low" }
            "research" = @{ subagent = "explore"; success = 0; total = 0; confidence = "low" }
            "test-fix" = @{ subagent = "sdd-verify"; success = 0; total = 0; confidence = "low" }
            "general-task" = @{ subagent = "general"; success = 0; total = 0; confidence = "low" }
        }
        history = @()
    }
}

function Set-ScalingDb {
    param($Db)
    
    $dbDir = Split-Path $scalingDbPath
    if (-not (Test-Path $dbDir)) {
        New-Item -Path $dbDir -ItemType Directory -Force | Out-Null
    }
    
    $Db | ConvertTo-Json -Depth 10 | Out-File -FilePath $scalingDbPath -Encoding UTF8
}

function Show-Status {
    Write-Host ""
    Write-Host "" -ForegroundColor Green
    Write-Host "  AUTO-SCALING DELEGATION STATUS                           " -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host ""
    
    $db = Get-ScalingDb
    
    Write-Scale "Patterns learned: $($db.patterns.Count)"
    Write-Scale "History entries: $($db.history.Count)"
    Write-Host ""
    
    Write-Host "Pattern -> Best Subagent (Confidence / Success Rate):" -ForegroundColor White
    
    foreach ($key in $db.patterns.Keys) {
        $pattern = $db.patterns[$key]
        $rate = 0
        if ($pattern.total -gt 0) { $rate = [math]::Round(($pattern.success / $pattern.total), 2) }
        $color = switch ($pattern.confidence) {
            "high" { "Green" }
            "medium" { "Yellow" }
            "low" { "Gray" }
            default { "White" }
        }
        Write-Host "  $key -> $($pattern.subagent)" -ForegroundColor White -NoNewline
        Write-Host " ($($pattern.confidence), rate: $rate, total: $($pattern.total))" -ForegroundColor $color
    }
    
    Write-Host ""
    
    if ($db.history.Count -gt 0) {
        Write-Host "Recent History (last 5):" -ForegroundColor Gray
        $db.history | Select-Object -Last 5 | ForEach-Object {
            $status = if ($_.success) { "" } else { "" }
            Write-Host "  $status $($_.pattern) -> $($_.subagent) (rate: $($_.successRate))" -ForegroundColor Gray
        }
    }
    
    return @{ status = "SUCCESS"; patterns = $db.patterns.Count; history = $db.history.Count }
}

$result = $null
switch ($Action) {
    "status" { $result = Show-Status }
    "optimize" {
        Write-Scale "Running optimization..."
        $db = Get-ScalingDb
        $optimized = 0
        
        foreach ($key in $db.patterns.Keys) {
            $pattern = $db.patterns[$key]
            if ($pattern.total -ge 5) {
                $rate = 0
                if ($pattern.total -gt 0) { $rate = $pattern.success / $pattern.total }
                if ($rate -ge 0.8 -and $pattern.confidence -ne "high") {
                    $pattern.confidence = "high"
                    $optimized++
                    Write-Scale "Optimized: $key (high confidence)"
                }
            }
        }
        
        Set-ScalingDb -Db $db
        Write-ScaleOk "Optimization complete: $optimized pattern(s) updated"
        $result = @{ status = "SUCCESS"; optimized = $optimized }
    }
    "reset" {
        if (Test-Path $scalingDbPath) {
            Remove-Item $scalingDbPath -Force
            Write-ScaleOk "Scaling database reset"
        }
        $result = @{ status = "RESET"; patterns = 0; history = 0 }
    }
}

if ($Trigger -eq "session-close") {
    Write-Scale "Auto-optimizing at session close..."
    $optResult = Show-Status
    Write-Scale "Status: $($optResult.status)"
}

return $result


