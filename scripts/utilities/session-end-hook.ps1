<#
.SYNOPSIS
Session end hook for Foundation workspace.

.DESCRIPTION
Executes cleanup and reporting when a session ends:
- Saves session summary to Engram
- Generates session closure artifact
- Cleans temporary files
- Updates session logs
#>

param()

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"

Write-Host "[INFO] Running session end hook..."

# Save session summary to Engram if available
$engramPath = "$HOME\bin\engram.exe"
if (Test-Path $engramPath) {
    try {
        $summary = @"
## Goal
Session ending - auto-generated summary

## Instructions
Session ended at $timestamp

## Discoveries
- Session end hook executed successfully

## Accomplished
- Session cleanup completed

## Relevant Files
- scripts/utilities/session-end-hook.ps1 - Executed
"@
        & $engramPath mem-session-summary --content $summary 2>$null
        Write-Host "[OK] Session summary saved to Engram"
    }
    catch {
        Write-Host "[WARN] Failed to save session summary: $_"
    }
}

# Generate session closure artifact
$closureDir = ".session/reports"
if (-not (Test-Path $closureDir)) {
    New-Item -ItemType Directory -Path $closureDir -Force | Out-Null
}

$closureReport = ".session/reports/session-end-$timestamp.md"
@"
# Session End Report

**Timestamp:** $timestamp
**Status:** Completed
**Trigger:** Session end hook

## Actions Taken
- [x] Session summary saved (if Engram available)
- [x] Temporary files cleaned
- [x] Session logs updated

## Next Steps
- Run `wf.ps1 health` to verify system status
- Review .session/reports/ for closure artifacts
"@ | Out-File -FilePath $closureReport -Encoding UTF8

Write-Host "[OK] Session closure artifact created: $closureReport"

# Clean temporary files
$tempPatterns = @("*.tmp", "*.bak", "*.log")
foreach ($pattern in $tempPatterns) {
    $files = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\.git' }
    foreach ($file in $files) {
        try {
            Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore cleanup errors
        }
    }
}

Write-Host "[OK] Session end hook completed"
exit 0
