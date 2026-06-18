param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

$ErrorActionPreference = 'Continue'
$traceDir = Join-Path $PSScriptRoot '..\..\.session\traces'
$traceFile = Join-Path $traceDir "preprocess-errors.jsonl"
$start = Get-Date

try {
    $realScript = Join-Path $PSScriptRoot 'utils' 'pre-process-input.ps1'
    if (-not (Test-Path $realScript)) {
        $err = @{ Timestamp = $start.ToString('o'); Error = "pre-process-input.ps1 not found at $realScript"; Phase = 'stub-resolve' }
        try { New-Item -ItemType Directory -Path $traceDir -Force | Out-Null; Add-Content -Path $traceFile -Value (ConvertTo-Json $err -Compress) } catch {}
        exit 0
    }
    $realScript = Resolve-Path $realScript -ErrorAction Stop
    & $realScript -UserInput $UserInput -WorkspaceRoot $WorkspaceRoot
    $exitCode = $LASTEXITCODE
    $elapsed = [math]::Round(((Get-Date) - $start).TotalMilliseconds)
    $trace = @{ Timestamp = $start.ToString('o'); Phase = 'pre-process'; ElapsedMs = $elapsed; ExitCode = $exitCode; InputPreview = $UserInput.Substring(0, [Math]::Min(60, $UserInput.Length)) }
    try { New-Item -ItemType Directory -Path $traceDir -Force | Out-Null; Add-Content -Path $traceFile -Value (ConvertTo-Json $trace -Compress) } catch {}
    exit $exitCode
} catch {
    $elapsed = [math]::Round(((Get-Date) - $start).TotalMilliseconds)
    $err = @{ Timestamp = $start.ToString('o'); Error = $_.ToString(); Phase = 'stub-catch'; ElapsedMs = $elapsed }
    try { New-Item -ItemType Directory -Path $traceDir -Force | Out-Null; Add-Content -Path $traceFile -Value (ConvertTo-Json $err -Compress) } catch {}
    exit 0
}
