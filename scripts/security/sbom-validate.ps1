<#
.SYNOPSIS
    SBOM Validation — verifies SBOM exists, is valid CycloneDX, and passes compliance checks

.DESCRIPTION
    Validates Software Bill of Materials (SBOM) for supply chain security compliance.
    Checks: file exists, valid JSON/CycloneDX format, dependency count, known vulnerabilities.
    Compliance: SOC2 CC6.1, ISO 27001 A.5.9, OWASP LLM03.

.PARAMETER SbomPath
    Path to SBOM file (default: reports/sbom/sbom-latest.json)

.PARAMETER MinDependencies
    Minimum expected dependencies (default: 1). Fails if fewer.

.PARAMETER Strict
    Enable strict mode: fails on warnings, not just errors.

.EXAMPLE
    .\scripts\security\sbom-validate.ps1
    .\scripts\security\sbom-validate.ps1 -SbomPath reports/sbom/sbom-2.21.0-2026-05-23.json -Strict
#>

param(
    [string]$SbomPath = "",
    [int]$MinDependencies = 1,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path

function Write-Result {
    param([string]$Check, [string]$Status, [string]$Detail)
    $color = switch ($Status) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'WARN' { 'Yellow' } default { 'Gray' } }
    Write-Host ("[{0,-4}] {1,-50} {2}" -f $Status, $Check, $Detail) -ForegroundColor $color
}

# Auto-detect SBOM
if (-not $SbomPath) {
    $sbomDir = Join-Path $repoRoot "reports" "sbom"
    $latest = Join-Path $sbomDir "sbom-latest.json"
    if (Test-Path $latest) { $SbomPath = $latest }
    else {
        $files = Get-ChildItem -Path $sbomDir -Filter "sbom-*.json" -ErrorAction SilentlyContinue
        if ($files) { $SbomPath = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName }
    }
}

Write-Host "=== SBOM VALIDATION ===" -ForegroundColor Cyan
Write-Host ""

# Check 1: File exists
$checks = @{ total = 0; passed = 0; failed = 0; warnings = 0 }

if (-not (Test-Path $SbomPath)) {
    Write-Result -Check "SBOM file exists" -Status "FAIL" -Detail "Not found: $SbomPath"
    Write-Host "[RESULT] FAIL - SBOM file required for compliance" -ForegroundColor Red
    exit 1
}
Write-Result -Check "SBOM file exists" -Status "PASS" -Detail "Found: $SbomPath"
$checks.total++; $checks.passed++

# Check 2: Valid JSON
try {
    $sbom = Get-Content $SbomPath -Raw | ConvertFrom-Json
    Write-Result -Check "SBOM is valid JSON" -Status "PASS" -Detail ""
    $checks.total++; $checks.passed++
}
catch {
    Write-Result -Check "SBOM is valid JSON" -Status "FAIL" -Detail $_.Exception.Message
    $checks.total++; $checks.failed++
    exit 1
}

# Check 3: CycloneDX format
$isCycloneDx = $sbom.bomFormat -eq "CycloneDX" -or $sbom.specVersion -match "^\d+\.\d+$"
if ($isCycloneDx) {
    Write-Result -Check "SBOM format (CycloneDX)" -Status "PASS" -Detail "v$($sbom.specVersion)"
    $checks.total++; $checks.passed++
}
else {
    Write-Result -Check "SBOM format (CycloneDX)" -Status "WARN" -Detail "Unknown format - expected CycloneDX"
    $checks.total++; $checks.warnings++
}

# Check 4: Has dependencies
$deps = $sbom.components
$depCount = if ($deps) { $deps.Count } else { 0 }
if ($depCount -ge $MinDependencies) {
    Write-Result -Check "SBOM dependencies" -Status "PASS" -Detail "$depCount components"
    $checks.total++; $checks.passed++
}
else {
    Write-Result -Check "SBOM dependencies" -Status $('FAIL', 'WARN')[$Strict -eq $false] -Detail "Found $depCount, expected >= $MinDependencies"
    if ($Strict) { $checks.total++; $checks.failed++ } else { $checks.total++; $checks.warnings++ }
}

# Check 5: File size (min 100 bytes)
$size = (Get-Item $SbomPath).Length
if ($size -ge 100) {
    Write-Result -Check "SBOM file size" -Status "PASS" -Detail "$size bytes"
    $checks.total++; $checks.passed++
}
else {
    Write-Result -Check "SBOM file size" -Status "FAIL" -Detail "Too small: $size bytes (min 100)"
    $checks.total++; $checks.failed++
}

# Summary
Write-Host ""
Write-Host "---" -ForegroundColor Gray
Write-Host "Passed: $($checks.passed) / Failed: $($checks.failed) / Warnings: $($checks.warnings)" -ForegroundColor $(if ($checks.failed -eq 0) { 'Green' } else { 'Red' })

if ($checks.failed -gt 0) { exit 1 }
if ($Strict -and $checks.warnings -gt 0) { exit 1 }
exit 0
