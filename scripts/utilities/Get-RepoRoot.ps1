# Get-RepoRoot.ps1
# Reusable function for robust repository root resolution
# Handles $PSScriptRoot null/empty scenarios

function Get-RepoRoot {
    <#
    .SYNOPSIS
        Returns the repository root directory with robust fallback handling.
    
    .DESCRIPTION
        Resolves the repository root by checking multiple sources in order:
        1. Environment variable GENTLE_VANGUARD_BASE_DIR
        2. $PSScriptRoot (if available)
        3. $MyInvocation.MyCommand.Path (fallback)
        4. Current directory (last resort)
        
        Validates the root by looking for config/orchestrator.json marker file.
    
    .PARAMETER ValidateMarker
        If set, validates that config/orchestrator.json exists in the resolved root.
    
    .PARAMETER AdditionalMarkers
        Additional files to check for validation (e.g., @('.git', 'README.md'))
    
    .EXAMPLE
        $repoRoot = Get-RepoRoot -ValidateMarker
        $configPath = Join-Path $repoRoot 'config' 'orchestrator.json'
    
    .EXAMPLE
        $repoRoot = Get-RepoRoot -AdditionalMarkers @('.git', 'CLAUDE.md')
    #>
    
    param(
        [switch]$ValidateMarker,
        [string[]]$AdditionalMarkers = @()
    )
    
    $ErrorActionPreference = 'Continue'
    
    # Priority 1: Environment variable
    if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) {
        $candidate = $env:GENTLE_VANGUARD_BASE_DIR
        if (-not $ValidateMarker -or (Test-Path (Join-Path $candidate 'config\orchestrator.json'))) {
            return $candidate
        }
    }
    
    # Priority 2: $PSScriptRoot
    $scriptRoot = if ($PSScriptRoot) { 
        $PSScriptRoot 
    } elseif ($MyInvocation.MyCommand.Path) { 
        Split-Path -Parent $MyInvocation.MyCommand.Path 
    } else { 
        Get-Location 
    }
    
    # Walk up to find repo root (looking for config directory)
    $candidate = $scriptRoot
    $maxDepth = 10
    $depth = 0
    
    while ($candidate -and $depth -lt $maxDepth) {
        if (Test-Path (Join-Path $candidate 'config\orchestrator.json')) {
            return $candidate
        }
        
        # Check additional markers if specified
        $allMarkersFound = $true
        foreach ($marker in $AdditionalMarkers) {
            if (-not (Test-Path (Join-Path $candidate $marker))) {
                $allMarkersFound = $false
                break
            }
        }
        if ($allMarkersFound -and $AdditionalMarkers.Count -gt 0) {
            return $candidate
        }
        
        $parent = Split-Path -Parent $candidate
        if ($parent -eq $candidate) { break }  # Reached filesystem root
        $candidate = $parent
        $depth++
    }
    
    # Last resort: return script root
    return $scriptRoot
}

function Get-ScriptRoot {
    <#
    .SYNOPSIS
        Returns the script's directory with fallback handling.
    
    .DESCRIPTION
        Returns $PSScriptRoot if available, otherwise derives from 
        $MyInvocation.MyCommand.Path or returns current directory.
    #>
    
    if ($PSScriptRoot) { 
        return $PSScriptRoot 
    } 
    if ($MyInvocation.MyCommand.Path) { 
        return Split-Path -Parent $MyInvocation.MyCommand.Path 
    }
    return Get-Location
}

# Export module members if loaded as module
if ($MyInvocation.MyCommand.Path -and (Test-Path $MyInvocation.MyCommand.Path)) {
    Export-ModuleMember -Function Get-RepoRoot, Get-ScriptRoot -ErrorAction SilentlyContinue
}

# Standalone execution: test the functions
if ($MyInvocation.InvocationName -eq '&' -or $MyInvocation.InvocationName -eq '.') {
    Write-Host "Get-RepoRoot.ps1 loaded successfully" -ForegroundColor Green
    Write-Host "Functions available: Get-RepoRoot, Get-ScriptRoot" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Example usage:" -ForegroundColor Cyan
    Write-Host '  $repoRoot = Get-RepoRoot -ValidateMarker' -ForegroundColor Gray
    Write-Host '  $configPath = Join-Path $repoRoot "config" "orchestrator.json"' -ForegroundColor Gray
}
