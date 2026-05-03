<#
.SYNOPSIS
    Validates system health status
.DESCRIPTION
    Checks system components and reports health status
#>
param()

$health = @{
    Timestamp = Get-Date -Format "o"
    Status = "Healthy"
    Components = @()
}

# Check Engram
try {
    $engramVersion = & engram --version 2>$null
    $health.Components += @{ Name = "Engram"; Status = "OK"; Version = $engramVersion }
} catch {
    $health.Status = "Degraded"
    $health.Components += @{ Name = "Engram"; Status = "FAIL"; Error = $_.Exception.Message }
}

# Check Git
if (Test-Path ".git") {
    $health.Components += @{ Name = "Git"; Status = "OK" }
} else {
    $health.Status = "Degraded"
    $health.Components += @{ Name = "Git"; Status = "FAIL" }
}

$health | ConvertTo-Json -Depth 3
