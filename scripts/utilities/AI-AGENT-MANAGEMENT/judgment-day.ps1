#!/usr/bin/env pwsh
# judgment-day.ps1
# Dual review orchestration with bounded passes and user confirmation.
# Usage: .\judgment-day.ps1 [-Target <path>] [-MaxPasses <n>] [-Scope <Full|Quick>] [-NoPrompt]

param(
    [string]$Target = ".",
    [ValidateRange(1,10)]
    [int]$MaxPasses = 3,
    [ValidateSet('Full','Quick')]
    [string]$Scope = 'Full',
    [switch]$NoPrompt
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

$judgmentScript = Join-Path $scriptDir 'invoke-judgment.ps1'
if (-not (Test-Path $judgmentScript)) {
    Write-Host "[ERROR] invoke-judgment.ps1 not found: $judgmentScript" -ForegroundColor Red
    exit 1
}

function Write-Title {
    param([string]$Text)
    Write-Host "";
    Write-Host "============================================================================" -ForegroundColor Magenta
    Write-Host " $Text" -ForegroundColor Magenta
    Write-Host "============================================================================" -ForegroundColor Magenta
}

function Write-PassSummary {
    param(
        [int]$Pass,
        [bool]$Approved,
        [array]$Warnings,
        [array]$Suggestions
    )

    Write-Host "";
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host " PASS $Pass - Results" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host " Verdict: $(if ($Approved) { 'APPROVED' } else { 'REQUIRES ATTENTION' })" -ForegroundColor $(if ($Approved) { 'Green' } else { 'Yellow' })

    if ($Warnings.Count -gt 0) {
        Write-Host " Warnings:" -ForegroundColor Yellow
        foreach ($w in $Warnings) {
            Write-Host "   - $w" -ForegroundColor Yellow
        }
    }

    if ($Suggestions.Count -gt 0) {
        Write-Host " Suggestions:" -ForegroundColor Cyan
        foreach ($s in $Suggestions) {
            Write-Host "   - $s" -ForegroundColor Cyan
        }
    }
}

function Get-JudgmentSignals {
    param([string]$Stdout)

    $warnings = @()
    $suggestions = @()

    foreach ($line in ($Stdout -split "`r?`n")) {
        if ($line -match '(?i)\[WARN\]|warning') {
            $warnings += $line.Trim()
        }
        if ($line -match '(?i)suggestion|recommend|next step') {
            $suggestions += $line.Trim()
        }
    }

    return @{
        Warnings = @($warnings | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
        Suggestions = @($suggestions | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    }
}

function Has-BlockingIssues {
    param([string]$Stdout)

    $text = $Stdout.ToLowerInvariant()

    if ($text -match 'connection failed|unauthorized|credential|api[_ -]?key|auth failed|bedrock') {
        return $false
    }

    if ($text -match '\[fail\]|verdict:\s*rejected|critical|error') {
        return $true
    }

    return $false
}

function Is-ScopeApproved {
    param(
        [string]$ScopeName,
        [string]$Stdout,
        [int]$ExitCode
    )

    if ($ScopeName -eq 'Quick') {
        return ($ExitCode -eq 0)
    }

    $hasBlocking = Has-BlockingIssues -Stdout $Stdout
    return ($ExitCode -eq 0 -and -not $hasBlocking)
}

Write-Title "JUDGMENT DAY - Bounded Pass Mode"
Write-Host " Target: $Target" -ForegroundColor Cyan
Write-Host " Scope: $Scope" -ForegroundColor Cyan
Write-Host " Max Passes: $MaxPasses" -ForegroundColor Cyan
Write-Host " Connection/Credential errors are advisory warnings (non-blocking)." -ForegroundColor DarkGray

$pass = 1
$approved = $false
$history = @()

while ($pass -le $MaxPasses) {
    Write-Host "";
    Write-Host "[JUDGMENT] Starting pass $pass/$MaxPasses..." -ForegroundColor Cyan

    if ($pass -gt 1) {
        $output = & $judgmentScript -Scope $Scope -Remediate -MaxIterations 1 2>&1 | Out-String
    } else {
        $output = & $judgmentScript -Scope $Scope 2>&1 | Out-String
    }
    $exitCode = $LASTEXITCODE

    $signals = Get-JudgmentSignals -Stdout $output
    $hasBlocking = Has-BlockingIssues -Stdout $output
    $approved = Is-ScopeApproved -ScopeName $Scope -Stdout $output -ExitCode $exitCode

    $history += [pscustomobject]@{
        pass = $pass
        exitCode = $exitCode
        approved = $approved
        blocking = $hasBlocking
        warnings = $signals.Warnings
        suggestions = $signals.Suggestions
    }

    Write-PassSummary -Pass $pass -Approved $approved -Warnings $signals.Warnings -Suggestions $signals.Suggestions

    if ($approved) {
        break
    }

    if ($pass -ge $MaxPasses) {
        break
    }

    if ($NoPrompt) {
        $pass++
        continue
    }

    Write-Host "";
    Write-Host "Choose next action:" -ForegroundColor Cyan
    Write-Host "  1) Run another pass" -ForegroundColor Yellow
    Write-Host "  2) Stop and keep current findings" -ForegroundColor Yellow
    Write-Host "  3) Stop and apply manual fixes first" -ForegroundColor Yellow
    $choice = Read-Host "Option (1/2/3)"

    if ($choice -ne '1') {
        break
    }

    $pass++
}

Write-Host "";
Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host " JUDGMENT RUN SUMMARY" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------" -ForegroundColor Yellow
foreach ($item in $history) {
    Write-Host " Pass $($item.pass): approved=$($item.approved) exit=$($item.exitCode) blocking=$($item.blocking)" -ForegroundColor Gray
}

if ($approved) {
    Write-Host "";
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host " JUDGMENT: APPROVED" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    exit 0
}

Write-Host "";
Write-Host "============================================================================" -ForegroundColor Yellow
Write-Host " JUDGMENT: ATTENTION REQUIRED" -ForegroundColor Yellow
Write-Host " Max passes reached or stopped by user. Review warnings/suggestions above." -ForegroundColor Yellow
Write-Host "============================================================================" -ForegroundColor Yellow
exit 1
