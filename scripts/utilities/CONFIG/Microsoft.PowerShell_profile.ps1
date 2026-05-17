# Microsoft.PowerShell_profile.ps1
# PowerShell profile for Gentle-Vanguard - Development Stack development
# This runs automatically when PowerShell starts

# Only run in interactive sessions
if ($Host.Name -eq 'ConsoleHost') {

    # Check if we're in a Gentle-Vanguard - Development Stack project
    $currentDir = Get-Location
    $isGFProject = $false
    $checkPaths = @(
        (Join-Path $currentDir '.gentleman'),
        (Join-Path $currentDir 'SKILL.md'),
        (Join-Path $currentDir 'scripts/utilities/gv.ps1')
    )

    foreach ($path in $checkPaths) {
        if (Test-Path $path) {
            $isGFProject = $true
            break
        }
    }

    if ($isGFProject) {
        Write-Host " Gentle-Vanguard - Development Stack project detected - Activating tools..." -ForegroundColor Cyan

        # Run auto-init in background to avoid blocking shell startup
        $initScript = Join-Path $currentDir 'scripts/utilities/UTILITIES/auto-init-dev-environment.ps1'
        if (Test-Path $initScript) {
            Start-Job -ScriptBlock {
                param($scriptPath)
                & $scriptPath -Quiet
            } -ArgumentList $initScript | Out-Null
        }

        Write-Host " Development environment activation started in background" -ForegroundColor Green
        Write-Host "Use '.\scripts\utilities\gv.ps1 health' to check status" -ForegroundColor Blue
        Write-Host ""
    }
}

# Set common aliases for Gentle-Vanguard - Development Stack
Set-Alias -Name gv-status -Value '.\scripts\utilities\gv.ps1 status' -ErrorAction SilentlyContinue
Set-Alias -Name gv-health -Value '.\scripts\utilities\gv.ps1 health' -ErrorAction SilentlyContinue
Set-Alias -Name gv-review -Value '.\scripts\utilities\gv.ps1 review' -ErrorAction SilentlyContinue
Set-Alias -Name gv-audit -Value '.\scripts\utilities\gv.ps1 audit' -ErrorAction SilentlyContinue

