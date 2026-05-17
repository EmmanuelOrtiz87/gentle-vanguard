param(
    [switch]$AutoRepair,
    [switch]$Quiet,
    [switch]$JSON
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { (Get-Location).Path }

$diagnostics = [ordered]@{
    timestamp = Get-Date -Format 'o'
    projectRoot = $repoRoot
    projectType = 'unknown'
    overallStatus = 'unknown'
    checks = @()
    errors = @()
    warnings = @()
    suggestions = @()
}

function Write-Diag {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )

    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Add-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Message = '',
        [switch]$Critical
    )

    $diagnostics.checks += [pscustomobject]@{
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

function Invoke-LocalPowerShellScript {
    param(
        [string]$ScriptPath,
        [string[]]$ScriptArgs = @()
    )

    & $ScriptPath @ScriptArgs
}

function Get-CommandVersion {
    param(
        [string]$Name,
        [string[]]$Args = @('--version')
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return $null
    }

    try {
        $output = & $cmd.Source @Args 2>$null | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($output)) {
            return 'installed'
        }
        return $output
    } catch {
        return 'installed'
    }
}

# Detect project type
$hasAngular = Test-Path (Join-Path $repoRoot 'angular.json')
$hasGo = Test-Path (Join-Path $repoRoot 'go.mod')
$hasBootstrap = Test-Path (Join-Path $repoRoot 'scripts\core\bootstrap.ps1')

if ($hasAngular -and $hasGo) {
    $diagnostics.projectType = 'bitbucket-dashboard'
} elseif ($hasBootstrap) {
    $diagnostics.projectType = 'gentle-vanguard'
}

Write-Diag ''
Write-Diag '=======================================================' -Color Cyan
Write-Diag '  Gentle-Vanguard - Development Stack - System Diagnostics' -Color Cyan
Write-Diag '=======================================================' -Color Cyan
Write-Diag "Project Type: $($diagnostics.projectType)" -Color Yellow
Write-Diag "Project Root: $repoRoot" -Color Yellow

# Critical dependency checks
Write-Diag ''
Write-Diag '=== CRITICAL DEPENDENCIES ===' -Color Cyan

$goVersion = Get-CommandVersion -Name 'go' -Args @('version')
if ($goVersion) {
    Add-Check -Name 'Go' -Status 'PASS' -Message $goVersion -Critical
    Write-Diag "[OK] Go: $goVersion" -Color Green
} else {
    Add-Check -Name 'Go' -Status 'FAIL' -Message 'Go not found in PATH' -Critical
    Add-Error 'Go not found in PATH.'
    Add-Suggestion 'Install Go from https://go.dev/ and restart the terminal.'
    Write-Diag '[ERR] Go: NOT FOUND' -Color Red
}

$gitVersion = Get-CommandVersion -Name 'git' -Args @('--version')
if ($gitVersion) {
    Add-Check -Name 'Git' -Status 'PASS' -Message $gitVersion -Critical
    Write-Diag "[OK] Git: $gitVersion" -Color Green
} else {
    Add-Check -Name 'Git' -Status 'FAIL' -Message 'Git not found in PATH' -Critical
    Add-Error 'Git not found in PATH.'
    Add-Suggestion 'Install Git from https://git-scm.com/ and restart the terminal.'
    Write-Diag '[ERR] Git: NOT FOUND' -Color Red
}

$nodeVersion = Get-CommandVersion -Name 'node' -Args @('--version')
if ($nodeVersion) {
    Add-Check -Name 'Node' -Status 'PASS' -Message $nodeVersion
    Write-Diag "[OK] Node: $nodeVersion" -Color Green
} else {
    if ($diagnostics.projectType -eq 'bitbucket-dashboard') {
        Add-Check -Name 'Node' -Status 'FAIL' -Message 'Node not found in PATH' -Critical
        Add-Error 'Node is required for bitbucket-dashboard but was not found.'
        Add-Suggestion 'Install Node.js from https://nodejs.org/ and restart the terminal.'
        Write-Diag '[ERR] Node: NOT FOUND' -Color Red
    } else {
        Add-Check -Name 'Node' -Status 'WARN' -Message 'Node not found in PATH'
        Add-Warning 'Node not found in PATH.'
        Write-Diag '[WARN] Node: NOT FOUND (optional for this project type)' -Color Yellow
    }
}

# Engram check
Write-Diag ''
Write-Diag '=== ENGRAM MEMORY SYSTEM ===' -Color Cyan

$engramPath = $null
if ($env:ENGRAM_CMD -and (Test-Path $env:ENGRAM_CMD)) {
    $engramPath = $env:ENGRAM_CMD
} else {
    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd) {
        $engramPath = $engramCmd.Source
    }
}

if ($engramPath) {
    Add-Check -Name 'Engram CLI' -Status 'PASS' -Message $engramPath
    Write-Diag "[OK] Engram CLI: $engramPath" -Color Green
} else {
    Add-Check -Name 'Engram CLI' -Status 'WARN' -Message 'Engram not found in PATH'
    Add-Warning 'Engram CLI not found in PATH.'
    Add-Suggestion 'Run scripts/utilities/install-engram.ps1 or gv.ps1 install-engram.'
    Write-Diag '[WARN] Engram CLI: NOT FOUND' -Color Yellow
}

# Orchestrator and skills
Write-Diag ''
Write-Diag '=== ORCHESTRATOR AND SKILLS ===' -Color Cyan

$activationFile = Join-Path $repoRoot '.orchestrator-active'
if (Test-Path $activationFile) {
    Add-Check -Name 'Orchestrator Active' -Status 'PASS' -Message $activationFile
    Write-Diag '[OK] Orchestrator: ACTIVE' -Color Green
} else {
    Add-Check -Name 'Orchestrator Active' -Status 'WARN' -Message 'Orchestrator not activated'
    Add-Warning 'Orchestrator not activated.'
    Add-Suggestion 'Run gv.ps1 orchestrator-status to initialize orchestrator metadata.'
    Write-Diag '[WARN] Orchestrator: NOT ACTIVATED' -Color Yellow
}

$orchestratorConfig = Join-Path $repoRoot 'config\orchestrator.json'
if (Test-Path $orchestratorConfig) {
    Add-Check -Name 'Orchestrator Config' -Status 'PASS' -Message $orchestratorConfig
    Write-Diag '[OK] Orchestrator config found' -Color Green
} else {
    Add-Check -Name 'Orchestrator Config' -Status 'WARN' -Message 'config/orchestrator.json not found'
    Add-Warning 'Orchestrator config not found.'
    Write-Diag '[WARN] Orchestrator config: NOT FOUND' -Color Yellow
}

$skillsDir = Join-Path $repoRoot 'skills'
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    Add-Check -Name 'Skills Directory' -Status 'PASS' -Message "$skillCount skills found"
    Write-Diag "[OK] Skills directory: $skillCount skills" -Color Green
} else {
    Add-Check -Name 'Skills Directory' -Status 'WARN' -Message 'skills directory not found'
    Add-Warning 'Skills directory not found.'
    Write-Diag '[WARN] Skills directory: NOT FOUND' -Color Yellow
}

# Engram data directory check
Write-Diag ''
Write-Diag '=== ENGRAM DATA DIRECTORY ===' -Color Cyan

$engramDataDir = Join-Path $repoRoot '.engram-data'
if (Test-Path $engramDataDir) {
    Add-Check -Name 'Engram Data Directory' -Status 'PASS' -Message $engramDataDir
    Write-Diag '[OK] .engram-data directory exists' -Color Green
} else {
    Add-Check -Name 'Engram Data Directory' -Status 'WARN' -Message 'Will be created on first use'
    Add-Warning '.engram-data directory does not exist yet.'
    Write-Diag '[WARN] .engram-data directory: WILL BE CREATED ON FIRST USE' -Color Yellow
}

# Derive final status
$criticalFailures = @($diagnostics.checks | Where-Object { $_.critical -and $_.status -eq 'FAIL' })
if ($criticalFailures.Count -gt 0) {
    $diagnostics.overallStatus = 'CRITICAL'
} elseif ($diagnostics.errors.Count -gt 0 -or $diagnostics.warnings.Count -gt 0) {
    $diagnostics.overallStatus = 'DEGRADED'
} else {
    $diagnostics.overallStatus = 'HEALTHY'
}

Write-Diag ''
if ($diagnostics.overallStatus -eq 'CRITICAL') {
    Write-Diag '==============================' -Color Red
    Write-Diag '  CRITICAL ISSUES DETECTED' -Color Red
    Write-Diag '==============================' -Color Red
} elseif ($diagnostics.overallStatus -eq 'DEGRADED') {
    Write-Diag '==============================' -Color Yellow
    Write-Diag '  WARNINGS DETECTED (DEGRADED)' -Color Yellow
    Write-Diag '==============================' -Color Yellow
} else {
    Write-Diag '==============================' -Color Green
    Write-Diag '  STACK IS HEALTHY' -Color Green
    Write-Diag '==============================' -Color Green
}

if ($diagnostics.errors.Count -gt 0) {
    Write-Diag ''
    Write-Diag '=== ERRORS ===' -Color Red
    foreach ($message in $diagnostics.errors) {
        Write-Diag "- $message" -Color Red
    }
}

if ($diagnostics.warnings.Count -gt 0) {
    Write-Diag ''
    Write-Diag '=== WARNINGS ===' -Color Yellow
    foreach ($message in $diagnostics.warnings) {
        Write-Diag "- $message" -Color Yellow
    }
}

if ($diagnostics.suggestions.Count -gt 0) {
    Write-Diag ''
    Write-Diag '=== SUGGESTIONS ===' -Color Cyan
    foreach ($message in $diagnostics.suggestions) {
        Write-Diag "- $message" -Color Cyan
    }
}

if ($AutoRepair -and $diagnostics.overallStatus -ne 'HEALTHY') {
    Write-Diag ''
    Write-Diag '=== AUTO-REPAIR IN PROGRESS ===' -Color Yellow

    if (-not $engramPath) {
        $installScript = Join-Path $scriptDir '..\utilities\SKILLS-TOOLS\install-engram.ps1'
        if (Test-Path $installScript) {
            Write-Diag 'Installing Engram CLI...' -Color Yellow
            Invoke-LocalPowerShellScript -ScriptPath $installScript -ScriptArgs @('-Force')
        }
    }

    $healthScript = Join-Path $scriptDir '..\utilities\SKILLS-TOOLS\ensure-tools-active.ps1'
    if (Test-Path $healthScript) {
        Write-Diag 'Running health activation...' -Color Yellow
        Invoke-LocalPowerShellScript -ScriptPath $healthScript -ScriptArgs @('-AutoStart', '-Quiet')
    }
}

if ($JSON) {
    $diagnostics | ConvertTo-Json -Depth 10
} else {
    Write-Diag '' -Color Gray
    Write-Diag "Diagnostics Report Generated at: $($diagnostics.timestamp)" -Color Gray
    Write-Diag "Status: $($diagnostics.overallStatus)" -Color Gray
}

switch ($diagnostics.overallStatus) {
    'HEALTHY' { exit 0 }
    'DEGRADED' { exit 1 }
    'CRITICAL' { exit 2 }
    default { exit 2 }
}

