#!/usr/bin/env pwsh
# security-scan.ps1 - Security Expert Scanner
# Scans code for security issues before commit

param(
    [switch]$Audit,
    [switch]$Report,
    [switch]$Fix,
    [string]$Path = ".",
    [switch]$Interactive,
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'

$Script:ISSUES = @()
$Script:CRITICAL = 0
$Script:HIGH = 0
$Script:MEDIUM = 0
$Script:LOW = 0
$Script:PROJECT_ROOT = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { "." }

function Write-SecurityHeader {
    param([string]$Text, [string]$Color = 'Cyan')
    Write-Host ""
    Write-Host " [SECURITY] $Text" -ForegroundColor $Color
}

function Write-SecurityIssue {
    param(
        [string]$File,
        [int]$Line,
        [string]$Issue,
        [string]$Severity = "HIGH",
        [string]$Description,
        [string]$Recommendation
    )
    
    $color = switch ($Severity) {
        "CRITICAL" { "Red" }
        "HIGH" { "Magenta" }
        "MEDIUM" { "Yellow" }
        "LOW" { "Gray" }
        default { "White" }
    }
    
    $script:ISSUES += @{
        File = $File
        Line = $Line
        Issue = $Issue
        Severity = $Severity
        Description = $Description
        Recommendation = $Recommendation
    }
    
    switch ($Severity) {
        "CRITICAL" { $script:CRITICAL++ }
        "HIGH" { $script:HIGH++ }
        "MEDIUM" { $script:MEDIUM++ }
        "LOW" { $script:LOW++ }
    }
    
    $location = if ($Line -gt 0) { "$File`:$Line" } else { $File }
    Write-Host "  [$Severity] $location - $Issue" -ForegroundColor $color
    
    if ($Verbose -and $Description) {
        Write-Host "         $Description" -ForegroundColor DarkGray
    }
}

function Invoke-SecretDetection {
    Write-SecurityHeader "Scanning for exposed secrets..."
    
    $secretPatterns = @(
        @{ Name = "AWS Access Key"; Pattern = "AKIA[0-9A-Z]{16}"; Severity = "CRITICAL" },
        @{ Name = "AWS Secret Key"; Pattern = "(?i)aws_secret_access_key[`"'\s]*[=:]?[`"'\s]*[A-Za-z0-9/+=]{40}[`"']"; Severity = "CRITICAL" },
        @{ Name = "GitHub Token"; Pattern = "ghp_[A-Za-z0-9]{36}"; Severity = "CRITICAL" },
        @{ Name = "GitHub OAuth"; Pattern = "gho_[A-Za-z0-9]{36}"; Severity = "CRITICAL" },
        @{ Name = "Private Key"; Pattern = "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"; Severity = "CRITICAL" },
        @{ Name = "Generic API Key"; Pattern = "(?i)(api[_-]?key|apikey)[`"'\s]*[=:][`"'\s]*[A-Za-z0-9]{20,}"; Severity = "HIGH" },
        @{ Name = "Bearer Token"; Pattern = "(?i)bearer\s+[A-Za-z0-9_\-\.]+"; Severity = "HIGH" },
        @{ Name = "Basic Auth"; Pattern = "(?i)basic\s+[A-Za-z0-9+=]+"; Severity = "HIGH" },
        @{ Name = "JWT Token"; Pattern = "eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+"; Severity = "HIGH" },
        @{ Name = "Database URL"; Pattern = "(?i)(mysql|postgres|mongodb)://[^:\s]+:[^@\s]+@"; Severity = "HIGH" },
        @{ Name = "Password in URL"; Pattern = "[?&][Pp]assword=[^&\s]+"; Severity = "HIGH" },
        @{ Name = "Slack Token"; Pattern = "xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[A-Za-z0-9]+"; Severity = "HIGH" },
        @{ Name = "Stripe Key"; Pattern = "sk_live_[0-9a-zA-Z]{24,}"; Severity = "CRITICAL" },
        @{ Name = "Stripe Publishable"; Pattern = "pk_live_[0-9a-zA-Z]{24,}"; Severity = "MEDIUM" },
        @{ Name = "SendGrid Key"; Pattern = "SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}"; Severity = "CRITICAL" },
        @{ Name = "Google API Key"; Pattern = "AIza[0-9A-Za-z_-]{35}"; Severity = "HIGH" },
        @{ Name = "Firebase Key"; Pattern = "[A-Fa-f0-9]{32}:(?:android|ios):[a-f0-9]{32}"; Severity = "HIGH" },
        @{ Name = "Hardcoded Password"; Pattern = "(?i)(password|passwd|pwd)[`"'\s]*[=:][`"'\s]*[a-zA-Z0-9]{4,}"; Severity = "MEDIUM" },
        @{ Name = "Secret Variable"; Pattern = "(?i)SECRET[`"'\s]*[=:][`"'\s]*[a-zA-Z0-9]{8,}"; Severity = "HIGH" },
        @{ Name = "Token Variable"; Pattern = "(?i)TOKEN[`"'\s]*[=:][`"'\s]*[a-zA-Z0-9]{8,}"; Severity = "HIGH" }
    )
    
    $extensions = @("*.ps1", "*.js", "*.ts", "*.tsx", "*.jsx", "*.py", "*.go", "*.java", "*.cs", "*.rb", "*.php", "*.json", "*.yaml", "*.yml", "*.xml", "*.env", "*.sh", "*.bash", "*.sql", "*.md", "*.txt")
    
    $excludeDirs = @("node_modules", ".git", "dist", "build", "coverage", ".next", ".nuxt", "vendor", "__pycache__", "venv", ".venv")
    
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -Path $Path -Recurse -Include $ext -File -ErrorAction SilentlyContinue | Where-Object {
            $dir = $_.DirectoryName
            -not ($excludeDirs | Where-Object { $dir -match [regex]::Escape($_) })
        }
        
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }
            
            foreach ($secretPattern in $secretPatterns) {
                if ($content -match $secretPattern.Pattern) {
                    $lineNumber = 0
                    $lines = Get-Content $file.FullName
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i] -match $secretPattern.Pattern) {
                            $lineNumber = $i + 1
                            break
                        }
                    }
                    
                    Write-SecurityIssue `
                        -File $file.FullName `
                        -Line $lineNumber `
                        -Issue $secretPattern.Name `
                        -Severity $secretPattern.Severity `
                        -Description "Potential $($secretPattern.Name.ToLower()) detected in code" `
                        -Recommendation "Remove or use environment variables. Store secrets in .env files excluded from version control."
                }
            }
        }
    }
}

function Invoke-VulnerabilityScan {
    Write-SecurityHeader "Scanning for vulnerability patterns..."
    
    $vulnPatterns = @(
        @{ Name = "Eval with User Input"; Pattern = "eval\s*\(\s*.*(?:req\.|request\.|body\.|params\.|query\.|input\.)"; Severity = "CRITICAL"; Lang = "js,ts" },
        @{ Name = "InnerHTML with User Input"; Pattern = "(innerHTML|outerHTML|insertAdjacentHTML)\s*\(\s*.*(?:req\.|request\.|body\.|params\.|query\.)"; Severity = "HIGH"; Lang = "js,ts" },
        @{ Name = "SQL Query with String Concatenation"; Pattern = "(?:execute|query|select|insert|update|delete).*\+.*(?:req\.|request\.|body\.|params\.)"; Severity = "CRITICAL"; Lang = "js,py,cs,java" },
        @{ Name = "Command Injection Risk"; Pattern = "(?:exec|spawn|execSync|system|popen|os\.system|subprocess)\s*\(\s*.*(?:req\.|request\.|body\.|params\.|query\.)"; Severity = "CRITICAL"; Lang = "js,py,cs,java" },
        @{ Name = "Path Traversal"; Pattern = "(?:readFile|readFileSync|open|readdir|stat).*\.join\(.*(?:req\.|request\.|params\.)"; Severity = "HIGH"; Lang = "js,ts" },
        @{ Name = "Insecure Crypto (MD5)"; Pattern = "(?:createHash|md5)\s*\("; Severity = "HIGH"; Lang = "js,ts,py,cs,java" },
        @{ Name = "CORS Allow All"; Pattern = "(?:Access-Control-Allow-Origin|CORS)\s*\*"; Severity = "HIGH"; Lang = "js,ts" },
        @{ Name = "No Rate Limiting"; Pattern = "(?i)(rateLimit|express-rate-limit).*disabled"; Severity = "HIGH"; Lang = "js,ts" },
        @{ Name = "Session Cookie Insecure"; Pattern = "cookie.*secure\s*[:=]\s*false"; Severity = "HIGH"; Lang = "js,ts" },
        @{ Name = "YAML Unsafe Load"; Pattern = "yaml\.load\s*\("; Severity = "HIGH"; Lang = "py" },
        @{ Name = "Pickle Unsafe"; Pattern = "(?:pickle\.load|pickle\.loads)\s*\("; Severity = "CRITICAL"; Lang = "py" },
        @{ Name = "Security Issues"; Pattern = "(?i)(HACK|XXX).*(?:security|auth|crypto|credential|token)"; Severity = "LOW"; Lang = "*" }
    )
    
    $extensions = @{
        "js" = @("*.js", "*.jsx")
        "ts" = @("*.ts", "*.tsx")
        "py" = @("*.py")
        "cs" = @("*.cs")
        "java" = @("*.java")
        "*" = @("*.js", "*.ts", "*.tsx", "*.jsx", "*.py", "*.cs", "*.java", "*.go", "*.rb", "*.php")
    }
    
    foreach ($vuln in $vulnPatterns) {
        $langExtensions = if ($extensions.ContainsKey($vuln.Lang)) { $extensions[$vuln.Lang] } else { $extensions["*"] }
        
        foreach ($ext in $langExtensions) {
            $files = Get-ChildItem -Path $Path -Recurse -Include $ext -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                if (-not $content) { continue }
                
                if ($content -match $vuln.Pattern) {
                    $lineNumber = 0
                    $lines = Get-Content $file.FullName
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i] -match $vuln.Pattern) {
                            $lineNumber = $i + 1
                            break
                        }
                    }
                    
                    Write-SecurityIssue `
                        -File $file.FullName `
                        -Line $lineNumber `
                        -Issue $vuln.Name `
                        -Severity $vuln.Severity `
                        -Description "Potential security vulnerability detected" `
                        -Recommendation "Review OWASP guidelines and implement secure alternative"
                }
            }
        }
    }
}

function Invoke-DependencyScan {
    Write-SecurityHeader "Scanning dependencies for vulnerabilities..."
    
    if (Test-Path "package.json") {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            Write-Host "  Running npm audit..." -ForegroundColor Gray
            try {
                $audit = npm audit --json 2>$null | ConvertFrom-Json
                if ($audit -and $audit.metadata.vulnerability_count -gt 0) {
                    foreach ($vuln in $audit.vulnerabilities.PSObject.Properties) {
                        $sev = switch ($vuln.Value.severity) {
                            "critical" { "CRITICAL" }
                            "high" { "HIGH" }
                            "medium" { "MEDIUM" }
                            "low" { "LOW" }
                            default { "MEDIUM" }
                        }
                        Write-SecurityIssue -File "package.json" -Line 0 -Issue "Vulnerable dependency: $($vuln.Name)" -Severity $sev -Description "$($vuln.Value.title)" -Recommendation "Update to latest secure version"
                    }
                }
            } catch {
                Write-Host "  npm audit not available or failed" -ForegroundColor Yellow
            }
        }
    }
    
    if (Test-Path "requirements.txt") {
        if (Get-Command pip -ErrorAction SilentlyContinue) {
            Write-Host "  Running pip audit..." -ForegroundColor Gray
        }
    }
    
    if (Test-Path "go.mod") {
        if (Get-Command govulncheck -ErrorAction SilentlyContinue) {
            Write-Host "  Running govulncheck..." -ForegroundColor Gray
        }
    }
}

function Invoke-SecurityReport {
    param([string]$OutputPath = "docs/security-review.md")
    
    Write-SecurityHeader "Generating Security Report..."
    
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $total = $script:CRITICAL + $script:HIGH + $script:MEDIUM + $script:LOW
    
    $report = @"
# Security Review Report

**Date:** $date  
**Scope:** $Path  
**Total Issues:** $total ($script:CRITICAL critical, $script:HIGH high, $script:MEDIUM medium, $script:LOW low)

## Executive Summary

$(if ($total -eq 0) {
    "No security issues detected. The codebase appears to follow security best practices."
} elseif ($script:CRITICAL -gt 0) {
    "CRITICAL issues detected that require immediate attention. Do not deploy until resolved."
} elseif ($script:HIGH -gt 0) {
    "High severity issues detected. Review recommended before production deployment."
} else {
    "Issues found are mostly informational. Consider addressing medium/low issues."
})

## Issues by Severity

| Severity | Count | Action Required |
|----------|-------|-----------------|
| CRITICAL | $script:CRITICAL | Block deployment |
| HIGH | $script:HIGH | Fix before merge |
| MEDIUM | $script:MEDIUM | Review and fix |
| LOW | $script:LOW | Consider fixing |

"@

    if ($script:CRITICAL -gt 0) {
        $report += "`n## Critical Issues`n`n"
        $report += "| File | Issue | Recommendation |`n"
        $report += "|------|-------|----------------|`n"
        foreach ($issue in $script:ISSUES | Where-Object { $_.Severity -eq "CRITICAL" }) {
            $file = Split-Path $issue.File -Leaf
            $line = if ($issue.Line -gt 0) { ":$($issue.Line)" } else { "" }
            $report += "| $file$line | $($issue.Issue) | $($issue.Recommendation) |`n"
        }
    }
    
    if ($script:HIGH -gt 0) {
        $report += "`n## High Priority Issues`n`n"
        $report += "| File | Issue | Recommendation |`n"
        $report += "|------|-------|----------------|`n"
        foreach ($issue in $script:ISSUES | Where-Object { $_.Severity -eq "HIGH" }) {
            $file = Split-Path $issue.File -Leaf
            $line = if ($issue.Line -gt 0) { ":$($issue.Line)" } else { "" }
            $report += "| $file$line | $($issue.Issue) | $($issue.Recommendation) |`n"
        }
    }
    
    if ($script:MEDIUM -gt 0) {
        $report += "`n## Medium Priority Issues`n`n"
        $report += "| File | Issue |`n"
        $report += "|------|-------|`n"
        foreach ($issue in $script:ISSUES | Where-Object { $_.Severity -eq "MEDIUM" }) {
            $file = Split-Path $issue.File -Leaf
            $line = if ($issue.Line -gt 0) { ":$($issue.Line)" } else { "" }
            $report += "| $file$line | $($issue.Issue) |`n"
        }
    }
    
    if ($script:LOW -gt 0) {
        $report += "`n## Low Priority Issues`n`n"
        $report += "| File | Issue |`n"
        $report += "|------|-------|`n"
        foreach ($issue in $script:ISSUES | Where-Object { $_.Severity -eq "LOW" }) {
            $file = Split-Path $issue.File -Leaf
            $line = if ($issue.Line -gt 0) { ":$($issue.Line)" } else { "" }
            $report += "| $file$line | $($issue.Issue) |`n"
        }
    }
    
    $report += @"

## Recommendations

1. **Immediate:** Fix all CRITICAL and HIGH severity issues
2. **Short-term:** Review MEDIUM issues and address where applicable
3. **Long-term:** Implement security training and code review processes
4. **Monitoring:** Set up automated security scanning in CI/CD

## Tools Used

- Secret Detection: Pattern matching (configurable)
- Vulnerability Scan: Static analysis patterns
- Dependency Scan: npm audit, safety, govulncheck

## Next Steps

1. Review the issues above
2. Apply recommended fixes
3. Re-run security scan
4. Commit changes
5. Update this report

---
*Report generated by Workspace Foundation Security Expert*
"@

    $outFile = Join-Path $Path $OutputPath
    $report | Out-File -FilePath $outFile -Encoding UTF8
    
    Write-Host "  Report saved to: $outFile" -ForegroundColor Green
}

function Invoke-InteractiveMode {
    if ($script:ISSUES.Count -eq 0) {
        Write-SecurityHeader "No issues found!" "Green"
        return
    }
    
    Write-Host ""
    Write-Host " Security issues detected. Choose action:" -ForegroundColor Yellow
    Write-Host "  1) View details" -ForegroundColor White
    Write-Host "  2) Generate full report" -ForegroundColor White
    Write-Host "  3) Skip (accept risk)" -ForegroundColor White
    Write-Host "  4) Exit" -ForegroundColor White
    
    $choice = Read-Host "`nSelect option [1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    
    switch ($choice) {
        "1" {
            Write-Host "`n## Detailed Issues`n" -ForegroundColor Cyan
            $i = 1
            foreach ($issue in $script:ISSUES) {
                Write-Host "$i) [$($issue.Severity)] $($issue.File):$($issue.Line)" -ForegroundColor $(if ($issue.Severity -eq "CRITICAL") { "Red" } elseif ($issue.Severity -eq "HIGH") { "Magenta" } else { "White" })
                Write-Host "   Issue: $($issue.Issue)" -ForegroundColor Gray
                if ($issue.Description) { Write-Host "   Description: $($issue.Description)" -ForegroundColor DarkGray }
                if ($issue.Recommendation) { Write-Host "   Recommendation: $($issue.Recommendation)" -ForegroundColor Green }
                Write-Host ""
                $i++
            }
        }
        "2" { Invoke-SecurityReport }
        "3" {
            Write-Warning "Risk accepted. Commit will proceed with warnings."
        }
        "4" { exit 0 }
    }
}

Write-SecurityHeader "Security Expert Scanner"
Write-Host " Path: $Path" -ForegroundColor Gray
$modeText = if ($Audit) { "Audit" } elseif ($Report) { "Report" } elseif ($Fix) { "Fix" } else { "Scan" }
Write-Host " Mode: $modeText" -ForegroundColor Gray
Write-Host ""

Invoke-SecretDetection
Invoke-VulnerabilityScan

if ($Audit) {
    Invoke-DependencyScan
}

Write-Host ""
Write-SecurityHeader "Scan Complete"
Write-Host "  Found: $total issues" -ForegroundColor $(if ($total -eq 0) { "Green" } elseif ($CRITICAL -gt 0 -or $HIGH -gt 0) { "Red" } else { "Yellow" })
Write-Host "    - $script:CRITICAL critical" -ForegroundColor $(if ($script:CRITICAL -gt 0) { "Red" } else { "Gray" })
Write-Host "    - $script:HIGH high" -ForegroundColor $(if ($script:HIGH -gt 0) { "Magenta" } else { "Gray" })
Write-Host "    - $script:MEDIUM medium" -ForegroundColor $(if ($script:MEDIUM -gt 0) { "Yellow" } else { "Gray" })
Write-Host "    - $script:LOW low" -ForegroundColor Gray

if ($Report) {
    Invoke-SecurityReport
}

if ($Interactive -or ($PSBoundParameters.Count -eq 0 -and -not $Report -and -not $Audit -and -not $Fix)) {
    if ($script:ISSUES.Count -gt 0) {
        Invoke-InteractiveMode
    }
}

if ($CRITICAL -gt 0) {
    Write-Host "`n[BLOCKED] Critical issues found. Fix before commit." -ForegroundColor Red
    exit 1
}

if ($HIGH -gt 0 -and -not $Interactive) {
    Write-Host "`n[WARNING] High severity issues found. Review recommended." -ForegroundColor Yellow
}

exit 0
