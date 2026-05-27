#Requires -Version 7.0
param([switch]$Verbose,[switch]$CI)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$reportsDir=Join-Path $repoRoot 'reports'
$metricsDir=Join-Path $repoRoot '.runtime' 'metrics'
$results=@{Total=0;Passed=0;Failed=0;Warnings=0}
function Write-Result($Name,$Status,$Message=''){
    $results.Total++
    switch($Status){'PASS'{$results.Passed++;$c='Green'}'FAIL'{$results.Failed++;$c='Red'}'WARN'{$results.Warnings++;$c='Yellow'}}
    $icon=switch($Status){'PASS'{'[OK]'}'FAIL'{'[FAIL]'}'WARN'{'[WARN]'}}
    Write-Host "$icon $Name" -ForegroundColor $c -NoNewline
    if($Message){Write-Host " - $Message" -ForegroundColor Gray}else{Write-Host ""}
}
Write-Host "Dashboard Validator v1.0" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan
$sw=[System.Diagnostics.Stopwatch]::StartNew()
# Test 1: Dashboard exists
$path=Join-Path $reportsDir 'dashboard.html'
if(Test-Path $path){
    $size=(Get-Item $path).Length
    if($size -gt 1000){Write-Result 'Dashboard Exists' 'PASS' "$([math]::Round($size/1KB,2)) KB"}
    else{Write-Result 'Dashboard Exists' 'FAIL' 'File too small'}
}else{Write-Result 'Dashboard Exists' 'FAIL' 'Not found'}
# Test 2: JSON files valid
$jsonFiles=Get-ChildItem -Path $metricsDir -Filter '*.json' -ErrorAction SilentlyContinue
$valid=0;$invalid=0
foreach($file in $jsonFiles){try{$null=Get-Content $file.FullName -Raw|ConvertFrom-Json;$valid++}catch{$invalid++}}
if($invalid -eq 0){Write-Result 'JSON Valid' 'PASS' "$valid files"}else{Write-Result 'JSON Valid' 'FAIL' "$invalid invalid"}
# Test 3: Structure
if(Test-Path $path){
    $html=Get-Content $path -Raw
    $checks=@{
        '9 Sections'=([regex]::Matches($html,'section id=')).Count -ge 9
        'Navigation'=$html -match 'data-target='
        'Charts'=$html -match '<canvas[^>]*id="chart'
        'Export'=$html -match 'gvExportPdf'
        'TV Mode'=$html -match 'tv-mode'
        'Alerts'=$html -match 'alert-toast'
        'Sparklines'=$html -match 'sparkline'
    }
    $passed=($checks.Values|Where-Object{$_}).Count
    if($passed -eq $checks.Count){Write-Result 'Structure' 'PASS' "All $($checks.Count) checks"}else{Write-Result 'Structure' 'FAIL' "$passed/$($checks.Count)"}
}else{Write-Result 'Structure' 'FAIL' 'No HTML to check'}
$sw.Stop()
Write-Host "`nSummary: $($results.Passed)/$($results.Total) passed" -ForegroundColor Cyan
Write-Host "Duration: $($sw.Elapsed.TotalSeconds.ToString('F2'))s" -ForegroundColor Gray
if($results.Failed -gt 0){exit 1}else{exit 0}
