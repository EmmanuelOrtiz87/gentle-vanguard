function Write-Step { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Invoke-LocalPowerShellScript {
    param([string]$ScriptPath, [string[]]$ScriptArgs = @())
    if ($ScriptArgs.Count -gt 0) { & $ScriptPath @ScriptArgs }
    else { & $ScriptPath }
}
