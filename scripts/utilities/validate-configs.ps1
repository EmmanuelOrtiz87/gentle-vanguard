#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Validates all JSON config files and critical workspace invariants.

.DESCRIPTION
    Gate script - run before commit, release, or audit.
    Checks:
      1. All JSON config files parse without error
      2. auto-delegation.json has required top-level keys
      3. pre-process-input.ps1 exists and is non-empty
      4. All files listed in structure-policy.json#allowedRootMarkdownFiles exist
      5. hooks/ scripts exist for every hook registered in hooks-config.json
      6. All agentCodeToSkill values have a matching skills/ directory

.PARAMETER ConfigDir
    Path to config directory (default: config/)

.PARAMETER Strict
    Exit code 1 on any WARNING (not just errors).

.EXAMPLE
    pwsh -File tools/validate-configs.ps1
    pwsh -File tools/validate-configs.ps1 -Strict
#>
param(
    [string]$ConfigDir = 'config',
    [switch]$Strict
)

$ErrorActionPreference = 'Continue'
$Root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$errors  = 0
$warns   = 0

function Write-Pass([string]$msg)  { Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail([string]$msg)  { Write-Host "  [FAIL] $msg" -ForegroundColor Red;    $script:errors++ }
function Write-Warn([string]$msg)  { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:warns++ }

# --- 1. Parse all JSON config files --------------------------------------------
Write-Host "`n[1/6] JSON syntax" -ForegroundColor Cyan
Get-ChildItem (Join-Path $Root $ConfigDir) -Filter "*.json" | ForEach-Object {
    $fileName = $_.Name
    try   { $null = Get-Content $_.FullName -Raw | ConvertFrom-Json; Write-Pass $fileName }
    catch { Write-Fail "${fileName}: $($_.Exception.Message.Split("`n")[0])" }
}

# --- 2. auto-delegation.json required keys -------------------------------------
Write-Host "`n[2/6] auto-delegation.json required keys" -ForegroundColor Cyan
$adPath = Join-Path $Root $ConfigDir 'auto-delegation.json'
if (Test-Path $adPath) {
    $ad = Get-Content $adPath -Raw | ConvertFrom-Json
    foreach ($key in @('agentCodeToSkill','agentProfiles','keywordMappings','fallbackStrategy','confidenceThreshold')) {
        if ($null -ne $ad.$key) { Write-Pass $key }
        else                    { Write-Fail "auto-delegation.json missing key: $key" }
    }
} else {
    Write-Fail "auto-delegation.json not found"
}

# --- 3. Critical scripts exist -------------------------------------------------
Write-Host "`n[3/6] Critical scripts" -ForegroundColor Cyan
$autostartFile = if ([Environment]::OSVersion.Platform -eq 'Win32NT') { 'scripts/utilities/session-autostart.cmd' } else { 'scripts/utilities/session-autostart.sh' }
$criticalScripts = @(
    'scripts/utilities/pre-process-input.ps1',
    $autostartFile,
    'scripts/utilities/install-hooks.ps1',
    'hooks/pre-commit.ps1'
)
foreach ($rel in $criticalScripts) {
    $full = Join-Path $Root $rel
    if ((Test-Path $full) -and (Get-Item $full).Length -gt 0) { Write-Pass $rel }
    else { Write-Fail "Missing or empty: $rel" }
}

# --- 4. Root markdown files from structure-policy ------------------------------
Write-Host "`n[4/6] Root files (structure-policy.json)" -ForegroundColor Cyan
$spPath = Join-Path $Root $ConfigDir 'structure-policy.json'
if (Test-Path $spPath) {
    $sp = Get-Content $spPath -Raw | ConvertFrom-Json
    foreach ($f in $sp.allowedRootMarkdownFiles) {
        $full = Join-Path $Root $f
        if (Test-Path $full) { Write-Pass $f }
        else                 { Write-Warn "Declared but missing: $f" }
    }
} else {
    Write-Warn "structure-policy.json not found - skipping root file check"
}

# --- 5. Hook scripts referenced in hooks-config.json --------------------------
Write-Host "`n[5/6] Hook scripts" -ForegroundColor Cyan
$hcPath = Join-Path $Root $ConfigDir 'hooks-config.json'
if (Test-Path $hcPath) {
    $hc = Get-Content $hcPath -Raw | ConvertFrom-Json
    $hc.hooks.PSObject.Properties | ForEach-Object {
        $hookName   = $_.Name
        $scriptRel  = $_.Value.script
        if ($scriptRel) {
            $full = Join-Path $Root $scriptRel
            if (Test-Path $full) { Write-Pass "$hookName -> $scriptRel" }
            else                 { Write-Fail "$hookName script not found: $scriptRel" }
        }
    }
} else {
    Write-Warn "hooks-config.json not found - skipping hook script check"
}

# --- 6. agentCodeToSkill -> skills/ directory ----------------------------------
Write-Host "`n[6/6] agentCodeToSkill -> skills/ directories" -ForegroundColor Cyan
if (Test-Path $adPath) {
    $ad = Get-Content $adPath -Raw | ConvertFrom-Json
    $ad.agentCodeToSkill.PSObject.Properties | ForEach-Object {
        $agent = $_.Name
        $skill = $_.Value
        $dir   = Join-Path $Root 'skills' $skill
        if (Test-Path $dir) { Write-Pass "$agent -> $skill" }
        else                { Write-Warn "$agent -> skills/$skill not found (may be in user skills)" }
    }
}

# --- Summary -------------------------------------------------------------------
Write-Host ""
Write-Host "-----------------------------------------" -ForegroundColor DarkGray
if ($errors -gt 0) {
    Write-Host "RESULT: FAIL  ($errors errors, $warns warnings)" -ForegroundColor Red
    exit 1
} elseif ($Strict -and $warns -gt 0) {
    Write-Host "RESULT: FAIL  (strict mode: $warns warnings)" -ForegroundColor Red
    exit 1
} elseif ($warns -gt 0) {
    Write-Host "RESULT: PASS  (with $warns warnings)" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "RESULT: PASS  (all checks clean)" -ForegroundColor Green
    exit 0
}
