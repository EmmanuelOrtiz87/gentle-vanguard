param(
    [string]$TaskName,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$projectName = Split-Path $repoRoot -Leaf

function Convert-ToSlug {
    param([string]$Value)
    $slug = $Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) { return 'task' }
    return $slug
}

$sessionsDir = Join-Path $repoRoot 'docs\sessions'
$tasksDir = Join-Path $repoRoot 'docs\tasks'
New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null

$branch = git rev-parse --abbrev-ref HEAD 2>$null
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = 'unknown' }
$gitStatus = git status --short 2>$null
$gitState = if ([string]::IsNullOrWhiteSpace(($gitStatus -join '').Trim())) { 'clean' } else { 'has uncommitted changes' }

$sessionFile = Join-Path $sessionsDir ("{0}-session-start.md" -f (Get-Date -Format 'yyyy-MM-dd-HHmmss'))
if ((Test-Path $sessionFile) -and -not $Force) {
    $sessionFile = Join-Path $sessionsDir ("{0}-session-start-{1}.md" -f (Get-Date -Format 'yyyy-MM-dd'), (Get-Date -Format 'HHmmss'))
}

$taskNote = "- Task brief: create if the session scope is non-trivial"
if (-not [string]::IsNullOrWhiteSpace($TaskName)) {
    $taskFile = Join-Path $tasksDir ((Convert-ToSlug -Value $TaskName) + '.md')
    @"
# Task Brief: $TaskName

## Goal

- Problem to solve:
- Desired outcome:

## Scope

- In scope:
- Out of scope:

## Key Files

- Primary implementation files:
- Validation files:
- Documentation files:

## Acceptance Criteria

- [ ] Behavior is implemented
- [ ] Focused validation passes
- [ ] Documentation updated if needed
"@ | Out-File -FilePath $taskFile -Encoding UTF8
    $taskNote = "- Task brief: $taskFile"
}

@"
# Session Start Brief

## Context

- Project: $projectName
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- Branch: $branch
- Git state: $gitState

## Objective

- Primary goal for this session:
- Expected outcome at handoff:

## Working Set

- Primary files or directories:
- Related decisions or documents:
- Known blockers or assumptions:

## Acceptance Criteria

- [ ] Scope is clear and bounded
- [ ] Validation command is known before editing
- [ ] Documentation impact is identified
- [ ] Repository publication expectation is clear

## Notes

$taskNote
"@ | Out-File -FilePath $sessionFile -Encoding UTF8

Write-Host "Session brief created: $sessionFile" -ForegroundColor Green