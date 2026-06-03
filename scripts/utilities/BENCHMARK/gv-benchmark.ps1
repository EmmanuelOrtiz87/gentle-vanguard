param(
    [string[]]$Commands = @('status', 'health'),
    [switch]$AsJson,
    [switch]$Strict,
    [switch]$AutoRemediate,
    [switch]$UpdateBaseline
)

$sloDefaults = @{
    status = 5
    health = 15
    version = 10
    verify = 30
}

$results = @{}
foreach ($cmd in $Commands) {
    $slo = if ($sloDefaults.ContainsKey($cmd)) { $sloDefaults[$cmd] } else { 30 }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & ".\scripts\utilities\gv.ps1" $cmd -Quiet 2>&1 | Out-Null
    $sw.Stop()
    $results[$cmd] = @{
        elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 2)
        slo = $slo
        pass = ($sw.Elapsed.TotalSeconds -le $slo)
    }
}

$summary = @{
    timestamp = (Get-Date -Format 'o')
    commands = $Commands
    results = $results
    allPass = ($results.Values.pass -notcontains $false)
}

if ($AsJson) {
    $summary | ConvertTo-Json -Depth 3
} else {
    $summary.allPass
    foreach ($cmd in $Commands) {
        $r = $results[$cmd]
        $pass = if ($r.pass) { 'PASS' } else { 'FAIL' }
        "$cmd`: $($r.elapsed)s / SLO $($r.slo)s [$pass]"
    }
}

if ($Strict -and -not $summary.allPass) { exit 1 }
