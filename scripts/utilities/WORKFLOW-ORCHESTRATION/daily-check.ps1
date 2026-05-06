#!/usr/bin/env pwsh
# Daily check - Quick status for daily workflow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wfPath = Join-Path $scriptDir "wf.ps1"

Write-Output "=== Daily Foundation Check ==="
Write-Output ""

# Git status
Write-Output "📍 Git Status:"
& git status --short
Write-Output ""

# Quick verify
Write-Output "✅ Stack Health:"
& $wfPath verify 2>&1 | Select-Object -First 15
Write-Output ""

# Context efficiency
Write-Output "📊 Context Efficiency:"
& $wfPath status 2>&1 | Select-Object -First 10
Write-Output ""

Write-Output "=== Ready for daily work ==="
