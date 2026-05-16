#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate Software Bill of Materials (SBOM) for the gv release.

.DESCRIPTION
    Generates a CycloneDX-compatible SBOM in JSON format capturing all npm
    dependencies. Tries @cyclonedx/npm (via npx workspace) first; falls back
    to building a minimal BOM from npm list --json.

    Output is written to reports/sbom/ with both a versioned file and
    sbom-latest.json for CI/tooling consumption.

.PARAMETER RepoRoot
    Root path of the repository. Defaults to two directories above this script.

.PARAMETER Version
    Release version string (e.g. "2.4.1"). If omitted, reads from VERSION file.

.PARAMETER OutputDir
    Directory for SBOM artifacts. Defaults to <RepoRoot>/reports/sbom.

.PARAMETER Quiet
    Suppress non-essential output.

.EXAMPLE
    .\generate-sbom.ps1
    .\generate-sbom.ps1 -Version "2.5.0" -Quiet
#>

param(
    [string]$RepoRoot = '',
    [string]$Version  = '',
    [string]$OutputDir = '',
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

# ─── Resolve paths ────────────────────────────────────────────────────────────
if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}
if (-not (Test-Path $RepoRoot)) {
    throw "Repository root not found: $RepoRoot"
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $RepoRoot 'reports\sbom'
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# ─── Resolve version ──────────────────────────────────────────────────────────
if (-not $Version) {
    $versionFile = Join-Path $RepoRoot 'VERSION'
    if (Test-Path $versionFile) {
        $Version = (Get-Content $versionFile -Raw).Trim()
    } else {
        $Version = 'unknown'
    }
}

$timestamp  = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
$dateStamp  = (Get-Date -Format 'yyyy-MM-dd')
$outFile    = Join-Path $OutputDir "sbom-$Version-$dateStamp.json"
$latestFile = Join-Path $OutputDir 'sbom-latest.json'

if (-not $Quiet) {
    Write-Host "[SBOM] Generating SBOM for version $Version ..." -ForegroundColor Cyan
}

# ─── Helper: build minimal BOM from npm list ──────────────────────────────────
function Build-FallbackBom {
    param([string]$Root, [string]$Ver, [string]$Ts)

    $packageJsonPath = Join-Path $Root 'package.json'
    $metadata = if (Test-Path $packageJsonPath) {
        Get-Content $packageJsonPath | ConvertFrom-Json
    } else {
        $null
    }

    $components = @()
    $npmListOutput = & npm list --json --all --prefix $Root 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue

    if ($npmListOutput -and $npmListOutput.dependencies) {
        function Flatten-Deps {
            param($deps, [int]$depth = 0)
            if (-not $deps -or $depth -gt 5) { return }
            foreach ($prop in $deps.PSObject.Properties) {
                $name = $prop.Name
                $dep  = $prop.Value
                $script:components += [ordered]@{
                    type    = 'library'
                    name    = $name
                    version = if ($dep.version) { $dep.version } else { 'unknown' }
                    scope   = if ($depth -eq 0) { 'required' } else { 'optional' }
                    purl    = "pkg:npm/$name@$($dep.version)"
                }
                if ($dep.dependencies) {
                    Flatten-Deps -deps $dep.dependencies -depth ($depth + 1)
                }
            }
        }
        $script:components = @()
        Flatten-Deps -deps $npmListOutput.dependencies
        $components = $script:components
    }

    $bom = [ordered]@{
        bomFormat   = 'CycloneDX'
        specVersion = '1.4'
        serialNumber = "urn:uuid:$([guid]::NewGuid())"
        version     = 1
        metadata    = [ordered]@{
            timestamp = $Ts
            tools     = @([ordered]@{ vendor = 'gentle-vanguard'; name = 'generate-sbom.ps1'; version = '1.0.0' })
            component = [ordered]@{
                type    = 'application'
                name    = if ($metadata -and $metadata.name) { $metadata.name } else { 'gentle-vanguard' }
                version = $Ver
            }
        }
        components  = $components
    }

    return $bom
}

# ─── Try CycloneDX npm via npx workspace ──────────────────────────────────────
$sbomGenerated = $false
$packageJsonPath = Join-Path $RepoRoot 'package.json'

if (Test-Path $packageJsonPath) {
    # Check if @cyclonedx/cyclonedx-npm is available locally
    $cdxBin = Join-Path $RepoRoot 'node_modules\.bin\cyclonedx-npm'
    if (-not (Test-Path $cdxBin)) {
        $cdxBin = $null
    }

    if ($cdxBin) {
        if (-not $Quiet) { Write-Host "[SBOM] Using @cyclonedx/cyclonedx-npm..." -ForegroundColor DarkGray }
        & $cdxBin --output-format JSON --output-file $outFile --project-dir $RepoRoot 2>$null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $outFile)) {
            $sbomGenerated = $true
            if (-not $Quiet) { Write-Host "[SBOM] CycloneDX generation succeeded." -ForegroundColor Green }
        }
    }
}

# ─── Fallback: build BOM from npm list ────────────────────────────────────────
if (-not $sbomGenerated) {
    if (-not $Quiet) { Write-Host "[SBOM] Building BOM from npm list (fallback)..." -ForegroundColor DarkGray }
    $bom = Build-FallbackBom -Root $RepoRoot -Ver $Version -Ts $timestamp
    $bom | ConvertTo-Json -Depth 20 | Set-Content -Path $outFile -Encoding UTF8
    $sbomGenerated = $true
    if (-not $Quiet) { Write-Host "[SBOM] Fallback BOM built ($($bom.components.Count) components)." -ForegroundColor Green }
}

# ─── Copy to latest ───────────────────────────────────────────────────────────
Copy-Item -Path $outFile -Destination $latestFile -Force

if (-not $Quiet) {
    Write-Host "[SBOM] Written: $outFile" -ForegroundColor Green
    Write-Host "[SBOM] Latest:  $latestFile" -ForegroundColor Green
}

exit 0

