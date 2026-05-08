#!/usr/bin/env pwsh
# Compact start - Initialize context tracking for session

param(
    [string]$Objective = "Foundation maintenance"
)

$dataRoot = if ($env:FOUNDATION_DATA_DIR) { $env:FOUNDATION_DATA_DIR } else { "$env:LOCALAPPDATA\Foundation\data" }
$engramData = "$dataRoot\.engram-data"
if (-not (Test-Path $engramData)) {
    New-Item -ItemType Directory -Path $engramData -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$sessionId = "session-$(Get-Date -Format 'yyyy-MM-dd')-$(Get-Random -Minimum 1 -Maximum 99)"

$context = @{
    sessionId = $sessionId
    objective = $Objective
    startTime = $timestamp
    project = "workspace-foundation"
}

$context | ConvertTo-Json | Out-File -FilePath "$engramData\compact-start-$timestamp.json" -Encoding utf8

Write-Output "=== Compact Start Initialized ==="
Write-Output "Session: $sessionId"
Write-Output "Objective: $Objective"
Write-Output "Data dir: $dataRoot"
Write-Output "Context tracking active."
