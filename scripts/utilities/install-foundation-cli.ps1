<#
.SYNOPSIS
    Installs the 'gentle-vanguard' CLI command globally for easy access.

.DESCRIPTION
    Creates a PowerShell function and alias that maps 'gentle-vanguard' command to the 
    WORKFLOW-ORCHESTRATION/gentle-vanguard.ps1 script. This avoids the Windows Defender 
    Firewall conflict with the 'gv' command.

    Installation Options:
    1. CurrentUser scope (recommended for development)
    2. AllUsers scope (requires admin, affects all users on the machine)

.PARAMETER Scope
    Profile scope: 'CurrentUser' or 'AllUsers'. Default: CurrentUser

.EXAMPLE
    # Install for current user
    .\\scripts\\utilities\\install-gentle-vanguard-cli.ps1
    
    # Install for all users (requires admin)
    .\\scripts\\utilities\\install-gentle-vanguard-cli.ps1 -Scope AllUsers
#>

param(
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
)

$ErrorActionPreference = 'Stop'

# Determine PowerShell profile path
if ($Scope -eq 'CurrentUser') {
    $profilePath = $PROFILE.CurrentUserCurrentHost
} else {
    $profilePath = $PROFILE.AllUsersCurrentHost
}

# Ensure profile directory exists
$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) {
    Write-Host "Creating profile directory: $profileDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Create PowerShell profile content with gentle-vanguard function
$gentle-vanguardCode = @'
# Gentle-Vanguard CLI - Workflow orchestration command
# Replaces 'gv' to avoid Windows Defender Firewall conflicts

function gentle-vanguard {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$Arguments = @()
    )

    $gentle-vanguardPath = & {
        # Try to find gentle-vanguard.ps1 from common locations
        $possiblePaths = @(
            ".\scripts\utilities\WORKFLOW-ORCHESTRATION\gentle-vanguard.ps1",
            "..\scripts\utilities\WORKFLOW-ORCHESTRATION\gentle-vanguard.ps1",
            "~\gentle-vanguard\scripts\utilities\WORKFLOW-ORCHESTRATION\gentle-vanguard.ps1"
        )
        
        foreach ($path in $possiblePaths) {
            $expanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
            if (Test-Path $expanded) {
                return $expanded
            }
        }
        
        # Fallback: search in PATH or current directory
        $found = Get-Command gentle-vanguard.ps1 -ErrorAction SilentlyContinue
        if ($found) {
            return $found.Path
        }
        
        throw "gentle-vanguard.ps1 not found. Ensure you're in the Gentle-Vanguard repository or add its path to `$env:PATH"
    }
    
    & $gentle-vanguardPath @Arguments
}

# Alias for even faster access (optional)
Set-Alias -Name gentle-vanguard-cli -Value gentle-vanguard -Force

# Tab completion for gentle-vanguard command
$gentle-vanguardCompletionPaths = @(
    ".\scripts\utilities\register-gentle-vanguard-completion.ps1",
    "..\scripts\utilities\register-gentle-vanguard-completion.ps1",
    "~\gentle-vanguard\scripts\utilities\register-gentle-vanguard-completion.ps1"
)
$gentle-vanguardCompletionLoaded = $false
foreach ($fcp in $gentle-vanguardCompletionPaths) {
    $fcpExpanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fcp)
    if (-not $gentle-vanguardCompletionLoaded -and (Test-Path $fcpExpanded)) {
        . $fcpExpanded
        $gentle-vanguardCompletionLoaded = $true
    }
}

Write-Host "[INFO] 'gentle-vanguard' command ready. Type 'gv help' for available commands." -ForegroundColor Green
'@

# Check if profile exists
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    
    # Check if already installed
    if ($profileContent -match 'function gentle-vanguard') {
        Write-Host "[OK] 'gentle-vanguard' command already installed in PowerShell profile" -ForegroundColor Green
        exit 0
    }
    
    # Append to existing profile
    Write-Host "Appending gentle-vanguard command to existing profile: $profilePath" -ForegroundColor Cyan
    Add-Content -Path $profilePath -Value "`n$gentle-vanguardCode"
} else {
    # Create new profile
    Write-Host "Creating new PowerShell profile: $profilePath" -ForegroundColor Cyan
    Set-Content -Path $profilePath -Value $gentle-vanguardCode
}

Write-Host "`n[SUCCESS] Gentle-Vanguard CLI installed!" -ForegroundColor Green
Write-Host "Restart PowerShell or run: . `$PROFILE`n" -ForegroundColor Yellow
Write-Host "Usage examples:" -ForegroundColor Cyan
Write-Host "  gv health" -ForegroundColor Gray
Write-Host "  gv dashboard" -ForegroundColor Gray
Write-Host "  gv dashboard live" -ForegroundColor Gray
Write-Host "  gv benchmark full" -ForegroundColor Gray
Write-Host "  gv benchmark full remediate`n" -ForegroundColor Gray

