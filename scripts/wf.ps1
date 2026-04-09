#!/usr/bin/env pwsh
# wf.ps1 - Workspace Foundation CLI
# Unified interface for all workspace operations

param(
    [Parameter(Position = 0)]
    [ValidateSet('init', 'new', 'validate', 'tools', 'skills', 'clean', 'help', 'version', 'info', 'doctor', 'update', 'completion', 'list', 'search', 'config', 'deploy', 'migrate', 'test')]
    [string]$Command = 'help',
    [switch]$Interactive
)

$ErrorActionPreference = 'Stop'

$Script:WF_ROOT = $PSScriptRoot | Split-Path
$Script:WF_CONFIG = Join-Path $Script:WF_ROOT 'config\workspace.config.json'
$Script:WF_TEMPLATES = Join-Path $Script:WF_ROOT 'templates'
$Script:WF_TOOLS = Join-Path $Script:WF_ROOT 'tools'

function Get-Platform {
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) { return 'windows' }
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) { return 'macos' }
    return 'linux'
}

function Write-Banner {
    param([string]$Text, [string]$Color = 'Cyan')
    $line = "========================================"
    Write-Host ""
    Write-Host " $Text" -ForegroundColor $Color
    Write-Host " $line" -ForegroundColor Gray
    Write-Host ""
}

function Write-Step { param([string]$Msg) Write-Host "  [->] $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Warning { param([string]$Msg) Write-Host "  [!] $Msg" -ForegroundColor Yellow }
function Write-Error { param([string]$Msg) Write-Host "  [X] $Msg" -ForegroundColor Red }

function Show-Help {
    Write-Banner "Workspace Foundation CLI"
    
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  wf <command>" -ForegroundColor White
    Write-Host ""
    
    Write-Host "COMMANDS:" -ForegroundColor Yellow
    Write-Host "  init         Initialize workspace" -ForegroundColor White
    Write-Host "  new          Create new project (interactive)" -ForegroundColor White
    Write-Host "  validate     Validate workspace" -ForegroundColor White
    Write-Host "  tools        Manage tools" -ForegroundColor White
    Write-Host "  skills       Manage skills" -ForegroundColor White
    Write-Host "  clean        Clean runtime" -ForegroundColor White
    Write-Host "  doctor       Diagnose issues" -ForegroundColor White
    Write-Host "  list         List projects" -ForegroundColor White
    Write-Host "  version      Show version" -ForegroundColor White
    Write-Host "  help         Show this help" -ForegroundColor White
    Write-Host ""
    
    Write-Host "For help on a command, run: wf <command> -help" -ForegroundColor Gray
}

function Show-Version {
    Write-Host ""
    Write-Host "Workspace Foundation CLI v1.0.0" -ForegroundColor Cyan
    Write-Host "Workspace: $(Split-Path $Script:WF_ROOT -Leaf)" -ForegroundColor Gray
    Write-Host "Root: $Script:WF_ROOT" -ForegroundColor Gray
    Write-Host "Platform: $(Get-Platform)" -ForegroundColor Gray
    Write-Host ""
}

function Invoke-Init {
    Write-Banner "Initialize Workspace"
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is required. Install from: https://git-scm.com/"
        exit 1
    }
    
    Write-Step "Verifying directory structure..."
    $requiredDirs = @('config', 'tools', 'projects', 'docs', '.engram-data')
    foreach ($dir in $requiredDirs) {
        $path = Join-Path $Script:WF_ROOT $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Success "Created: $dir/"
        } else {
            Write-Success "Exists: $dir/"
        }
    }
    
    Write-Step "Checking Git identity..."
    $gitName = git config --global user.name 2>$null
    $gitEmail = git config --global user.email 2>$null
    if ([string]::IsNullOrWhiteSpace($gitName) -or [string]::IsNullOrWhiteSpace($gitEmail)) {
        Write-Warning "Git user identity not configured."
        Write-Host "  Run: git config --global user.name 'Your Name'"
        Write-Host "  Run: git config --global user.email 'your@email.com'"
    } else {
        Write-Success "Git configured: $gitName <$gitEmail>"
    }
    
    Write-Banner "Workspace Ready!" "Green"
    Write-Host "Run 'wf help' to see available commands." -ForegroundColor Gray
}

function Show-NewProjectWizard {
    Write-Banner "New Project Wizard" "Magenta"
    
    Write-Host "Let's create your new project." -ForegroundColor Gray
    Write-Host ""
    
    $name = Read-Host "Project name"
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = "my-project"
    }
    Write-Host "Using name: $name" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Project type [1-7]:" -ForegroundColor Yellow
    Write-Host "  1) Service (API, backend)" -ForegroundColor White
    Write-Host "  2) CLI (command-line tool)" -ForegroundColor White
    Write-Host "  3) Library (reusable package)" -ForegroundColor White
    Write-Host "  4) Frontend (web app)" -ForegroundColor White
    Write-Host "  5) Fullstack" -ForegroundColor White
    Write-Host "  6) Microservices" -ForegroundColor White
    Write-Host "  7) Mobile" -ForegroundColor White
    $kindChoice = Read-Host "Select [1]"
    $kindMap = @{'1'='service'; '2'='cli'; '3'='library'; '4'='frontend'; '5'='fullstack'; '6'='microservices'; '7'='mobile'}
    $kind = if ($kindChoice -and $kindMap.ContainsKey($kindChoice)) { $kindMap[$kindChoice] } else { 'service' }
    Write-Host "Using kind: $kind" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Architecture [1-4]:" -ForegroundColor Yellow
    Write-Host "  1) Layered  2) Clean  3) Modular  4) Microservices" -ForegroundColor White
    $archChoice = Read-Host "Select [1]"
    $archMap = @{'1'='layered'; '2'='clean'; '3'='modular'; '4'='microservices'}
    $architecture = if ($archChoice -and $archMap.ContainsKey($archChoice)) { $archMap[$archChoice] } else { 'layered' }
    
    return @{
        name = $name
        kind = $kind
        architecture = $architecture
    }
}

function Invoke-New {
    Write-Host ""
    
    $answers = Show-NewProjectWizard
    
    $name = $answers.name
    $kind = $answers.kind
    $architecture = $answers.architecture
    
    Write-Banner "Creating Project: $name"
    
    $bootstrapScript = Join-Path $Script:WF_ROOT "scripts\bootstrap-workspace.ps1"
    if (-not (Test-Path $bootstrapScript)) {
        Write-Error "Bootstrap script not found: $bootstrapScript"
        exit 1
    }
    
    Write-Step "Scaffolding project..."
    & $bootstrapScript -ProjectName $name -ProjectKind $kind -ProjectArchitecture $architecture -CreateProject
    
    $projectPath = Join-Path $Script:WF_ROOT "projects\$name"
    if (Test-Path $projectPath) {
        Write-Banner "Project Created!" "Green"
        Write-Host "Location: $projectPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  cd projects\$name" -ForegroundColor White
        Write-Host "  wf validate" -ForegroundColor White
        Write-Host ""
    }
}

function Invoke-Validate {
    Write-Banner "Validate Workspace"
    
    $validateScript = Join-Path $Script:WF_ROOT "scripts\validate-workspace.ps1"
    if (Test-Path $validateScript) {
        & $validateScript
    } else {
        Write-Warning "Validation script not found"
    }
}

function Invoke-Doctor {
    Write-Banner "Workspace Doctor"
    
    $issues = @()
    
    Write-Step "Checking prerequisites..."
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $issues += "Git not found" }
    if (-not (Get-Command powershell -ErrorAction SilentlyContinue)) { $issues += "PowerShell not found" }
    
    Write-Step "Checking Git configuration..."
    $gitName = git config --global user.name 2>$null
    $gitEmail = git config --global user.email 2>$null
    if ([string]::IsNullOrWhiteSpace($gitName)) { $issues += "Git user.name not configured" }
    if ([string]::IsNullOrWhiteSpace($gitEmail)) { $issues += "Git user.email not configured" }
    
    Write-Step "Checking workspace directories..."
    $requiredDirs = @('config', 'tools', 'projects', 'docs', '.engram-data')
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path (Join-Path $Script:WF_ROOT $dir))) {
            $issues += "Missing directory: $dir"
        }
    }
    
    Write-Host ""
    if ($issues.Count -eq 0) {
        Write-Success "No issues found!"
    } else {
        Write-Warning "Found $($issues.Count) issue(s):"
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor White
        }
    }
}

function Invoke-Tools {
    Write-Banner "Workspace Tools"
    
    $config = $null
    if (Test-Path $Script:WF_CONFIG) {
        $config = Get-Content $Script:WF_CONFIG -Raw | ConvertFrom-Json
    }
    
    Write-Host "Configured tools:" -ForegroundColor Yellow
    if ($config -and $config.tools) {
        foreach ($tool in $config.tools) {
            $installed = Get-Command $tool.checkCommand -ErrorAction SilentlyContinue
            $status = if ($installed) { "[OK] Installed" } else { "[--] Not installed" }
            $color = if ($installed) { "Green" } else { "Gray" }
            Write-Host "  $($tool.name): $status" -ForegroundColor $color
        }
    } else {
        Write-Host "  No tools configured" -ForegroundColor Gray
    }
}

function Invoke-Skills {
    Write-Banner "Workspace Skills"
    
    $skillsDir = Join-Path $Script:WF_ROOT 'skills'
    if (Test-Path $skillsDir) {
        $skills = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue
        if ($skills) {
            Write-Host "Available skills:" -ForegroundColor Yellow
            foreach ($skill in $skills) {
                Write-Host "  $($skill.Name)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "No skills installed" -ForegroundColor Gray
        }
    } else {
        Write-Host "Skills directory not found" -ForegroundColor Gray
    }
}

function Invoke-Clean {
    Write-Banner "Clean Workspace"
    
    Write-Step "Cleaning runtime data..."
    $engramData = Join-Path $Script:WF_ROOT '.engram-data'
    if (Test-Path $engramData) {
        Get-ChildItem -Path $engramData -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Cleaned .engram-data"
    }
    
    Write-Banner "Clean Complete!" "Green"
}

function Invoke-List {
    Write-Banner "Projects"
    
    $projectsRoot = Join-Path $Script:WF_ROOT 'projects'
    if (Test-Path $projectsRoot) {
        $projects = Get-ChildItem -Path $projectsRoot -Directory -ErrorAction SilentlyContinue
        if ($projects) {
            Write-Host "Found $($projects.Count) project(s):" -ForegroundColor Gray
            Write-Host ""
            foreach ($proj in $projects) {
                Write-Host "  $($proj.Name)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "No projects found. Run 'wf new' to create one." -ForegroundColor Gray
        }
    } else {
        Write-Warning "Projects directory not found"
    }
}

switch ($Command) {
    'help' { Show-Help }
    'version' { Show-Version }
    'init' { Invoke-Init }
    'new' { Invoke-New }
    'validate' { Invoke-Validate }
    'doctor' { Invoke-Doctor }
    'tools' { Invoke-Tools }
    'skills' { Invoke-Skills }
    'clean' { Invoke-Clean }
    'list' { Invoke-List }
    default {
        Write-Error "Unknown command: $Command"
        Write-Host "Run 'wf help' for available commands."
        exit 1
    }
}
