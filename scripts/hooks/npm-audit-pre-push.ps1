# npm-audit-pre-push.ps1
# Security gate: block push if vulnerabilities exist at moderate level or above
# Reference: npm-security-best-practices (supply-chain hardening)

param(
    [ValidateSet("critical", "high", "moderate", "low")]
    [string]$AuditLevel = "moderate",
    
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

Write-Host "`n[npm-audit] Running npm vulnerability scan..." -ForegroundColor Cyan

# Check if package.json exists
if (-not (Test-Path "package.json")) {
    Write-Host "[npm-audit] No package.json found, skipping audit" -ForegroundColor Yellow
    exit 0
}

# Run npm audit
$auditResult = $null
try {
    $auditJson = npm audit --json 2>&1
    $auditResult = $auditJson | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    if (-not $auditResult) {
        Write-Host "[npm-audit] Invalid audit JSON, retrying with text output..." -ForegroundColor Yellow
        $auditText = npm audit 2>&1
        Write-Host $auditText
        
        # Check if audit failed
        if ($LASTEXITCODE -ne 0 -and $auditText -match 'vulnerabilities') {
            Write-Host "[BLOCKED] npm audit found vulnerabilities" -ForegroundColor Red
            Write-Host "`nTo fix vulnerabilities:" -ForegroundColor Yellow
            Write-Host "  npm audit fix" -ForegroundColor White
            Write-Host "  npm audit fix --force  (if needed)" -ForegroundColor White
            exit 1
        }
        exit 0
    }
}
catch {
    Write-Host "[npm-audit] Error running audit: $_" -ForegroundColor Yellow
    # Don't fail on audit parse errors, but warn
    exit 0
}

# Extract vulnerability counts
$vulnerabilities = $auditResult.metadata.vulnerabilities

if ($Verbose) {
    Write-Host "[npm-audit] Vulnerability summary:" -ForegroundColor Cyan
    Write-Host "  Critical:  $($vulnerabilities.critical)" -ForegroundColor $(if ($vulnerabilities.critical -gt 0) { "Red" } else { "Green" })
    Write-Host "  High:      $($vulnerabilities.high)" -ForegroundColor $(if ($vulnerabilities.high -gt 0) { "Red" } else { "Green" })
    Write-Host "  Moderate:  $($vulnerabilities.moderate)" -ForegroundColor $(if ($vulnerabilities.moderate -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  Low:       $($vulnerabilities.low)" -ForegroundColor $(if ($vulnerabilities.low -gt 0) { "White" } else { "Green" })
}

# Check against threshold
$blockLevels = @{
    "critical" = @("critical")
    "high"     = @("critical", "high")
    "moderate" = @("critical", "high", "moderate")
    "low"      = @("critical", "high", "moderate", "low")
}

$hasBlockingVuln = $false
foreach ($level in $blockLevels[$AuditLevel]) {
    if ($vulnerabilities.$level -gt 0) {
        $hasBlockingVuln = $true
        break
    }
}

if ($hasBlockingVuln) {
    Write-Host "`n[BLOCKED] npm audit found vulnerabilities at $AuditLevel level or above" -ForegroundColor Red
    Write-Host "`nTo fix:" -ForegroundColor Yellow
    Write-Host "  1. Run: npm audit fix" -ForegroundColor White
    Write-Host "  2. Review changes to package-lock.json" -ForegroundColor White
    Write-Host "  3. Test changes: npm test" -ForegroundColor White
    Write-Host "  4. Commit: git add package-lock.json && git commit -m 'fix(security): resolve npm vulnerabilities'" -ForegroundColor White
    Write-Host "  5. Push again" -ForegroundColor White
    Write-Host "`nFor force push (not recommended):" -ForegroundColor Yellow
    Write-Host "  git push --no-verify" -ForegroundColor White
    exit 1
}

Write-Host "[OK] npm audit passed (audit-level: $AuditLevel)" -ForegroundColor Green
exit 0
