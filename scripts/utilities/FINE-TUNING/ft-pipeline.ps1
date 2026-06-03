param(
    [ValidateSet("full","collect","build","train","eval")]
    [string]$Stage = "full",
    [ValidateSet("BA","SAD","DEV","QA","")]
    [string]$Domain = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$ftDir = Join-Path $ProjectRoot "scripts" "utilities" "FINE-TUNING"

Write-Host "=== FT Pipeline ===" -ForegroundColor Cyan
Write-Host "Stage: $Stage"
$startTime = Get-Date

function Run-Stage {
    param([string]$Name, [string]$Script, [string]$ScriptArgs)
    Write-Host "`n[PIPELINE] Running $Name..." -ForegroundColor Yellow
    $scriptPath = Join-Path $ftDir $Script
    if (-not (Test-Path $scriptPath)) {
        Write-Host "[PIPELINE] Script not found: $scriptPath" -ForegroundColor Red
        return $false
    }
    $cmd = "& '$scriptPath' $ScriptArgs"
    try {
        $output = Invoke-Expression $cmd
        Write-Host "[PIPELINE] $Name completed" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[PIPELINE] $Name failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

$domainArg = if ($Domain) { "-Domain $Domain" } else { "" }
$forceArg = if ($Force) { "-Force" } else { "" }

switch ($Stage) {
    "collect" {
        Run-Stage -Name "Data Collection" -Script "ft-data-collector.ps1" -ScriptArgs "-Source all $forceArg"
    }
    "build" {
        Run-Stage -Name "Dataset Builder" -Script "ft-dataset-builder.ps1" -ScriptArgs "$forceArg"
    }
    "train" {
        Run-Stage -Name "Trainer" -Script "ft-trainer.ps1" -ScriptArgs "$domainArg -Mode dry-run $forceArg"
    }
    "eval" {
        Run-Stage -Name "Evaluator" -Script "ft-evaluator.ps1" -ScriptArgs "-CompareBaseline $forceArg"
    }
    "full" {
        $ok = Run-Stage -Name "Data Collection" -Script "ft-data-collector.ps1" -ScriptArgs "-Source all $forceArg"
        if (-not $ok) { Write-Host "[PIPELINE] Aborting after collect failure" -ForegroundColor Red; exit 1 }
        $ok = Run-Stage -Name "Dataset Builder" -Script "ft-dataset-builder.ps1" -ScriptArgs "$forceArg"
        if (-not $ok) { Write-Host "[PIPELINE] Aborting after build failure" -ForegroundColor Red; exit 1 }
        if ($Domain) { Run-Stage -Name "Trainer (dry-run)" -Script "ft-trainer.ps1" -ScriptArgs "$domainArg -Mode dry-run $forceArg" }
        else { Write-Host "[PIPELINE] Skipping trainer (no domain specified). Use: -Domain BA|SAD|DEV|QA" -ForegroundColor Gray }
        Run-Stage -Name "Evaluator" -Script "ft-evaluator.ps1" -ScriptArgs "-CompareBaseline $forceArg"
    }
}

$elapsed = (Get-Date) - $startTime
Write-Host "`n[PIPELINE] Complete in $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
