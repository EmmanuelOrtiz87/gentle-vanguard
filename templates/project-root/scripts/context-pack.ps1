param(
    [string]$Objective = '',
    [int]$MaxChangedFiles = 12,
    [int]$MaxCommits = 8,
    [string]$OutputPath = '',
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

function Get-ChangedFiles {
    param([int]$Limit)

    $lines = git status --porcelain 2>$null
    if (-not $lines) {
        return @()
    }

    $items = @()
    foreach ($line in $lines) {
        if ($line.Length -lt 4) {
            continue
        }

        $status = $line.Substring(0, 2).Trim()
        $path = $line.Substring(3).Trim()

        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $items += "- [$status] $path"
    }

    return $items | Select-Object -First $Limit
}

function Get-RecentCommits {
    param([int]$Limit)

    $lines = git log --oneline -n $Limit 2>$null
    if (-not $lines) {
        return @('- none')
    }

    $items = @()
    foreach ($line in $lines) {
        $items += "- $line"
    }
    return $items
}

$branch = git rev-parse --abbrev-ref HEAD 2>$null
if (-not $branch) {
    $branch = '(unknown)'
}

$changedFiles = Get-ChangedFiles -Limit $MaxChangedFiles
if ($changedFiles.Count -eq 0) {
    $changedFiles = @('- clean working tree')
}

$recentCommits = Get-RecentCommits -Limit $MaxCommits

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$dateTag = Get-Date -Format 'yyyy-MM-dd-HHmm'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $sessionsDir = Join-Path $repoRoot 'docs/sessions'
    if (-not (Test-Path $sessionsDir)) {
        New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
    }
    $OutputPath = Join-Path $sessionsDir "$dateTag-context-pack.md"
}

$objectiveLine = if ([string]::IsNullOrWhiteSpace($Objective)) { '[define objective in one sentence]' } else { $Objective }
$changedSection = ($changedFiles -join [Environment]::NewLine)
$commitSection = ($recentCommits -join [Environment]::NewLine)

$content = @"
# Context Pack

Generated: $timestamp
Repository: $(Split-Path $repoRoot -Leaf)
Branch: $branch

## Objective
$objectiveLine

## Current State
$changedSection

## Recent Commits
$commitSection

## Continue Prompt (Compact)
Use this context and continue the same objective.

Constraints:
- Keep only the last 5-10 chat messages in active context.
- Use this context pack as source of truth for previous state.
- Avoid repeating long instructions unless they changed.
- Prefer short prompts and explicit acceptance criteria.

Request template:
Continue objective: "$objectiveLine".
Apply only minimal required changes.
Validate changes and report concise results.

## Daily Token Control
1. Run `./scripts/context-pack.ps1 "<objective>"` before starting a new thread.
2. Start a fresh chat and paste only this file plus the immediate request.
3. Regenerate a new context pack after major milestones.
"@

Set-Content -Path $OutputPath -Value $content -Encoding UTF8
Write-Host "[OK] Context pack generated: $OutputPath" -ForegroundColor Green
if ($PassThru) {
    Write-Output $OutputPath
}
