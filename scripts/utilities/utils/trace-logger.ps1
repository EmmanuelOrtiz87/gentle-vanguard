param(
    [Parameter(Mandatory=$true, ParameterSetName='write')][string]$Phase,
    [Parameter(Mandatory=$true, ParameterSetName='write')][int]$ElapsedMs,
    [Parameter(ParameterSetName='write')][string]$Status = 'ok',
    [Parameter(ParameterSetName='write')][string]$Detail = '',
    [Parameter(ParameterSetName='write')][string]$TraceFile = '',
    [Parameter(ParameterSetName='status')][switch]$Status,
    [Parameter(ParameterSetName='status')][string]$Range = 'last50'
)

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else { (Get-Location).Path }
$sessionDir = Join-Path $repoRoot ".session"
$traceDir = Join-Path $sessionDir "traces"
if (-not $TraceFile) { $TraceFile = Join-Path $traceDir "preprocess.jsonl" }

function Initialize-TraceDir {
    if (-not (Test-Path $traceDir)) { New-Item -ItemType Directory -Path $traceDir -Force | Out-Null }
}

function Write-TraceEntry {
    param([string]$FilePath, [hashtable]$Entry)
    try {
        Initialize-TraceDir
        Add-Content -Path $FilePath -Value (ConvertTo-Json $Entry -Compress)
    } catch {}
}

function Get-TraceStatus {
    param([string]$FilePath, [string]$Range)
    if (-not (Test-Path $FilePath)) { return @{ File = $FilePath; Entries = 0; Status = 'empty' } }
    try {
        $lines = Get-Content $FilePath
        $total = $lines.Count
        $sample = switch ($Range) {
            'last50' { $lines[-50..-1] }
            'last20' { $lines[-20..-1] }
            'all' { $lines }
            default { $lines[-50..-1] }
        }
        $entries = $sample | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} }
        $errors = $entries | Where-Object { $_.Status -eq 'error' -or $_.Status -eq 'timeout' }
        $avgMs = if ($entries) { [math]::Round(($entries | Measure-Object -Property ElapsedMs -Average).Average) } else { 0 }
        $phases = $entries | Where-Object { $_.Phase } | Group-Object Phase | ForEach-Object {
            @{ Phase = $_.Name; Count = $_.Count; AvgMs = [math]::Round(($_.Group | Measure-Object -Property ElapsedMs -Average).Average) }
        }
        return @{ File = $FilePath; Total = $total; SampleSize = $sample.Count; Errors = $errors.Count; AvgMs = $avgMs; Phases = $phases; LatestEntries = $entries[-5..-1] }
    } catch { return @{ File = $FilePath; Entries = 0; Status = 'error'; Detail = $_.ToString() } }
}

switch ($PSCmdlet.ParameterSetName) {
    'write' {
        $entry = @{ Timestamp = (Get-Date -Format 'o'); Phase = $Phase; ElapsedMs = $ElapsedMs; Status = $Status }
        if ($Detail) { $entry.Detail = $Detail }
        Write-TraceEntry -FilePath $TraceFile -Entry $entry
        if ($Status -in @('error', 'timeout')) {
            Write-Output "[TRACE] $Status in $Phase (${ElapsedMs}ms): $Detail"
        }
    }
    'status' {
        Get-TraceStatus -FilePath $TraceFile -Range $Range | ConvertTo-Json -Depth 3
    }
}
