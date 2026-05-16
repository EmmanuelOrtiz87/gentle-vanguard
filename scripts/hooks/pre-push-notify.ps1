param(
    [string]$HookName,
    [string]$ScriptPath,
    [string]$Message = "",
    [switch]$IsLong,
    [Parameter(ValueFromRemainingArguments)]
    $PassThru
)

$ts = Get-Date -Format "HH:mm:ss"
$notice = if ($Message) { " — $Message" } else { "" }
$warn = if ($IsLong) { " (puede tomar ~2-3 min)" } else { "" }

Write-Host "[$ts] $HookName iniciado$warn$notice" -ForegroundColor $(if ($IsLong) { "Yellow" } else { "Cyan" })

$t0 = Get-Date
& $ScriptPath @PassThru
$exitCode = $LASTEXITCODE
$duration = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

$tsEnd = Get-Date -Format "HH:mm:ss"
Write-Host "[$tsEnd] $HookName completado (${duration}s)" -ForegroundColor Cyan

exit $exitCode
