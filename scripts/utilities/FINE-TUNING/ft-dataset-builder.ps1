param(
    [string]$RawPath = "",
    [string]$OutputPath = "",
    [ValidateRange(0.0, 1.0)]
    [double]$SplitRatio = 0.8,
    [switch]$Force
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
if (-not $RawPath) { $RawPath = Join-Path $ProjectRoot ".ft" "dataset" "raw" }
if (-not $OutputPath) { $OutputPath = Join-Path $ProjectRoot ".ft" "dataset" }

$trainDir = Join-Path $OutputPath "train"
$valDir = Join-Path $OutputPath "val"
$null = New-Item -ItemType Directory -Path $trainDir -Force
$null = New-Item -ItemType Directory -Path $valDir -Force

$allRecords = @()
$rawFiles = Get-ChildItem $RawPath -Filter "ft-raw-*.json" -ErrorAction SilentlyContinue
foreach ($f in $rawFiles) {
    try {
        $data = Get-Content $f.FullName -Raw | ConvertFrom-Json
        $allRecords += $data
    } catch {
        Write-Warning "Skipping $($f.Name): $($_.Exception.Message)"
    }
}

if ($allRecords.Count -eq 0) {
    Write-Host "[FT] No raw data found. Run ft-data-collector.ps1 first." -ForegroundColor Yellow
    exit 0
}

Write-Host "=== FT Dataset Builder ===" -ForegroundColor Cyan
Write-Host "[FT] Processing $($allRecords.Count) records..."

$deduped = $allRecords | Sort-Object -Property sourceRef -Unique
Write-Host "[FT] After dedup: $($deduped.Count) records (removed $($allRecords.Count - $deduped.Count) duplicates)"

$domains = @("BA", "SAD", "DEV", "QA")
$trainAll = @()
$valAll = @()

foreach ($domain in $domains) {
    $domainRecs = $deduped | Where-Object { $_.domain -eq $domain }
    if ($domainRecs.Count -eq 0) {
        Write-Host "[FT]  ${domain}: 0 records — skipping" -ForegroundColor Gray
        continue
    }

    $shuffled = $domainRecs | Sort-Object { Get-Random }
    $splitIdx = [math]::Max(1, [int]($shuffled.Count * $SplitRatio))
    $train = $shuffled[0..($splitIdx - 1)]
    $val = $shuffled[$splitIdx..($shuffled.Count - 1)]

    $trainFile = Join-Path $trainDir "$domain.jsonl"
    $valFile = Join-Path $valDir "$domain.jsonl"

    $train | ForEach-Object {
        $rec = @{
            instruction = $_.instruction
            input = $_.input
            output = $_.output
            domain = $_.domain
            source = $_.source
        }
        ($rec | ConvertTo-Json -Compress -Depth 2) | Out-File $trainFile -Encoding utf8 -Append
    }
    $val | ForEach-Object {
        $rec = @{
            instruction = $_.instruction
            input = $_.input
            output = $_.output
            domain = $_.domain
            source = $_.source
        }
        ($rec | ConvertTo-Json -Compress -Depth 2) | Out-File $valFile -Encoding utf8 -Append
    }

    Write-Host "[FT]  ${domain}: $($domainRecs.Count) records → $($train.Count) train / $($val.Count) val" -ForegroundColor Green
    $trainAll += $train
    $valAll += $val
}

Write-Host ""
Write-Host "[FT] Dataset complete:" -ForegroundColor Green
Write-Host "      Train: $($trainAll.Count) records"
Write-Host "      Val:   $($valAll.Count) records"
Write-Host "      Total: $($trainAll.Count + $valAll.Count) records"
