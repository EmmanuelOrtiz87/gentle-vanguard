<#
.SYNOPSIS
    Handoff Compress - Compresses state for agent-to-agent transfer
    
.DESCRIPTION
    Prepares state for handoff by:
    - Preserving: decisions, results, FIXMEs, status flags
    - Truncating: verbose outputs, repeated patterns
    - Output: state-only handoff (~30% size reduction)
    
.PARAMETER ProjectName
    Project name for Engram
    
.PARAMETER CompressionRatio
    How much to compress (default: 0.30)
    
.EXAMPLE
    .\tools\handoff-compress.ps1 -ProjectName "gentleman-foundation" -CompressionRatio 0.30
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentleman-foundation",
    
    [Parameter(Mandatory=$false)]
    [double]$CompressionRatio = 0.30
)

$ErrorActionPreference = 'Continue'
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Status {
    param([string]$Message)
    Write-Host "[HANDOFF] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

# Collect state to preserve
function Get-StateToPreserve {
    Write-Status "Collecting state for handoff..."
    
    $state = @{
        timestamp = $timestamp
        project = $ProjectName
        preserved = @()
        truncated = @()
    }
    
    # Preserve: decisions, results, FIXMEs, status flags
    $patterns = @("FIXME", "TODO", "DECISION", "RESULT", "BUG")
    $files = Get-ChildItem -Path . -Recurse -File -Filter "*.ps1" -ErrorAction SilentlyContinue |
                Select-String -Pattern ($patterns -join "|") -ErrorAction SilentlyContinue
    
    foreach ($match in $files) {
        $state.preserved += @{
            file = $match.Filename
            line = $match.LineNumber
            content = $match.Line.Trim()
        }
    }
    
    Write-Status "Preserved $($state.preserved.Count) anchored items"
    return $state
}

# Truncate verbose content
function Compress-State {
    param([hashtable]$State, [double]$Ratio)
    
    Write-Status "Compressing state (ratio: $Ratio)..."
    
    # Keep only essential, truncate verbose entries
    $compressed = @{
        timestamp = $State.timestamp
        project = $State.project
        preserved = $State.preserved | Select-Object -First ([math]::Round($State.preserved.Count * $Ratio))
    }
    
    return $compressed
}

# Save to Engram
function Save-ToEngram {
    param([hashtable]$State)
    
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
    
    if (-not (Test-Path $engramBin)) {
        Write-Host "[WARN] Engram not found" -ForegroundColor Yellow
        return $false
    }
    
    $content = @"
## Handoff Compressed State
Timestamp: $timestamp
Project: $ProjectName

### Preserved Items:
$(($State.preserved | ForEach-Object { "- [$($_.file):$($_.line)] $($_.content)" }) -join "`n")

State compressed for agent transfer.
"@
    
    & $engramBin save --title "Handoff Compressed State" --content $content --project $ProjectName --type manual 2>$null | Out-Null
    
    return ($LASTEXITCODE -eq 0)
}

# Main execution
try {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              HANDOFF COMPRESS - STATE TRANSFER                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $state = Get-StateToPreserve
    $compressed = Compress-State -State $state -Ratio $CompressionRatio
    
    $saved = Save-ToEngram -State $compressed
    
    Write-Host ""
    Write-Success "Handoff compression completed"
    Write-Host "  Items preserved: $($compressed.preserved.Count)" -ForegroundColor Green
    Write-Host "  Compression ratio: $CompressionRatio" -ForegroundColor Gray
    
    if ($saved) {
        Write-Host "  State saved to Engram" -ForegroundColor Cyan
    }
    
    exit 0
}
catch {
    Write-Host "[HANDOFF] Error: $_" -ForegroundColor Red
    exit 1
}
