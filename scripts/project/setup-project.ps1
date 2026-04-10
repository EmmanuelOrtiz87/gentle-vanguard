# setup-project.ps1
# Setup project to use Gentleman Foundation
# Creates .skills/ symlinks and configures hooks

param(
    [string]$ProjectPath = "",
    [switch]$Force,
    [switch]$GlobalHooks,
    [switch]$SkillsOnly,
    [switch]$HooksOnly
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$GFRoot = Split-Path -Parent $scriptDir

if (-not $ProjectPath) {
    $ProjectPath = Split-Path -Parent $scriptDir
    if ((Split-Path -Leaf $ProjectPath) -eq "scripts") {
        $ProjectPath = Split-Path -Parent $ProjectPath
    }
}

$ProjectRoot = Resolve-Path $ProjectPath
$ProjectSkills = Join-Path $ProjectRoot ".skills"
$ProjectHooks = Join-Path $ProjectRoot ".githooks"

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Project Setup - Gentleman Foundation" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Project: $ProjectRoot"
Write-Host "Foundation: $GFRoot"
Write-Host ""

if (-not (Test-Path $GFRoot)) {
    Write-Err "Foundation not found at: $GFRoot"
    Write-Host "Run bootstrap-machine.ps1 first to install the foundation." -ForegroundColor Yellow
    exit 1
}

if (-not $SkillsOnly) {
    Write-Step "1. Creating .githooks Directory"
    if (-not (Test-Path $ProjectHooks)) {
        New-Item -ItemType Directory -Path $ProjectHooks -Force | Out-Null
    }
    Write-Success ".githooks directory ready"
    
    Write-Step "2. Installing Git Hooks"
    
    $hooksToInstall = @(
        @{ Source = "pre-commit"; Name = "pre-commit.ps1" }
    )
    
    foreach ($hook in $hooksToInstall) {
        $sourceHook = Join-Path (Join-Path $GFRoot "hooks") $hook.Name
        if (Test-Path $sourceHook) {
            $targetHook = Join-Path $ProjectHooks $hook.Name
            if ((Test-Path $targetHook) -and -not $Force) {
                Write-Warn "$($hook.Name) already exists (use -Force to overwrite)"
            } else {
                if (Test-Path $targetHook) { Remove-Item $targetHook -Force }
                Copy-Item -Path $sourceHook -Destination $targetHook -Force
                Write-Success "Installed: $($hook.Name)"
            }
        }
    }
    
    $gitHooksConfig = Join-Path (Join-Path $ProjectRoot ".git") "hooks"
    if (Test-Path $gitHooksConfig) {
        $localHooksPath = Join-Path (Join-Path (Join-Path $ProjectRoot ".git") "info") "hooks"
        $gitConfigFile = Join-Path (Join-Path $ProjectRoot ".git") "config"
        
        $currentHooksPath = git config --local core.hooksPath 2>$null
        if ($currentHooksPath -ne $ProjectHooks -or $GlobalHooks) {
            git config --local core.hooksPath $ProjectHooks
            Write-Success "Git hooks path configured to: $ProjectHooks"
        } else {
            Write-Success "Git hooks already configured: $ProjectHooks"
        }
    }
}

if (-not $HooksOnly) {
    Write-Step "3. Creating .skills Symlinks"
    
    if (-not (Test-Path $ProjectSkills)) {
        New-Item -ItemType Directory -Path $ProjectSkills -Force | Out-Null
    }
    
    $sourceSkills = Join-Path $GFRoot "skills"
    $availableSkills = Get-ChildItem $SourceSkills -Directory
    
    Write-Host "Available skills: $($availableSkills.Count)" -ForegroundColor Gray
    
    foreach ($skill in $availableSkills) {
        $targetLink = Join-Path $ProjectSkills $skill.Name
        
        if ((Test-Path $targetLink) -and -not $Force) {
            Write-Warn "Skipped (exists): $($skill.Name)"
            continue
        }
        
        if (Test-Path $targetLink) {
            if ((Get-Item $targetLink).LinkType -eq "SymbolicLink") {
                Remove-Item $targetLink -Force
            } else {
                Remove-Item $targetLink -Recurse -Force
            }
        }
        
        try {
            New-Item -ItemType SymbolicLink -Path $targetLink -Target $skill.FullName -Force | Out-Null
            Write-Success "[SYMLINK] $($skill.Name)"
        } catch {
            Write-Warn "[COPY] Symlink failed, copying: $($skill.Name)"
            Copy-Item -Path $skill.FullName -Destination $targetLink -Recurse -Force
        }
    }
    
    Write-Step "4. Creating AGENTS.md Reference"
    $agentsMd = Join-Path $ProjectRoot "AGENTS.md"
    
    $agentsContent = @"
# AI Agent Guidelines

This project is configured to work with the Gentleman Foundation.

## Skills

Skills are linked via `.skills/` directory and available globally.

| Category | Skills Available |
|----------|------------------|
| Orchestrator | project-orchestrator |
| Frontend | angular-spa, react-19, nextjs-15, tailwind-4 |
| Backend | golang-api, api-design, django-drf |
| Database | database-relational, database-nosql |
| Testing | testing-strategy, testing-skill |
| Quality | typescript, security |
| Workflow | github-pr, jira-task |

## Validation

Run before commits:
```powershell
.\scripts\validate-project.ps1
```

## Hooks

Git hooks are configured in `.githooks/` directory.
"@
    
    if ((Test-Path $agentsMd) -and -not $Force) {
        Write-Warn "AGENTS.md already exists (use -Force to overwrite)"
    } else {
        Set-Content -Path $agentsMd -Value $agentsContent
        Write-Success "AGENTS.md created/updated"
    }
}

Write-Step "Summary"
Write-Host ""
Write-Success "Project configured successfully!"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review and customize AGENTS.md"
Write-Host "  2. Add project-specific skills if needed"
Write-Host "  3. Run 'gf validate' to verify"
Write-Host ""
