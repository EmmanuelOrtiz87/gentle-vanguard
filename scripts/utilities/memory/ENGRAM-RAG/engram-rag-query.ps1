#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true, Position=0)][string]$Query,
    [int]$TopK = 10,
    [float]$MinScore = 0.0,
    [string]$Project = "",
    [string]$Type = "",
    [switch]$Raw,
    [string]$IndexFile = ""
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
if (-not $IndexFile) { $IndexFile = Join-Path $repoRoot '.session' 'engram-rag' 'vector-index.json' }
if (-not (Test-Path $IndexFile)) { Write-Host "[ERROR] Index not found. Run engram-vector-index.ps1 first" Red; exit 1 }

Write-Host "[ENGRAM-RAG] Loading index..." -ForegroundColor Cyan
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$json = [System.IO.File]::ReadAllText($IndexFile, [System.Text.UTF8Encoding]::new($false))
$index = $json | ConvertFrom-Json
Write-Host "[ENGRAM-RAG] Loaded in $($sw.Elapsed.TotalSeconds.ToString('F1'))s — $($index.total_docs) docs, $($index.total_terms) terms" -ForegroundColor Cyan

$idf = @{}; $index.idf | Get-Member -MemberType NoteProperty | ForEach-Object { $idf[$_.Name] = [double]$index.idf.$($_.Name) }
$ngramMin = [int]$index.ngram_range[0]; $ngramMax = [int]$index.ngram_range[1]
$docs = @($index.documents)

# --- N-gram ---
function Get-Ngrams {
    param([string]$Text, [int]$Min, [int]$Max)
    $text = $Text.ToLowerInvariant() -replace '[^\w\sáéíóúüñ]', ' ' -replace '\s+', ' '; $text = $text.Trim()
    $ng = @(); for ($n = $Min; $n -le $Max; $n++) { for ($i = 0; $i -le ($text.Length - $n); $i++) { $ng += $text.Substring($i, $n) } }; , $ng
}

# --- Build query vector ---
$queryNgrams = Get-Ngrams -Text $Query -Min $ngramMin -Max $ngramMax
$totalNgrams = $queryNgrams.Count; if ($totalNgrams -eq 0) { Write-Host "[ERROR] No n-grams" Red; exit 1 }
$tf = @{}; foreach ($ng in $queryNgrams) { $tf[$ng] = if ($tf.ContainsKey($ng)) { $tf[$ng] + 1 } else { 1 } }
$queryVec = @{}
foreach ($entry in $tf.GetEnumerator()) {
    $t = $entry.Key
    if ($idf.ContainsKey($t)) { $queryVec[$t] = ($entry.Value / $totalNgrams) * $idf[$t] }
}
Write-Host "[ENGRAM-RAG] Query vector: $($queryVec.Count) features" -ForegroundColor Cyan

# --- Cosine similarity (direct PSCustomObject access) ---
function Get-Sim {
    param($QV, $DF)
    $dot = 0.0; $qMag = 0.0; $dMag = 0.0
    foreach ($entry in $QV.GetEnumerator()) {
        $qv = [double]$entry.Value; $qMag += $qv * $qv
        $dv = $DF.$($entry.Key)
        if ($dv -ne $null) { $dot += $qv * [double]$dv }
    }
    foreach ($p in $DF.PSObject.Properties) {
        $dv = [double]$p.Value; $dMag += $dv * $dv
    }
    $qMag = [Math]::Sqrt($qMag); $dMag = [Math]::Sqrt($dMag)
    if ($qMag -eq 0 -or $dMag -eq 0) { return 0.0 }
    return $dot / ($qMag * $dMag)
}

$results = New-Object System.Collections.ArrayList
foreach ($doc in $docs) {
    if ($Project -and $doc.project -ne $Project) { continue }
    if ($Type -and $doc.type -ne $Type) { continue }
    $score = Get-Sim -QV $queryVec -DF $doc.features
    if ($score -ge $MinScore) {
        $docTitle = if ($doc.PSObject.Properties.Name -contains 'title' -and $doc.title) { "$($doc.title)" } else { "(untitled)" }
        $docType = if ($doc.PSObject.Properties.Name -contains 'type' -and $doc.type) { "$($doc.type)" } else { "unknown" }
        $docProject = if ($doc.PSObject.Properties.Name -contains 'project' -and $doc.project) { "$($doc.project)" } else { "" }
        $docPreview = if ($doc.PSObject.Properties.Name -contains 'content_preview' -and $doc.content_preview) { "$($doc.content_preview)" } else { "" }
        $docCreated = if ($doc.PSObject.Properties.Name -contains 'created_at' -and $doc.created_at) { "$($doc.created_at)" } else { "" }
        $null = $results.Add([PSCustomObject]@{
            id=$doc.id; title=$docTitle; type=$docType; project=$docProject
            score=[Math]::Round($score, 4); content_preview=$docPreview; created_at=$docCreated
        })
    }
}

$results = $results | Sort-Object score -Descending | Select-Object -First $TopK

if ($results.Count -eq 0) { Write-Host "[ENGRAM-RAG] No results" -ForegroundColor Yellow; exit 0 }

if ($Raw) {
    $results | ConvertTo-Json -Depth 2
} else {
    Write-Host "`n[ENGRAM-RAG] Top $($results.Count) for: '$Query'" -ForegroundColor Green
    Write-Host ("=" * 70) -ForegroundColor DarkGray; $i = 1
    foreach ($r in $results) {
        $bar = "#" * [Math]::Min(20, [Math]::Max(0, [Math]::Round($r.score * 20)))
        $c = if ($r.score -ge 0.3) { "Green" } elseif ($r.score -ge 0.1) { "Yellow" } else { "DarkGray" }
        Write-Host "  $i. $($r.title)" -ForegroundColor White
        Write-Host "     Score: $($r.score.ToString('F4')) [$($bar.PadRight(20))]" -ForegroundColor $c
        Write-Host "     Type : $($r.type)  Project: $($r.project)" -ForegroundColor Cyan
        $p = $r.content_preview -replace "`n"," " -replace "`r",""
        if ($p.Length -gt 120) { $p = $p.Substring(0,120) + "..." }
        Write-Host "     $p" -ForegroundColor Gray
        Write-Host "-" * 60 -ForegroundColor DarkGray; $i++
    }
}
Write-Host "[ENGRAM-RAG] Done in $($sw.Elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
