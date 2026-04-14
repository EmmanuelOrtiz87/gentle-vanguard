param(
    [string]$Objective = '',
    [int]$MaxChangedFiles = 12,
    [int]$MaxCommits = 8,
    [string]$OutputPath = '',
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

function Write-Metric {
    param(
        [string]$Event,
        [string]$Objective,
        [int]$ChangedCount,
        [int]$PromptChars,
        [string]$OutputFile
    )

    $metricsDir = Join-Path $repoRoot 'docs/sessions/metrics'
    if (-not (Test-Path $metricsDir)) {
        New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    }

    $metricsFile = Join-Path $metricsDir 'context-usage.csv'
    if (-not (Test-Path $metricsFile)) {
        'timestamp,event,repository,branch,objective_chars,changed_count,prompt_chars,output_file' | Set-Content -Path $metricsFile -Encoding UTF8
    }

    $branchName = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branchName) { $branchName = '(unknown)' }

    $line = ('{0},{1},{2},{3},{4},{5},{6},{7}' -f
        (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'),
        $Event,
        (Split-Path $repoRoot -Leaf),
        $branchName,
        $Objective.Length,
        $ChangedCount,
        $PromptChars,
        $OutputFile.Replace(',', ';')
    )

    Add-Content -Path $metricsFile -Value $line -Encoding UTF8
}

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

function Get-CustomRulesDigest {
    $rulesScript = Join-Path $PSScriptRoot 'custom-rules.ps1'
    if (-not (Test-Path $rulesScript)) {
        return '- custom rules script not found'
    }

    try {
        $digest = & $rulesScript -Mode export -PassThru -Quiet
        if ([string]::IsNullOrWhiteSpace(($digest | Out-String).Trim())) {
            return '- no custom rules loaded'
        }
        return ($digest | Out-String).Trim()
    }
    catch {
        return '- failed to load custom rules digest'
    }
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
$dateTag = Get-Date -Format 'yyyy-MM-dd-HHmmss'

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
$customRulesSection = Get-CustomRulesDigest

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

## Custom Rules (Loaded)
$customRulesSection

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
1. Run `wf.ps1 context-pack "<objective>"` before starting a new thread.
2. Start a fresh chat and paste only this file plus the immediate request.
3. Regenerate a new context pack after major milestones.
"@

Set-Content -Path $OutputPath -Value $content -Encoding UTF8
Write-Host "[OK] Context pack generated: $OutputPath" -ForegroundColor Green
Write-Metric -Event 'context-pack' -Objective $objectiveLine -ChangedCount $changedFiles.Count -PromptChars $content.Length -OutputFile $OutputPath
if ($PassThru) {
    Write-Output $OutputPath
}
