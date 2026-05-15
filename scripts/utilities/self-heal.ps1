<#
.SYNOPSIS
    Self-Healing Stack — auto-detects and repairs common infrastructure issues.

.DESCRIPTION
    Runs modular healers: config, hooks, session, skills, engram.
    Detects issues, reports, and optionally applies fixes.

.PARAMETER AutoFix
    Apply fixes automatically for all healable issues.
.PARAMETER Scope
    Run specific healer only: config, hooks, session, skills, engram, or all (default).
.PARAMETER Quiet
    Only output issues found (no OK status lines).
#>

param(
    [switch]$AutoFix,
    [string]$Scope = 'all',
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$healed = 0; $errors = 0; $issues = @()

function Write-Ok    { if (-not $Quiet) { Write-Host "  [OK] $args" -ForegroundColor Green } }
function Write-Warn  { Write-Host "  [WARN] $args" -ForegroundColor Yellow }
function Write-Err   { Write-Host "  [ERR] $args" -ForegroundColor Red }
function Write-Info  { if (-not $Quiet) { Write-Host "  [INFO] $args" -ForegroundColor Cyan } }
function Write-Step  { if (-not $Quiet) { Write-Host "`n--- $args ---" -ForegroundColor Magenta } }
function Write-Act   { Write-Host "  [ACT] $args" -ForegroundColor Blue }

function Add-Issue {
    param($Healer, $Severity, $Message, $FixAction)
    $issues += @{
        healer = $Healer; severity = $Severity; message = $Message; fixAction = $FixAction
    }
    if ($Severity -eq 'error') { Write-Err "${Healer}: ${Message}" }
    else { Write-Warn "${Healer}: ${Message}" }
}

# === Healers ===

function Heal-Config {
    Write-Step "Config Healer"

    $configDir = Join-Path $repoRoot "config"
    if (-not (Test-Path $configDir)) { Add-Issue "config" "error" "config/ directory missing"; return }

    $jsonFiles = @(Get-ChildItem -Path $configDir -Filter "*.json" -ErrorAction SilentlyContinue)
    if ($jsonFiles.Count -eq 0) { Add-Issue "config" "error" "No JSON files in config/"; return }

    foreach ($file in $jsonFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction Stop
            $null = $content | ConvertFrom-Json -ErrorAction Stop
            Write-Ok "$($file.Name) — valid JSON"
        } catch {
            $errMsg = $_.Exception.Message
            Add-Issue "config" "error" "$($file.Name) — parse failed: $errMsg"
            if ($AutoFix) {
                try {
                    $fixed = $content -replace ',\s*\}', '}' -replace ',\s*\]', ']'
                    $null = $fixed | ConvertFrom-Json -ErrorAction Stop
                    $fixed | Set-Content -Path $file.FullName -Encoding UTF8
                    $script:healed++; Write-Act "Fixed: $($file.Name) — trailing comma removed"
                } catch {
                    Write-Err "Cannot auto-fix $($file.Name): requires manual repair"
                }
            }
        }
    }

    # Check required files
    $required = @('orchestrator.json', 'auto-delegation.json', 'workspace.config.json')
    foreach ($name in $required) {
        $path = Join-Path $configDir $name
        if (-not (Test-Path $path)) {
            Add-Issue "config" "error" "Required config missing: $name"
        } else {
            Write-Ok "$name — present"
        }
    }
}

function Heal-Hooks {
    Write-Step "Hook Guardian"

    $hookDir = Join-Path $repoRoot ".git" "hooks"
    $sourceDir = Join-Path $repoRoot "scripts" "git-hooks"

    if (-not (Test-Path $hookDir)) {
        Add-Issue "hooks" "error" ".git/hooks/ directory missing (not a git repo?)"
        return
    }
    if (-not (Test-Path $sourceDir)) {
        Add-Issue "hooks" "error" "scripts/git-hooks/ source directory missing"
        return
    }

    $requiredHooks = @('pre-commit', 'commit-msg', 'pre-push')
    foreach ($hookName in $requiredHooks) {
        $hookPath = Join-Path $hookDir $hookName
        $srcPath = Join-Path $sourceDir $hookName

        if (Test-Path $hookPath) {
            Write-Ok "$hookName — installed"
        } else {
            Add-Issue "hooks" "error" "$hookName hook not found"
            if ($AutoFix -and (Test-Path $srcPath)) {
                Copy-Item -Path $srcPath -Destination $hookPath -Force
                $script:healed++; Write-Act "Installed: $hookName from scripts/git-hooks/"
            }
        }
    }

    # Check hook content matches source (not stale)
    foreach ($hookName in $requiredHooks) {
        $hookPath = Join-Path $hookDir $hookName
        $srcPath = Join-Path $sourceDir $hookName
        if ((Test-Path $hookPath) -and (Test-Path $srcPath)) {
            $hookContent = Get-Content $hookPath -Raw
            $srcContent = Get-Content $srcPath -Raw
            if ($hookContent -ne $srcContent) {
                Add-Issue "hooks" "warn" "$hookName — content differs from source (update available)"
                if ($AutoFix) {
                    Copy-Item -Path $srcPath -Destination $hookPath -Force
                    $script:healed++; Write-Act "Updated: $hookName to match source"
                }
            } else {
                Write-Ok "$hookName — up to date"
            }
        }
    }
}

function Heal-Session {
    Write-Step "Session Recovery"

    $sessionDir = Join-Path $repoRoot ".session"
    if (-not (Test-Path $sessionDir)) {
        Write-Ok "No .session/ directory (fresh workspace)"
        return
    }

    $sessionFiles = @(Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue)
    if ($sessionFiles.Count -eq 0) {
        Write-Ok "No session files to recover"
        return
    }

    $corrupt = 0
    foreach ($file in $sessionFiles) {
        try {
            $null = Get-Content $file.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
            Write-Ok "$($file.Name) — valid"
            Write-Info "$($file.Name) — $( [math]::Round((Get-Item $file.FullName).Length / 1KB) ) KB"
        } catch {
            $corrupt++
            Add-Issue "session" "error" "$($file.Name) — corrupt JSON"
            if ($AutoFix) {
                $backup = "$($file.FullName).bak"
                Copy-Item -Path $file.FullName -Destination $backup -Force
                try {
                    $content = Get-Content $file.FullName -Raw
                    $fixed = $content -replace '[^\x20-\x7E\r\n]', ''
                    $null = $fixed | ConvertFrom-Json -ErrorAction Stop
                    $fixed | Set-Content -Path $file.FullName -Encoding UTF8
                    $script:healed++; Write-Act "Repaired: $($file.Name) (backup at .bak)"
                } catch {
                    Write-Err "Cannot auto-fix $($file.Name) — backup saved at .bak"
                }
            }
        }
    }

    if ($corrupt -gt 0) {
        Add-Issue "session" "warn" "Engram recovery available: run 'engram_mem_context' to restore from memory"
    }
}

function Heal-Skills {
    Write-Step "Skill Integrity"

    $skillsDir = Join-Path $repoRoot "skills"
    if (-not (Test-Path $skillsDir)) {
        Add-Issue "skills" "error" "skills/ directory missing"
        return
    }

    $skillDirs = @(Get-ChildItem -Directory -Path $skillsDir -ErrorAction SilentlyContinue)
    Write-Info "Found $($skillDirs.Count) skill directories"

    foreach ($dir in $skillDirs) {
        $skillFile = Join-Path $dir.FullName "SKILL.md"
        if (-not (Test-Path $skillFile)) {
            Add-Issue "skills" "warn" "$($dir.Name)/ has no SKILL.md"
            if ($AutoFix) {
                $displayName = $dir.Name -replace '-', ' '
                $displayName = (Get-Culture).TextInfo.ToTitleCase($displayName)
                @"
---
name: $($dir.Name)-skill
description: >
  $displayName domain — auto-generated.
  Trigger: "$($dir.Name)"
license: Apache-2.0
metadata:
  author: foundation
  version: '1.0'
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
---

# $displayName Skill

*Auto-healed — missing SKILL.md was regenerated.*
"@ | Set-Content -Path $skillFile -Encoding UTF8
                $script:healed++; Write-Act "Created: $skillFile"
            }
        } else {
            Write-Ok "$($dir.Name)/SKILL.md — present"
        }
    }

    # Verify auto-delegation mappings resolve to real skills
    $autoDelPath = Join-Path $repoRoot "config" "auto-delegation.json"
    if (Test-Path $autoDelPath) {
        try {
            $config = Get-Content $autoDelPath -Raw | ConvertFrom-Json
            foreach ($entry in $config.agentCodeToSkill.PSObject.Properties) {
                $skillRef = $entry.Value
                if ($skillRef -is [string]) {
                    $resolved = Join-Path $repoRoot "skills" ($skillRef -replace 'skill$', '') "SKILL.md"
                    if (-not (Test-Path $resolved)) {
                        $resolved2 = Join-Path $repoRoot "skills" $skillRef "SKILL.md"
                        if (-not (Test-Path $resolved2)) {
                            Add-Issue "skills" "warn" "Broken reference: agent '$($entry.Name)' → skill '$skillRef' not found"
                        }
                    }
                }
            }
        } catch {
            Add-Issue "skills" "warn" "Cannot parse auto-delegation.json for skill reference check"
        }
    }
}

function Heal-Engram {
    Write-Step "Engram Health"

    $engramPaths = @(
        "$env:USERPROFILE\bin\engram.exe",
        "$env:USERPROFILE\go\bin\engram.exe"
    )
    $found = $null
    foreach ($p in $engramPaths) {
        if (Test-Path $p) { $found = $p; break }
    }

    if (-not $found) {
        Add-Issue "engram" "error" "engram.exe not found in expected paths"
        if ($AutoFix) {
            Write-Warn "Cannot auto-install engram — run 'foundation install-engram' manually"
        }
        return
    }

    Write-Ok "engram.exe found: $found"

    # Check if engram is running
    $proc = Get-Process -Name "engram" -ErrorAction SilentlyContinue
    if (-not $proc) {
        Add-Issue "engram" "error" "engram process not running"
        if ($AutoFix) {
            try {
                Start-Process -FilePath $found -WindowStyle Hidden
                Start-Sleep -Seconds 2
                $proc2 = Get-Process -Name "engram" -ErrorAction SilentlyContinue
                if ($proc2) { $script:healed++; Write-Act "Started engram process" }
                else { Write-Err "Failed to start engram" }
            } catch {
                Write-Err "Cannot start engram: $_"
            }
        }
    } else {
        Write-Ok "engram running (PID: $($proc.Id))"
    }
}

# === Main ===

Write-Step "Self-Healing Stack"

$scopes = if ($Scope -eq 'all') { @('config', 'hooks', 'session', 'skills', 'engram') }
          else { @($Scope) }

foreach ($s in $scopes) {
    $healerFn = "Heal-$((Get-Culture).TextInfo.ToTitleCase($s))"
    $fn = get-command $healerFn -ErrorAction SilentlyContinue
    if ($fn) { & $fn } else { Write-Warn "Unknown healer scope: $s" }
}

Write-Step "Healing Summary"
if ($issues.Count -eq 0) {
    Write-Ok "All checks passed — no issues found"
} else {
    $errCount = @($issues | Where-Object { $_.severity -eq 'error' }).Count
    $warnCount = @($issues | Where-Object { $_.severity -eq 'warn' }).Count
    Write-Info "$errCount error(s), $warnCount warning(s)"
    if ($AutoFix) {
        Write-Ok "Healed $healed issue(s)"
        if ($errors -gt 0) { Write-Err "$errors issue(s) could not be auto-fixed" }
    } else {
        Write-Info "Run with -AutoFix to apply fixes"
    }
}

exit ($issues.Count -gt 0 -and @($issues | Where-Object { $_.severity -eq 'error' }).Count -gt 0)
