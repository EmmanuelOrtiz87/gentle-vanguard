<#
.SYNOPSIS
    Validates README.md files against the governance policy in rules/README-GOVERNANCE.md
.DESCRIPTION
    Checks that mandatory sections exist, stats are accurate, Mermaid diagrams are present,
    badges are correct, and no content has been reduced below minimum thresholds.
.PARAMETER Repo
    Which repo to validate: 'private' (gentle-vanguard), 'public' (gentle-vanguard-public), or 'both'
.PARAMETER Strict
    If set, fails on warnings (missing recommended content) as well as errors
.EXAMPLE
    .\validate-readme.ps1 -Repo both
.EXAMPLE
    .\validate-readme.ps1 -Repo private -Strict
#>

[CmdletBinding()]
param(
    [ValidateSet('private', 'public', 'both')]
    [string]$Repo = 'both',
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

$repoRoot = $null
if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path (Join-Path $env:GENTLE_VANGUARD_BASE_DIR 'config/orchestrator.json'))) {
    $repoRoot = $env:GENTLE_VANGUARD_BASE_DIR
}
if (-not $repoRoot) {
    $candidate = $PSScriptRoot
    while ($candidate) {
        if (Test-Path (Join-Path $candidate 'config/orchestrator.json')) {
            $repoRoot = $candidate
            break
        }
        $parent = Split-Path $candidate -Parent
        if ($parent -eq $candidate) { break }
        $candidate = $parent
    }
}
if (-not $repoRoot) {
    Write-Host "[ERROR] Cannot determine repo root. Set GENTLE_VANGUARD_BASE_DIR or run from repo directory." -ForegroundColor Red
    exit 1
}

$exitCode = 0
$errors = @()
$warnings = @()

function Test-ReadmeSection {
    param(
        [string]$Content,
        [string]$SectionName,
        [string[]]$RequiredPatterns
    )
    $sectionErrors = @()
    foreach ($pattern in $RequiredPatterns) {
        if ($Content -notmatch $pattern) {
            $sectionErrors += "Missing required pattern: $pattern in section '$SectionName'"
        }
    }
    return $sectionErrors
}

function Get-ActualStats {
    param([string]$Root)
    $stats = @{}
    $skills = Get-ChildItem -Path (Join-Path $Root 'skills') -Directory -ErrorAction SilentlyContinue
    $stats['Skills'] = if ($skills) { $skills.Count } else { 0 }
    $workflows = Get-ChildItem -Path (Join-Path $Root '.github/workflows') -Filter '*.yml' -ErrorAction SilentlyContinue
    $stats['Workflows'] = if ($workflows) { $workflows.Count } else { 0 }
    $tests = Get-ChildItem -Path (Join-Path $Root 'tests') -Filter '*.tests.ps1' -Recurse -ErrorAction SilentlyContinue
    $stats['Tests'] = if ($tests) { $tests.Count } else { 0 }
    $deleg = Get-Content (Join-Path $Root 'config/auto-delegation.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
    $routingProfiles = @('hallucinationGuardLevels', 'GITFLOW', 'SCRIPT')
    $agentCount = ($deleg.agentProfiles.PSObject.Properties | Where-Object { $_.Name -notin $routingProfiles }).Count
    $stats['Agents'] = $agentCount + 1
    $stats['KeywordMappings'] = $deleg.keywordMappings.PSObject.Properties.Count
    return $stats
}

function Test-PrivateReadme {
    param([string]$FilePath, [hashtable]$ActualStats)
    $content = Get-Content $FilePath -Raw
    $allErrors = @()
    $allWarnings = @()

    $mandatorySections = @{
        'Header' = @('Gentle-Vanguard', 'img.shields.io/badge/Version', 'img.shields.io/badge/Agents', 'img.shields.io/badge/Skills')
        'What is Gentle-Vanguard' = @('What is Gentle-Vanguard', 'Routes work', 'Enforces SDD', 'Persists memory', '```mermaid')
        'Architecture' = @('Work Routing Ladder', 'Delegation Rules', '5-Layer Architecture', '```mermaid')
        'Agent Ecosystem' = @('Orchestrator', 'BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC', 'Model Profile')
        'Key Capabilities' = @('SDD', 'Review Workload Guard', 'Skill Registry', 'Chain-Delivery', 'Cross-Tool')
        'Quick Start' = @('git clone', 'session-autostart', 'gv verify')
        'Development' = @('Invoke-Pester', 'gv verify', 'build')
        'CI/CD Pipeline' = @('gentle-vanguard-quality-gate', 'test-suite', 'sync-public')
        'Project Status' = @('Configuration', 'Skills', 'Tests', 'Hooks', 'Structure')
        'Key Documentation' = @('AGENTS.md', 'Delegation Rules', 'Model Routing', 'SDD Config', 'Skill Registry')
    }

    foreach ($section in $mandatorySections.GetEnumerator()) {
        $sectionErrors = Test-ReadmeSection -Content $content -SectionName $section.Key -RequiredPatterns $section.Value
        if ($sectionErrors) {
            $allErrors += "SECTION '$($section.Key)': $($sectionErrors -join '; ')"
        }
    }

    if ($content -notmatch '(\d+)\s+agents') {
        $allWarnings += 'Agent count not found in header'
    } else {
        $readmeAgents = [int]$Matches[1]
        if ($readmeAgents -ne $ActualStats['Agents']) {
            $allErrors += "STATS: README says $readmeAgents agents, actual count is $($ActualStats['Agents'])"
        }
    }

    if ($content -match '(\d+)\s+skills') {
        $readmeSkills = [int]$Matches[1]
        if ($readmeSkills -ne $ActualStats['Skills']) {
            $allErrors += "STATS: README says $readmeSkills skills, actual count is $($ActualStats['Skills'])"
        }
    }

    if ($content -match '(\d+)\s+Workflows') {
        $readmeWf = [int]$Matches[1]
        if ($readmeWf -ne $ActualStats['Workflows']) {
            $allErrors += "STATS: README says $readmeWf workflows, actual count is $($ActualStats['Workflows'])"
        }
    }

    $changelog = Get-Content (Join-Path $repoRoot 'CHANGELOG.md') -TotalCount 15 -ErrorAction SilentlyContinue
    if ($changelog) {
        $changelogVersion = ($changelog | Select-String '\[(\d+\.\d+\.\d+)\]').Matches[0].Groups[1].Value
        if ($content -match "badge/Version-([0-9.]+)" -and $Matches[1] -ne $changelogVersion) {
            $allErrors += "VERSION: Badge says $($Matches[1]), CHANGELOG says $changelogVersion"
        }
    }

    $mermaidCount = ([regex]::Matches($content, '```mermaid')).Count
    if ($mermaidCount -lt 3) {
        $allErrors += "MERMAID: Expected at least 3 Mermaid diagrams, found $mermaidCount"
    }

    $lineCount = ($content -split "`n").Count
    if ($lineCount -lt 150) {
        $allErrors += "LENGTH: README has $lineCount lines, minimum is 150 (governance policy)"
    }

    return @{ Errors = $allErrors; Warnings = $allWarnings }
}

function Test-PublicReadme {
    param([string]$FilePath, [hashtable]$ActualStats)
    $content = Get-Content $FilePath -Raw
    $allErrors = @()
    $allWarnings = @()

    $mandatorySections = @{
        'Header' = @('Gentle-Vanguard', 'img.shields.io/badge/Version', 'img.shields.io/badge/Agents', 'img.shields.io/badge/Skills')
        'What It Solves' = @('What It Solves', 'Engram', 'SDD', 'judgment-day')
        'Architecture' = @('```mermaid', '5-Layer Architecture')
        'Agent Ecosystem' = @('Orchestrator', 'BA', 'SAD', 'DEV', 'QA', 'Model Profile')
        'Key Features' = @('Specialized Agents', 'On-Demand Skills', 'Persistent Engram Memory', 'Cost-Aware Model Router')
        'Skill Catalog' = @('Frontend', 'Backend', 'DevOps', 'Security', 'Testing')
        'Quick Install' = @('git clone', 'bootstrap.ps1')
        'Requirements' = @('PowerShell', 'Git')
        'CI/CD Pipeline' = @('gentle-vanguard-quality-gate', 'test-suite', 'sync-public')
        'Defensive Patterns' = @('repoRoot', 'UTF-8', 'ErrorActionPreference')
        'Security' = @('AES-256', 'SECURITY.md')
        'Documentation' = @('Getting Started', 'Architecture', 'INSTALLATION')
    }

    foreach ($section in $mandatorySections.GetEnumerator()) {
        $sectionErrors = Test-ReadmeSection -Content $content -SectionName $section.Key -RequiredPatterns $section.Value
        if ($sectionErrors) {
            $allErrors += "SECTION '$($section.Key)': $($sectionErrors -join '; ')"
        }
    }

    if ($content -match '(\d+)\s+agents') {
        $readmeAgents = [int]$Matches[1]
        if ($readmeAgents -ne $ActualStats['Agents']) {
            $allErrors += "STATS: README says $readmeAgents agents, actual count is $($ActualStats['Agents'])"
        }
    }

    if ($content -match '(\d+)\s+skills') {
        $readmeSkills = [int]$Matches[1]
        if ($readmeSkills -ne $ActualStats['Skills']) {
            $allErrors += "STATS: README says $readmeSkills skills, actual count is $($ActualStats['Skills'])"
        }
    }

    $mermaidCount = ([regex]::Matches($content, '```mermaid')).Count
    if ($mermaidCount -lt 1) {
        $allErrors += "MERMAID: Expected at least 1 Mermaid diagram, found $mermaidCount"
    }

    $lineCount = ($content -split "`n").Count
    if ($lineCount -lt 120) {
        $allErrors += "LENGTH: README has $lineCount lines, minimum is 120 (governance policy)"
    }

    return @{ Errors = $allErrors; Warnings = $allWarnings }
}

Write-Host "`n=== README Governance Validation ===" -ForegroundColor Cyan
Write-Host "Repo: $Repo | Strict: $Strict`n" -ForegroundColor Gray

$actualStats = Get-ActualStats -Root $repoRoot
Write-Host "Actual project stats:" -ForegroundColor Gray
Write-Host "  Agents: $($actualStats['Agents'])" -ForegroundColor Gray
Write-Host "  Skills: $($actualStats['Skills'])" -ForegroundColor Gray
Write-Host "  Workflows: $($actualStats['Workflows'])" -ForegroundColor Gray
Write-Host "  Tests: $($actualStats['Tests'])" -ForegroundColor Gray
Write-Host ""

if ($Repo -in @('private', 'both')) {
    $privateReadme = Join-Path $repoRoot 'README.md'
    if (Test-Path $privateReadme) {
        Write-Host "--- Private README (gentle-vanguard) ---" -ForegroundColor Yellow
        $result = Test-PrivateReadme -FilePath $privateReadme -ActualStats $actualStats
        if ($result.Errors) {
            foreach ($e in $result.Errors) { Write-Host "  [ERROR] $e" -ForegroundColor Red }
            $errors += $result.Errors
        }
        if ($result.Warnings) {
            foreach ($w in $result.Warnings) { Write-Host "  [WARN]  $w" -ForegroundColor Yellow }
            $warnings += $result.Warnings
        }
        if (-not $result.Errors -and -not $result.Warnings) {
            Write-Host "  [PASS] All checks passed" -ForegroundColor Green
        }
    } else {
        Write-Host "  [ERROR] Private README not found at $privateReadme" -ForegroundColor Red
        $errors += "Private README not found"
    }
    Write-Host ""
}

if ($Repo -in @('public', 'both')) {
    $publicRoot = Join-Path (Split-Path $repoRoot -Parent) 'gentle-vanguard-public'
    if (-not (Test-Path $publicRoot)) {
        $publicRoot = Join-Path $repoRoot '..\gentle-vanguard-public'
    }
    if (-not (Test-Path $publicRoot)) {
        $publicRoot = if ($env:GENTLE_VANGUARD_PUBLIC_ROOT) { $env:GENTLE_VANGUARD_PUBLIC_ROOT } else { Join-Path (Split-Path $repoRoot -Parent) 'gentle-vanguard-public' }
    }
    $publicReadme = Join-Path $publicRoot 'README.md'
    if (Test-Path $publicReadme) {
        Write-Host "--- Public README (gentle-vanguard-public) ---" -ForegroundColor Yellow
        $result = Test-PublicReadme -FilePath $publicReadme -ActualStats $actualStats
        if ($result.Errors) {
            foreach ($e in $result.Errors) { Write-Host "  [ERROR] $e" -ForegroundColor Red }
            $errors += $result.Errors
        }
        if ($result.Warnings) {
            foreach ($w in $result.Warnings) { Write-Host "  [WARN]  $w" -ForegroundColor Yellow }
            $warnings += $result.Warnings
        }
        if (-not $result.Errors -and -not $result.Warnings) {
            Write-Host "  [PASS] All checks passed" -ForegroundColor Green
        }
    } else {
        Write-Host "  [ERROR] Public README not found at $publicReadme" -ForegroundColor Red
        $errors += "Public README not found"
    }
    Write-Host ""
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Errors:   $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -gt 0) { 'Yellow' } else { 'Green' })

if ($errors.Count -gt 0) {
    Write-Host "`n  FAIL — Fix errors before committing README changes" -ForegroundColor Red
    $exitCode = 1
} elseif ($Strict -and $warnings.Count -gt 0) {
    Write-Host "`n  FAIL (strict mode) — Fix warnings before committing" -ForegroundColor Yellow
    $exitCode = 1
} else {
    Write-Host "`n  PASS — README governance validation successful" -ForegroundColor Green
}

exit $exitCode