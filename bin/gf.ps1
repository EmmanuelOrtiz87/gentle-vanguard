# gv.ps1 - Gentle-Vanguard CLI
# Main entry point for the development gentle-vanguard

param(
    [string]$Command = "",
    [string]$Name = "",
    [string]$Type = "service",
    [string]$Architecture = "clean",
    # secret subcommand args
    [string]$Subcommand = "",
    [string]$SecretType = "",
    [string]$Value = "",
    [string]$Reason = "",
    [string]$ReportType = "",
    [string]$CompromisedSecret = "",
    [string]$Tag = "",
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
    ".\gentle-vanguard\scripts"
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
    Write-Host "  Gentle-Vanguard CLI" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-CLI-Footer {
    Write-Host ""
    Write-Host "Run 'gv --help' for usage information." -ForegroundColor Gray
}

function Show-Help {
    Write-CLI-Header
    Write-Host @"
Gentle-Vanguard CLI - Agnostic Development Platform

REQUIREMENTS (any AI agent works):
  - git + PowerShell
  - AI Agent: opencode, claude, copilot, etc.

USAGE:
  gv <command> [options]

COMMANDS:
  check       Check system status (core, skills, tools)
  validate    Validate gentle-vanguard installation
  info        Show gentle-vanguard information
  list        List installed skills
  update      Update skills from source
  sync        Sync skills (alias for update)
  update-all  Update gentle-vanguard + skills
  tools       Show optional tools status
  new         Create new project
  secret      Manage secrets (vault, rotation, compliance, breach response)
  cache       Multi-tier cache management (L1/L2/L3/Archive)
  help        Show this help

OPTIONS:
  --name <name>       Project name (for 'new') or secret identifier (UPPER_SNAKE_CASE)
  --type <type>       Project type: service, cli, library, frontend
  --arch <pattern>    Architecture: layered, clean, modular
  --force             Force update (overwrite existing)
  --help              Show this help

SECRET SUBCOMMANDS:
  gv secret create --name TOKEN --secrettype api-keys --value xxx
  gv secret get    --name TOKEN --reason "CI pipeline"
  gv secret rotate --name TOKEN [--value newval]
  gv secret list
  gv secret validate-compliance
  gv secret audit-report [--reporttype access|rotation|violations]
  gv secret breach-response --compromisedsecret TOKEN --reason "leaked"

Examples:
  gv new --name my-api --type service --arch clean
  gv validate
  gv check
  gv update
  gv update-all
  gv tools
  gv secret list
  gv secret validate-compliance
"@ -ForegroundColor White
    Write-CLI-Footer
}

function Get-Gentle-Vanguard-Info {
    $versionFile = Join-Path $GFRoot "gentle-vanguard.version"
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
    $info = Get-Gentle-Vanguard-Info
    
    Write-CLI-Header
    Write-Host "Gentle-Vanguard Information" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Root:         $($info.root)" -ForegroundColor White
    Write-Host "  Version:      $($info.version)" -ForegroundColor White
    Write-Host "  Installed:    $($info.installed)" -ForegroundColor White
    Write-Host "  Skills:       $($info.skillsCount)" -ForegroundColor White
    Write-Host "  Git Hooks:    $($info.gitHooks)" -ForegroundColor White
    Write-Host ""
    
    if (Test-Path $SkillsDir) {
        Write-Host "  Available Skills:" -ForegroundColor Yellow
        Get-ChildItem $SkillsDir -Directory | ForEach-Object {
            $skillFile = Join-Path $_.FullName "SKILL.md"
            if (Test-Path $skillFile) {
                Write-Host "    - $($_.Name)" -ForegroundColor Gray
            }
        }
    }
    
    Write-CLI-Footer
}

function Show-Validate {
    Write-CLI-Header
    Write-Host "Validating Gentle-Vanguard Installation..." -ForegroundColor Green
    Write-Host ""
    
    $errors = 0
    $warnings = 0
    
    if (Test-Path $GFRoot) {
        Write-Host "[OK] Gentle-Vanguard root exists: $GFRoot" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Gentle-Vanguard root not found!" -ForegroundColor Red
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
        Write-Host "[WARN] gv not in PATH - restart terminal" -ForegroundColor Yellow
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
    Write-Host "Project scaffolding available via: gv.ps1 scaffold" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For now, create project manually and run:" -ForegroundColor Cyan
    Write-Host "  gv setup --project $Name" -ForegroundColor White
    
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
        @{ name = "native"; desc = "native CLI - Code review" }
        @{ name = "engram"; desc = "Engram (opencode plugin)" }
        @{ name = "native-tools"; desc = "native-tools CLI" }
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

function Invoke-Cache {
    $cacheScript = Join-Path $GFRoot 'scripts' 'adaptive' 'cache-manager.ps1'
    if (-not (Test-Path $cacheScript)) {
        Write-Host "[ERROR] Cache manager script not found: $cacheScript" -ForegroundColor Red
        return
    }
    $cacheArgs = @()
    if ($Subcommand) { $cacheArgs += $Subcommand } else { $cacheArgs += 'stats' }
    if ($Name)  { $cacheArgs += '--Key'; $cacheArgs += $Name }
    if ($Value) { $cacheArgs += '--Value'; $cacheArgs += $Value }
    if ($Tag)   { $cacheArgs += '--Tag'; $cacheArgs += $Tag }
    & $cacheScript @cacheArgs
}

function Invoke-Secret {
    $vaultScript = Join-Path $GFRoot 'scripts' 'security' 'secret-vault.ps1'
    if (-not (Test-Path $vaultScript)) {
        Write-Host "[ERROR] Secret vault script not found: $vaultScript" -ForegroundColor Red
        return
    }
    
    # Build argument list
    $vaultArgs = @()
    if ($Subcommand) { $vaultArgs += $Subcommand }
    else              { $vaultArgs += 'validate-compliance' }
    if ($Name)              { $vaultArgs += '--Name'; $vaultArgs += $Name }
    if ($SecretType)        { $vaultArgs += '--Type'; $vaultArgs += $SecretType }
    if ($Value)             { $vaultArgs += '--Value'; $vaultArgs += $Value }
    if ($Reason)            { $vaultArgs += '--Reason'; $vaultArgs += $Reason }
    if ($ReportType)        { $vaultArgs += '--ReportType'; $vaultArgs += $ReportType }
    if ($CompromisedSecret) { $vaultArgs += '--CompromisedSecret'; $vaultArgs += $CompromisedSecret }
    
    & $vaultScript @vaultArgs
}

# Main command routing
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
    "secret" { Invoke-Secret }
    "cache"  { Invoke-Cache }
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

