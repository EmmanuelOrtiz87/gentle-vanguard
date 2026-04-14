# ensure-tools-active.ps1
# Health-check and auto-install for all foundation tools.
# Reads tool definitions from config/workspace.config.json (single source of truth).
# All 5 tools follow the same check → install → verify pattern.

param(
    [switch]$AutoStart,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot   = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

# ── Output helpers ────────────────────────────────────────────────────────────
function Write-Step { param([string]$m) if (-not $Quiet) { Write-Host "`n=== $m ===" -ForegroundColor Cyan } }
function Write-Ok   { param([string]$m) if (-not $Quiet) { Write-Host "[OK] $m"   -ForegroundColor Green  } }
function Write-Warn { param([string]$m) if (-not $Quiet) { Write-Host "[WARN] $m" -ForegroundColor Yellow } }
function Write-Info { param([string]$m) if (-not $Quiet) { Write-Host "[INFO] $m" -ForegroundColor Cyan   } }
function Write-Err  { param([string]$m) if (-not $Quiet) { Write-Host "[ERROR] $m" -ForegroundColor Red   } }

# ── Resolve {token} placeholders in a string ─────────────────────────────────
function Resolve-Placeholders {
    param([string]$Text, [hashtable]$Vars)
    foreach ($k in $Vars.Keys) { $Text = $Text.Replace("{$k}", $Vars[$k]) }
    return $Text
}

# ── Check if a tool is currently available ───────────────────────────────────
function Test-ToolAvailable {
    param($Tool, [string]$ToolsRoot)
    if ($Tool.checkCommand) {
        return [bool](Get-Command $Tool.checkCommand -ErrorAction SilentlyContinue)
    }
    if ($Tool.checkPath) {
        $resolved = Resolve-Placeholders -Text $Tool.checkPath -Vars @{
            toolsRoot     = $ToolsRoot
            workspaceRoot = $repoRoot
        }
        return (Test-Path $resolved)
    }
    return $false
}

# ── Install a tool using the command from workspace.config.json ──────────────
function Install-Tool {
    param($Tool, [string]$ToolsRoot)

    $installCmd = $null
    if ($Tool.install -and $Tool.install.windows) {
        $installCmd = Resolve-Placeholders -Text ([string]$Tool.install.windows) -Vars @{
            toolsRoot     = $ToolsRoot
            workspaceRoot = $repoRoot
        }
    }
    if (-not $installCmd) {
        Write-Warn "$($Tool.name): no install command defined for Windows"
        return $false
    }

    # Prerequisite check (go, git, bash) before attempting install
    foreach ($req in $Tool.requires) {
        if ($req -eq 'bash') {
            $hasBash = (Get-Command bash -ErrorAction SilentlyContinue) -or
                       (Test-Path 'C:\Program Files\Git\bin\bash.exe')
            if (-not $hasBash) {
                Write-Warn "$($Tool.name): requires bash (Git for Windows) — skipping auto-install"
                Write-Host "  Install Git for Windows: https://git-scm.com/download/win" -ForegroundColor Yellow
                return $false
            }
        } elseif (-not (Get-Command $req -ErrorAction SilentlyContinue)) {
            Write-Warn "$($Tool.name): requires '$req' but it is not found — skipping auto-install"
            return $false
        }
    }

    Write-Info "$($Tool.name): not found — installing..."
    try {
        Invoke-Expression $installCmd 2>&1 | Out-Null
    } catch {
        $msg = $_.Exception.Message
        # HTTP 403 on opencode.ai means corporate/network restriction — treat as optional-blocked
        if ($msg -like '*403*' -or $msg -like '*Prohibido*' -or $msg -like '*Forbidden*') {
            Write-Warn "$($Tool.name): install blocked by network restriction (HTTP 403)"
            Write-Info "  This tool is optional. Alternative install options:"
            Write-Info "  1. GitHub releases: https://github.com/sst/opencode/releases"
            Write-Info "  2. winget:          winget install sst.opencode"
            Write-Info "  3. npm:             npm install -g opencode"
            Write-Info "  4. Manual:          download binary from GitHub and add to PATH"
            # Return true so this does NOT block workspace bootstrap
            return $true
        }
        Write-Warn "$($Tool.name): install failed — $msg"
        return $false
    }
    return $true
}

# ── Re-check after install (handles GOPATH/bin and bash-installed tools not yet in PATH) ──
function Confirm-ToolAfterInstall {
    param($Tool, [string]$ToolsRoot)

    if (Test-ToolAvailable -Tool $Tool -ToolsRoot $ToolsRoot) { return $true }

    # For Go-installed binaries: check $GOPATH/bin directly
    if ($Tool.checkCommand -and $Tool.install -and
        ([string]$Tool.install.windows) -like '*go install*') {
        $goBin = if ($env:GOBIN) { $env:GOBIN } `
                 elseif ($env:GOPATH) { Join-Path $env:GOPATH 'bin' } `
                 else { Join-Path $env:USERPROFILE 'go\bin' }
        $exe = Join-Path $goBin "$($Tool.checkCommand).exe"
        if (-not (Test-Path $exe)) { $exe = Join-Path $goBin $Tool.checkCommand }
        if (Test-Path $exe) {
            Write-Ok "$($Tool.name) installed at $exe (add $goBin to PATH if not already)"
            return $true
        }
    }

    # For bash-installed tools (e.g. GGA): check common install locations
    if ($Tool.checkCommand -and $Tool.install -and
        ([string]$Tool.install.windows) -like '*bash*install.sh*') {
        $candidateDirs = @(
            (Join-Path $env:USERPROFILE 'bin'),
            (Join-Path $env:USERPROFILE '.local\bin'),
            'C:\Program Files\Git\usr\bin',
            'C:\Program Files\Git\bin'
        )
        foreach ($dir in $candidateDirs) {
            $candidate = Join-Path $dir $Tool.checkCommand
            if (Test-Path $candidate) {
                Write-Ok "$($Tool.name) installed at $candidate"
                Write-Info "  To use immediately, add to PATH: `$env:PATH += ';$dir'"
                Write-Info "  To persist, run: [Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$dir', 'User')"
                $env:PATH += ";$dir"
                Write-Info "  PATH updated for this session"
                return $true
            }
        }
        Write-Warn "$($Tool.name): install ran — binary not found in common locations"
        Write-Info "  Expected locations: $($candidateDirs -join ', ')"
        Write-Info "  Open a new terminal and run: $($Tool.checkCommand) --version"
    }

    return $false
}

# ── Main tool activation loop (data-driven over workspace.config.json) ────────
function Invoke-ToolActivation {
    Write-Step "Checking Foundation Tools"

    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
    if (-not (Test-Path $configPath)) {
        Write-Warn "workspace.config.json not found — skipping tool checks"
        return
    }

    $cfg       = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $toolsRoot = if ($cfg.toolsRoot) { Join-Path $repoRoot $cfg.toolsRoot } else { Join-Path $repoRoot 'tools' }
    $allOk     = $true

    foreach ($tool in $cfg.tools) {
        $available = Test-ToolAvailable -Tool $tool -ToolsRoot $toolsRoot

        if ($available) {
            Write-Ok "$($tool.name) is available"
            continue
        }

        if ($AutoStart) {
            $ok = Install-Tool -Tool $tool -ToolsRoot $toolsRoot
            if ($ok) {
                if (Confirm-ToolAfterInstall -Tool $tool -ToolsRoot $toolsRoot) {
                    Write-Ok "$($tool.name) installed and verified"
                } else {
                    Write-Warn "$($tool.name) install ran — binary may need a terminal restart to appear in PATH"
                }
            } else {
                Write-Warn "$($tool.name) could not be auto-installed — manual action needed"
                $allOk = $false
            }
        } else {
            Write-Warn "$($tool.name) not installed — run 'wf.ps1 health' to auto-install"
            $allOk = $false
        }
    }

    if ($allOk) { Write-Ok "All foundation tools are active" }
}

# ── Orchestrator skills ───────────────────────────────────────────────────────
function Test-OrchestratorSkills {
    Write-Step "Checking Orchestrator Skills"

    $skillsDir = Join-Path $repoRoot 'skills'
    $required  = @('project-orchestrator-skill', 'code-review-orchestrator-skill', 'session-workflow-skill')
    $allOk     = $true

    foreach ($skill in $required) {
        if (Test-Path (Join-Path $skillsDir $skill)) {
            Write-Ok "$skill available"
        } else {
            Write-Warn "$skill not found"
            $allOk = $false
        }
    }
    if ($allOk) { Write-Ok "Orchestrator skills ready" }
}

# ── Optional MCP integrations ─────────────────────────────────────────────────
function Test-MCPIntegrations {
    Write-Step "Checking Optional MCP Integrations"

    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
    if (-not (Test-Path $configPath)) { Write-Warn "Config not found — skipping MCP checks"; return }

    $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $cfg.mcpIntegrations) { Write-Ok "No MCP integrations configured (default)"; return }

    foreach ($name in @('context7', 'notion')) {
        $integration = $cfg.mcpIntegrations.$name
        if (-not $integration -or -not $integration.enabled) {
            Write-Ok "MCP $name disabled (default)"
            continue
        }
        $missing = @()
        foreach ($envName in $integration.requiredEnv) {
            if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable([string]$envName))) {
                $missing += [string]$envName
            }
        }
        if ($missing.Count -gt 0) {
            Write-Warn "MCP $name enabled but missing env vars: $($missing -join ', ')"
        } else {
            Write-Ok "MCP $name enabled and configured"
        }
    }
}

# ── Workflow CLI readiness ────────────────────────────────────────────────────
function Test-WorkflowReadiness {
    Write-Step "Checking Workflow CLI"

    $wfScript = Join-Path $scriptDir 'wf.ps1'
    if (-not (Test-Path $wfScript)) {
        Write-Err "Workflow CLI not found: $wfScript"
        return
    }
    $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wfScript status 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Workflow CLI (wf.ps1) is operational"
    } else {
        Write-Warn "Workflow CLI returned exit $LASTEXITCODE — check wf.ps1"
    }
}

# ── Summary ───────────────────────────────────────────────────────────────────
function Show-Summary {
    if ($Quiet) { return }
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Tool Activation Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  wf.ps1 status        — project status"   -ForegroundColor Cyan
    Write-Host "  wf.ps1 review        — run code review"  -ForegroundColor Cyan
    Write-Host "  wf.ps1 audit         — generate report"  -ForegroundColor Cyan
    Write-Host "  wf.ps1 update-tools  — update all tools" -ForegroundColor Cyan
    Write-Host ""
}

# ── Entry point ───────────────────────────────────────────────────────────────
if (-not $Quiet) {
    Write-Host "Gentleman Foundation — Tool Activation" -ForegroundColor Magenta
    Write-Host "Reads tool list from config/workspace.config.json" -ForegroundColor White
    Write-Host ""
}

Invoke-ToolActivation
Test-OrchestratorSkills
Test-MCPIntegrations
Test-WorkflowReadiness
Show-Summary

exit 0