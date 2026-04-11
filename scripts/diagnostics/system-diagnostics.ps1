param(
    [switch]$AutoRepair,
    [switch]$Quiet,
    [switch]$JSON
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

# Diagnostics state
$diagnostics = @{
    timestamp = Get-Date -Format "o"
    projectRoot = $repoRoot
    projectType = ''
    overallStatus = 'unknown'
    checks = @()
    errors = @()
    warnings = @()
    suggestions = @()
}

function Write-Diag {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Add-Check {
    param([string]$Name, [string]$Status, [string]$Message = '', [switch]$Critical)
    $diagnostics.checks += @{
        name = $Name
        status = $Status
        message = $Message
        critical = $Critical.IsPresent
    }
}

function Add-Error {
    param([string]$Message)
    $diagnostics.errors += $Message
}

function Add-Warning {
    param([string]$Message)
    $diagnostics.warnings += $Message
}

function Add-Suggestion {
    param([string]$Message)
    $diagnostics.suggestions += $Message
}

# Detect project type
$gitConfig = Join-Path $repoRoot '.git\config'
$hasAngular = Test-Path (Join-Path $repoRoot 'angular.json')
$hasGo = Test-Path (Join-Path $repoRoot 'go.mod')
$hasBootstrap = Test-Path (Join-Path $repoRoot 'scripts\foundation\bootstrap.ps1')

if ($hasAngular -and $hasGo) {
    $diagnostics.projectType = 'bitbucket-dashboard'
} elseif ($hasBootstrap) {
    $diagnostics.projectType = 'workspace-foundation'
} else {
    $diagnostics.projectType = 'unknown'
}

Write-Diag "`n╔═══════════════════════════════════════════════════════╗" -Color Cyan
Write-Diag "║    Gentleman Foundation - System Diagnostics          ║" -Color Cyan
Write-Diag "╚═══════════════════════════════════════════════════════╝" -Color Cyan
Write-Diag "Project Type: $($diagnostics.projectType)" -Color Yellow
Write-Diag "Project Root: $repoRoot`n" -Color Yellow

# Check critical dependencies
Write-Diag "=== CRITICAL DEPENDENCIES ===" -Color Cyan

if (Get-Command go -ErrorAction SilentlyContinue) {
    $goVersion = $(go version)
    Add-Check "Go" "PASS" $goVersion
    Write-Diag "[✓] Go: $goVersion" -Color Green
} else {
    Add-Check "Go" "FAIL" "Go not found in PATH" -Critical
    Add-Error "Go not found. Install from https://go.dev/"
    Write-Diag "[✗] Go: NOT FOUND" -Color Red
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = $(git --version)
    Add-Check "Git" "PASS" $gitVersion
    Write-Diag "[✓] Git: $gitVersion" -Color Green
} else {
    Add-Check "Git" "FAIL" "Git not found in PATH" -Critical
    Add-Error "Git not found. Install from https://git-scm.com/"
    Write-Diag "[✗] Git: NOT FOUND" -Color Red
}

# Check Engram CLI
Write-Diag "`n=== ENGRAM MEMORY SYSTEM ===" -Color Cyan

$engramPath = $null
if ($env:ENGRAM_CMD -and (Test-Path $env:ENGRAM_CMD)) {
    $engramPath = $env:ENGRAM_CMD
} elseif (Get-Command engram -ErrorAction SilentlyContinue) {
    $engramPath = (Get-Command engram).Source
} else {
    $pathsToCheck = @()
    if ($env:GOBIN) { $pathsToCheck += @($(Join-Path $env:GOBIN 'engram.exe'), $(Join-Path $env:GOBIN 'engram')) }
    if ($env:GOPATH) { $pathsToCheck += @($(Join-Path $env:GOPATH 'bin\engram.exe'), $(Join-Path $env:GOPATH 'bin\engram')) }
    if ($env:USERPROFILE) { $pathsToCheck += @($(Join-Path $env:USERPROFILE 'go\bin\engram.exe'), $(Join-Path $env:USERPROFILE 'go\bin\engram')) }
    
    foreach ($path in $pathsToCheck) {
        if (Test-Path $path) {
            $engramPath = $path
            break
        }
    }
}

if ($engramPath) {
    Add-Check "Engram CLI" "PASS" $engramPath
    Write-Diag "[✓] Engram CLI: $engramPath" -Color Green
} else {
    Add-Check "Engram CLI" "FAIL" "Not found in PATH or ENGRAM_CMD"
    Add-Warning "Engram CLI not found. Can be auto-installed."
    Write-Diag "[✗] Engram CLI: NOT FOUND (can auto-install)" -Color Yellow
}

# Check workspace configuration
Write-Diag "`n=== WORKSPACE CONFIGURATION ===" -Color Cyan

$configPath = Join-Path $repoRoot 'config\workspace.config.json'
if (Test-Path $configPath) {
    Add-Check "Config File" "PASS" $configPath
    Write-Diag "[✓] Config file exists" -Color Green
} else {
    Add-Check "Config File" "FAIL" "workspace.config.json not found"
    Add-Warning "Workspace config missing. Bootstrap may help."
    Write-Diag "[✗] Config file: NOT FOUND" -Color Yellow
}

# Check orchestrator state
Write-Diag "`n=== ORCHESTRATOR STATE ===" -Color Cyan

$orchestratorActive = Test-Path (Join-Path $repoRoot '.orchestrator-active')
if ($orchestratorActive) {
    Add-Check "Orchestrator Active" "PASS"
    Write-Diag "[✓] Orchestrator flag detected" -Color Green
} else {
    Add-Check "Orchestrator Active" "WARN" "Orchestrator not activated"
    Add-Warning "Orchestrator not activated. Run: wf.ps1 orchestrator-status"
    Write-Diag "[⚠] Orchestrator: NOT ACTIVATED" -Color Yellow
}

$orchestratorConfig = Join-Path $repoRoot 'config\orchestrator.json'
if (Test-Path $orchestratorConfig) {
    Add-Check "Orchestrator Config" "PASS"
    Write-Diag "[✓] Orchestrator config found" -Color Green
} else {
    Add-Check "Orchestrator Config" "WARN" 
    Write-Diag "[⚠] Orchestrator config: NOT FOUND" -Color Yellow
}

# Check skills
Write-Diag "`n=== SKILLS & KNOWLEDGE BASE ===" -Color Cyan

$skillsDir = Join-Path $repoRoot 'skills'
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    Add-Check "Skills Directory" "PASS" "$skillCount skills found"
    Write-Diag "[✓] Skills directory: $skillCount skills" -Color Green
} else {
    Add-Check "Skills Directory" "FAIL"
    Add-Warning "Skills directory not found"
    Write-Diag "[✗] Skills directory: NOT FOUND" -Color Yellow
}

# Check Engram data directory
Write-Diag "`n=== ENGRAM DATA & MEMORY ===" -Color Cyan

$engramDataDir = Join-Path $repoRoot '.engram-data'
if (Test-Path $engramDataDir) {
    Add-Check "Engram Data" "PASS" $engramDataDir
    Write-Diag "[✓] Engram data directory exists" -Color Green
} else {
    Add-Check "Engram Data" "WARN" "Will be created on first use"
    Write-Diag "[⚠] Engram data directory: WILL CREATE ON FIRST USE" -Color Yellow
}

# Project-specific checks
Write-Diag "`n=== PROJECT-SPECIFIC CHECKS ===" -Color Cyan

if ($diagnostics.projectType -eq 'bitbucket-dashboard') {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVersion = $(node --version)
        Add-Check "Node.js" "PASS" $nodeVersion
        Write-Diag "[✓] Node.js: $nodeVersion" -Color Green
    } else {
        Add-Check "Node.js" "FAIL" "Not found"
        Add-Error "Node.js required for bitbucket-dashboard"
        Write-Diag "[✗] Node.js: NOT FOUND" -Color Red
    }
    
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $npmVersion = $(npm --version)
        Add-Check "npm" "PASS" $npmVersion
        Write-Diag "[✓] npm: $npmVersion" -Color Green
    } else {
        Add-Check "npm" "FAIL" "Not found"
        Add-Error "npm required for bitbucket-dashboard"
        Write-Diag "[✗] npm: NOT FOUND" -Color Red
    }
    
    if (Get-Command ng -ErrorAction SilentlyContinue) {
        Add-Check "Angular CLI" "PASS"
        Write-Diag "[✓] Angular CLI installed" -Color Green
    } else {
        Add-Check "Angular CLI" "WARN" "Can be installed with: npm install -g @angular/cli"
        Write-Diag "[⚠] Angular CLI: Not globally installed (can auto-install)" -Color Yellow
    }
    
    $packageJson = Join-Path $repoRoot 'package.json'
    if (Test-Path $packageJson) {
        Add-Check "package.json" "PASS"
        Write-Diag "[✓] package.json found" -Color Green
    }
}

if ($diagnostics.projectType -eq 'workspace-foundation') {
    Write-Diag "[✓] Foundation workspace detected" -Color Green
}

# Determine overall status
Write-Diag "`n" -Color Cyan
$failedCritical = $diagnostics.checks | Where-Object { $_.status -eq 'FAIL' -and $_.critical }
if ($failedCritical) {
    $diagnostics.overallStatus = 'CRITICAL'
    Write-Diag "╔═════════════════════════════════════════╗" -Color Red
    Write-Diag "║    ⚠ CRITICAL ISSUES DETECTED ⚠        ║" -Color Red
    Write-Diag "╚═════════════════════════════════════════╝" -Color Red
} else {
    $failedWarnings = $diagnostics.checks | Where-Object { $_.status -in @('FAIL', 'WARN') }
    if ($failedWarnings) {
        $diagnostics.overallStatus = 'DEGRADED'
        Write-Diag "╔═════════════════════════════════════════╗" -Color Yellow
        Write-Diag "║    ⚠ WARNINGS - Stack Degraded ⚠       ║" -Color Yellow
        Write-Diag "╚═════════════════════════════════════════╝" -Color Yellow
    } else {
        $diagnostics.overallStatus = 'HEALTHY'
        Write-Diag "╔═════════════════════════════════════════╗" -Color Green
        Write-Diag "║    ✓ STACK IS HEALTHY ✓               ║" -Color Green
        Write-Diag "╚═════════════════════════════════════════╝" -Color Green
    }
}

# Show errors and warnings
if ($diagnostics.errors) {
    Write-Diag "`n=== ERRORS ===" -Color Red
    foreach ($error in $diagnostics.errors) {
        Write-Diag "  ✗ $error" -Color Red
    }
}

if ($diagnostics.warnings) {
    Write-Diag "`n=== WARNINGS ===" -Color Yellow
    foreach ($warning in $diagnostics.warnings) {
        Write-Diag "  ⚠ $warning" -Color Yellow
    }
}

if ($diagnostics.suggestions) {
    Write-Diag "`n=== SUGGESTIONS ===" -Color Cyan
    foreach ($suggestion in $diagnostics.suggestions) {
        Write-Diag "  → $suggestion" -Color Cyan
    }
}

# Auto-repair if requested
if ($AutoRepair -and $diagnostics.overallStatus -ne 'HEALTHY') {
    Write-Diag "`n=== AUTO-REPAIR IN PROGRESS ===" -Color Yellow
    
    if (-not $engramPath) {
        Write-Diag "Installing Engram CLI..." -Color Yellow
        $installScript = Join-Path $scriptDir '..\utilities\install-engram.ps1'
        if (Test-Path $installScript) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript -Force
        }
    }
    
    Write-Diag "Activating health check..." -Color Yellow
    $healthScript = Join-Path $scriptDir '..\utilities\ensure-tools-active.ps1'
    if (Test-Path $healthScript) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $healthScript -AutoStart -Quiet
    }
}

# JSON output if requested
if ($JSON) {
    $diagnostics | ConvertTo-Json -Depth 10
} else {
    Write-Diag "`nDiagnostics Report Generated at: $($diagnostics.timestamp)" -Color Gray
    Write-Diag "Status: $($diagnostics.overallStatus)" -Color Gray
}

exit 0
