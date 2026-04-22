#Requires -Version 5.1
<#
.SYNOPSIS
    Unified Audit Workflow - Foundation Audit + Judgment Day Integration
.DESCRIPTION
    Provides unified audit interface combining:
    - foundation-audit: Fast batch validation (0 tokens)
    - judgment-day: Deep adversarial review (sub-agents)
    
    Works standalone or integrated with wf.ps1
    
    STANDALONE MODE:
    Copy this script to any directory and run without Foundation dependency.
    All checks run locally with embedded rules.
    
    INTEGRATED MODE:
    Run via: .\scripts\utilities\wf.ps1 audit judgment
.PARAMETER Mode
    quick | standard | full | deep | judgment | unified
.PARAMETER Scope
    quick: deprecated refs + skill structure
    standard: quick + link checks
    full: standard + duplicates + skill index sync
    deep: full + orphaned documentation
    judgment: full + adversarial review guidance
    unified: full batch then prompt for judgment
.PARAMETER SkipJudgment
    Skip adversarial review, batch only
.PARAMETER StandalonePath
    Path to audit (default: current directory)
    Used in standalone mode
.EXAMPLE
    # Standalone - audit current directory
    .\audit-workflow.ps1 -Mode full
    
    # Integrated - full validation with judgment
    .\wf.ps1 audit judgment --mode full
    
    # Quick pre-commit check
    .\audit-workflow.ps1 -Mode quick -FailOnIssues
#>
param(
    [ValidateSet('quick', 'standard', 'full', 'deep', 'judgment', 'unified')]
    [string]$Mode = 'standard',
    
    [ValidateSet('text', 'json', 'markdown')]
    [string]$Output = 'text',
    
    [switch]$FailOnIssues,
    
    [switch]$SkipJudgment,
    
    [string]$StandalonePath = $PWD.Path,
    
    [string]$BasePath
)

$ErrorActionPreference = 'Continue'
$Script:StartTime = Get-Date
$Script:Issues = @()
$Script:Warnings = @()

# ============================================================================
# AUTO-DETECT MODE: Standalone vs Integrated
# ============================================================================
$IsStandalone = -not $BasePath
if ($IsStandalone) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $AuditScript = Join-Path $ScriptRoot 'audit-sweep.ps1'
    $WorkingDir = $StandalonePath
} else {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $AuditScript = Join-Path $BasePath 'skills\foundation-audit-skill\scripts\audit-sweep.ps1'
    $WorkingDir = $BasePath
}

# ============================================================================
# CONFIGURATION
# ============================================================================
$Config = @{
    BatchChecks = @{
        quick    = @{ Deprecated = $true; Structure = $true }
        standard = @{ Deprecated = $true; Structure = $true; Links = $true; Readme = $true }
        full     = @{ Deprecated = $true; Structure = $true; Links = $true; Readme = $true; Duplicates = $true; IndexSync = $true }
    }
    JudgmentTriggers = @(
        'pre-release',
        'v2.1',
        'release-candidate',
        'major-change'
    )
}

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================
function Write-AuditHeader {
    param([string]$Message, [string]$Color = 'Cyan')
    $prefix = if ($Output -eq 'markdown') { "##" } else { "===" }
    $suffix = if ($Output -eq 'markdown') { "`n" } else { " ===" }
    Write-Host "`n$prefix $Message $suffix" -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    if ($Output -eq 'text') {
        Write-Host "  → $Message" -ForegroundColor White
    } elseif ($Output -eq 'markdown') {
        Write-Output "- $Message"
    }
}

function Add-Issue {
    param([string]$Category, [string]$Message, [string]$Path, [string]$Severity = 'warning')
    $Script:Issues += @{
        Category = $Category
        Message = $Message
        Path = $Path
        Severity = $Severity
        Timestamp = (Get-Date).ToString('o')
    }
    if ($Output -eq 'text') {
        $color = @{ error = 'Red'; warning = 'Yellow'; info = 'DarkGray' }[$Severity]
        Write-Host "    [$Severity] $Message" -ForegroundColor $color
        if ($Path) { Write-Host "             $Path" -ForegroundColor DarkGray }
    }
}

function Resolve-PathSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseDirectory,
        [Parameter(Mandatory = $true)]
        [string]$RelativeOrAbsolutePath
    )

    $pathWithoutAnchor = ($RelativeOrAbsolutePath -split '#')[0]
    $pathWithoutQuery = ($pathWithoutAnchor -split '\?')[0]
    if ([string]::IsNullOrWhiteSpace($pathWithoutQuery)) {
        return $null
    }

    try {
        if ([System.IO.Path]::IsPathRooted($pathWithoutQuery)) {
            return [System.IO.Path]::GetFullPath($pathWithoutQuery)
        }
        return [System.IO.Path]::GetFullPath((Join-Path $BaseDirectory $pathWithoutQuery))
    } catch {
        return $null
    }
}

# ============================================================================
# PHASE 1: BATCH AUDIT (Zero Tokens)
# ============================================================================
function Invoke-BatchAudit {
    param([string]$Scope)
    
    Write-AuditHeader "PHASE 1: Batch Audit (Foundation Audit)" -Color Magenta
    Write-Host "Mode: $Scope | Cost: $0 | Est. Time: <5s" -ForegroundColor DarkGray
    
    # Run foundation-audit batch checks
    if (Test-Path $AuditScript) {
        Write-Step "Executing batch validation..."
        
        $scopeMap = @{
            'quick' = 'quick'
            'standard' = 'standard'
            'full' = 'full'
            'deep' = 'deep'
            'judgment' = 'full'
            'unified' = 'full'
        }
        
        $jsonOutput = & $AuditScript -Scope $scopeMap[$Scope] -Output 'json' -BasePath $WorkingDir 2>$null 3>$null 4>$null 5>$null 6>$null | Out-String
        if (-not [string]::IsNullOrWhiteSpace($jsonOutput)) {
            try {
                $parsed = $jsonOutput | ConvertFrom-Json -ErrorAction Stop
                if ($parsed.Issues) {
                    $Script:Issues = @($parsed.Issues)
                }
            } catch {
                Add-Issue -Category 'audit' -Message 'Could not parse JSON summary from audit-sweep.ps1' -Path $AuditScript -Severity 'warning'
            }
        }

        if ($Output -eq 'text') {
            Write-Step "Batch audit complete"
            Write-Host "    Parsed issues: $($Script:Issues.Count)" -ForegroundColor DarkGray
        } elseif ($Output -eq 'json' -and -not [string]::IsNullOrWhiteSpace($jsonOutput)) {
            Write-Output $jsonOutput
        }
    } else {
        # Standalone fallback - inline checks
        Write-Step "Running standalone checks..."
        Invoke-StandaloneChecks -Scope $Scope
    }
}

# ============================================================================
# STANDALONE CHECKS (No Foundation Required)
# ============================================================================
function Invoke-StandaloneChecks {
    param([string]$Scope)
    
    Write-Step "=== Standalone Mode: No Foundation Dependency ==="
    
    # Check 1: Git state
    $isGitRepo = Test-Path (Join-Path $WorkingDir '.git')
    if ($isGitRepo) {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        Write-Host "    Git repo detected | Branch: $branch" -ForegroundColor DarkGray
    } else {
        Write-Host "    Standalone directory (no git)" -ForegroundColor DarkGray
    }
    
    # Check 2: Basic structure
    $hasReadme = Test-Path (Join-Path $WorkingDir 'README.md')
    $srcPath = Join-Path $WorkingDir 'src'; $appPath = Join-Path $WorkingDir 'app'
    $testPath = Join-Path $WorkingDir 'tests'; $test2Path = Join-Path $WorkingDir 'test'
    $hasSrc = (Test-Path $srcPath) -or (Test-Path $appPath)
    $hasTests = (Test-Path $testPath) -or (Test-Path $test2Path)
    
    Write-Host "    Structure: README=$hasReadme | Source=$hasSrc | Tests=$hasTests" -ForegroundColor DarkGray
    
    # Check 3: Dependency files
    $depFiles = @('package.json', 'go.mod', 'Cargo.toml', 'requirements.txt', 'pyproject.toml')
    $foundDeps = $depFiles | Where-Object { Test-Path (Join-Path $WorkingDir $_) }
    if ($foundDeps.Count -gt 0) {
        Write-Host "    Dependencies: $($foundDeps -join ', ')" -ForegroundColor DarkGray
    }
    
    # Check 4: Secrets in env
    $hasEnvExample = Test-Path (Join-Path $WorkingDir '.env.example')
    $hasGitignore = Test-Path (Join-Path $WorkingDir '.gitignore')
    if ($hasEnvExample -and $hasGitignore) {
        $gitignore = Get-Content (Join-Path $WorkingDir '.gitignore') -Raw
        if ($gitignore -match '\.env[^\.]') {
            Write-Host "    Security: .env in .gitignore ✓" -ForegroundColor Green
        }
    }
    
    # Check 5: Skill files if exists
    $skillsDir = Join-Path $WorkingDir 'skills'
    if (Test-Path $skillsDir) {
        $skillCount = (Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue).Count
        Write-Host "    Skills: $skillCount found" -ForegroundColor DarkGray
    }
    
    # Check 6: Documentation links
    if ($hasReadme) {
        Write-Step "Validating README links..."
        $readmePath = Join-Path $WorkingDir 'README.md'
        $readmeContent = Get-Content $readmePath -Raw
        $links = [regex]::Matches($readmeContent, '\[([^\]]+)\]\(([^)]+\.md)\)')
        
        $brokenLinks = 0
        foreach ($link in $links) {
            $url = $link.Groups[2].Value
            if ($url -match '^(https?://|#|mailto:|skills/)') { continue }
            
            $resolved = Resolve-PathSafe -BaseDirectory (Split-Path $readmePath) -RelativeOrAbsolutePath $url
            
            if ($null -eq $resolved -or -not (Test-Path $resolved)) {
                $brokenLinks++
                Add-Issue -Category 'links' -Message "Broken link: $($link.Groups[1].Value)" -Path $readmePath
            }
        }
        
        if ($brokenLinks -eq 0) {
            Write-Host "    All README links valid" -ForegroundColor Green
        }
    }
    
    Write-Step "Standalone checks complete"
}

# ============================================================================
# PHASE 2: JUDGMENT DAY (Tokens Required)
# ============================================================================
function Invoke-JudgmentReview {
    param([switch]$Skip)
    
    if ($Skip) {
        Write-Step "Judgment review skipped (--SkipJudgment)"
        return
    }
    
    Write-AuditHeader "PHASE 2: Adversarial Review (Judgment Day)" -Color Red
    Write-Host "Mode: Dual Judge | Cost: ~$0.02-0.05 | Est. Time: 10-15min" -ForegroundColor DarkGray
    
    $judgmentSkill = Join-Path $WorkingDir 'skills\judgment-day\SKILL.md'
    
    if (Test-Path $judgmentSkill) {
        Write-Step "Loading judgment-day skill..."
        Write-Host "    See: skills/judgment-day/SKILL.md" -ForegroundColor DarkGray
        Write-Host "    Command to run dual review: wf.ps1 judgment-day" -ForegroundColor DarkGray
    } else {
        Write-Warning "judgment-day skill not found. Install Foundation for adversarial review."
    }
}

# ============================================================================
# PHASE 3: REPORT GENERATION
# ============================================================================
function Get-AuditReport {
    $elapsed = (Get-Date) - $Script:StartTime
    
    Write-AuditHeader "AUDIT SUMMARY" -Color Cyan
    
    $errors = $Script:Issues | Where-Object { $_.Severity -eq 'error' }
    $warnings = $Script:Issues | Where-Object { $_.Severity -eq 'warning' }
    
    Write-Host "`nTotal Issues: $($Script:Issues.Count)" -ForegroundColor $(if ($Script:Issues.Count -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { 'Red' } else { 'DarkGray' })
    Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -gt 0) { 'Yellow' } else { 'DarkGray' })
    Write-Host "`nExecution Time: $($elapsed.TotalSeconds.ToString('0.0'))s"
    Write-Host "Mode: $(if ($IsStandalone) { 'STANDALONE' } else { 'INTEGRATED' })"
    Write-Host "Path: $WorkingDir"
    
    # JSON output
    if ($Output -eq 'json') {
        @{
            Summary = @{
                TotalIssues = $Script:Issues.Count
                Errors = $errors.Count
                Warnings = $warnings.Count
                ExecutionTimeSeconds = [math]::Round($elapsed.TotalSeconds, 2)
                Mode = if ($IsStandalone) { 'standalone' } else { 'integrated' }
            }
            Issues = $Script:Issues
            Config = @{
                AuditMode = $Mode
                WorkingDirectory = $WorkingDir
                Timestamp = (Get-Date).ToString('o')
            }
        } | ConvertTo-Json -Depth 3
    }
    
    # Exit code
    if ($FailOnIssues -and $Script:Issues.Count -gt 0) {
        exit 1
    }
}

# ============================================================================
# WORKFLOW RECOMMENDATIONS
# ============================================================================
function Show-Recommendations {
    Write-AuditHeader "RECOMMENDATIONS" -Color Green
    
    if ($Script:Issues.Count -eq 0) {
        Write-Host "  ✓ No issues found. Ready for:" -ForegroundColor Green
        Write-Host "    - Pre-commit: git commit" -ForegroundColor DarkGray
        Write-Host "    - CI/CD: proceed to build" -ForegroundColor DarkGray
        Write-Host "    - Pre-release: Consider running judgment-day" -ForegroundColor DarkGray
    } else {
        Write-Host "  Fix issues before:" -ForegroundColor Yellow
        Write-Host "    - Committing to main/develop" -ForegroundColor DarkGray
        Write-Host "    - Creating PRs" -ForegroundColor DarkGray
        Write-Host "    - Release preparation" -ForegroundColor DarkGray
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║           UNIFIED AUDIT WORKFLOW v1.0                         ║
║  Foundation Audit + Judgment Day Integration                  ║
║  Mode: $($Mode.PadRight(15)) Cost: $(if ($Mode -eq 'judgment') { '~$0.03' } else { '$0' })                         ║
╚════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta

Write-Host "Started: $($Script:StartTime.ToString('HH:mm:ss'))"
Write-Host "Working Dir: $WorkingDir`n"

# Execute based on mode
switch ($Mode) {
    'quick' {
        Invoke-BatchAudit -Scope 'quick'
    }
    'standard' {
        Invoke-BatchAudit -Scope 'standard'
    }
    'full' {
        Invoke-BatchAudit -Scope 'full'
    }
    'deep' {
        Invoke-BatchAudit -Scope 'deep'
    }
    'judgment' {
        Invoke-BatchAudit -Scope 'full'
        Invoke-JudgmentReview -Skip:$SkipJudgment
    }
    'unified' {
        Invoke-BatchAudit -Scope 'full'
        if ($SkipJudgment) {
            Invoke-JudgmentReview -Skip:$true
        } else {
            $answer = Read-Host "Run adversarial review now? (y/N)"
            if ($answer -match '^(y|yes)$') {
                Invoke-JudgmentReview
            } else {
                Write-Step "Judgment review deferred. Run: wf.ps1 judgment-day"
            }
        }
    }
}

Get-AuditReport
Show-Recommendations

exit 0
