# gf.ps1 - Gentleman Foundation CLI
# Main entry point for the development foundation

param(
    [string]$Command = "",
    [string]$Name = "",
    [string]$Type = "service",
    [string]$Architecture = "clean",
    [switch]$Help,
    [switch]$List,
    [switch]$Validate,
    [switch]$Update,
    [switch]$New,
    [switch]$Info,
    [switch]$Check,
    [switch]$Tools,
    [switch]$All,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptPath = $PSCommandPath
    if ($scriptPath) {
        $scriptRoot = Split-Path -Parent $scriptPath
    }
}

if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$binDir = $scriptRoot
$GFRoot = Split-Path -Parent $binDir

if (-not (Test-Path (Join-Path $GFRoot "skills"))) {
    $GFRoot = Join-Path $env:USERPROFILE ".gentleman"
}

$SkillsDir = Join-Path $GFRoot "skills"
$ToolsDir = Join-Path $GFRoot "tools"
$ConfigDir = Join-Path $GFRoot "config"

$ScriptsDir = $null
$possibleScriptsDirs = @(
    (Join-Path $env:USERPROFILE ".gentleman\scripts"),
    (Join-Path $GFRoot "..\scripts"),
    "C:\Workspace_local\workspace-foundation\scripts"
)
foreach ($dir in $possibleScriptsDirs) {
    if (Test-Path $dir) {
        $ScriptsDir = $dir
        break
    }
}

function Write-CLI-Header {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Gentleman Foundation CLI" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-CLI-Footer {
    Write-Host ""
    Write-Host "Run 'gf --help' for usage information." -ForegroundColor Gray
}

function Show-Help {
    Write-CLI-Header
    Write-Host @"
Gentleman Foundation CLI - Agnostic Development Platform

REQUIREMENTS (any AI agent works):
  - git + PowerShell
  - AI Agent: opencode, claude, copilot, etc.

USAGE:
  gf <command> [options]

COMMANDS:
  check       Check system status (core, skills, tools)
  validate    Validate foundation installation
  info        Show foundation information
  list        List installed skills
  update      Update skills from source
  sync        Sync skills (alias for update)
  update-all  Update foundation + skills
  tools       Show optional tools status
  new         Create new project
  help        Show this help

OPTIONS:
  --name <name>       Project name (for 'new' command)
  --type <type>       Project type: service, cli, library, frontend
  --arch <pattern>     Architecture: layered, clean, modular
  --force             Force update (overwrite existing)
  --help              Show this help

Examples:
  gf new --name my-api --type service --arch clean
  gf validate
  gf check
  gf update
  gf update-all
  gf tools

"@ -ForegroundColor White
    Write-CLI-Footer
}

function Get-Foundation-Info {
    $versionFile = Join-Path $GFRoot "foundation.version"
    $info = @{
        root = $GFRoot
        skillsCount = 0
        version = "unknown"
        installed = "unknown"
        gitHooks = git config --global core.hooksPath 2>$null
    }
    
    if (Test-Path $versionFile) {
        $versionData = Get-Content $versionFile | ConvertFrom-Json
        $info.version = $versionData.version
        $info.installed = $versionData.installed
    }
    
    if (Test-Path $SkillsDir) {
        $info.skillsCount = (Get-ChildItem $SkillsDir -Directory).Count
    }
    
    return $info
}

function Show-Info {
    $info = Get-Foundation-Info
    
    Write-CLI-Header
    Write-Host "Foundation Information" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Root:         $($info.root)" -ForegroundColor White
    Write-Host "  Version:      $($info.version)" -ForegroundColor White
    Write-Host "  Installed:   $($info.installed)" -ForegroundColor White
    Write-Host "  Skills:       $($info.skillsCount)" -ForegroundColor White
    Write-Host "  Git Hooks:    $($info.gitHooks)" -ForegroundColor White
    Write-Host ""
    
    if (Test-Path $SkillsDir) {
        Write-Host "  Available Skills:" -ForegroundColor Yellow
        Get-ChildItem $SkillsDir -Directory | ForEach-Object {
            $skillFile = Join-Path $_.FullName "SKILL.md"
            if (Test-Path $skillFile) {
                $content = Get-Content $skillFile -Raw
                if ($content -match 'description:\s*(.+)') {
                    Write-Host "    - $($_.Name)" -ForegroundColor Gray
                } else {
                    Write-Host "    - $($_.Name)" -ForegroundColor Gray
                }
            }
        }
    }
    
    Write-CLI-Footer
}

function Show-Validate {
    Write-CLI-Header
    Write-Host "Validating Foundation Installation..." -ForegroundColor Green
    Write-Host ""
    
    $errors = 0
    $warnings = 0
    
    if (Test-Path $GFRoot) {
        Write-Host "[OK] Foundation root exists: $GFRoot" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Foundation root not found!" -ForegroundColor Red
        $errors++
    }
    
    if (Test-Path $SkillsDir) {
        $skillCount = (Get-ChildItem $SkillsDir -Directory).Count
        Write-Host "[OK] Skills directory: $skillCount skills" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Skills directory not found!" -ForegroundColor Red
        $errors++
    }
    
    $gitHooksPath = git config --global core.hooksPath 2>$null
    if ($gitHooksPath) {
        Write-Host "[OK] Git hooks configured: $gitHooksPath" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Git hooks not configured" -ForegroundColor Yellow
        $warnings++
    }
    
    $ggabin = Join-Path $GFRoot "bin"
    if ($env:PATH -like "*$ggabin*") {
        Write-Host "[OK] PATH configured" -ForegroundColor Green
    } else {
        Write-Host "[WARN] gf not in PATH - restart terminal" -ForegroundColor Yellow
        $warnings++
    }
    
    Write-Host ""
    if ($errors -eq 0 -and $warnings -eq 0) {
        Write-Host "Validation PASSED" -ForegroundColor Green
    } elseif ($errors -eq 0) {
        Write-Host "Validation PASSED with $warnings warning(s)" -ForegroundColor Yellow
    } else {
        Write-Host "Validation FAILED with $errors error(s)" -ForegroundColor Red
    }
    
    Write-CLI-Footer
}

function Show-List {
    Write-CLI-Header
    Write-Host "Installed Skills" -ForegroundColor Green
    Write-Host ""
    
    if (Test-Path $SkillsDir) {
        $skills = Get-ChildItem $SkillsDir -Directory | Sort-Object Name
        foreach ($skill in $skills) {
            $item = Get-Item $skill.FullName
            $linkType = if ($item.LinkType) { " -> symlink" } else { "" }
            Write-Host "  $($skill.Name)$linkType" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Total: $($skills.Count) skills" -ForegroundColor Gray
    } else {
        Write-Host "No skills directory found" -ForegroundColor Red
    }
    
    Write-CLI-Footer
}

function New-Project {
    if (-not $Name) {
        Write-Host "[ERROR] Project name required. Use --name <name>" -ForegroundColor Red
        return
    }
    
    Write-CLI-Header
    Write-Host "Creating New Project" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Name:         $Name" -ForegroundColor White
    Write-Host "  Type:         $Type" -ForegroundColor White
    Write-Host "  Architecture: $Architecture" -ForegroundColor White
    Write-Host ""
    
    $templatesDir = Join-Path $GFRoot "templates"
    if (Test-Path $templatesDir) {
        Write-Host "[INFO] Templates available at: $templatesDir" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "Project creation scaffolding..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "TODO: Implement project scaffolding from templates" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For now, create project manually and run:" -ForegroundColor Cyan
    Write-Host "  gf setup --project $Name" -ForegroundColor White
    
    Write-CLI-Footer
}

function Invoke-Update {
    Write-CLI-Header
    Write-Host "Updating Skills..." -ForegroundColor Green
    Write-Host ""
    
    $syncScript = if ($ScriptsDir) { Join-Path $ScriptsDir "sync-skills.ps1" } else { $null }
    
    if ($syncScript -and (Test-Path $syncScript)) {
        & $syncScript -Force
    } else {
        Write-Host "[ERROR] Sync script not found: $ScriptsDir\sync-skills.ps1" -ForegroundColor Red
    }
    
    Write-CLI-Footer
}

function Invoke-Check {
    Write-CLI-Header
    Write-Host "Checking for Updates..." -ForegroundColor Green
    Write-Host ""
    
    $checkScript = if ($ScriptsDir) { Join-Path $ScriptsDir "check-updates.ps1" } else { $null }
    
    if ($checkScript -and (Test-Path $checkScript)) {
        & $checkScript -All
    } else {
        Write-Host "[ERROR] Check script not found" -ForegroundColor Red
    }
    
    Write-CLI-Footer
}

function Invoke-UpdateAll {
    Write-CLI-Header
    Write-Host "Updating Everything..." -ForegroundColor Green
    Write-Host ""
    
    $updateScript = if ($ScriptsDir) { Join-Path $ScriptsDir "update-all.ps1" } else { $null }
    
    if ($updateScript -and (Test-Path $updateScript)) {
        & $updateScript -All -Force:$Force
    } else {
        Write-Host "[ERROR] Update script not found: $ScriptsDir\update-all.ps1" -ForegroundColor Red
    }
    
    Write-CLI-Footer
}

function Show-Tools {
    Write-CLI-Header
    Write-Host "Tools Status" -ForegroundColor Green
    Write-Host ""
    
    $tools = @(
        @{ name = "gga"; desc = "GGA CLI - Code review" }
        @{ name = "engram"; desc = "Engram (opencode plugin)" }
        @{ name = "gentle-ai"; desc = "Gentle-AI CLI" }
    )
    
    foreach ($tool in $tools) {
        $cmd = Get-Command $tool.name -ErrorAction SilentlyContinue
        if ($cmd) {
            Write-Host "[OK] $($tool.name) - $($tool.desc)" -ForegroundColor Green
        } else {
            Write-Host "[MISSING] $($tool.name) - $($tool.desc)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-CLI-Footer
}

switch ($Command) {
    "new" { New-Project }
    "validate" { Show-Validate }
    "update" { Invoke-Update }
    "sync" { Invoke-Update }
    "check" { Invoke-Check }
    "update-all" { Invoke-UpdateAll }
    "list" { Show-List }
    "info" { Show-Info }
    "tools" { Show-Tools }
    "help" { Show-Help }
    default {
        if ($Help) {
            Show-Help
        } elseif ($Validate) {
            Show-Validate
        } elseif ($List) {
            Show-List
        } elseif ($Update) {
            Invoke-Update
        } elseif ($Check) {
            Invoke-Check
        } elseif ($Tools) {
            Show-Tools
        } elseif ($Info) {
            Show-Info
        } elseif ($New) {
            New-Project
        } elseif ($All) {
            Invoke-UpdateAll
        } else {
            Show-Help
        }
    }
}
