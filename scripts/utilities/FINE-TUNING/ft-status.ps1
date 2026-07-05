param(
    [string]$RegistryPath = "",
    [string]$DatasetPath = "",
    [string]$BenchmarkPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot
if (-not $RegistryPath) { $RegistryPath = Join-Path (Join-Path $ProjectRoot ".ft") "registry.json" }
if (-not $DatasetPath) { $DatasetPath = Join-Path (Join-Path $ProjectRoot ".ft") "dataset" }
if (-not $BenchmarkPath) {
    $latest = Get-ChildItem (Join-Path (Join-Path $ProjectRoot ".ft") "benchmarks") -Filter "eval-*.json" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) { $BenchmarkPath = $latest.FullName }
}

Write-Host "=== FT System Status ===" -ForegroundColor Cyan
Write-Host ""

# Registry
if (Test-Path $RegistryPath) {
    $reg = Get-Content $RegistryPath -Raw | ConvertFrom-Json
    Write-Host "[Registry] $($reg.adapters.Count) adapters registered" -ForegroundColor Green
    foreach ($a in $reg.adapters) {
        $icon = if ($a.active) { "ACTIVE" } else { "INACTIVE" }
        Write-Host "  $($a.domain): $($a.model) v$($a.version) [$icon]"
        Write-Host "    Path: $($a.path)"
        Write-Host "    Trained: $($a.trainedAt)"
    }
} else {
    Write-Host "[Registry] No adapters registered" -ForegroundColor Yellow
}
Write-Host ""

# Dataset
$totalTrain = 0; $totalVal = 0; $totalRaw = 0
$domains = @("BA", "SAD", "DEV", "QA")
foreach ($d in $domains) {
    $tf = Join-Path $DatasetPath "train" "$d.jsonl"
    $vf = Join-Path $DatasetPath "val" "$d.jsonl"
    $tc = if (Test-Path $tf) { (Get-Content $tf -ErrorAction SilentlyContinue | Measure-Object).Count } else { 0 }
    $vc = if (Test-Path $vf) { (Get-Content $vf -ErrorAction SilentlyContinue | Measure-Object).Count } else { 0 }
    if ($tc -gt 0 -or $vc -gt 0) {
        Write-Host ("[Dataset] {0}: {1} train / {2} val" -f $d, $tc, $vc) -ForegroundColor $(if($tc -gt 0){'Green'}else{'Gray'})
    }
    $totalTrain += $tc; $totalVal += $vc
}
$rawFiles = Get-ChildItem (Join-Path $DatasetPath "raw") -Filter "ft-raw-*.json" -ErrorAction SilentlyContinue
$totalRaw = $rawFiles.Count
Write-Host "[Dataset] Total: $totalTrain train / $totalVal val ($totalRaw raw files)" -ForegroundColor Green
Write-Host ""

# Benchmarks
if ($BenchmarkPath -and (Test-Path $BenchmarkPath)) {
    $bm = Get-Content $BenchmarkPath -Raw | ConvertFrom-Json
    Write-Host "[Benchmark] Last eval: $($bm.evalDate)" -ForegroundColor Cyan
    foreach ($d in $domains) {
        $ds = $bm.dataset.$d
        $bl = $bm.baseline.$d
        $adp = $bm.adapters.$d
        if ($ds -or $bl) {
            $dsStr = if ($ds) { "T:$($ds.train)/V:$($ds.val)" } else { "no data" }
            $blStr = if ($bl) { "$($bl.latencyMs)ms" } else { "N/A" }
            $adpStr = if ($adp) { "$($adp.model) v$($adp.version)" } else { "no adapter" }
            Write-Host "  $d — $dsStr | TF-IDF: $blStr | $adpStr"
        }
    }
} else {
    Write-Host "[Benchmark] No eval reports found" -ForegroundColor Yellow
}
Write-Host ""

# Scripts
$ftDir = Join-Path $ProjectRoot "scripts" "utilities" "FINE-TUNING"
$scripts = Get-ChildItem $ftDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name
Write-Host "[Scripts] $($scripts.Count) available:" -ForegroundColor Cyan
foreach ($s in $scripts) {
    Write-Host "  $($s.Name) ($(if($s.Length -gt 1KB){'{0:N0}KB' -f ($s.Length/1KB)}else{'{0}B' -f $s.Length}))"
}

# Tests
$testDir = Join-Path $ProjectRoot "tests" "unit" "fine-tuning"
$tests = Get-ChildItem $testDir -Filter "*.tests.ps1" -ErrorAction SilentlyContinue
if ($tests) {
    Write-Host "[Tests] $($tests.Count) test files" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Use: ft-pipeline.ps1 -Stage full    # Run full pipeline" -ForegroundColor Gray
Write-Host "Use: ft-trainer.ps1 -Domain BA -Mode dry-run  # Test training" -ForegroundColor Gray
Write-Host "Use: ft-registry.ps1 -Action list  # List adapters" -ForegroundColor Gray
