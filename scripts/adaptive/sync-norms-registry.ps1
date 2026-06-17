param([switch]$VerboseOutput)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..') | Select-Object -ExpandProperty Path
$adaptiveRulesPath = Join-Path $repoRoot "rules\adaptive"
$mdPath = Join-Path $adaptiveRulesPath "LEARNED-NORMS.md"
$jsonPath = Join-Path $adaptiveRulesPath "norms-registry.json"

Write-Host "[SYNC] Sincronizando normas desde MD a JSON..." -ForegroundColor Cyan

if (-not (Test-Path $mdPath)) { Write-Host "[SYNC] ERROR: No se encuentra LEARNED-NORMS.md" -ForegroundColor Red; exit 1 }

$lines = Get-Content $mdPath
$norms = @()
$cat = "UNKNOWN"

foreach ($line in $lines) {
    if ($line -match '^## (\w+) Norms') { $cat = $matches[1] }
    if ($line -match '^\| ([A-Z]+-\d+) \| (.+?) \| (\w+) \| (.+?) \| (\d{4}-\d{2}-\d{2}) \|') {
        $norms += @{
            id = $matches[1]
            text = ($matches[2] -replace '\s+', ' ').Trim()
            category = $cat
            source = ($matches[4] -replace '\s+', ' ').Trim()
            confidence = $matches[3]
            createdAt = "$($matches[5])T00:00:00Z"
            updatedAt = "$($matches[5])T00:00:00Z"
            hitCount = 0
            successRate = 0.0
            status = "active"
            tags = @()
        }
    }
}

# Preserve hitCount/successRate from existing JSON if available
$oldRegistry = @{}
if (Test-Path $jsonPath) {
    try {
        $old = Get-Content $jsonPath -Raw | ConvertFrom-Json
        foreach ($n in $old.norms) { $oldRegistry[$n.id] = @{ hitCount = $n.hitCount; successRate = $n.successRate; status = $n.status } }
    } catch {}
}

# Build category stats
$catCount = @{}
foreach ($n in $norms) {
    if (-not $catCount.ContainsKey($n.category)) { $catCount[$n.category] = 0 }
    $catCount[$n.category]++
    if ($oldRegistry.ContainsKey($n.id)) {
        $n.hitCount = $oldRegistry[$n.id].hitCount
        $n.successRate = $oldRegistry[$n.id].successRate
        $n.status = $oldRegistry[$n.id].status
    }
}

$activeCount = ($norms | Where-Object { $_.status -eq 'active' }).Count
$deprecatedCount = ($norms | Where-Object { $_.status -eq 'deprecated' }).Count

$registry = @{
    version = 3
    lastUpdated = (Get-Date -Format 'o')
    stats = @{
        totalNorms = $norms.Count
        categories = $catCount
        activeNorms = $activeCount
        deprecatedNorms = $deprecatedCount
    }
    norms = $norms
}

$json = $registry | ConvertTo-Json -Depth 5
Set-Content -Path $jsonPath -Value $json -Encoding UTF8

Write-Host "[SYNC] Normas sincronizadas: $($norms.Count) desde $($catCount.Count) categorías" -ForegroundColor Green
if ($VerboseOutput) {
    foreach ($kv in $catCount.GetEnumerator() | Sort-Object Value -Descending) {
        Write-Host "  $($kv.Key): $($kv.Value) normas" -ForegroundColor White
    }
    Write-Host "[SYNC] Activas: $activeCount | Deprecadas: $deprecatedCount" -ForegroundColor White
}
