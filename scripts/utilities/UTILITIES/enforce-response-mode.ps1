param(
    [ValidateSet('simple', 'executive')]
    [string]$Mode = 'simple',
    [ValidateSet('ultra', 'compact')]
    [string]$Compression = 'ultra'
)

$ErrorActionPreference = 'Stop'

function Set-UserEnv {
    param([string]$Name, [string]$Value)
    try {
        $null = [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
        return $true
    }
    catch {
        # Some environments block writes to HKCU\Environment.
        # Fall back to current process so startup remains stable.
        [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
        return $false
    }
}

$userWrites = @()
$userWrites += Set-UserEnv -Name 'OPENCODE_RESPONSE_MODE' -Value $Mode
$userWrites += Set-UserEnv -Name 'OPENCODE_RESPONSE_COMPRESSION' -Value $Compression
$userWrites += Set-UserEnv -Name 'OPENCODE_CHAT_MODE' -Value "$Mode-$Compression"

if ($userWrites -notcontains $false) {
    Write-Host "[OK] Global response mode enforced: $Mode / $Compression" -ForegroundColor Green
} else {
    Write-Host "[WARN] User env write blocked; applied for current session only: $Mode / $Compression" -ForegroundColor Yellow
}