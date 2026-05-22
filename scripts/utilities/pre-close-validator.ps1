# pre-close-validator.ps1
# Robust session closure validation with auto-resolve

param(
    [switch]$AutoResolve,
    [switch]$Force,
    [string]$ProjectName = "gentle-vanguard",
    [switch]$NoExit
)

$ErrorActionPreference = 'Continue'
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}
Set-Location $repoRoot

$engramSafeScript = Join-Path $repoRoot 'scripts\utilities\engram-safe.ps1'
if (Test-Path $engramSafeScript) {
    . $engramSafeScript
}

function Write-Step { param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Ok { param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn { param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Info { param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-MessageError { param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Complete-Script {
    param([int]$ExitCode = 0)

    if ($NoExit) {
        return $ExitCode
    }

    exit $ExitCode
}

function Resolve-EngramBinary {
    $candidates = @(
        (Join-Path $PSScriptRoot "engram.exe"),
        (Join-Path (Split-Path -Parent $PSScriptRoot) "tools\engram.exe")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    $command = Get-Command "engram" -ErrorAction SilentlyContinue
    if ($command -and $command.Source) {
        return $command.Source
    }

    return $null
}

Write-Host "STARTING: Pre-close validation for $ProjectName" -ForegroundColor Cyan
Write-Host "Auto-resolve: $AutoResolve, Force: $Force" -ForegroundColor Gray

$allPassed = $true
$failedChecks = @()
$gitError = $false

# 1. Git State Validation
Write-Step "Validating Git state"

try {
    $statusOutput = git status --porcelain 2>$null
    $hasUncommitted = -not [string]::IsNullOrWhiteSpace($statusOutput)
    
    if ($hasUncommitted) {
        Write-Warn "Uncommitted changes detected"
        git status --short
        
        if ($AutoResolve -and $Force) {
            Write-Host "WARNING: Auto-committing ALL changes..." -ForegroundColor Yellow
            git add . 2>$null
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $commitMsg = "fix: auto-commit before session close - $timestamp"
            $commitOutput = git commit -m $commitMsg 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Auto-committed pending changes"
            } else {
                Write-MessageError "Failed to auto-commit: $commitOutput"
                $allPassed = $false
                $failedChecks += "GitCommit"
                $gitError = $true
            }
        } else {
            Write-Warn "Uncommitted changes block session close. Options:"
            Write-Warn "  - Commit manually: git add <files> && git commit -m \"...\""
            Write-Warn "  - Force close: re-run with -Force (bypasses validation)"
            Write-Warn "  - Auto-commit + Force: re-run with -AutoResolve -Force (commits ALL changes)"
            $allPassed = $false
            $failedChecks += "GitUncommitted"
        }
    } else {
        Write-Ok "Working directory clean"
    }
    
    if (-not $gitError) {
        $upstream = git rev-parse --abbrev-ref '@{upstream}' 2>$null
        if (-not [string]::IsNullOrWhiteSpace($upstream)) {
            $aheadOutput = git rev-list --count '@{upstream}..HEAD' 2>$null
            $ahead = 0
            if (-not [string]::IsNullOrWhiteSpace($aheadOutput)) {
                $ahead = [int]$aheadOutput
            }
            
            if ($ahead -gt 0) {
                Write-Warn "Unpushed commits: $ahead"
                
                if ($AutoResolve -and $Force) {
                    Write-Host "WARNING: Auto-pushing to $upstream..." -ForegroundColor Yellow
                    $pushBranch = git rev-parse --abbrev-ref HEAD 2>$null
                    $null = $LASTEXITCODE
                    $pushOutput = git push origin $pushBranch 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Ok "Auto-pushed commits to $upstream"
                    } else {
                        Write-MessageError "Failed to auto-push: $pushOutput"
                        $allPassed = $false
                        $failedChecks += "GitPush"
                    }
                } else {
                    Write-Warn "Unpushed commits: $ahead. Options:"
                    Write-Warn "  - Push manually: git push"
                    Write-Warn "  - Force close: re-run with -Force"
                    $allPassed = $false
                    $failedChecks += "GitUnpushed"
                }
            } else {
                Write-Ok "All commits synced with upstream"
            }
        } else {
            Write-Warn "No upstream configured"
            if (-not $Force) { 
                $allPassed = $false
                $failedChecks += "GitNoUpstream"
            }
        }
    }
} catch {
    Write-MessageError "Git validation error: $_"
    $allPassed = $false
    $failedChecks += "GitError"
}

# 2. Quick Pending Tasks Check
Write-Step "Checking for critical pending tasks"
try {
    $criticalPatterns = @('HACK:', 'XXX:')
    $foundTasks = @()
    
    $codeFiles = Get-ChildItem -Path $repoRoot -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object {
                     $_.Extension -in @('.ps1', '.ts', '.js') -and
                     $_.FullName -notmatch 'node_modules|\.git|docs|templates'
                 } |
                 Select-Object -First 50
    
    foreach ($file in $codeFiles) {
        $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            foreach ($pattern in $criticalPatterns) {
                if ($line -and $line.Contains($pattern)) {
                    $relativePath = $file.FullName.Replace($repoRoot, '').TrimStart('\')
                    $lineNum = $i + 1
                    $foundTasks += "{0}:{1}: {2}" -f $relativePath, $lineNum, $line.Trim()
                    break
                }
            }
        }
    }
    
    if ($foundTasks.Count -gt 0) {
        if (-not $Force) {
            Write-Warn "Critical pending tasks found: $($foundTasks.Count)"
            $foundTasks | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            $allPassed = $false
            $failedChecks += "PendingTasks"
        } else {
            Write-Info "Pending task markers observed: $($foundTasks.Count) (non-blocking with Force)"
        }
    } else {
        Write-Ok "No critical pending tasks"
    }
} catch {
    Write-Warn "Error checking pending tasks: $_"
}

# 3. Session Locks Check
Write-Step "Checking for session locks"
try {
    $lockFiles = Get-ChildItem -Path $repoRoot -Filter "*.lock" -Recurse -ErrorAction SilentlyContinue | 
                  Where-Object { $_.FullName -match '\.session|session.*lock|engram.*lock' }
    
    if ($lockFiles.Count -gt 0) {
        Write-Warn "Session lock files found: $($lockFiles.Count)"
        if ($AutoResolve) {
            $lockFiles | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Ok "Removed session locks"
        } else {
            $allPassed = $false
            $failedChecks += "SessionLocks"
        }
    } else {
        Write-Ok "No session locks"
    }
} catch {
    Write-Warn "Error checking locks: $_"
}

# 4. Engram Check (non-blocking)
Write-Step "Checking Engram (non-critical)"
try {
    if (Get-Command Invoke-Gentle-VanguardEngram -ErrorAction SilentlyContinue) {
        $result = Invoke-Gentle-VanguardEngram -RepoRoot $repoRoot -Arguments @('doctor', '--project', $ProjectName)
        if ($result.Success) {
            Write-Ok "Engram is responsive"
        } else {
            Write-Info "Engram check did not pass; non-critical for session closure"
            $sessionList = $result.Output | Out-String
            if (-not [string]::IsNullOrWhiteSpace($sessionList)) {
                Write-Info "Engram output: $($sessionList.Substring(0, [Math]::Min(100, $sessionList.Length)))"
            }
        }
    } else {
        Write-Info "Engram binary not found; skipping non-critical check"
    }
} catch {
    Write-Info "Engram check error (non-critical): $_"
}

# Final Result
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
if ($allPassed) {
    Write-Ok "ALL VALIDATIONS PASSED - Session ready for closure"
    Write-Host "`nNext steps:"
    Write-Host "  1. Call mem_session_summary with proper structure"
    Write-Host "  2. Call mem_session_end to close the session"
    $endScript = if ([Environment]::OSVersion.Platform -eq 'Win32NT') { 'scripts/utilities/session-manual-end.cmd' } else { 'bash scripts/utilities/session-manual-end.sh' }
    Write-Host "  3. Run $endScript if needed"
    Complete-Script -ExitCode 0
    return
} else {
    Write-MessageError "VALIDATION FAILED - Checks failed: $($failedChecks -join ', ')"
    Write-Host "`nRequired actions:"
    Write-Host "  - Fix critical issues or use -Force to override"
    Write-Host "  - Run with -AutoResolve to auto-fix git issues"
    Complete-Script -ExitCode 1
    return
}

