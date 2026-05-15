param(
    [Parameter(Mandatory)]
    [string]$HookName,
    [Parameter(Mandatory)]
    [string]$ScriptPath,
    [string]$ScriptArgs = "",
    [string]$Message = "",
    [switch]$IsLong
)

$ts = Get-Date -Format "HH:mm:ss"
$notice = if ($Message) { " — $Message" } else { "" }
$warn = if ($IsLong) { " (puede tomar ~2-3 min)" } else { "" }

Write-Host "[$ts] $HookName iniciado$warn$notice" -ForegroundColor $(if ($IsLong) { "Yellow" } else { "Cyan" })

$t0 = Get-Date
if ($ScriptArgs) {
    & $ScriptPath $ScriptArgs
} else {
    & $ScriptPath
}
$exitCode = $LASTEXITCODE
$duration = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

$tsEnd = Get-Date -Format "HH:mm:ss"
Write-Host "[$tsEnd] $HookName completado (${duration}s)" -ForegroundColor Cyan

exit $exitCode
