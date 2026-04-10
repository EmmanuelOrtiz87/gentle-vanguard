#!/usr/bin/env pwsh
# validate-workspace.ps1 - Comprehensive workspace validation

param(
    [switch]$Fix,
    [switch]$Detailed,
    [switch]$SkipTools,
    [switch]$SkipSkills
)

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = (Resolve-Path (Join-Path $root "..")).Path
$configPath = Join-Path $workspaceRoot 'config\workspace.config.json'

$script:FAIL_COUNT = 0
$script:WARN_COUNT = 0

function Write-Header { param([string]$Msg) 
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  $Msg" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
}

function Write-Success { param([string]$Msg) Write-Host "  [PASS] $Msg" -ForegroundColor Green }
function Write-Warning { param([string]$Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow; $script:WARN_COUNT++ }
function Write-Fail { param([string]$Msg) Write-Host "  [FAIL] $Msg" -ForegroundColor Red; $script:FAIL_COUNT++ }
function Write-Info { param([string]$Msg) Write-Host "  [INFO] $Msg" -ForegroundColor Gray }

if ($Detailed) {
    Write-Host "Workspace Root: $workspaceRoot" -ForegroundColor DarkGray
    Write-Host "Config Path: $configPath" -ForegroundColor DarkGray
}

Write-Header "System Requirements"

$requiredCommands = @(
    @{ name = 'git'; desc = 'Version Control'; critical = $true }
    @{ name = 'pwsh'; desc = 'PowerShell Core'; critical = $true }
    @{ name = 'go'; desc = 'Go Runtime'; critical = $false }
)

foreach ($cmd in $requiredCommands) {
    if (Get-Command $cmd.name -ErrorAction SilentlyContinue) {
        $version = & $cmd.name version 2>$null | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($version)) { $version = "OK" }
        Write-Success "$($cmd.desc): $version"
    } else {
        if ($cmd.critical) {
            Write-Fail "$($cmd.desc): NOT FOUND"
        } else {
            Write-Warning "$($cmd.desc): NOT FOUND"
        }
    }
}

if (-not $SkipTools) {
    Write-Header "Workspace Tools"
    
    $config = $null
    if (Test-Path $configPath) {
        $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    
    $defaultTools = @(
        @{ name = 'engram'; checkCommand = 'engram'; desc = 'Engram CLI' }
        @{ name = 'gga'; checkCommand = 'gga'; desc = 'Guardian Angel' }
    )
    
    $toolsToCheck = if ($config -and $config.tools) { $config.tools } else { @() }
    foreach ($tool in $toolsToCheck) {
        $checkCmd = $tool.checkCommand
        $checkPath = $tool.checkPath
        
        $installed = $false
        if ($checkCmd -and (Get-Command $checkCmd -ErrorAction SilentlyContinue)) {
            Write-Success "$($tool.name): Command '$checkCmd' available"
            $installed = $true
        } elseif ($checkPath) {
            $resolvedPath = $ExecutionContext.InvokeCommand.ExpandString($checkPath)
            if (Test-Path $resolvedPath) {
                Write-Success "$($tool.name): Path '$resolvedPath' exists"
                $installed = $true
            }
        }
        
        if (-not $installed) {
            Write-Warning "$($tool.name): Not installed"
        }
    }
}

if (-not $SkipSkills) {
    Write-Header "Workspace Skills"
    
    $skillsDir = Join-Path $workspaceRoot 'skills'
    if (Test-Path $skillsDir) {
        $skills = Get-ChildItem -Path $skillsDir -Directory
        if ($skills.Count -gt 0) {
            foreach ($skill in $skills) {
                $skillMd = Join-Path $skill.FullName 'SKILL.md'
                if (Test-Path $skillMd) {
                    Write-Success "Skill: $($skill.Name)"
                } else {
                    Write-Warning "Skill: $($skill.Name) - Missing SKILL.md"
                }
            }
        } else {
            Write-Info "No skills installed"
        }
    } else {
        Write-Info "Skills directory not found"
    }
}

Write-Header "Template Files"

$requiredFiles = @(
    @{ path = 'templates\project-root\README.md'; desc = 'Root template README' }
    @{ path = 'templates\project-root\AGENTS.md'; desc = 'Agent rules' }
    @{ path = 'templates\project-root\ARCHITECTURE.md'; desc = 'Architecture doc' }
    @{ path = 'templates\project-root\docs\project-context.md'; desc = 'Project context template' }
)

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $workspaceRoot $file.path
    if (Test-Path $fullPath) {
        Write-Success $file.desc
    } else {
        Write-Fail "$($file.desc): Missing"
    }
}

Write-Header "Project Type Templates"

$projectTypes = @('service', 'cli', 'library', 'frontend', 'fullstack', 'microservices')
foreach ($type in $projectTypes) {
    $typeDir = Join-Path $workspaceRoot "templates\project-types\$type"
    if (Test-Path $typeDir) {
        Write-Success "Template: $type"
    } else {
        Write-Info "Template: $type - Not available"
    }
}

Write-Header "Configuration Files"

$configFiles = @(
    @{ path = 'config\workspace.config.json'; desc = 'Main config' }
    @{ path = 'config\workspace.example.json'; desc = 'Example config' }
)

foreach ($file in $configFiles) {
    $fullPath = Join-Path $workspaceRoot $file.path
    if (Test-Path $fullPath) {
        Write-Success $file.desc
        if ($Detailed) {
            $content = Get-Content $fullPath -Raw | ConvertFrom-Json
            $content.PSObject.Properties | ForEach-Object { 
                Write-Info "  $($_.Name): $($_.Value)" 
            }
        }
    } else {
        Write-Warning "$($file.desc): Missing"
    }
}

Write-Header "Directory Structure"

$requiredDirs = @(
    'config'
    'docs'
    'scripts'
    'skills'
    'templates'
    'tools'
    '.engram-data'
)

foreach ($dir in $requiredDirs) {
    $fullPath = Join-Path $workspaceRoot $dir
    if (Test-Path $fullPath) {
        $itemCount = (Get-ChildItem $fullPath -ErrorAction SilentlyContinue).Count
        Write-Success "$dir/ ($itemCount items)"
    } else {
        Write-Wail "$dir/: Missing"
    }
}

Write-Header "Git Configuration"

$gitName = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null

if (-not [string]::IsNullOrWhiteSpace($gitName)) {
    Write-Success "Git user: $gitName"
} else {
    Write-Warning "Git user.name not configured"
}

if (-not [string]::IsNullOrWhiteSpace($gitEmail)) {
    Write-Success "Git email: $gitEmail"
} else {
    Write-Warning "Git user.email not configured"
}

$hooksPath = git config core.hooksPath 2>$null
if (-not [string]::IsNullOrWhiteSpace($hooksPath)) {
    Write-Success "Git hooks: $hooksPath"
} else {
    Write-Info "Git hooks: Using default (.git/hooks)"
}

Write-Header "Validation Summary"

Write-Host ""
Write-Host "  Results:" -ForegroundColor White
Write-Host "    PASSED: $($script:FAIL_COUNT -eq 0 -and $script:WARN_COUNT -eq 0)" -ForegroundColor $(if ($script:FAIL_COUNT -eq 0) { 'Green' } else { 'Red' })
Write-Host "    Warnings: $script:WARN_COUNT" -ForegroundColor Yellow
Write-Host "    Failures: $script:FAIL_COUNT" -ForegroundColor $(if ($script:FAIL_COUNT -gt 0) { 'Red' } else { 'Green' })

if ($Fix) {
    Write-Header "Auto-fix Suggestions"
    
    if ([string]::IsNullOrWhiteSpace($gitName)) {
        Write-Info "Set git name: git config --global user.name 'Your Name'"
    }
    if ([string]::IsNullOrWhiteSpace($gitEmail)) {
        Write-Info "Set git email: git config --global user.email 'your@email.com'"
    }
}

Write-Host ""
if ($script:FAIL_COUNT -eq 0) {
    Write-Host "Workspace validation completed successfully." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Workspace validation found $($script:FAIL_COUNT) failure(s)." -ForegroundColor Red
    exit 1
}
