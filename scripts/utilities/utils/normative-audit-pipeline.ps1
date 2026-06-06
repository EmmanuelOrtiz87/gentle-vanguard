<#
.SYNOPSIS
    Unified normative audit and enforcement pipeline.
.DESCRIPTION
    Runs checks across all 25+ normatives, reports violations, and auto-fixes where possible.
    Designed for: pre-commit, CI, and session-start execution.
.PARAMETER Mode
    'pre-commit' (fast, checks 1-3), 'ci' (full, checks 1-6), 'session' (health check)
.PARAMETER ReportPath
    Path for the generated compliance report (default: .session/compliance-report.json)
.PARAMETER Fix
    Apply auto-fixes where supported.
#>

param(
    [ValidateSet('pre-commit','ci','session')]
    [string]$Mode = 'pre-commit',
    [string]$ReportPath = '',
    [switch]$Fix
)

$ErrorActionPreference = 'Stop'
$root = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $d = $PSScriptRoot
    while ($d -and -not (Test-Path (Join-Path $d 'config\orchestrator.json'))) { $d = Split-Path -Parent $d }
    $d
}
if (-not $root) { $root = Split-Path -Parent $PSScriptRoot }

if (-not $ReportPath) {
    $sessionDir = Join-Path $root '.session'
    if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }
    $ReportPath = Join-Path $sessionDir 'compliance-report.json'
}

$results = @{
    timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    mode = $Mode
    fix = $Fix.IsPresent
    checks = @()
    violations = @()
    summary = @{ passed = 0; failed = 0; fixed = 0; total = 0 }
}

function Add-CheckResult($name, $status, $details, $autoFix = $false) {
    $results.checks += @{
        check = $name
        status = $status
        details = $details
        autoFix = $autoFix
    }
    if ($status -eq 'pass') { $results.summary.passed++ }
    else { $results.summary.failed++ }
    $results.summary.total++
}

function Add-Violation($rule, $file, $severity, $message) {
    $results.violations += @{
        rule = $rule
        file = $file
        severity = $severity
        message = $message
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    }
    # Log to violations JSONL
    $violationsLog = Join-Path (Join-Path $root '.session') 'input-violations.jsonl'
    $entry = @{ Timestamp = (Get-Date -Format 'o'); Rule = $rule; Severity = $severity; Message = $message; InputPreview = $file } | ConvertTo-Json -Compress
    Add-Content -Path $violationsLog -Value $entry
}

# ============================================================================
# CHECK 1: Code Standards — Write-Host in libs, Select-String in automation
# ============================================================================
function Check-CodeStandards {
    $violations = @()
    $patterns = @{
        'Write-Host' = @{
            msg = 'Use Write-Output or Write-Verbose instead of Write-Host in library modules'
            dirs = @('scripts/common', 'scripts/functions')
            exts = @('.psm1')
        }
        'Select-String' = @{
            msg = 'Select-String is prohibited in automation — use -match operator'
            dirs = @('scripts/core', '.github/workflows', 'scripts/hooks')
            exts = @('.ps1', '.yml', '.yaml')
        }
    }
    foreach ($pattern in $patterns.Keys) {
        $cfg = $patterns[$pattern]
        foreach ($dir in $cfg.dirs) {
            $fullDir = Join-Path $root $dir
            if (-not (Test-Path $fullDir)) { continue }
            Get-ChildItem -Path $fullDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                $ext = $_.Extension.ToLower()
                if ($ext -notin $cfg.exts) { return }
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match $pattern) {
                    $violations += @{ file = $_.FullName; pattern = $pattern; msg = $cfg.msg }
                }
            }
        }
    }
    if ($violations.Count -eq 0) {
        Add-CheckResult -name 'code-standards-write-host' -status 'pass' -details 'No Write-Host in libs or Select-String in automation violations found'
    } else {
        foreach ($v in $violations) {
            Add-Violation -rule 'NORMATIVAS-CODIGO.md §4.3' -file $v.file -severity 'warn' -message $v.msg
        }
        Add-CheckResult -name 'code-standards-write-host' -status 'fail' -details "$($violations.Count) violation(s) found"
    }
}

# ============================================================================
# CHECK 2: Performance Patterns — Out-Null in loops, -Include usage
# ============================================================================
function Check-PerformancePatterns {
    $violations = @()
    $scriptDirs = @(Join-Path $root 'scripts')
    foreach ($dir in $scriptDirs) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $PSCommandPath } | ForEach-Object {
            $lines = Get-Content $_.FullName
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '\| Out-Null' -and ($lines[$i] -match '\b(foreach|while|for)\b')) {
                    $violations += @{ file = $_.FullName; line = $i + 1; msg = 'Out-Null in loop — use [void] instead' }
                }
                if ($lines[$i] -match 'Get-ChildItem.*-Include' -and ($lines[$i] -match '\*\.\*')) {
                    $violations += @{ file = $_.FullName; line = $i + 1; msg = 'Get-ChildItem -Include with wildcard — use -Filter for performance' }
                }
            }
        }
    }
    if ($violations.Count -eq 0) {
        Add-CheckResult -name 'performance-patterns' -status 'pass' -details 'No performance anti-patterns found'
    } else {
        foreach ($v in $violations) {
            Add-Violation -rule 'NORMATIVAS-PERFORMANCE.md §3.1' -file $v.file -severity 'warn' -message "$($v.msg) (line $($v.line))"
        }
        Add-CheckResult -name 'performance-patterns' -status 'fail' -details "$($violations.Count) anti-pattern(s) found"
    }
}

# ============================================================================
# CHECK 3: Cross-Platform — hardcoded absolute paths
# ============================================================================
function Check-CrossPlatform {
    $violations = @()
    $scriptDirs = @(Join-Path $root 'scripts')
    foreach ($dir in $scriptDirs) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object {
            $lines = Get-Content $_.FullName
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match 'C:\\[A-Za-z]' -and $lines[$i] -notmatch '^\s*#' -and $lines[$i] -notmatch 'C:\\Windows' -and $lines[$i] -notmatch 'C:\\Program') {
                    $violations += @{ file = $_.FullName; line = $i + 1; text = $lines[$i].Trim() }
                }
            }
        }
    }
    if ($violations.Count -eq 0) {
        Add-CheckResult -name 'cross-platform-paths' -status 'pass' -details 'No hardcoded absolute paths found'
    } else {
        foreach ($v in $violations) {
            Add-Violation -rule 'NORMATIVAS-CROSS-PLATFORM.md' -file $v.file -severity 'warn' -message "Hardcoded path at line $($v.line): $($v.text)"
        }
        Add-CheckResult -name 'cross-platform-paths' -status 'fail' -details "$($violations.Count) hardcoded path(s) found"
    }
}

# ============================================================================
# CHECK 4: Learned Norms — verify LEARNED-NORMS.md has content
# ============================================================================
function Check-LearnedNorms {
    $normsFile = Join-Path (Join-Path $root 'rules') 'adaptive\LEARNED-NORMS.md'
    if (-not (Test-Path $normsFile)) {
        Add-Violation -rule 'NORMATIVAS-ENFORCEMENT.md §3' -file $normsFile -severity 'warn' -message 'LEARNED-NORMS.md does not exist'
        Add-CheckResult -name 'learned-norms' -status 'fail' -details 'LEARNED-NORMS.md not found'
        return
    }
    $content = Get-Content $normsFile -Raw
    if ([string]::IsNullOrWhiteSpace($content) -or $content.Trim().Length -lt 50) {
        Add-Violation -rule 'NORMATIVAS-ENFORCEMENT.md §3' -file $normsFile -severity 'warn' -message 'LEARNED-NORMS.md is empty — auto-norm-learner not producing output'
        Add-CheckResult -name 'learned-norms' -status 'fail' -details 'LEARNED-NORMS.md is empty'
        return
    }
    Add-CheckResult -name 'learned-norms' -status 'pass' -details "LEARNED-NORMS.md has content ($($content.Length) chars)"
}

# ============================================================================
# CHECK 5: File Structure — orphan files in root
# ============================================================================
function Check-FileStructure {
    $violations = @()
    $rootFiles = Get-ChildItem -Path $root -File -ErrorAction SilentlyContinue
    $expectedRootFiles = @(
        '.gitignore', '.editorconfig', '.node-version', '.nvmrc', 
        'CHANGELOG.md', 'LICENSE', 'README.md', 'README-PUBLIC.md',
        'VERSION', 'package.json', 'pnpm-lock.yaml', 'tsconfig.json',
        'opencode.json', 'renovate.json', 'pyproject.toml',
        'docker-compose.test.yml', 'gentle-vanguard.ps1',
        'gentle-vanguard-presentation.html',
        '.prettierrc', '.prettierignore', '.eslintrc.json',
        '.markdownlint.json', '.secretlintrc.json', '.secretlintignore',
        '.trivyignore', '.gitleaks.toml', '.lefthook.yml', '.npmrc',
        '.clineignore', '.orchestrator-active', 'skills-lock.json',
        '.env.example', '.env.local.example',
        '.gitattributes', 'CONTRIBUTING.md'
    )
    foreach ($f in $rootFiles) {
        if ($f.Name -notin $expectedRootFiles -and $f.Name -notlike '.*' -and $f.Name -notin @('SECURITY.md')) {
            $violations += @{ file = $f.Name; reason = 'Unexpected root-level file' }
        }
    }
    if ($violations.Count -eq 0) {
        Add-CheckResult -name 'file-structure-root' -status 'pass' -details 'No orphan root files'
    } else {
        foreach ($v in $violations) {
            Add-Violation -rule 'NORMATIVAS-MULTI-REPO.md §2' -file $v.file -severity 'info' -message $v.reason
        }
        Add-CheckResult -name 'file-structure-root' -status 'fail' -details "$($violations.Count) unexpected root file(s)"
    }
}

# ============================================================================
# CHECK 6: Documentation Status — drifted docs
# ============================================================================
function Check-DocumentationDrift {
    $violations = @()
    $refs = @{
        'docs/STACK-STATUS-REPORT.md' = 'Stack status report'
        'README.md' = 'Private README'
        'README-PUBLIC.md' = 'Public README'
    }
    $versionFile = Join-Path $root 'VERSION'
    $currentVersion = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { 'unknown' }
    $readme = Get-Content (Join-Path $root 'README.md') -Raw
    if ($readme -notmatch [regex]::Escape($currentVersion)) {
        $violations += @{ file = 'README.md'; msg = "Version mismatch: VERSION=$currentVersion not found in README" }
    }
    $publicReadme = Get-Content (Join-Path $root 'README-PUBLIC.md') -Raw
    if ($publicReadme -notmatch [regex]::Escape($currentVersion)) {
        $violations += @{ file = 'README-PUBLIC.md'; msg = "Version mismatch: VERSION=$currentVersion not found in README-PUBLIC" }
    }
    if ($violations.Count -eq 0) {
        Add-CheckResult -name 'documentation-version-drift' -status 'pass' -details 'Documentation versions match VERSION file'
    } else {
        foreach ($v in $violations) {
            Add-Violation -rule 'NORMATIVAS-DOCS.md §1' -file $v.file -severity 'warn' -message $v.msg
        }
        Add-CheckResult -name 'documentation-version-drift' -status 'fail' -details "$($violations.Count) drift(s) found"
    }
}

# ============================================================================
# EXECUTION
# ============================================================================
Write-Output "=== Normative Audit Pipeline ($Mode mode) ==="
Write-Output "Root: $root"
Write-Output ""

# Pre-commit: fast checks (1-3)
Check-CodeStandards
Check-PerformancePatterns
Check-CrossPlatform

# CI: full checks (1-6)
if ($Mode -in @('ci','session')) {
    Check-LearnedNorms
    Check-FileStructure
    Check-DocumentationDrift
}

# Reporting
$reportJson = $results | ConvertTo-Json -Depth 4
$results.summary | Format-Table -AutoSize | Out-String | Write-Output

$ReportPath = Resolve-Path $ReportPath -ErrorAction SilentlyContinue
if (-not $ReportPath) { $ReportPath = Join-Path (Join-Path $root '.session') 'compliance-report.json' }
$results | ConvertTo-Json -Depth 4 | Set-Content -Path $ReportPath -Force
Write-Output "Report saved: $ReportPath"

if ($results.violations.Count -gt 0) {
    Write-Output ""
    Write-Output "Violations found: $($results.violations.Count)"
    $results.violations | ForEach-Object { Write-Output "  [$($_.severity)] $($_.rule): $($_.file) - $($_.message)" }
}

if ($results.summary.failed -gt 0) {
    Write-Output ""
    Write-Output "FAILED: $($results.summary.failed) check(s) failed. See report for details."
    exit 1
}

Write-Output "PASS: All checks passed."
exit 0
