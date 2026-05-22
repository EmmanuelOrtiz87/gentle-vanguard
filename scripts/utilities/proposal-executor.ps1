param(
    [switch]$AutoApply,
    [switch]$CreatePR,
    [string]$ProposalId,
    [string]$ProposalsDir = ".local\improvement-proposals"
)

$ErrorActionPreference = "Stop"
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Get-Location
}
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
$proposalsPath = Join-Path $repoRoot $ProposalsDir

function Write-Info  { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Ok   { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Hit  { Write-Host "[HIT] $args" -ForegroundColor Yellow }
function Write-Err  { Write-Host "[ERR] $args" -ForegroundColor Red }
function Write-Step { Write-Host "`n=== $args ===" -ForegroundColor Magenta }

# --- Executors ---

function Invoke-SkillScaffold {
    param($Proposal)
    $domain = if ($Proposal.domain) { $Proposal.domain } else { $Proposal.id -replace 'prop-\d+-\d+-', '' }
    $skillDir = Join-Path $repoRoot (Join-Path "skills" (Join-Path "business" $domain))
    $skillFile = Join-Path $skillDir "SKILL.md"
    if (Test-Path $skillFile) {
        Write-Info "Skill already exists: $skillFile"
        return $true
    }
    $null = New-Item -ItemType Directory -Path $skillDir -Force
    $displayName = $domain -replace '-', ' '
    $displayName = (Get-Culture).TextInfo.ToTitleCase($displayName)
    @"
---
name: $domain-skill
description: >
  $displayName domain expertise — add specific description.
  Trigger: "$domain"
license: Apache-2.0
metadata:
  author: gv version: '1.0'
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
---

# $displayName Skill

## When to Use
User asks about $domain topics.

## Core Concepts
- TODO: Add domain-specific concepts

## Response Patterns
- TODO: Add expected response patterns

## Key Metrics / KPIs
- TODO: Add domain-specific metrics

## Regulatory Considerations
- TODO: Add relevant regulations

---
*Auto-generated from learning proposal: $($Proposal.id)*
"@ | Set-Content -Path $skillFile -Encoding UTF8
    Write-Ok "Created skill: $skillFile"
    return $true
}

function Invoke-ConfigPatch {
    param($Proposal)
    Write-Hit "Config patch not yet implemented: $($Proposal.description)"
    return $false
}

function Invoke-ScriptCreate {
    param($Proposal)
    Write-Hit "Script creation not yet implemented: $($Proposal.description)"
    return $false
}

# --- Dispatcher ---

function Invoke-Executor {
    param($Proposal)
    $executors = @{
        "missing-skill"      = ${function:Invoke-SkillScaffold}
        "config-gap"         = ${function:Invoke-ConfigPatch}
        "pattern-opportunity" = ${function:Invoke-ScriptCreate}
    }
    $exec = $executors[$Proposal.category]
    if (-not $exec) {
        Write-Info "No executor for category '$($Proposal.category)'"
        return $false
    }
    return & $exec -Proposal $Proposal
}

# --- Main ---

Write-Step "Proposal Executor"

if (-not (Test-Path $proposalsPath)) {
    Write-Info "No proposals directory at $proposalsPath"
    exit 0
}

$proposals = if ($ProposalId) {
    $file = Join-Path $proposalsPath "$ProposalId.json"
    if (Test-Path $file) { @(Get-Content $file -Raw | ConvertFrom-Json) }
    else { Write-Err "Proposal not found: $ProposalId"; exit 1 }
} else {
    @(Get-ChildItem -Path $proposalsPath -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($AutoApply) { $p }
        elseif (-not $p.applied) { $p }
    })
}

if ($proposals.Count -eq 0) {
    Write-Ok "No pending proposals to execute"
    exit 0
}

$applied = @()
$errors = @()

foreach ($p in $proposals) {
    Write-Step "Proposal: $($p.id) [$($p.category)]"
    Write-Info "$($p.description)"
    $ok = Invoke-Executor -Proposal $p
    if ($ok) {
        $p | Add-Member -NotePropertyName 'applied' -NotePropertyValue $true -Force
        $p | Add-Member -NotePropertyName 'appliedAt' -NotePropertyValue (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") -Force
        $p | ConvertTo-Json | Set-Content -Path (Join-Path $proposalsPath "$($p.id).json") -Encoding UTF8
        $applied += $p.id
        Write-Ok "Applied: $($p.id)"
    } else {
        $errors += $p.id
        Write-Err "Failed: $($p.id)"
    }
}

# Git ops
if ($applied.Count -gt 0 -and $CreatePR) {
    Write-Step "Creating git branch + commit"
    $branchName = "auto-improve/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    & "git" "checkout", "-b", $branchName
    foreach ($id in $applied) {
        & "git" "add", "-A"
    }
    & "git" "commit", "-m", "auto: apply $($applied.Count) learning proposal(s): $($applied -join ', ')"
    Write-Ok "Branch: $branchName"
    Write-Hit "Push and create PR manually or use --create-pr"
}

Write-Step "Summary"
Write-Ok "Applied: $($applied.Count)"
if ($errors.Count -gt 0) { Write-Err "Errors: $($errors.Count)" }
Write-Ok "Pending: $((Get-ChildItem $proposalsPath -Filter '*.json' | ForEach-Object {
    $p = Get-Content $_.FullName -Raw | ConvertFrom-Json
    if (-not $p.applied) { $_ }
}).Count)"

