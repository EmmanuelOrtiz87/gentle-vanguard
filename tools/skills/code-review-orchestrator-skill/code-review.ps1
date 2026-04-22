#!/usr/bin/env pwsh
# code-review.ps1 - Code Review Orchestrator
# Coordinates all skills for comprehensive code review

param(
    [ValidateSet('all', 'security', 'quality', 'architecture', 'testing', 'docs', 'api', 'git', 'quick', 'full', 'judgment-day')]
    [string]$Scope = 'all',
    [string]$Path = ".",
    [switch]$Report,
    [switch]$Interactive,
    [switch]$Verbose,
    [switch]$Track,
    [string]$OutputPath = "docs/code-reviews",
    [string]$Target = "",
    [int]$MaxIterations = 2
)

$ErrorActionPreference = 'Continue'

if ([string]::IsNullOrWhiteSpace($Path)) { $Path = "." }

$Script:ISSUES = @()
$Script:CRITICAL = 0
$Script:HIGH = 0
$Script:MEDIUM = 0
$Script:LOW = 0
$Script:PROJECT_ROOT = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { $Path }
$Script:SKILL_DIR = Split-Path $PSScriptRoot -Parent
$Script:REVIEW_START = Get-Date

function Write-ReviewHeader {
    param([string]$Text, [string]$Color = 'Cyan')
    Write-Host ""
    Write-Host " [REVIEW] $Text" -ForegroundColor $Color
}

function Write-ReviewProgress {
    param([int]$Percent, [string]$Message = "")
    $filled = [Math]::Floor($Percent / 5)
    $empty = 20 - $filled
    $bar = ("=" * $filled) + ("-" * $empty)
    Write-Host "`r[$bar] $Percent% $Message" -NoNewline -ForegroundColor Cyan
    if ($Percent -eq 100) { Write-Host "" }
}

function Add-Issue {
    param(
        [string]$File,
        [int]$Line,
        [string]$Title,
        [string]$Severity = "MEDIUM",
        [string]$Category,
        [string]$Description,
        [string]$Impact,
        [string]$Recommendation,
        [string]$Fix
    )
    
    $color = switch ($Severity) {
        "CRITICAL" { "Red" }
        "HIGH" { "Magenta" }
        "MEDIUM" { "Yellow" }
        "LOW" { "Gray" }
        default { "White" }
    }
    
    $issue = @{
        Id = $Script:ISSUES.Count + 1
        File = $File
        Line = $Line
        Title = $Title
        Severity = $Severity
        Category = $Category
        Description = $Description
        Impact = $Impact
        Recommendation = $Recommendation
        Fix = $Fix
        Status = "open"
    }
    
    $Script:ISSUES += $issue
    
    switch ($Severity) {
        "CRITICAL" { $Script:CRITICAL++ }
        "HIGH" { $Script:HIGH++ }
        "MEDIUM" { $Script:MEDIUM++ }
        "LOW" { $Script:LOW++ }
    }
    
    if ($Verbose) {
        $location = if ($Line -gt 0) { "$File`:$Line" } else { $File }
        Write-Host "  [$Severity] [$Category] $location - $Title" -ForegroundColor $color
    }
}

function Invoke-SecurityReview {
    Write-ReviewHeader "Security Review (security-expert-skill)"
    
    $securityScript = Join-Path $SKILL_DIR "skills\security-expert-skill\security-scan.ps1"
    if (Test-Path $securityScript) {
        & $securityScript -Path $Path -Verbose:$Verbose 2>$null | Out-Null
    }
    
    Write-ReviewHeader "Scanning for code quality issues..."
    
    $qualityPatterns = @(
        @{ Name = "Console.log in production"; Pattern = "console\.(log|debug|info)\("; Severity = "LOW"; Category = "Quality"; Description = "Console logging found in code"; Impact = "May expose sensitive data in production logs"; Recommendation = "Use structured logging library"; Fix = "# Use logger library: `nimport logger from './logger';`nlogger.info('message', { data });" },
        @{ Name = "TODO without tracking"; Pattern = "(?i)(TODO|FIXME|HACK):"; Severity = "LOW"; Category = "Quality"; Description = "TODO comment found"; Impact = "May indicate incomplete implementation"; Recommendation = "Create issue/ticket for tracking" },
        @{ Name = "Empty catch block"; Pattern = "catch\s*\([^)]*\)\s*\{\s*\}"; Severity = "MEDIUM"; Category = "Quality"; Description = "Empty catch block suppresses errors"; Impact = "Errors may go unnoticed"; Recommendation = "Log or handle the error appropriately"; Fix = "catch (err) {`n  logger.error('Error occurred', { error: err });`n}" },
        @{ Name = "Hardcoded array size"; Pattern = "\[[0-9]+\]"; Severity = "LOW"; Category = "Quality"; Description = "Magic number used for array access"; Recommendation = "Use named constant" },
        @{ Name = "Synchronous file in async"; Pattern = "async\s+function.*\{[^}]*readFileSync"; Severity = "HIGH"; Category = "Quality"; Description = "Synchronous file operation in async function"; Impact = "Blocks event loop"; Recommendation = "Use async file operations" },
        @{ Name = "Nested callbacks"; Pattern = "\.then\([^)]*\{[^}]*\.then\("; Severity = "MEDIUM"; Category = "Quality"; Description = "Deeply nested promises detected"; Recommendation = "Use async/await for better readability" },
        @{ Name = "Long function"; Pattern = "function\s+\w+[^{]*\{[^}]{500,\}"; Severity = "MEDIUM"; Category = "Quality"; Description = "Function exceeds recommended length"; Recommendation = "Break into smaller functions" }
    )
    
    $codeExtensions = @("*.ps1", "*.js", "*.ts", "*.tsx", "*.jsx", "*.py", "*.go", "*.cs", "*.java")
    
    foreach ($ext in $codeExtensions) {
        $files = Get-ChildItem -Path $Path -Recurse -Include $ext -File -ErrorAction SilentlyContinue | Where-Object {
            $_.DirectoryName -notmatch "node_modules|\.git|dist|build|coverage|vendor"
        }
        
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }
            
            foreach ($pattern in $qualityPatterns) {
                if ($content -match $pattern.Pattern) {
                    Add-Issue `
                        -File $file.FullName `
                        -Line 0 `
                        -Title $pattern.Name `
                        -Severity $pattern.Severity `
                        -Category $pattern.Category `
                        -Description $pattern.Description `
                        -Impact $pattern.Impact `
                        -Recommendation $pattern.Recommendation `
                        -Fix $pattern.Fix
                }
            }
        }
    }
}

function Invoke-QualityReview {
    Write-ReviewHeader "Quality Review"
    
    $complexityPatterns = @(
        @{ Name = "Deeply nested code"; Pattern = "(if|for|while)\s*\([^)]*\)\s*\{[^}]{50,}\1\s*\("; Severity = "MEDIUM"; Description = "Deeply nested code structure detected"; Recommendation = "Refactor to improve readability" },
        @{ Name = "Long line detected"; Pattern = "^.{150,}$"; Severity = "LOW"; Description = "Line exceeds 150 characters"; Recommendation = "Split long lines for readability" }
    )
    
    $codeExtensions = @("*.ps1", "*.js", "*.ts", "*.tsx", "*.jsx", "*.py", "*.go", "*.cs", "*.java")
    
    foreach ($ext in $codeExtensions) {
        $files = Get-ChildItem -Path $Path -Recurse -Include $ext -File -ErrorAction SilentlyContinue | Where-Object {
            $_.DirectoryName -notmatch "node_modules|\.git|dist|build|coverage|vendor"
        }
        
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }
            
            foreach ($pattern in $complexityPatterns) {
                if ($content -match $pattern.Pattern) {
                    Add-Issue `
                        -File $file.FullName `
                        -Line 0 `
                        -Title $pattern.Name `
                        -Severity $pattern.Severity `
                        -Category "Quality" `
                        -Description $pattern.Description `
                        -Recommendation $pattern.Recommendation
                }
            }
        }
    }
}

function Invoke-ArchitectureReview {
    Write-ReviewHeader "Architecture Review (architecture-governance)"
    
    $structureIssues = @()
    
    $srcDir = Join-Path $Path "src"
    $libDir = Join-Path $Path "lib"
    $internalDir = Join-Path $Path "internal"
    
    if (-not (Test-Path $srcDir) -and -not (Test-Path $libDir) -and -not (Test-Path $internalDir)) {
        Add-Issue -File $Path -Title "Missing source directory structure" -Severity "MEDIUM" -Category "Architecture" -Description "No standard source directory found (src/, lib/, internal/)" -Recommendation "Organize code in standard directory structure"
    }
    
    $files = Get-ChildItem -Path $Path -Recurse -Include "*.ts", "*.tsx", "*.js", "*.jsx" -File -ErrorAction SilentlyContinue | Where-Object {
        $_.DirectoryName -notmatch "node_modules|\.git|dist|build" -and $_.Name -match "^(index|main|app)\."
    }
    
    if ($files.Count -gt 10) {
        Add-Issue -File $Path -Title "Too many root-level entry files" -Severity "LOW" -Category "Architecture" -Description "Found $($files.Count) entry files in root" -Recommendation "Consider organizing in src/ directory"
    }
    
    $bigFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ts", "*.tsx", "*.js", "*.jsx" -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Length -gt 100KB
    }
    
    foreach ($bigFile in $bigFiles) {
        Add-Issue -File $bigFile.FullName -Title "Large file detected ($([Math]::Round($bigFile.Length/1KB))KB)" -Severity "MEDIUM" -Category "Architecture" -Description "File exceeds 100KB" -Recommendation "Consider splitting into smaller modules"
    }
}

function Invoke-TestingReview {
    Write-ReviewHeader "Testing Review (testing-skill)"
    
    $hasTests = $false
    $testPatterns = @("*.spec.ts", "*.test.ts", "*_test.go", "*_test.py", "*.spec.js", "*.test.js")
    
    foreach ($pattern in $testPatterns) {
        $tests = Get-ChildItem -Path $Path -Recurse -Include $pattern -ErrorAction SilentlyContinue | Where-Object {
            $_.DirectoryName -notmatch "node_modules|\.git"
        }
        if ($tests) { $hasTests = $true; break }
    }
    
    if (-not $hasTests) {
        Add-Issue -File $Path -Title "No tests found" -Severity "HIGH" -Category "Testing" -Description "No test files detected in project" -Impact "Code changes may break functionality undetected" -Recommendation "Add unit and integration tests"
    }
    
    $srcFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ts", "*.tsx", "*.js", "*.jsx" -File -ErrorAction SilentlyContinue | Where-Object {
        $_.DirectoryName -notmatch "node_modules|\.git|dist|build|tests?|__tests?__" -and $_.Name -notmatch "\.(spec|test)\."
    }
    
    $testFiles = Get-ChildItem -Path $Path -Recurse -Include "*.spec.ts", "*.test.ts", "*.spec.js", "*.test.js" -File -ErrorAction SilentlyContinue | Where-Object {
        $_.DirectoryName -notmatch "node_modules|\.git"
    }
    
    if ($srcFiles.Count -gt 0 -and $testFiles.Count -gt 0) {
        $coverage = [Math]::Round(($testFiles.Count / $srcFiles.Count) * 100)
        
        if ($coverage -lt 50) {
            Add-Issue -File $Path -Title "Low test coverage ($coverage%)" -Severity "HIGH" -Category "Testing" -Description "Test coverage is below 50%" -Impact "High risk of undetected bugs" -Recommendation "Aim for at least 70% test coverage"
        }
    }
}

function Invoke-DocumentationReview {
    Write-ReviewHeader "Documentation Review (documentation-governance)"
    
    $docs = @{
        "README.md" = $false
        "docs/" = $false
    }
    
    if (Test-Path (Join-Path $Path "README.md")) { $docs["README.md"] = $true }
    if (Test-Path (Join-Path $Path "docs")) { $docs["docs/"] = $true }
    
    foreach ($doc in $docs.GetEnumerator()) {
        if (-not $doc.Value) {
            $sev = if ($doc.Key -eq "README.md") { "HIGH" } else { "MEDIUM" }
            Add-Issue -File (Join-Path $Path $doc.Key) -Title "Missing $($doc.Key)" -Severity $sev -Category "Documentation" -Description "$($doc.Key) not found" -Recommendation "Create $($doc.Key) with project documentation"
        }
    }
    
    $readmeContent = Get-Content (Join-Path $Path "README.md") -Raw -ErrorAction SilentlyContinue
    if ($readmeContent) {
        $required = @("Installation", "Usage", "License")
        foreach ($req in $required) {
            if ($readmeContent -notmatch "(?i)$req") {
                Add-Issue -File "README.md" -Title "README missing '$req' section" -Severity "LOW" -Category "Documentation" -Recommendation "Add '$req' section to README"
            }
        }
    }
}

function Invoke-APIReview {
    Write-ReviewHeader "API Design Review (api-design-skill)"
    
    $apiFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ts", "*.js" -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match "(route|controller|handler|api|endpoint)" -and $_.DirectoryName -notmatch "node_modules|\.git"
    }
    
    foreach ($apiFile in $apiFiles) {
        $content = Get-Content $apiFile.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content -match "(?i)(app\.(get|post|put|delete|patch)|router\.(get|post|put|delete|patch))") {
            if ($content -notmatch "(?i)(error|throw|reject)" -and $content -match "(?i)(async\s+function|await)") {
                Add-Issue -File $apiFile.FullName -Title "Missing error handling in API endpoint" -Severity "MEDIUM" -Category "API Design" -Description "API endpoint may not handle errors properly" -Recommendation "Add try-catch and error response handling"
            }
            
            if ($content -match "(?i)(req\.(params|query|body))" -and $content -notmatch "(?i)(validate|sanitize|parse)") {
                Add-Issue -File $apiFile.FullName -Title "Missing input validation in API endpoint" -Severity "HIGH" -Category "API Design" -Description "User input not validated before processing" -Impact = "Potential injection attacks" -Recommendation "Add input validation using Zod, Joi, or similar"
            }
        }
    }
}

function Invoke-GitWorkflowReview {
    Write-ReviewHeader "Git Workflow Review (git-workflow-skill)"
    
    $gitDir = Join-Path $Path ".git"
    if (-not (Test-Path $gitDir)) {
        Add-Issue -File $Path -Title "Not a Git repository" -Severity "HIGH" -Category "Git Workflow" -Description ".git directory not found" -Recommendation "Initialize Git repository"
        return
    }
    
    $hooksDir = Join-Path $Path ".git\hooks"
    $requiredHooks = @("pre-commit", "pre-push")
    
    foreach ($hook in $requiredHooks) {
        $hookPath = Join-Path $hooksDir $hook
        if (-not (Test-Path $hookPath)) {
            Add-Issue -File ".git/hooks/$hook" -Title "Missing $hook hook" -Severity "MEDIUM" -Category "Git Workflow" -Recommendation "Install Git hooks for code quality"
        }
    }
    
    if (Test-Path (Join-Path $Path "package.json")) {
        $packageJson = Get-Content (Join-Path $Path "package.json") -Raw | ConvertFrom-Json
        if ($packageJson.scripts -and $packageJson.scripts.commit -and $packageJson.scripts.commit -notmatch "cz|commitizen") {
            Add-Issue -File "package.json" -Title "Consider using conventional commits" -Severity "LOW" -Category "Git Workflow" -Recommendation "Use commitizen or similar for standardized commit messages"
        }
    }
}

function Get-ReportHeader {
    param([string]$Title, [string]$Scope, [datetime]$Date)
    
    $dateStr = $Date.ToString("yyyy-MM-dd HH:mm")
    $total = $Script:CRITICAL + $Script:HIGH + $Script:MEDIUM + $Script:LOW
    
    $severityCounts = @{
        Critical = $Script:CRITICAL
        High = $Script:HIGH
        Medium = $Script:MEDIUM
        Low = $Script:LOW
    }
    
    $categoryCounts = @{}
    foreach ($issue in $Script:ISSUES) {
        if (-not $categoryCounts.ContainsKey($issue.Category)) {
            $categoryCounts[$issue.Category] = @{ Total = 0; Critical = 0; High = 0; Medium = 0; Low = 0 }
        }
        $categoryCounts[$issue.Category].Total++
        $categoryCounts[$issue.Category][$issue.Severity]++
    }
    
    $categoryRows = ($categoryCounts.GetEnumerator() | ForEach-Object {
        "| $($_.Key) | $($_.Value.Total) | $($_.Value.Critical) | $($_.Value.High) | $($_.Value.Medium) | $($_.Value.Low) |"
    } | Out-String)
    
    $output = @"
# Code Review Report

**Date:** $dateStr  
**Scope:** $Scope  
**Total Issues:** $total ($Script:CRITICAL critical, $Script:HIGH high, $Script:MEDIUM medium, $Script:LOW low)

## Summary

### Issues by Severity

| Severity | Count | Action Required |
|----------|-------|----------------|
| CRITICAL | $Script:CRITICAL | Block deployment |
| HIGH | $Script:HIGH | Fix before merge |
| MEDIUM | $Script:MEDIUM | Review and fix |
| LOW | $Script:LOW | Consider fixing |

### Issues by Category

| Category | Total | Critical | High | Medium | Low |
|----------|-------|----------|------|--------|-----|
$categoryRows
"@
    
    return $output
}

function Get-IssuesBySeverity {
    param([string]$Severity)
    
    return $Script:ISSUES | Where-Object { $_.Severity -eq $Severity } | Sort-Object { $_.File }
}

function Get-ReportBody {
    $body = ""
    
    foreach ($severity in @("CRITICAL", "HIGH", "MEDIUM", "LOW")) {
        $issues = Get-IssuesBySeverity -Severity $severity
        if ($issues.Count -eq 0) { continue }
        
        $sectionName = switch ($severity) {
            "CRITICAL" { "Critical Issues (Action Required)" }
            "HIGH" { "High Priority Issues" }
            "MEDIUM" { "Medium Priority Issues" }
            "LOW" { "Low Priority Issues" }
        }
        
        $body += "`n## $sectionName`n`n"
        
        foreach ($issue in $issues) {
            $file = Split-Path $issue.File -Leaf
            $line = if ($issue.Line -gt 0) { ":$($issue.Line)" } else { "" }
            
            $body += "### $($issue.Id). [$($issue.Severity)] $($issue.Title)`n`n"
            $body += "**File:** \`$file\`\`$line\`n"
            $body += "**Category:** $($issue.Category)`n`n"
            
            if ($issue.Description) { $body += "**Issue:** $($issue.Description)`n`n" }
            if ($issue.Impact) { $body += "**Impact:** $($issue.Impact)`n`n" }
            if ($issue.Recommendation) { $body += "**Recommendation:** $($issue.Recommendation)`n`n" }
            
            if ($issue.Fix) {
                $body += "**Suggested Fix:**`n`````n$($issue.Fix)`n`````n`n"
            }
            
            $body += "---\n`n"
        }
    }
    
    return $body
}

function Get-ReportFooter {
    $actionItems = ($Script:ISSUES | ForEach-Object {
        "- [ ] [$($_.Severity)] $($_.Title) - $($_.File)"
    } | Out-String)
    
    $criticalItems = ($Script:ISSUES | Where-Object { $_.Severity -eq "CRITICAL" } | ForEach-Object { "1. $($_.Title)" } | Out-String)
    $highItems = ($Script:ISSUES | Where-Object { $_.Severity -eq "HIGH" } | Select-Object -First 5 | ForEach-Object { "1. $($_.Title)" } | Out-String)
    $mediumItems = ($Script:ISSUES | Where-Object { $_.Severity -eq "MEDIUM" } | Select-Object -First 3 | ForEach-Object { "1. $($_.Title)" } | Out-String)
    
    $filesScanned = (Get-ChildItem -Path $Path -Recurse -Include "*.ps1","*.js","*.ts","*.py","*.go","*.cs" -File -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -notmatch "node_modules|\.git|dist" }).Count
    $totalIssues = $Script:CRITICAL + $Script:HIGH + $Script:MEDIUM + $Script:LOW
    
    return @"
## Action Items

$actionItems

## Recommendations

### Immediate (Before Next Release)
$criticalItems

### Short Term (This Sprint)
$highItems

### Long Term (Tech Debt)
$mediumItems

## Statistics

- Review Duration: $([math]::Round(((Get-Date) - $Script:REVIEW_START).TotalSeconds)) seconds
- Files Scanned: $filesScanned
- Issues Found: $totalIssues

---
*Review generated by Workspace Foundation Code Review Orchestrator*
"@
}

function Export-IssuesToCSV {
    param([string]$OutputFile)
    
    $csv = $Script:ISSUES | ForEach-Object {
        [PSCustomObject]@{
            Id = $_.Id
            Severity = $_.Severity
            Category = $_.Category
            Title = $_.Title
            File = $_.File
            Line = $_.Line
            Status = $_.Status
        }
    }
    
    $csv | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
    Write-Host "  Issues exported to: $OutputFile" -ForegroundColor Green
}

Write-ReviewHeader "Code Review Orchestrator"
Write-Host " Scope: $Scope" -ForegroundColor Gray
Write-Host " Path: $Path" -ForegroundColor Gray
Write-Host ""

Write-ReviewProgress -Percent 0 -Message "Starting review..."

if ($Scope -eq "all" -or $Scope -eq "full") {
    Invoke-SecurityReview
    Write-ReviewProgress -Percent 30 -Message "Security reviewed"
    
    Invoke-QualityReview
    Write-ReviewProgress -Percent 40 -Message "Quality reviewed"
    
    Invoke-ArchitectureReview
    Write-ReviewProgress -Percent 55 -Message "Architecture reviewed"
    
    Invoke-TestingReview
    Write-ReviewProgress -Percent 70 -Message "Testing reviewed"
    
    Invoke-DocumentationReview
    Write-ReviewProgress -Percent 80 -Message "Documentation reviewed"
    
    Invoke-APIReview
    Write-ReviewProgress -Percent 90 -Message "API reviewed"
    
    Invoke-GitWorkflowReview
    Write-ReviewProgress -Percent 100 -Message "Complete"
}
elseif ($Scope -eq "security") {
    Invoke-SecurityReview
}
elseif ($Scope -eq "quality") {
    Invoke-SecurityReview
    Invoke-QualityReview
}
elseif ($Scope -eq "architecture") {
    Invoke-ArchitectureReview
}
elseif ($Scope -eq "testing") {
    Invoke-TestingReview
}
elseif ($Scope -eq "docs") {
    Invoke-DocumentationReview
}
elseif ($Scope -eq "api") {
    Invoke-APIReview
}
elseif ($Scope -eq "git") {
    Invoke-GitWorkflowReview
}
elseif ($Scope -eq "quick") {
    Invoke-SecurityReview
    Invoke-QualityReview
}

Write-Host ""
Write-ReviewHeader "Review Complete"
Write-Host "  Found: $($Script:CRITICAL + $Script:HIGH + $Script:MEDIUM + $Script:LOW) issues" -ForegroundColor $(if (($Script:CRITICAL + $Script:HIGH) -gt 0) { "Yellow" } else { "Green" })
Write-Host "    - $Script:CRITICAL critical" -ForegroundColor $(if ($Script:CRITICAL -gt 0) { "Red" } else { "Gray" })
Write-Host "    - $Script:HIGH high" -ForegroundColor $(if ($Script:HIGH -gt 0) { "Magenta" } else { "Gray" })
Write-Host "    - $Script:MEDIUM medium" -ForegroundColor $(if ($Script:MEDIUM -gt 0) { "Yellow" } else { "Gray" })
Write-Host "    - $Script:LOW low" -ForegroundColor Gray

if ($Report -or $OutputPath) {
    Write-ReviewHeader "Generating Report..."
    
    $reportDir = Join-Path $Path $OutputPath
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $dateStr = (Get-Date).ToString("yyyy-MM-dd-HHmmss")
    $reportFile = Join-Path $reportDir "$dateStr-$Scope-review.md"
    
    $headerOutput = Get-ReportHeader -Title "Code Review" -Scope $Scope -Date $Script:REVIEW_START
    $bodyOutput = Get-ReportBody
    $footerOutput = Get-ReportFooter
    
    $fullReport = $headerOutput + $bodyOutput + $footerOutput
    
    $fullReport | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "  Report saved to: $reportFile" -ForegroundColor Green
    
    if ($Track) {
        $csvFile = Join-Path $reportDir "$dateStr-issues.csv"
        Export-IssuesToCSV -OutputFile $csvFile
    }
}

if ($Interactive) {
    Write-Host ""
    Write-Host " Interactive Mode:" -ForegroundColor Yellow
    Write-Host "  1) View all issues" -ForegroundColor White
    Write-Host "  2) View by category" -ForegroundColor White
    Write-Host "  3) Get fix suggestion" -ForegroundColor White
    Write-Host "  4) Export to CSV" -ForegroundColor White
    Write-Host "  5) Exit" -ForegroundColor White
    
    $choice = Read-Host "`nSelect option [1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    
    switch ($choice) {
        "1" {
            Write-Host "`n## All Issues`n" -ForegroundColor Cyan
            foreach ($issue in $Script:ISSUES) {
                $color = switch ($issue.Severity) {
                    "CRITICAL" { "Red" }
                    "HIGH" { "Magenta" }
                    "MEDIUM" { "Yellow" }
                    default { "White" }
                }
                Write-Host "$($issue.Id)) [$($issue.Severity)] [$($issue.Category)] $($issue.Title)" -ForegroundColor $color
                Write-Host "   File: $($issue.File)" -ForegroundColor Gray
                if ($issue.Recommendation) { Write-Host "   Fix: $($issue.Recommendation)" -ForegroundColor Green }
                Write-Host ""
            }
        }
        "4" {
            $csvFile = Join-Path $Path "issues.csv"
            Export-IssuesToCSV -OutputFile $csvFile
        }
    }
}

if ($Script:CRITICAL -gt 0) {
    Write-Host "`n[ACTION REQUIRED] Critical issues found. Review report and fix before proceeding." -ForegroundColor Red
    exit 1
}

exit 0
