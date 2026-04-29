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
    Write-Step "Checking for pending tasks"
    
    $pendingMarkers = @('TODO', 'FIXME', 'HACK', 'XXX', 'TEMP', 'PARTIAL')
    $pendingFiles = @()
    
    foreach ($marker in $pendingMarkers) {
        $results = Get-ChildItem -Path $repoRoot -Include "*.ps1", "*.md", "*.json" -Recurse -ErrorAction SilentlyContinue | 
                   Select-String -Pattern $marker -CaseSensitive:$false | 
                   Where-Object { 
                       $line = $_.Line
                       # Exclude lines that are just documenting the marker itself
                       (-not ($line -match "preservePatterns|pattern.*TODO|FIXME.*pattern")) -and
                       # Exclude documentation about TODOs
                       (-not ($line -match "TODO.*comment|TODO.*found|FIXME.*found")) -and
                       # Only match actual code comments or standalone markers
                       (($line -match "^\s*[#///*]+.*$marker") -or
                        ($line -match "$marker\s*:" -and $line -match "^\s*$marker") -or
                        ($line -match "^\s*$marker\s*$"))
                   } |
                   Select-Object -First 10
        if ($results) {
            $pendingFiles += $results | ForEach-Object { "$($_.FileName):$($_.LineNumber): $($_.Line.Trim())" }
        }
    }
    
    if ($pendingFiles.Count -gt 0) {
        Write-Warn "Pending markers found in code:"
        $pendingFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        
        if ($AutoResolve) {
            Write-Step "Auto-resolution of pending markers"
            Write-Warn "Auto-resolution of pending markers requires manual review"
            Write-Warn "Found $($pendingFiles.Count) pending markers that should be reviewed"
            return $false
        } else {
            return $false
        }
    } else {
        Write-Ok "No pending task markers found"
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
        # Use -SkipUpdate to avoid GitHub API rate limiting
        $env:ENGAM_SKIP_UPDATE = "1"
        & $engramBin health --skip-update 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Engram health check passed"
        } else {
            Write-Warn "Engram health check failed - trying basic check"
            # Try without update check
            $engramOutput = & $engramBin session-list 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Engram basic check passed"
            } else {
                Write-Warn "Engram not responding properly"
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
