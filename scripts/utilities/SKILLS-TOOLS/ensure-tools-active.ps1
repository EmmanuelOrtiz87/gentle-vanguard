# ensure-tools-active.ps1
# Health-check and auto-install for all foundation tools.
# Reads tool definitions from config/workspace.config.json (single source of truth).
# All 5 tools follow the same check  install  verify pattern.

param(
    [switch]$AutoStart,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot   = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

#  Output helpers 
function Write-Step { param([string]$m) if (-not $Quiet) { Write-Host "`n=== $m ===" -ForegroundColor Cyan } }
function Write-Ok   { param([string]$m) if (-not $Quiet) { Write-Host "[OK] $m"   -ForegroundColor Green  } }
function Write-Warn { param([string]$m) if (-not $Quiet) { Write-Host "[WARN] $m" -ForegroundColor Yellow } }
function Write-Info { param([string]$m) if (-not $Quiet) { Write-Host "[INFO] $m" -ForegroundColor Cyan   } }
function Write-Err  { param([string]$m) if (-not $Quiet) { Write-Host "[ERROR] $m" -ForegroundColor Red   } }

function Get-CurrentPlatform {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) { return 'windows' }
        if ($IsMacOS) { return 'macos' }
        if ($IsLinux) { return 'linux' }
    }
    try {
        $os = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription.ToLowerInvariant()
        if ($os -like '*windows*') { return 'windows' }
        if ($os -like '*darwin*' -or $os -like '*mac*') { return 'macos' }
        if ($os -like '*linux*') { return 'linux' }
    } catch {}
    return 'windows'
}

function Get-PathSeparator {
    return [string][System.IO.Path]::PathSeparator
}

function Get-HomePath {
    if ((Get-CurrentPlatform) -eq 'windows') {
        return $env:USERPROFILE
    }
    return $HOME
}

function Get-GoBinDir {
    if ($env:GOBIN)  { return $env:GOBIN }
    if ($env:GOPATH) { return (Join-Path $env:GOPATH 'bin') }
    return (Join-Path (Join-Path (Get-HomePath) 'go') 'bin')
}

function Get-BashPath {
    $bashCmd = Get-Command bash -ErrorAction SilentlyContinue
    if ($bashCmd) { return $bashCmd.Source }
    if ((Get-CurrentPlatform) -eq 'windows') {
        $gitBash = 'C:\Program Files\Git\bin\bash.exe'
        if (Test-Path $gitBash) { return $gitBash }
    }
    return $null
}

function Get-PlatformInstallInfo {
    param($InstallNode)
    if (-not $InstallNode) { return $null }
    $platform = Get-CurrentPlatform
    $prop = $InstallNode.PSObject.Properties[$platform]
    if ($prop) { return $prop.Value }
    return $null
}

#  Resolve {token} placeholders in a string 
function Resolve-Placeholders {
    param([string]$Text, [hashtable]$Vars)
    foreach ($k in $Vars.Keys) { $Text = $Text.Replace("{$k}", $Vars[$k]) }
    return $Text
}

#  Check if a tool is currently available 
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

#  System dependency management (go, git, node, etc.) 

# Returns the installed version string for a system dep, or $null if undetectable.
function Get-SystemDepVersion {
    param($Dep)
    if (-not (Get-Command $Dep.checkCommand -ErrorAction SilentlyContinue)) { return $null }
    try {
        $vArgs = if ($Dep.versionArgs) { [string[]]($Dep.versionArgs | ForEach-Object { [string]$_ }) } else { @('--version') }
        $raw   = (& $Dep.checkCommand $vArgs 2>&1) | Select-Object -First 1 | Out-String
        if ($raw -match [string]$Dep.versionRegex) { return $Matches[1] }
    } catch {}
    return $null
}

# Attempts to install a system dep via winget; falls back to clear manual instructions.
# Returns $true if installed (may need terminal restart), $false if manual action required.
function Install-SystemDep {
    param($Dep)

    $platform = Get-CurrentPlatform
    $info = Get-PlatformInstallInfo -InstallNode $Dep.install

    Write-Host ""
    Write-Host "  --- REQUIRED SYSTEM DEPENDENCY: $($Dep.name) ---" -ForegroundColor Yellow
    if ($Dep.minVersion) {
        Write-Host "  Minimum version : $($Dep.minVersion)" -ForegroundColor Yellow
    }
    if ($Dep.usedBy) {
        Write-Host "  Used by         : $($Dep.usedBy -join ', ')" -ForegroundColor Yellow
    }

    if (-not $info) {
        Write-Host "  - [ERROR] No install info in workspace.config.json for '$($Dep.name)' on '$platform'" -ForegroundColor Red
        return $false
    }

    #  Attempt auto-install via available package managers 
    $didAutoInstall = $false
    if ($info.winget) {
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        $winget = if ($wingetCmd) { $wingetCmd.Source } else { $null }
        if ((-not $winget) -and ($platform -eq 'windows')) {
            # winget ships as an AppX alias on Windows 10/11
            $alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
            if (Test-Path $alias) { $winget = $alias }
        }
        if ($winget) {
            Write-Host "  -  Trying winget auto-install: $($info.winget)" -ForegroundColor Cyan
            try {
                $output   = & $winget install --id $info.winget --silent `
                                --accept-package-agreements --accept-source-agreements 2>&1
                $exitCode = $LASTEXITCODE
                $outText  = $output | Out-String

                $alreadyOk = ($exitCode -eq 0) -or
                             ($outText -like '*already installed*') -or
                             ($outText -like '*No applicable upgrade*') -or
                             ($exitCode -eq -1978335189)

                if ($alreadyOk) {
                    Write-Host "  [OK] winget install succeeded" -ForegroundColor Green
                    $didAutoInstall = $true
                } else {
                    $lastLines = ($output | Select-Object -Last 4) -join "`n"
                    Write-Host "  [ERROR] winget exit $exitCode" -ForegroundColor Red
                    Write-Host "  $lastLines" -ForegroundColor Red
                }
            } catch {
                Write-Host "  [ERROR] winget threw: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    if ((-not $didAutoInstall) -and $info.brew) {
        $brewCmd = Get-Command brew -ErrorAction SilentlyContinue
        if ($brewCmd) {
            Write-Host "  -  Trying brew auto-install: $($info.brew)" -ForegroundColor Cyan
            try {
                & $brewCmd.Source install $info.brew 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [OK] brew install succeeded" -ForegroundColor Green
                    $didAutoInstall = $true
                }
            } catch {
                Write-Host "  [ERROR] brew threw: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    if ($didAutoInstall) {
        if ($info.notes) {
            Write-Host "  NOTE: $($info.notes)" -ForegroundColor Yellow
        }
        $pathSep = Get-PathSeparator
        $userHome = Get-HomePath
        $refreshDirs = @()
        if ($platform -eq 'windows') {
            $refreshDirs = @(
                'C:\Program Files\Go\bin',
                'C:\Program Files\Git\bin',
                'C:\Program Files\Git\cmd',
                'C:\Program Files\nodejs',
                (Join-Path (Join-Path $userHome 'go') 'bin')
            )
        } elseif ($platform -eq 'macos') {
            $refreshDirs = @(
                '/usr/local/bin',
                '/opt/homebrew/bin',
                '/usr/local/go/bin',
                (Join-Path (Join-Path $userHome 'go') 'bin')
            )
        } else {
            $refreshDirs = @(
                '/usr/local/bin',
                '/usr/bin',
                '/usr/local/go/bin',
                (Join-Path (Join-Path $userHome 'go') 'bin')
            )
        }
        foreach ($d in $refreshDirs) {
            if ((Test-Path $d) -and ($env:PATH -notlike "*$d*")) {
                $env:PATH += "$pathSep$d"
            }
        }
        $nowAvailable = [bool](Get-Command $Dep.checkCommand -ErrorAction SilentlyContinue)
        if ($nowAvailable) {
            Write-Host "  [OK] $($Dep.name) is now available in this session" -ForegroundColor Green
        } else {
            Write-Host "  [OK] $($Dep.name) installed - open a NEW terminal, then re-run: wf.ps1 health" -ForegroundColor Yellow
        }
        return $true
    }

    if (($platform -eq 'windows') -and (-not (Get-Command winget -ErrorAction SilentlyContinue))) {
        Write-Host "  winget not found on this system" -ForegroundColor Yellow
    }

    #  Manual install fallback 
    Write-Host "" -ForegroundColor Red
    Write-Host "  MANUAL INSTALL REQUIRED" -ForegroundColor Red
    Write-Host "  ---------------------------------------------------------" -ForegroundColor Red
    Write-Host "  1. Download from : $($info.url)" -ForegroundColor White
    Write-Host "  2. Install version $($Dep.minVersion) or newer" -ForegroundColor White
    if ($info.notes) {
        Write-Host "  3. $($info.notes)" -ForegroundColor White
    }
    Write-Host "  4. Restart this terminal" -ForegroundColor White
    Write-Host "  5. Re-run: wf.ps1 health" -ForegroundColor White
    Write-Host "  [BLOCKED] Cannot auto-install '$($Dep.name)' -- see instructions above" -ForegroundColor Red
    return $false
}

# Iterates systemDependencies from config; checks availability, version, and auto-installs
# required missing deps when -AutoStart is set.
function Invoke-SystemDeps {
    Write-Step "Checking System Dependencies"

    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
    if (-not (Test-Path $configPath)) { Write-Warn 'Config not found - skipping system dep checks'; return }

    $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $cfg.systemDependencies) { Write-Info "No system dependencies declared in config"; return }

    $missingRequired = @()

    $platform = Get-CurrentPlatform
    foreach ($dep in $cfg.systemDependencies) {
        $depInfo = Get-PlatformInstallInfo -InstallNode $dep.install
        $available = [bool](Get-Command $dep.checkCommand -ErrorAction SilentlyContinue)

        if ($available) {
            # Optionally check minimum version
            if ($dep.versionRegex -and $dep.minVersion) {
                $ver = Get-SystemDepVersion -Dep $dep
                if ($ver) {
                    $cmp = 0
                    try {
                        $va = [Version]($ver  -replace '[^0-9.]', '')
                        $vb = [Version]([string]$dep.minVersion -replace '[^0-9.]', '')
                        # Pad to same component count for reliable comparison
                        while ($va.ToString().Split('.').Count -lt $vb.ToString().Split('.').Count) {
                            $va = [Version]("$va.0")
                        }
                        $cmp = $va.CompareTo($vb)
                    } catch {}

                    if ($cmp -lt 0) {
                        Write-Warn "$($dep.name) v$ver is below required minimum v$($dep.minVersion)"
                        if ($depInfo -and $depInfo.url) {
                            Write-Info "  Update from: $($depInfo.url)"
                        }
                        if (-not $dep.optional) { $missingRequired += $dep.name }
                    } else {
                        Write-Ok "$($dep.name) v$ver"
                    }
                } else {
                    Write-Ok "$($dep.name) installed (version check skipped)"
                }
            } else {
                Write-Ok "$($dep.name) installed"
            }
            continue
        }

        # Not installed
        if ($dep.optional) {
            $usedMsg = if ($dep.usedBy) { " (used by: $($dep.usedBy -join ', '))" } else { '' }
            Write-Warn "$($dep.name) not installed [optional]$usedMsg"
            if ($depInfo -and $depInfo.url) {
                Write-Info "  Install from: $($depInfo.url)"
            }
            continue
        }

        # Required dep is missing
        Write-Err "$($dep.name) is REQUIRED but not installed"
        if ($AutoStart) {
            $ok = Install-SystemDep -Dep $dep
            if (-not $ok) { $missingRequired += $dep.name }
        } else {
            if ($depInfo -and $depInfo.url) {
                Write-Host "  Install from : $($depInfo.url)" -ForegroundColor Yellow
            }
            Write-Host "  Then run     : wf.ps1 health" -ForegroundColor Yellow
            $missingRequired += $dep.name
        }
    }

    if ($missingRequired.Count -gt 0) {
        Write-Host ""
        Write-Host "  =========================================================" -ForegroundColor Red
        Write-Host "  MISSING REQUIRED DEPENDENCIES: $($missingRequired -join ', ')" -ForegroundColor Red
        Write-Host "  Install the packages listed above, restart this terminal," -ForegroundColor Red
        Write-Host "  then run: wf.ps1 health" -ForegroundColor Red
        Write-Host "  =========================================================" -ForegroundColor Red
        Write-Host ""
    } else {
        Write-Ok "All required system dependencies are satisfied"
    }
}

#  Install a tool using the command from workspace.config.json 
function Install-Tool {
    param($Tool, [string]$ToolsRoot)

    $platform = Get-CurrentPlatform
    $installCmd = $null
    $platformInstall = Get-PlatformInstallInfo -InstallNode $Tool.install
    if ($platformInstall) {
        $installCmd = Resolve-Placeholders -Text ([string]$platformInstall) -Vars @{
            toolsRoot     = $ToolsRoot
            workspaceRoot = $repoRoot
        }
    }
    if (-not $installCmd) {
        Write-Warn "$($Tool.name): no install command defined for '$platform'"
        return $false
    }

    # Prerequisite check (go, git, bash)  attempt auto-install via system deps if missing
    foreach ($req in $Tool.requires) {
        if ($req -eq 'bash') {
            $bashPath = Get-BashPath
            $hasBash = -not [string]::IsNullOrWhiteSpace($bashPath)
            if (-not $hasBash) {
                Write-Warn "$($Tool.name): requires bash"
                # Try to resolve via git's system dep entry if AutoStart is on
                if ($AutoStart) {
                    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
                    $cfg        = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    $gitDep     = $cfg.systemDependencies | Where-Object { $_.name -eq 'git' } | Select-Object -First 1
                    if ($gitDep) {
                        $ok = Install-SystemDep -Dep $gitDep
                        if ($ok) {
                            $bashPath = Get-BashPath
                            $hasBash = -not [string]::IsNullOrWhiteSpace($bashPath)
                        }
                    }
                }
                if (-not $hasBash) {
                    Write-Host "  Install bash (or Git, if it bundles bash), then re-run: wf.ps1 health" -ForegroundColor Yellow
                    return $false
                }
            }
        } else {
            $reqFound = [bool](Get-Command $req -ErrorAction SilentlyContinue)
            if (-not $reqFound) {
                Write-Warn "$($Tool.name): requires '$req' but it is not installed"
                # Try to resolve via systemDependencies if AutoStart is on
                if ($AutoStart) {
                    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
                    $cfg        = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    $sysDep     = $cfg.systemDependencies | Where-Object { $_.name -eq $req } | Select-Object -First 1
                    if ($sysDep) {
                        $ok = Install-SystemDep -Dep $sysDep
                        if ($ok) {
                            $reqFound = [bool](Get-Command $req -ErrorAction SilentlyContinue)
                        }
                    }
                }
                if (-not $reqFound) {
                    Write-Host "  Once '$req' is installed, re-run: wf.ps1 health" -ForegroundColor Yellow
                    return $false
                }
            }
        }
    }

    Write-Info "$($Tool.name): not found - installing..."
    try {
        Invoke-Expression $installCmd 2>&1 | Out-Null
    } catch {
        $msg = $_.Exception.Message
        # HTTP 403 on opencode.ai means corporate/network restriction  treat as optional-blocked
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
        Write-Warn "$($Tool.name): install failed - $msg"
        return $false
    }
    return $true
}

#  Re-check after install (handles GOPATH/bin and bash-installed tools not yet in PATH) 
function Confirm-ToolAfterInstall {
    param($Tool, [string]$ToolsRoot)

    if (Test-ToolAvailable -Tool $Tool -ToolsRoot $ToolsRoot) { return $true }

    $platformInstall = Get-PlatformInstallInfo -InstallNode $Tool.install
    $installText = if ($platformInstall) { [string]$platformInstall } else { '' }

    # For Go-installed binaries: check $GOPATH/bin directly
    if ($Tool.checkCommand -and $Tool.install -and
        $installText -like '*go install*') {
        $goBin = Get-GoBinDir
        $exe = Join-Path $goBin "$($Tool.checkCommand).exe"
        if (-not (Test-Path $exe)) { $exe = Join-Path $goBin $Tool.checkCommand }
        if (Test-Path $exe) {
            Write-Ok "$($Tool.name) installed at $exe (add $goBin to PATH if not already)"
            return $true
        }
    }

    # For bash-installed tools: check common install locations
    if ($Tool.checkCommand -and $Tool.install -and
        $installText -like '*bash*install.sh*') {
        $pathSep = Get-PathSeparator
        $userHome = Get-HomePath
        $candidateDirs = @(
            (Join-Path $userHome 'bin'),
            (Join-Path $userHome '.local\bin')
        )
        if ((Get-CurrentPlatform) -eq 'windows') {
            $candidateDirs += @(
                'C:\Program Files\Git\usr\bin',
                'C:\Program Files\Git\bin'
            )
        }
        foreach ($dir in $candidateDirs) {
            $candidate = Join-Path $dir $Tool.checkCommand
            if (Test-Path $candidate) {
                Write-Ok "$($Tool.name) installed at $candidate"
                Write-Info "  To use immediately in this session: PATH updated automatically"
                Write-Info "  To persist, restart your terminal after install"
                if ($env:PATH -notlike "*$dir*") {
                    $env:PATH += "$pathSep$dir"
                }
                Write-Info "  PATH updated for this session"
                return $true
            }
        }
        Write-Warn "$($Tool.name): install ran - binary not found in common locations"
        Write-Info "  Expected locations: $($candidateDirs -join ', ')"
        Write-Info "  Open a new terminal and run: $($Tool.checkCommand) --version"
    }

    return $false
}

#  Main tool activation loop (data-driven over workspace.config.json) 
function Invoke-ToolActivation {
    Write-Step "Checking Foundation Tools"

    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
    if (-not (Test-Path $configPath)) {
        Write-Warn "workspace.config.json not found - skipping tool checks"
        return
    }

    $cfg       = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $toolsRoot = if ($cfg.toolsRoot) { Join-Path $repoRoot $cfg.toolsRoot } else { Join-Path $repoRoot 'tools' }
    $allOk     = $true

    foreach ($tool in $cfg.tools) {
        $available = Test-ToolAvailable -Tool $tool -ToolsRoot $toolsRoot
        $isOptionalTool = $false
        if ($tool.PSObject.Properties.Name -contains 'optional') {
            $isOptionalTool = [bool]$tool.optional
        }

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
                    Write-Warn "$($tool.name) install ran - binary may need a terminal restart to appear in PATH"
                    if (-not $isOptionalTool) {
                        $allOk = $false
                    }
                }
            } else {
                if ($isOptionalTool) {
                    Write-Warn "$($tool.name) could not be auto-installed - optional tool, continuing"
                } else {
                    Write-Warn "$($tool.name) could not be auto-installed - manual action needed"
                    $allOk = $false
                }
            }
        } else {
            if ($isOptionalTool) {
                Write-Warn "$($tool.name) not installed [optional]"
            } else {
                Write-Warn "$($tool.name) not installed - run 'wf.ps1 health' to auto-install"
                $allOk = $false
            }
        }
    }

    if ($allOk) { Write-Ok "Required foundation tools are active" }
}

#  Orchestrator skills 
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

#  Optional MCP integrations 
function Test-MCPIntegrations {
    Write-Step "Checking Optional MCP Integrations"

    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
    if (-not (Test-Path $configPath)) { Write-Warn "Config not found - skipping MCP checks"; return }

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

#  Workflow CLI readiness 
function Test-WorkflowReadiness {
    Write-Step "Checking Workflow CLI"

    $wfScript = Join-Path $scriptDir 'wf.ps1'
    if (-not (Test-Path $wfScript)) {
        Write-Err "Workflow CLI not found: $wfScript"
        return
    }
    $shellCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $shellCmd) { $shellCmd = Get-Command powershell -ErrorAction SilentlyContinue }
    if (-not $shellCmd) {
        Write-Warn "Cannot locate a PowerShell runner to execute wf.ps1 status"
        return
    }

    if ((Get-CurrentPlatform) -eq 'windows') {
        $null = & $shellCmd.Source -NoProfile -ExecutionPolicy Bypass -File $wfScript status 2>$null
    } else {
        $null = & $shellCmd.Source -NoProfile -File $wfScript status 2>$null
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Workflow CLI (wf.ps1) is operational"
    } else {
        Write-Warn "Workflow CLI returned exit $LASTEXITCODE - check wf.ps1"
    }
}

#  Summary 
function Show-Summary {
    if ($Quiet) { return }
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Tool Activation Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  wf.ps1 status        - project status"   -ForegroundColor Cyan
    Write-Host "  wf.ps1 review        - run code review"  -ForegroundColor Cyan
    Write-Host "  wf.ps1 audit         - generate report"  -ForegroundColor Cyan
    Write-Host "  wf.ps1 update-tools  - update all tools" -ForegroundColor Cyan
    Write-Host ""
}

# - Entry point 
if (-not $Quiet) {
    Write-Host "Foundation - Development Stack - Tool Activation" -ForegroundColor Magenta
    Write-Host "Reads tool list from config/workspace.config.json" -ForegroundColor White
    Write-Host ""
}

Invoke-SystemDeps
Invoke-ToolActivation
Test-OrchestratorSkills
Test-MCPIntegrations
Test-WorkflowReadiness
Show-Summary

exit 0
