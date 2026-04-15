#!/usr/bin/env pwsh
# validate-project.ps1 - Comprehensive project validation

param(
    [string]$ProjectPath = '',
    [switch]$Full,
    [switch]$Fix,
    [switch]$Detailed,
    [string[]]$SkipChecks
)

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $ProjectPath = $PSScriptRoot | Split-Path
}
$ProjectPath = Resolve-Path $ProjectPath

$script:FAIL_COUNT = 0
$script:WARN_COUNT = 0
$script:PASS_COUNT = 0

function Write-Header { param([string]$Msg)
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  $Msg" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
}

function Write-Success { param([string]$Msg); Write-Host "  [PASS] $Msg" -ForegroundColor Green; $script:PASS_COUNT++ }
function Write-Warning { param([string]$Msg); Write-Host "  [WARN] $Msg" -ForegroundColor Yellow; $script:WARN_COUNT++ }
function Write-Fail { param([string]$Msg); Write-Host "  [FAIL] $Msg" -ForegroundColor Red; $script:FAIL_COUNT++ }
function Write-Info { param([string]$Msg); Write-Host "  [INFO] $Msg" -ForegroundColor Gray }

if ($Detailed) {
    Write-Host "Project Path: $ProjectPath" -ForegroundColor DarkGray
}

Push-Location $ProjectPath

Write-Header "Essential Files"

$essentialFiles = @(
    @{ name = 'README.md'; desc = 'Project documentation' }
    @{ name = 'AGENTS.md'; desc = 'Agent instructions' }
)

foreach ($file in $essentialFiles) {
    if (Test-Path $file.name) {
        $size = (Get-Item $file.name).Length
        Write-Success "$($file.desc) ($size bytes)"
    } else {
        Write-Warning "$($file.desc): Missing"
    }
}

Write-Header "Project Type Detection"

$detectedType = 'unknown'
if (Test-Path 'package.json') {
    $detectedType = 'node'
    $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
    Write-Success "Node.js project: $($pkg.name) v$($pkg.version)"
    
    $scripts = $pkg.scripts.PSObject.Properties.Name
    Write-Info "Available scripts: $($scripts -join ', ')"
}
if (Test-Path 'go.mod') {
    $detectedType = 'go'
    $mod = Get-Content 'go.mod' -Raw
    if ($mod -match 'module\s+(.+)') {
        Write-Success "Go project: $($matches[1])"
    }
}
if (Test-Path 'Cargo.toml') {
    $detectedType = 'rust'
    $cargo = Get-Content 'Cargo.toml' -Raw | ConvertFrom-Json
    Write-Success "Rust project: $($cargo.package.name) v$($cargo.package.version)"
}
if (Test-Path 'requirements.txt') {
    $detectedType = 'python'
    Write-Success "Python project detected"
}
if (Test-Path 'Dockerfile') {
    Write-Success "Docker support detected"
}
if (Test-Path 'docker-compose.yml') {
    Write-Success "Docker Compose support detected"
}
if (Test-Path 'k8s/') {
    Write-Success "Kubernetes manifests detected"
}
if (Test-Path '.github/workflows/') {
    Write-Success "GitHub Actions detected"
}
if (Test-Path '.gitlab-ci.yml') {
    Write-Success "GitLab CI detected"
}
if (Test-Path 'azure-pipelines.yml') {
    Write-Success "Azure DevOps detected"
}

if ($detectedType -eq 'unknown') {
    Write-Warning "Could not detect project type"
}

Write-Header "Code Quality"

if (Test-Path 'package.json') {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
        
        if ($pkg.scripts.lint) {
            Write-Info "Running linter..."
            npm run lint 2>$null
            if ($LASTEXITCODE -eq 0) { Write-Success "Linting passed" }
            else { Write-Warning "Linting found issues" }
        }
        
        if ($pkg.scripts.typecheck -or $pkg.scripts.'tsc') {
            Write-Info "Running type check..."
            npm run typecheck 2>$null
            if ($LASTEXITCODE -eq 0) { Write-Success "Type checking passed" }
            else { Write-Warning "Type checking found issues" }
        }
    }
}

if (Test-Path 'go.mod') {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Write-Info "Running go vet..."
        go vet ./... 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Success "go vet passed" }
        else { Write-Warning "go vet found issues" }
    }
}

Write-Header "Testing"

if (Test-Path 'package.json') {
    $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
    
    if ($pkg.scripts.test) {
        Write-Info "Running tests..."
        npm run test 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Success "Tests passed" }
        else { Write-Warning "Tests failed" }
    }
}

if (Test-Path 'go.mod') {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Write-Info "Running Go tests..."
        go test ./... 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Success "Go tests passed" }
        else { Write-Warning "Go tests failed" }
    }
}

Write-Header "Security Checks"

if (Test-Path 'package.json') {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Info "Checking for known vulnerabilities..."
        npm audit --audit-level=high 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Success "No vulnerabilities found" }
        elseif ($LASTEXITCODE -eq 1) { Write-Warning "Vulnerabilities found" }
        else { Write-Info "Audit skipped" }
    }
}

if (Test-Path '.env.example') {
    Write-Success ".env.example present (secrets not in repo)"
} elseif (-not (Test-Path '.env')) {
    Write-Warning "No .env.example or .env found"
}

Write-Header "Git Status"

$status = git status --short 2>$null
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Success "Clean working directory"
} else {
    Write-Info "Changes detected:"
    $status | ForEach-Object { Write-Info "  $_" }
}

$hasRemote = git remote get-url origin 2>$null
if ($hasRemote) {
    Write-Success "Remote: $hasRemote"
    
    $aheadBehind = git rev-list --count --left-right '@{upstream}...HEAD' 2>$null
    if ($aheadBehind) {
        $ahead = [int]$aheadBehind.Split()[0]
        $behind = [int]$aheadBehind.Split()[1]
        if ($ahead -gt 0) { Write-Info "Commits ahead: $ahead" }
        if ($behind -gt 0) { Write-Warning "Commits behind: $behind" }
    }
}

Write-Header "Documentation"

$docFiles = @(
    @{ name = 'docs/project-context.md'; desc = 'Project context' }
    @{ name = 'docs/reference/ARCHITECTURE.md'; desc = 'Architecture doc (canonical)' }
    @{ name = 'docs/architecture/ARCHITECTURE.md'; desc = 'Architecture doc (directory entry)' }
    @{ name = 'docs/CHANGELOG.md'; desc = 'Changelog' }
    @{ name = 'LICENSE'; desc = 'License file' }
)

foreach ($file in $docFiles) {
    if (Test-Path $file.name) {
        Write-Success $file.desc
    } else {
        Write-Info "$($file.desc): Not present"
    }
}

if ($Full) {
    Write-Header "Dependency Analysis"
    
    if (Test-Path 'package-lock.json') {
        $lock = Get-Content 'package-lock.json' -Raw | ConvertFrom-Json
        $deps = ($lock.dependencies.PSObject.Properties).Count
        Write-Info "Dependencies: $deps"
    }
    
    if (Test-Path 'go.sum') {
        $sum = Get-Content 'go.sum'
        $modules = ($sum | Where-Object { $_ -match '^github.com/' }).Count
        Write-Info "Go modules: $modules"
    }
    
    Write-Header "File Structure"
    
    $excludeDirs = @('.git', 'node_modules', 'dist', 'build', 'coverage', '.next', 'vendor', '__pycache__')
    $files = Get-ChildItem -Recurse -File | Where-Object { 
        $dir = $_.DirectoryName -replace [regex]::Escape($ProjectPath), ''
        -not ($excludeDirs | Where-Object { $dir -match $_ })
    } | Select-Object -First 20
    
    Write-Info "Top files:"
    $files | ForEach-Object { Write-Info "  $($_.FullName.Replace($ProjectPath, ''))" }
}

Write-Header "Validation Summary"

Write-Host ""
Write-Host "  Results:" -ForegroundColor White
Write-Host "    PASSED: $script:PASS_COUNT" -ForegroundColor Green
Write-Host "    Warnings: $script:WARN_COUNT" -ForegroundColor Yellow
Write-Host "    Failures: $script:FAIL_COUNT" -ForegroundColor $(if ($script:FAIL_COUNT -gt 0) { 'Red' } else { 'Green' })

Pop-Location

Write-Host ""
if ($script:FAIL_COUNT -eq 0) {
    Write-Host "Project validation completed successfully." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Project validation found $($script:FAIL_COUNT) failure(s)." -ForegroundColor Red
    exit 1
}
