<#
.SYNOPSIS
    Installs the 'foundation' CLI command globally for easy access.

.DESCRIPTION
    Creates a PowerShell function and alias that maps 'foundation' command to the 
    WORKFLOW-ORCHESTRATION/foundation.ps1 script. This avoids the Windows Defender 
    Firewall conflict with the 'wf' command.

    Installation Options:
    1. CurrentUser scope (recommended for development)
    2. AllUsers scope (requires admin, affects all users on the machine)

.PARAMETER Scope
    Profile scope: 'CurrentUser' or 'AllUsers'. Default: CurrentUser

.EXAMPLE
    # Install for current user
    .\\scripts\\utilities\\install-foundation-cli.ps1
    
    # Install for all users (requires admin)
    .\\scripts\\utilities\\install-foundation-cli.ps1 -Scope AllUsers
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

# Create PowerShell profile content with foundation function
$foundationCode = @'
# Foundation CLI - Workflow orchestration command
# Replaces 'wf' to avoid Windows Defender Firewall conflicts

function foundation {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$Arguments = @()
    )

    $foundationPath = & {
        # Try to find foundation.ps1 from common locations
        $possiblePaths = @(
            ".\scripts\utilities\WORKFLOW-ORCHESTRATION\foundation.ps1",
            "..\scripts\utilities\WORKFLOW-ORCHESTRATION\foundation.ps1",
            "~\foundation\scripts\utilities\WORKFLOW-ORCHESTRATION\foundation.ps1"
        )
        
        foreach ($path in $possiblePaths) {
            $expanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
            if (Test-Path $expanded) {
                return $expanded
            }
        }
        
        # Fallback: search in PATH or current directory
        $found = Get-Command foundation.ps1 -ErrorAction SilentlyContinue
        if ($found) {
            return $found.Path
        }
        
        throw "foundation.ps1 not found. Ensure you're in the Foundation repository or add its path to `$env:PATH"
    }
    
    & $foundationPath @Arguments
}

# Alias for even faster access (optional)
Set-Alias -Name foundation-cli -Value foundation -Force

# Tab completion for foundation command
$foundationCompletionPaths = @(
    ".\scripts\utilities\register-foundation-completion.ps1",
    "..\scripts\utilities\register-foundation-completion.ps1",
    "~\foundation\scripts\utilities\register-foundation-completion.ps1"
)
$foundationCompletionLoaded = $false
foreach ($fcp in $foundationCompletionPaths) {
    $fcpExpanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fcp)
    if (-not $foundationCompletionLoaded -and (Test-Path $fcpExpanded)) {
        . $fcpExpanded
        $foundationCompletionLoaded = $true
    }
}

Write-Host "[INFO] 'foundation' command ready. Type 'foundation help' for available commands." -ForegroundColor Green
'@

# Check if profile exists
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    
    # Check if already installed
    if ($profileContent -match 'function foundation') {
        Write-Host "[OK] 'foundation' command already installed in PowerShell profile" -ForegroundColor Green
        exit 0
    }
    
    # Append to existing profile
    Write-Host "Appending foundation command to existing profile: $profilePath" -ForegroundColor Cyan
    Add-Content -Path $profilePath -Value "`n$foundationCode"
} else {
    # Create new profile
    Write-Host "Creating new PowerShell profile: $profilePath" -ForegroundColor Cyan
    Set-Content -Path $profilePath -Value $foundationCode
}

Write-Host "`n[SUCCESS] Foundation CLI installed!" -ForegroundColor Green
Write-Host "Restart PowerShell or run: . `$PROFILE`n" -ForegroundColor Yellow
Write-Host "Usage examples:" -ForegroundColor Cyan
Write-Host "  foundation health" -ForegroundColor Gray
Write-Host "  foundation dashboard" -ForegroundColor Gray
Write-Host "  foundation dashboard live" -ForegroundColor Gray
Write-Host "  foundation benchmark full" -ForegroundColor Gray
Write-Host "  foundation benchmark full remediate`n" -ForegroundColor Gray
