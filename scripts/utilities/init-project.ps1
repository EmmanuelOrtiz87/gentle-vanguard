param(
    [string]$ProjectName = '',
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Read-Choice($Prompt, $Default, $Options) {
    if (-not $Quiet) {
        $defaultStr = if ($Default) { " [$Default]" } else { '' }
        Write-Host "$Prompt$defaultStr" -ForegroundColor Cyan -NoNewline
        $input = (Read-Host).Trim()
        if ([string]::IsNullOrWhiteSpace($input)) { $input = $Default }
        return $input
    }
    return $Default
}

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Read-Choice "Project name:" "gentle-vanguard-project"
}

$features = @{}
$featureList = @(
    @{Key='core'; Label='Core scaffold (README, VERSION, .gitignore)'; Default=$true},
    @{Key='gv'; Label='GV CLI (gv.ps1 entry point)'; Default=$true},
    @{Key='adr'; Label='ADR tooling (adr-new.ps1 + CI)'; Default=$true},
    @{Key='dashboard'; Label='Dashboard (metrics + HTML render)'; Default=$false},
    @{Key='ci'; Label='CI workflows (GitHub Actions)'; Default=$true},
    @{Key='lefthook'; Label='Lefthook git hooks'; Default=$true},
    @{Key='skills'; Label='Skills framework'; Default=$false},
    @{Key='engram'; Label='Engram memory integration'; Default=$false}
)

if (-not $Quiet) {
    Write-Host ""
    Write-Host " Gentle-Vanguard Init v3.0" -ForegroundColor Cyan
    Write-Host " Interactive project scaffolding" -ForegroundColor DarkGray
    Write-Host ""

    foreach ($f in $featureList) {
        $defaultStr = if ($f.Default) { 'Y' } else { 'n' }
        $choice = Read-Choice "  Include $($f.Label)? [y/N]" $defaultStr
        $features[$f.Key] = $choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq 'yes'
    }
} else {
    foreach ($f in $featureList) { $features[$f.Key] = $f.Default }
}

$target = Join-Path $repoRoot $ProjectName
if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    if (-not $Quiet) { Write-Host "[INIT] Created directory: $target" -ForegroundColor Green }
}

$created = @()
$skipped = @()

# Core scaffold
if ($features['core']) {
    $files = @{}
    $readmePath = Join-Path $target 'README.md'
    if (-not (Test-Path $readmePath) -or $Force) {
        $files['README.md'] = @"
# $ProjectName

**Gentle-Vanguard scaffolded project**

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    }

    $versionPath = Join-Path $target 'VERSION'
    if (-not (Test-Path $versionPath) -or $Force) {
        $files['VERSION'] = '1.0.0'
    }

    $gitignorePath = Join-Path $target '.gitignore'
    if (-not (Test-Path $gitignorePath) -or $Force) {
        $files['.gitignore'] = @"
# Gentle-Vanguard
.session/
reports/
.runtime/
.local/
*.log
.DS_Store
"@
    }

    foreach ($name in $files.Keys) {
        $path = Join-Path $target $name
        if ((Test-Path $path) -and -not $Force) {
            $skipped += $name
            continue
        }
        $files[$name] | Set-Content -Path $path -Encoding UTF8
        $created += $name
    }
}

# GV CLI entry
if ($features['gv']) {
    $gvPath = Join-Path $target 'gv.ps1'
    if (-not (Test-Path $gvPath) -or $Force) {
        @"
# gv.ps1 - $ProjectName Workflow CLI
param(
    [Parameter(Position=0)]
    [string]`$Command = 'help',
    [Parameter(Position=1, ValueFromRemainingArguments=`$true)]
    [string[]]`$Args = @()
)

`$ErrorActionPreference = 'Continue'

switch (`$Command) {
    'help' {
        Write-Host "$ProjectName CLI - Usage: .\gv.ps1 <command>" -ForegroundColor Cyan
        Write-Host "  help     Show this help" -ForegroundColor Gray
        Write-Host "  status   Show project status" -ForegroundColor Gray
    }
    'status' {
        Write-Host "[STATUS] $ProjectName - ready" -ForegroundColor Green
    }
    default {
        Write-Host "Unknown command. Use 'help' for usage." -ForegroundColor Yellow
    }
}
"@ | Set-Content -Path $gvPath -Encoding UTF8
        $created += 'gv.ps1'
    }
}

# ADR directory
if ($features['adr']) {
    $adrDir = Join-Path $target 'docs\architecture\decisions'
    if (-not (Test-Path $adrDir)) {
        New-Item -ItemType Directory -Path $adrDir -Force | Out-Null
        $created += 'docs/architecture/decisions/'
    }
    $readmeAdr = Join-Path $adrDir 'README.md'
    if (-not (Test-Path $readmeAdr) -or $Force) {
        @"
# Architecture Decision Records

| ID | Title | Status | Date |
|----|-------|--------|------|
"@ | Set-Content -Path $readmeAdr -Encoding UTF8
        $created += 'docs/architecture/decisions/README.md'
    }
}

# CI workflows
if ($features['ci']) {
    $ciDir = Join-Path $target '.github\workflows'
    if (-not (Test-Path $ciDir)) {
        New-Item -ItemType Directory -Path $ciDir -Force | Out-Null
    }
    $ciPath = Join-Path $ciDir 'ci.yml'
    if (-not (Test-Path $ciPath) -or $Force) {
        @"
name: CI

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd
      - name: Validate
        run: echo "CI validation passed"
"@ | Set-Content -Path $ciPath -Encoding UTF8
        $created += '.github/workflows/ci.yml'
    }
}

# Lefthook
if ($features['lefthook']) {
    $lefthookPath = Join-Path $target 'lefthook.yml'
    if (-not (Test-Path $lefthookPath) -or $Force) {
        @"
pre-commit:
  commands:
    validate-json:
      run: echo "JSON validation placeholder"
commit-msg:
  commands:
    commitlint:
      run: echo "Commit lint placeholder"
"@ | Set-Content -Path $lefthookPath -Encoding UTF8
        $created += 'lefthook.yml'
    }
}

if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Scaffold Summary ===" -ForegroundColor Cyan
    Write-Host "Project: $ProjectName" -ForegroundColor White
    Write-Host "Target:  $target" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Created: $($created.Count) items" -ForegroundColor Green
    foreach ($item in $created) { Write-Host "  [+] $item" -ForegroundColor Green }
    if ($skipped.Count -gt 0) {
        Write-Host "Skipped (already exists, use -Force to overwrite): $($skipped.Count) items" -ForegroundColor Yellow
        foreach ($item in $skipped) { Write-Host "  [-] $item" -ForegroundColor Yellow }
    }
    Write-Host ""
    Write-Host "[HINT] cd '$ProjectName' && .\gv.ps1 status" -ForegroundColor Yellow
}

exit 0
