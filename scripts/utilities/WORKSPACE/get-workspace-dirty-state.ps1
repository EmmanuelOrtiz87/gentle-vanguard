#!/usr/bin/env pwsh
param(
    [string]$RepoRoot = '.',
    [switch]$AsJson
)

$ErrorActionPreference = 'SilentlyContinue'

function Get-StatusPath {
    param([string]$StatusLine)

    if ([string]::IsNullOrWhiteSpace($StatusLine) -or $StatusLine.Length -lt 4) {
        return $null
    }

    $pathPart = $StatusLine.Substring(3).Trim()
    if ($pathPart -match ' -> ') {
        $pathPart = ($pathPart -split ' -> ')[-1].Trim()
    }

    if ($pathPart.StartsWith('"') -and $pathPart.EndsWith('"')) {
        $pathPart = $pathPart.Substring(1, $pathPart.Length - 2)
    }

    return ($pathPart -replace '\\', '/')
}

$operationalPatterns = @(
    '^\.cline/config\.json$',
    '^\.claude/settings\.json$',
    '^\.clinerules$',
    '^scripts/\.session/.*$',
    '^\.session/metrics/current-session\.json$',
    '^docs/code-reviews/\d{4}-\d{2}-\d{2}-\d{6}-all-review\.md$'
)

$statusLines = @(git -C $RepoRoot status --porcelain 2>$null)
$allDirty = @()
$operationalDirty = @()
$userDirty = @()

foreach ($line in $statusLines) {
    $normalizedPath = Get-StatusPath -StatusLine ([string]$line)
    if ([string]::IsNullOrWhiteSpace($normalizedPath)) {
        continue
    }

    $allDirty += $normalizedPath
    $isOperational = $false
    foreach ($pattern in $operationalPatterns) {
        if ($normalizedPath -match $pattern) {
            $isOperational = $true
            break
        }
    }

    if ($isOperational) {
        $operationalDirty += $normalizedPath
    } else {
        $userDirty += $normalizedPath
    }
}

$state = 'clean'
if ($userDirty.Count -gt 0) {
    $state = 'dirty-user'
} elseif ($operationalDirty.Count -gt 0) {
    $state = 'dirty-operational'
}

$result = [pscustomobject]@{
    state = $state
    totalDirtyCount = $allDirty.Count
    userDirtyCount = $userDirty.Count
    operationalDirtyCount = $operationalDirty.Count
    userDirtyFiles = $userDirty
    operationalDirtyFiles = $operationalDirty
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 6
} else {
    $result.state
}

exit 0