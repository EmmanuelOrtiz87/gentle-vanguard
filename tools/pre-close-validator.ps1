# pre-close-validator.ps1
# Comprehensive session closure validation with automatic resolution
# Ensures no pending work, partial implementations, or misunderstandings for next session

param(
    [switch]$AutoResolve,
    [switch]$Force,
    [string]$ProjectName = "workspace-foundation"
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

function Write-Step { param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Ok { param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn { param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error { param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-GitState {
    Write-Step "Validating Git state"
    
    $status = git status --porcelain 2>$null
    $hasUncommitted = -not [string]::IsNullOrWhiteSpace($status)
    
    if ($hasUncommitted) {
        Write-Warn "Uncommitted changes detected:"
        git status --short
        
        if ($AutoResolve) {
            Write-Step "Auto-resolving uncommitted changes"
            git add .
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $branch = git rev-parse --abbrev-ref HEAD 2>$null
            if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }
            
            git commit -m "fix: auto-commit pending changes before session close - $timestamp"
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Auto-committed pending changes"
            } else {
                Write-Error "Failed to auto-commit changes"
                return $false
            }
        } else {
            return $false
        }
    } else {
        Write-Ok "Working directory clean"
    }
    
    $upstream = git rev-parse --abbrev-ref '@{upstream}' 2>$null
    if (-not [string]::IsNullOrWhiteSpace($upstream)) {
        $ahead = git rev-list --count '@{upstream}..HEAD' 2>$null
        if ([int]$ahead -gt 0) {
            Write-Warn "Unpushed commits detected: $ahead commit(s) ahead of $upstream"
            
            if ($AutoResolve) {
                Write-Step "Auto-resolving unpushed commits"
                git push origin HEAD:$branch --set-upstream
                if ($LASTEXITCODE -eq 0) {
                    Write-Ok "Auto-pushed commits to $upstream"
                } else {
                    Write-Error "Failed to auto-push commits"
                    return $false
                }
            } else {
                return $false
            }
        } else {
            Write-Ok "All commits synced with upstream"
        }
    } else {
        Write-Warn "No upstream configured"
        if (-not $Force) { return $false }
    }
    
    return $true
}

function Test-PendingTasks {
    Write-Step "Checking for pending tasks in code files"
    
    # Only check actual code files, not documentation
    $codeFiles = Get-ChildItem -Path $repoRoot -Include "*.ps1", "*.ts", "*.js", "*.go", "*.py" -Recurse -ErrorAction SilentlyContinue | 
                 Where-Object { $_.FullName -notmatch 'node_modules|\.git|docs|templates' }
    
    $pendingPatterns = @(
        '^\s*#.*\bTODO\b(?!.*comment)',  # PowerShell/Python TODO in comments
        '^\s*//.*\bTODO\b',                # JS/TS TODO in comments
        '^\s*/\*.*\bTODO\b',               # C-style TODO
        '^\s*#.*\bFIXME\b',
        '^\s*//.*\bFIXME\b',
        '^\s*#.*\bHACK\b',
        '^\s*//.*\bHACK\b',
        '^\s*#.*\bXXX\b',
        '^\s*//.*\bXXX\b'
    )
    
    $pendingItems = @()
    foreach ($file in $codeFiles) {
        $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]
            foreach ($pattern in $pendingPatterns) {
                if ($line -match $pattern) {
                    $relativePath = $file.FullName.Replace($repoRoot, '').TrimStart('\')
                    $lineNum = $i + 1
                    $pendingItems += "{0}:{1}: {2}" -f $relativePath, $lineNum, $line.Trim()
                    break
                }
            }
        }
    }
    
    if ($pendingItems.Count -gt 0) {
        Write-Warn "Pending task markers found in code:"
        $pendingItems | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        if ($pendingItems.Count -gt 15) {
            Write-Host "  ... and $($pendingItems.Count - 15) more" -ForegroundColor Yellow
        }
        
        if ($AutoResolve) {
            Write-Warn "Auto-resolution: Converting TODO/FIXME to work items requires manual review"
            return $false
        } else {
            return $false
        }
    } else {
        Write-Ok "No pending task markers in code files"
    }
    
    return $true
}

function Test-PartialImplementations {
    Write-Step "Checking for partial implementations"
    
    $partialPatterns = @(
        'partial.*implementation',
        'work.*in.*progress',
        'WIP',
        'not.*complete',
        'incomplete',
        'placeholder'
    )
    
    $found = $false
    $foundItems = @()
    
    foreach ($pattern in $partialPatterns) {
        $results = Get-ChildItem -Path $repoRoot -Include "*.ps1", "*.md" -Recurse -ErrorAction SilentlyContinue | 
                   Select-String -Pattern $pattern -CaseSensitive:$false | 
                   Select-Object -First 5
        if ($results) {
            if (-not $found) {
                Write-Warn "Potential partial implementations found:"
                $found = $true
            }
            $results | ForEach-Object { 
                $line = "$($_.FileName):$($_.LineNumber): $($_.Line.Trim())"
                Write-Host "  $line" -ForegroundColor Yellow
                $foundItems += $line
            }
        }
    }
    
    if ($found) {
        Write-Warn "Partial implementations detected - manual review required"
        if (-not $Force) { return $false }
    } else {
        Write-Ok "No partial implementations detected"
    }
    
    return $true
}

function Test-RunningProcesses {
    Write-Step "Checking for running processes or locks"
    
    $sessionLock = Join-Path $repoRoot '.session\*.lock'
    if (Test-Path $sessionLock) {
        Write-Warn "Session lock files detected"
        if ($AutoResolve) {
            Remove-Item $sessionLock -Force -ErrorAction SilentlyContinue
            Write-Ok "Removed session lock files"
        } else {
            return $false
        }
    } else {
        Write-Ok "No session locks detected"
    }
    
    return $true
}

function Test-EngramState {
    Write-Step "Validating Engram memory state"
    
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
    if (Test-Path $engramBin) {
        # Try health check with error suppression
        $output = & $engramBin health 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Engram health check passed"
        } else {
            # Check if it's just a GitHub API issue (not critical)
            if ($output -match "Could not check for updates|403 Forbidden") {
                Write-Warn "Engram: Update check failed (rate limited) - core functionality assumed working"
                # Try a basic operation to verify Engram works
                $testOutput = & $engramBin session-list 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Ok "Engram core functionality verified"
                } else {
                    Write-Warn "Engram not responding properly"
                    if (-not $Force) { return $false }
                }
            } else {
                Write-Warn "Engram health check failed"
                if (-not $Force) { return $false }
            }
        }
    } else {
        Write-Warn "Engram binary not found - skipping Engram validation"
    }
    
    return $true
}

# Main validation flow
Write-Host "STARTING: Pre-close validation for $ProjectName" -ForegroundColor Cyan
Write-Host "Auto-resolve: $AutoResolve, Force: $Force" -ForegroundColor Gray

$allPassed = $true
$failedChecks = @()

if (-not (Test-GitState)) { $allPassed = $false; $failedChecks += "GitState" }
if (-not (Test-PendingTasks)) { $allPassed = $false; $failedChecks += "PendingTasks" }
if (-not (Test-PartialImplementations)) { $allPassed = $false; $failedChecks += "PartialImpl" }
if (-not (Test-RunningProcesses)) { $allPassed = $false; $failedChecks += "RunningProcesses" }
if (-not (Test-EngramState)) { $allPassed = $false; $failedChecks += "EngramState" }

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
if ($allPassed) {
    Write-Ok "ALL VALIDATIONS PASSED - Session ready for closure"
    Write-Host "`nNext steps for AI agent:"
    Write-Host "  1. Call mem_session_summary with proper structure"
    Write-Host "  2. Call mem_session_end to close the session"
    Write-Host "  3. Proceed with tools/session-manual-end.cmd if needed"
    exit 0
} else {
    Write-Error "VALIDATION FAILED - Checks failed: $($failedChecks -join ', ')"
    Write-Host "`nRecommended actions:"
    Write-Host "  - Run with -AutoResolve to auto-fix git issues"
    Write-Host "  - Review and manually fix pending markers"
    Write-Host "  - Use -Force to close anyway (not recommended)"
    Write-Host "`nSession will NOT be closed to avoid pending work in next session."
    exit 1
}
