<#
.SYNOPSIS
    Pre-Compact Hook - Saves state before context compaction
    
.DESCRIPTION
    Executes automatically before context compaction (~25k tokens).
    Saves session summary to Engram and preserves anchored content.
    
.PARAMETER ProjectName
    Project name for Engram (default: gentleman-foundation)
    
.PARAMETER CompressionRatio
    How much to compress (default: 0.90)
    
.EXAMPLE
    .\tools\pre-compact-hook.ps1 -ProjectName "gentleman-foundation" -CompressionRatio 0.90
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentleman-foundation",
    
    [Parameter(Mandatory=$false)]
    [double]$CompressionRatio = 0.90
)

$ErrorActionPreference = 'Continue'
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Status {
    param([string]$Message)
    Write-Host "[PRE-COMPACT] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

# Save critical content to Engram before compaction
function Save-CriticalContent {
    Write-Status "Saving critical content to Engram before compaction..."
    
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
    
    if (-not (Test-Path $engramBin)) {
        Write-Host "[WARN] Engram not found, skipping save" -ForegroundColor Yellow
        return $false
    }
    
    # Collect anchored content (FIXME, TODO, BUG, DECISION, RESULT)
    $anchoredContent = ""
    $patterns = @("FIXME", "TODO", "BUG", "DECISION", "RESULT")
    
    $sessionFiles = Get-ChildItem -Path . -Recurse -File -Filter "*.ps1" -ErrorAction SilentlyContinue | 
                    Select-String -Pattern ($patterns -join "|") -ErrorAction SilentlyContinue
    
    if ($sessionFiles) {
        $anchoredContent = "## Anchored Content Before Compaction`n`n"
        $anchoredContent += "Timestamp: $timestamp`n`n"
        
        foreach ($match in $sessionFiles) {
            $anchoredContent += "### $($match.Filename)`n"
            $anchoredContent += "$($match.Line)`n`n"
        }
    }
    
    # Save to Engram
    $content = @"
## Pre-Compaction Save
Timestamp: $timestamp
Compression Ratio: $CompressionRatio

$anchoredContent

Context preserved before automatic compaction.
"@
    
    & $engramBin save --title "Pre-Compaction Save" --content $content --project $ProjectName --type manual 2>$null | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Critical content saved to Engram"
        return $true
    } else {
        Write-Host "[WARN] Failed to save to Engram" -ForegroundColor Yellow
        return $false
    }
}

# Run handoff compress to prepare state
function Invoke-HandoffCompress {
    Write-Status "Running handoff compression..."
    
    $handoffScript = Join-Path $PSScriptRoot "handoff-compress.ps1"
    
    if (Test-Path $handoffScript) {
        & $handoffScript -ProjectName $ProjectName -CompressionRatio $CompressionRatio 2>$null
        Write-Success "Handoff compression completed"
        return $true
    } else {
        Write-Host "[WARN] handoff-compress.ps1 not found" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
try {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              PRE-COMPACT HOOK - SAVING STATE                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $saved = Save-CriticalContent
    $compressed = Invoke-HandoffCompress
    
    Write-Host ""
    if ($saved -and $compressed) {
        Write-Success "Pre-compaction tasks completed"
    } else {
        Write-Host "[WARN] Some pre-compaction tasks failed" -ForegroundColor Yellow
    }
    
    exit 0
}
catch {
    Write-Host "[ERROR] Pre-compact hook failed: $_" -ForegroundColor Red
    exit 1
}
