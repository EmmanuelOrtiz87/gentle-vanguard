param(
    [ValidateSet('validate', 'consolidate', 'cleanup', 'audit', 'all')]
    [string]$Action = 'all',
    [switch]$AutoFix
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "$Message" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
}

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Header "Documentation Manager Skill"

# Configuration
$essentialDocs = @(
    'docs/guides/README.md',
    'docs/guides/GETTING-STARTED.md',
    'docs/guides/GITFLOW-WORKFLOW.md',
    'docs/guides/SCRIPT-STANDARDS.md',
    'docs/guides/AI-TOOLS-INTEGRATION.md',
    'docs/guides/TROUBLESHOOTING.md',
    'docs/architecture/OVERVIEW.md',
    'docs/architecture/COMPONENTS.md',
    'docs/architecture/MESSAGE-FORMATS.md',
    'docs/DOCUMENTATION-STANDARDS.md'
)

$redundantDocs = @(
    'docs/guides/GITHUB-ACTIONS-TROUBLESHOOTING.md',
    'docs/guides/PRE-DEPLOYMENT-CHECKLIST.md',
    'docs/guides/DEPLOYMENT-OPTIMIZATION-GUIDE.md',
    'docs/guides/REMAINING-SCRIPTS-TO-FIX.md',
    'docs/guides/QUICK-FIX-GUIDE.md',
    'docs/guides/SCRIPT-NORMALIZATION-COMPLETION-REPORT.md'
)

# Action 1: Validate Documentation
if ($Action -in @('validate', 'all')) {
    Write-Info "Validating documentation structure..."
    
    $issues = @()
    
    # Check essential docs exist
    foreach ($doc in $essentialDocs) {
        if (-not (Test-Path $doc)) {
            $issues += "Missing essential doc: $doc"
            Write-Warn "Missing: $doc"
        } else {
            Write-Success "Found: $doc"
        }
    }
    
    # Check for redundant docs
    foreach ($doc in $redundantDocs) {
        if (Test-Path $doc) {
            $issues += "Redundant doc found: $doc"
            Write-Warn "Redundant: $doc"
        }
    }
    
    # Check file sizes
    Get-ChildItem docs -Filter "*.md" -Recurse | ForEach-Object {
        $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines
        if ($lines -gt 2000) {
            $issues += "File too large: $($_.Name) ($lines lines)"
            Write-Warn "Large file: $($_.Name) ($lines lines)"
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Success "Documentation structure is valid"
    } else {
        Write-Warn "Found $($issues.Count) issues"
    }
}

# Action 2: Consolidate Documentation
if ($Action -in @('consolidate', 'all')) {
    Write-Info "Consolidating documentation..."
    
    # Ensure directories exist
    @('docs/guides', 'docs/architecture', 'docs/audit') | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-Success "Created directory: $_"
        }
    }
    
    # Create .gitignore for audit directory
    $gitignoreContent = @"
# Auto-generated reports
*.report.md
*.audit.md
*.log
"@
    
    $gitignoreContent | Out-File "docs/audit/.gitignore" -Encoding UTF8
    Write-Success "Created docs/audit/.gitignore"
}

# Action 3: Cleanup Documentation
if ($Action -in @('cleanup', 'all')) {
    Write-Info "Cleaning up redundant documentation..."
    
    foreach ($doc in $redundantDocs) {
        if (Test-Path $doc) {
            if ($AutoFix) {
                Remove-Item $doc -Force
                Write-Success "Removed: $doc"
            } else {
                Write-Warn "Would remove: $doc"
            }
        }
    }
    
    # Remove auto-generated reports
    if (Test-Path "docs/audit") {
        Get-ChildItem "docs/audit" -Filter "*.md" | ForEach-Object {
            if ($AutoFix) {
                Remove-Item $_.FullName -Force
                Write-Success "Removed report: $($_.Name)"
            } else {
                Write-Warn "Would remove report: $($_.Name)"
            }
        }
    }
}

# Action 4: Audit Documentation
if ($Action -in @('audit', 'all')) {
    Write-Info "Auditing documentation..."
    
    $stats = @{
        TotalDocs = 0
        EssentialDocs = 0
        RedundantDocs = 0
        TotalLines = 0
        AverageLines = 0
        LargeFiles = 0
    }
    
    # Count docs
    $allDocs = Get-ChildItem docs -Filter "*.md" -Recurse
    $stats.TotalDocs = $allDocs.Count
    
    # Count essential
    foreach ($doc in $essentialDocs) {
        if (Test-Path $doc) {
            $stats.EssentialDocs++
        }
    }
    
    # Count redundant
    foreach ($doc in $redundantDocs) {
        if (Test-Path $doc) {
            $stats.RedundantDocs++
        }
    }
    
    # Count lines
    $allDocs | ForEach-Object {
        $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines
        $stats.TotalLines += $lines
        if ($lines -gt 2000) {
            $stats.LargeFiles++
        }
    }
    
    if ($stats.TotalDocs -gt 0) {
        $stats.AverageLines = [math]::Round($stats.TotalLines / $stats.TotalDocs, 0)
    }
    
    Write-Host ""
    Write-Host "Documentation Audit Results:" -ForegroundColor Cyan
    Write-Host "  Total Documents: $($stats.TotalDocs)" -ForegroundColor White
    Write-Host "  Essential Docs: $($stats.EssentialDocs)" -ForegroundColor Green
    Write-Host "  Redundant Docs: $($stats.RedundantDocs)" -ForegroundColor Yellow
    Write-Host "  Total Lines: $($stats.TotalLines)" -ForegroundColor White
    Write-Host "  Average Lines: $($stats.AverageLines)" -ForegroundColor White
    Write-Host "  Large Files (>2000 lines): $($stats.LargeFiles)" -ForegroundColor Yellow
    
    # Calculate compliance
    $compliance = if ($stats.TotalDocs -gt 0) {
        [math]::Round(($stats.EssentialDocs / $stats.TotalDocs) * 100, 2)
    } else {
        0
    }
    
    Write-Host "  Compliance: $compliance%" -ForegroundColor $(if ($compliance -ge 80) { 'Green' } else { 'Yellow' })
}

Write-Header "Documentation Manager Complete"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review documentation structure" -ForegroundColor White
Write-Host "  2. Run with -AutoFix to apply changes" -ForegroundColor White
Write-Host "  3. Verify all links work" -ForegroundColor White
Write-Host "  4. Commit changes to repository" -ForegroundColor White

Write-Host ""
exit 0