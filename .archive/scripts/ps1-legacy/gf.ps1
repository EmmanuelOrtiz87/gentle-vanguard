# gv.ps1 — Gentle-Vanguard CLI (thin wrapper)
# Delegates to TS CLI (src/cli/gv.ts) when possible, falls back to PS1 for
# PowerShell-specific commands (secret vault, cache, installers).
#
# TS-supported commands: check, validate, info, list, help, health, prune, backup, optimize
# PS1-only commands: new, update, sync, update-all, tools, secret, cache

param(
    [string]$Command = "",
    [string]$Name = "",
    [string]$Type = "service",
    [string]$Architecture = "clean",
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

# Commands that the TS CLI handles natively
$tsCommands = @('check', 'validate', 'info', 'list', 'help', 'health', 'prune', 'backup', 'optimize')
# PS1-only commands that need native PowerShell
$ps1Commands = @('new', 'update', 'sync', 'update-all', 'tools', 'secret', 'cache')

# Resolve repo root
$scriptRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptRoot

# ─── TS delegation ───────────────────────────────────────────────────
if ($Command -and $tsCommands -contains $Command) {
    $tsCli = Join-Path $repoRoot 'src/cli/gv.ts'
    if (Test-Path $tsCli) {
        $tsArgs = @($Command)
        if ($Help) { $tsArgs += '--help' }
        & "npx.cmd" tsx $tsCli @tsArgs
        exit $LASTEXITCODE
    }
}

# ─── PS1-native commands ─────────────────────────────────────────────
$GFRoot = $repoRoot
$SkillsDir = Join-Path $GFRoot 'skills'
$ScriptsDir = Join-Path $GFRoot 'scripts'

function Write-CLI-Header {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Gentle-Vanguard CLI (PS1)" -ForegroundColor Cyan
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
Gentle-Vanguard CLI — TS + PS1 hybrid

TS COMMANDS (npx tsx src/cli/gv.ts):
  check       Run system checks (watchtower health)
  validate    Validate stack installation
  info        Show stack information
  list        List available skills
  health      Show Nexus DB health
  prune       Prune old Nexus data
  backup      Backup Nexus DB
  optimize    Optimize Nexus DB (WAL + VACUUM)

PS1-ONLY COMMANDS:
  new         Create new project (scaffolding)
  update      Update skills from source (git pull)
  sync        Alias for update
  update-all  Update everything in stack
  tools       Show optional tools status
  secret      Manage secrets (vault, rotation, breach)
  cache       Multi-tier cache management

USAGE:
  gv <command> [options]
  gv --help
  gv info
"@ -ForegroundColor White
    Write-CLI-Footer
}

function Show-Validate {
    Write-CLI-Header
    Write-Host "Validating Gentle-Vanguard Installation..." -ForegroundColor Green
    Write-Host ""
    & "npx.cmd" tsx (Join-Path $GFRoot 'src/cli/gv.ts') validate
    Write-CLI-Footer
}

function Show-Info {
    & "npx.cmd" tsx (Join-Path $GFRoot 'src/cli/gv.ts') info
}

function Show-List {
    & "npx.cmd" tsx (Join-Path $GFRoot 'src/cli/gv.ts') list
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
    $templatesDir = Join-Path $GFRoot 'templates'
    if (Test-Path $templatesDir) {
        Write-Host "[INFO] Templates available at: $templatesDir" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "Project scaffolding via: template system" -ForegroundColor Yellow
    Write-CLI-Footer
}

function Invoke-Update {
    Write-CLI-Header
    Write-Host "Updating Skills..." -ForegroundColor Green
    Write-Host ""
    $syncScript = Join-Path $ScriptsDir 'utilities/sync-skills.ps1'
    if (Test-Path $syncScript) {
        & $syncScript -Force:$Force
    } else {
        Write-Host "[ERROR] Sync script not found. Use git pull directly:" -ForegroundColor Red
        Write-Host "  git pull origin develop" -ForegroundColor White
    }
    Write-CLI-Footer
}

function Invoke-UpdateAll {
    Write-CLI-Header
    Write-Host "Updating Everything..." -ForegroundColor Green
    Write-Host ""
    & "npx.cmd" tsx (Join-Path $GFRoot 'src/cli/gv.ts') info
    Write-Host ""
    Write-Host "Run updates via:" -ForegroundColor Cyan
    Write-Host "  git pull origin develop" -ForegroundColor White
    Write-Host "  npm update" -ForegroundColor White
    Write-CLI-Footer
}

function Show-Tools {
    Write-CLI-Header
    Write-Host "Tools Status" -ForegroundColor Green
    Write-Host ""
    $tools = @(
        @{ name = 'native'; desc = 'native CLI - Code review' }
        @{ name = 'engram'; desc = 'Engram (opencode plugin)' }
        @{ name = 'opencode'; desc = 'opencode CLI' }
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
    Write-Host "All tools are optional. The stack works without them." -ForegroundColor Gray
    Write-CLI-Footer
}

function Invoke-Cache {
    $cacheScript = Join-Path $GFRoot 'scripts/adaptive/cache-manager.ps1'
    if (-not (Test-Path $cacheScript)) {
        Write-Host "[ERROR] Cache manager script not found" -ForegroundColor Red
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
    $vaultScript = Join-Path $GFRoot 'scripts/security/secret-vault.ps1'
    if (-not (Test-Path $vaultScript)) {
        Write-Host "[ERROR] Secret vault script not found" -ForegroundColor Red
        return
    }
    $vaultArgs = @()
    if ($Subcommand) { $vaultArgs += $Subcommand } else { $vaultArgs += 'validate-compliance' }
    if ($Name)              { $vaultArgs += '--Name'; $vaultArgs += $Name }
    if ($SecretType)        { $vaultArgs += '--Type'; $vaultArgs += $SecretType }
    if ($Value)             { $vaultArgs += '--Value'; $vaultArgs += $Value }
    if ($Reason)            { $vaultArgs += '--Reason'; $vaultArgs += $Reason }
    if ($ReportType)        { $vaultArgs += '--ReportType'; $vaultArgs += $ReportType }
    if ($CompromisedSecret) { $vaultArgs += '--CompromisedSecret'; $vaultArgs += $CompromisedSecret }
    & $vaultScript @vaultArgs
}

# ─── Main routing ────────────────────────────────────────────────────
switch ($Command) {
    'new' { New-Project }
    'update' { Invoke-Update }
    'sync' { Invoke-Update }
    'update-all' { Invoke-UpdateAll }
    'tools' { Show-Tools }
    'secret' { Invoke-Secret }
    'cache' { Invoke-Cache }
    'help' { Show-Help }
    default {
        if ($Help) { Show-Help }
        elseif ($Validate) { Show-Validate }
        elseif ($Info) { Show-Info }
        elseif ($List) { Show-List }
        elseif ($New) { New-Project }
        elseif ($Update) { Invoke-Update }
        elseif ($Tools) { Show-Tools }
        elseif ($Check) { & "npx.cmd" tsx (Join-Path $GFRoot 'src/cli/gv.ts') check }
        elseif ($All) { Invoke-UpdateAll }
        else { Show-Help }
    }
}
