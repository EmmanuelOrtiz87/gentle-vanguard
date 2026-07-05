#!/usr/bin/env pwsh
param(
    [string]$Project = "",
    [switch]$Force,
    [string]$ExportFile = ""
)

$ErrorActionPreference = "Continue"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$indexDir = Join-Path $repoRoot '.session' 'engram-rag'
$indexFile = Join-Path $indexDir 'vector-index.json'
$metaFile = Join-Path $indexDir 'index-meta.json'

if (-not (Test-Path $indexDir)) { New-Item -ItemType Directory -Path $indexDir -Force | Out-Null }

function Write-Log { param([string]$M, [string]$C = "Cyan") Write-Host "[ENGRAM-VECTOR-INDEX] $M" -ForegroundColor $C }

# --- Load observations ---
$observations = @()
if ($ExportFile -and (Test-Path $ExportFile)) {
    Write-Log "Loading export from $ExportFile"
    $exportData = Get-Content $ExportFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $observations = @($exportData.observations)
    if ($Project) { $observations = @($observations | Where-Object { $_.project -eq $Project }) }
} else {
    $engramPath = (Get-Command engram.exe -ErrorAction SilentlyContinue).Source
    if (-not $engramPath) { $engramPath = Join-Path $repoRoot 'tools\engram.exe' }
    if (-not (Test-Path $engramPath)) { Write-Log "Engram CLI not found" Red; exit 1 }

    $tmpExport = Join-Path $indexDir '_export-tmp.json'
    Write-Log "Exporting observations..."
    $null = & $engramPath @('export', $tmpExport) + $(if ($Project) { @('--project', $Project) } else { @() }) 2>&1
    if (-not (Test-Path $tmpExport)) { Write-Log "Export failed" Red; exit 1 }
    $exportData = Get-Content $tmpExport -Raw -Encoding UTF8 | ConvertFrom-Json
    $observations = @($exportData.observations)
}

Write-Log "Loaded $($observations.Count) observations"
if ($observations.Count -eq 0) { Write-Log "No observations to index" Yellow; exit 0 }

# --- Incremental check ---
$meta = @{ lastId = 0; indexedAt = ""; count = 0; version = "1.0" }
if ((-not $Force) -and (Test-Path $metaFile)) {
    try { $meta = Get-Content $metaFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Write-Log "Failed to read meta file: using defaults" Yellow }
}

$newObservations = if ($Force -or $meta.lastId -eq 0) {
    $observations
} else {
    @($observations | Where-Object { [int]$_.id -gt [int]$meta.lastId })
}
if ($newObservations.Count -eq 0 -and -not $Force) {
    Write-Log "No new observations (last indexed ID: $($meta.lastId))" Green; exit 0
}
Write-Log "Indexing $($newObservations.Count) new observations"

# --- Character n-gram ---
$ngramMin = 2; $ngramMax = 3
function Get-Ngrams {
    param([string]$Text, [int]$Min, [int]$Max)
    $text = $Text.ToLowerInvariant() -replace '[^\w\sáéíóúüñ]', ' ' -replace '\s+', ' '; $text = $text.Trim()
    $ng = @(); for ($n = $Min; $n -le $Max; $n++) { for ($i = 0; $i -le ($text.Length - $n); $i++) { $ng += $text.Substring($i, $n) } }; , $ng
}

# --- Build vectors ---
$globalDf = @{}
$newVectors = @()

foreach ($obs in $newObservations) {
    $obsTitle = if ($obs.PSObject.Properties.Name -contains 'title' -and $obs.title) { "$($obs.title)" } else { "" }
    $obsContent = if ($obs.PSObject.Properties.Name -contains 'content' -and $obs.content) { "$($obs.content)" } else { "" }
    $obsType = if ($obs.PSObject.Properties.Name -contains 'type' -and $obs.type) { "$($obs.type)" } else { "unknown" }
    $obsCreatedAt = if ($obs.PSObject.Properties.Name -contains 'created_at' -and $obs.created_at) { "$($obs.created_at)" } else { "" }
    $obsUpdatedAt = if ($obs.PSObject.Properties.Name -contains 'updated_at' -and $obs.updated_at) { "$($obs.updated_at)" } else { "" }

    $content = "$obsTitle $obsContent"
    $ngrams = Get-Ngrams -Text $content -Min $ngramMin -Max $ngramMax
    $totalNgrams = $ngrams.Count
    if ($totalNgrams -eq 0) { continue }

    $tf = @{}
    foreach ($ng in $ngrams) { $tf[$ng] = if ($tf.ContainsKey($ng)) { $tf[$ng] + 1 } else { 1 } }

    $vector = @{}
    foreach ($entry in $tf.GetEnumerator()) {
        $t = $entry.Key
        $vector[$t] = $entry.Value / $totalNgrams
        $globalDf[$t] = if ($globalDf.ContainsKey($t)) { $globalDf[$t] + 1 } else { 1 }
    }

    $proj = if ($obs.PSObject.Properties.Name -contains 'project' -and $obs.project) { "$($obs.project)" } else { "" }
    $preview = $obsContent; if ($preview.Length -gt 300) { $preview = $preview.Substring(0, 300) + '...' }
    $newVectors += @{ id=[int]$obs.id; title=$obsTitle; type=$obsType; project=$proj; content_preview=$preview; created_at=$obsCreatedAt; updated_at=$obsUpdatedAt; features=$vector }
}

Write-Log "Built $($newVectors.Count) vectors, $($globalDf.Count) raw terms"

# --- Load existing index + merge ---
$allDocs = @($newVectors)

if ((Test-Path $indexFile) -and (-not $Force)) {
    try {
        $existing = @(Get-Content $indexFile -Raw -Encoding UTF8 | ConvertFrom-Json)
        # Convert PSCustomObject features to hashtables
        foreach ($doc in $existing) {
            $ht = @{}; $doc.features | Get-Member -MemberType NoteProperty | ForEach-Object { $ht[$_.Name] = $doc.features.$($_.Name) }
            $doc.features = $ht; $allDocs += $doc
        }
        Write-Log "Merged with $($existing.Count) existing docs"
    } catch { Write-Log "Could not load existing index, rebuilding from scratch" Yellow }
}

$totalDocs = $allDocs.Count

# --- Compute IDF (prune terms appearing in only 1 doc) ---
$idf = @{}
foreach ($entry in $globalDf.GetEnumerator()) {
    $df = $entry.Value
    if ($df -le 1) { continue }
    $idf[$entry.Key] = [Math]::Log(($totalDocs + 1) / ($df + 1)) + 1
}
Write-Log "IDF computed: $($idf.Count) terms (pruned $($globalDf.Count - $idf.Count) rare terms)"

# --- Apply IDF to all docs, prune zero-weight terms ---
foreach ($doc in $allDocs) {
    $keysToRemove = New-Object System.Collections.ArrayList
    $featureKeys = @($doc.features.Keys)
    foreach ($term in $featureKeys) {
        if ($idf.ContainsKey($term)) {
            $doc.features[$term] = $doc.features[$term] * $idf[$term]
        } else {
            $null = $keysToRemove.Add($term)
        }
    }
    foreach ($k in $keysToRemove) { $doc.features.Remove($k) }
}

# --- Write index ---
$indexPayload = @{
    version = "1.0"
    built_at = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    total_docs = $totalDocs
    total_terms = $idf.Count
    ngram_range = @($ngramMin, $ngramMax)
    idf = $idf
    documents = $allDocs
}
$json = $indexPayload | ConvertTo-Json -Depth 10 -Compress
[System.IO.File]::WriteAllText($indexFile, $json, [System.Text.UTF8Encoding]::new($false))
Write-Log "Index written: $($json.Length) bytes, $totalDocs docs, $($idf.Count) terms" Green

# --- Write meta ---
$lastId = if ($totalDocs -gt 0) { ($allDocs | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
@{ version="1.0"; lastId=[int]$lastId; indexedAt=(Get-Date -Format "yyyy-MM-dd HH:mm:ss"); count=$totalDocs; totalTerms=$idf.Count } |
    ConvertTo-Json -Compress | Set-Content $metaFile -Encoding UTF8
Write-Log "Last indexed ID: $lastId" Green
