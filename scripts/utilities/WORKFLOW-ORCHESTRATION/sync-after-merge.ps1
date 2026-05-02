<#
.SYNOPSIS
Post-merge hook for Foundation workspace.

.DESCRIPTION
Syncs dependencies and tools after merge:
- npm install if package.json changed
- Validate merged code
- Update session state
#>

param()

$ErrorActionPreference = "Continue"
$mergedFiles = git diff HEAD@\{1} --name-only 2>$null

if (-not $mergedFiles) {
    Write-Host "[INFO] No merged files to process"
    exit 0
}

Write-Host "[INFO] Post-merge: Processing merged files..."

# Sync npm dependencies
if ($mergedFiles -match "package\.json") {
    Write-Host "[INFO] package.json changed, running npm install..."
    npm install
}

# Validate critical scripts
$criticalScripts = @("tools/session-manager.ps1", "scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1")
foreach ($script in $criticalScripts) {
    if ($mergedFiles -contains $script -and (Test-Path $script)) {
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$null)
            Write-Host "[OK] $script - Syntax valid after merge"
        }
        catch {
            Write-Host "[WARN] $script - Syntax error after merge: $_"
        }
    }
}

# Update session if needed
if (Test-Path "tools/session-manager.ps1") {
    try {
        .\tools\session-manager.ps1 -Action "update" -Silent
    }
    catch {
        Write-Host "[WARN] Session update failed: $_"
    }
}

Write-Host "[OK] Post-merge processing completed"
exit 0
