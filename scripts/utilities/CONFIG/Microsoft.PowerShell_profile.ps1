# Microsoft.PowerShell_profile.ps1
# PowerShell profile for Foundation - Development Stack development
# This runs automatically when PowerShell starts

# Only run in interactive sessions
if ($Host.Name -eq 'ConsoleHost') {

    # Check if we're in a Foundation - Development Stack project
    $currentDir = Get-Location
    $isGFProject = $false
    $checkPaths = @(
        (Join-Path $currentDir '.gentleman'),
        (Join-Path $currentDir 'SKILL.md'),
        (Join-Path $currentDir 'scripts/utilities/wf.ps1')
    )

    foreach ($path in $checkPaths) {
        if (Test-Path $path) {
            $isGFProject = $true
            break
        }
    }

    if ($isGFProject) {
        Write-Host " Foundation - Development Stack project detected - Activating tools..." -ForegroundColor Cyan

        # Run auto-init in background to avoid blocking shell startup
        $initScript = Join-Path $currentDir 'scripts/utilities/auto-init-dev-environment.ps1'
        if (Test-Path $initScript) {
            Start-Job -ScriptBlock {
                param($scriptPath)
                & $scriptPath -Quiet
            } -ArgumentList $initScript | Out-Null
        }

        Write-Host " Development environment activation started in background" -ForegroundColor Green
        Write-Host "Use '.\scripts\utilities\wf.ps1 health' to check status" -ForegroundColor Blue
        Write-Host ""
    }
}

# Set common aliases for Foundation - Development Stack
Set-Alias -Name gf-status -Value '.\scripts\utilities\wf.ps1 status' -ErrorAction SilentlyContinue
Set-Alias -Name gf-health -Value '.\scripts\utilities\wf.ps1 health' -ErrorAction SilentlyContinue
Set-Alias -Name gf-review -Value '.\scripts\utilities\wf.ps1 review' -ErrorAction SilentlyContinue
Set-Alias -Name gf-audit -Value '.\scripts\utilities\wf.ps1 audit' -ErrorAction SilentlyContinue