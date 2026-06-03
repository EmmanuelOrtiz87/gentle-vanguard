param(
    [ValidateSet("session","engram","skills","routing","all")]
    [string]$Source = "all",
    [string]$OutputPath = "",
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
if (-not $OutputPath) { $OutputPath = Join-Path $ProjectRoot ".ft" "dataset" "raw" }

$null = New-Item -ItemType Directory -Path $OutputPath -Force

$results = @()

function Add-Record {
    param([string]$Instruction, [string]$Input, [string]$Output, [string]$Domain, [string]$Source, [string]$SourceRef)
    $script:results += @{
        instruction = $Instruction
        input = $Input
        output = $Output
        domain = $Domain
        source = $Source
        sourceRef = $SourceRef
        timestamp = (Get-Date -Format "o")
    }
}

function Collect-SessionLogs {
    Write-Host "  [FT] Collecting session logs..." -ForegroundColor Gray
    $ctxDir = Join-Path $ProjectRoot ".session" "context-log"
    if (-not (Test-Path $ctxDir)) { return }

    $sessions = Get-ChildItem $ctxDir -Directory | Where-Object { $_.Name -ne 'live-traceability-session' -and $_.Name -ne '__archive' }
    foreach ($s in $sessions) {
        $turns = Get-ChildItem (Join-Path $s.FullName "turn-*.md") -ErrorAction SilentlyContinue
        $summaryPath = Join-Path $s.FullName "context-summary.md"
        $summary = if (Test-Path $summaryPath) { Get-Content $summaryPath -Raw } else { "" }

        foreach ($t in $turns) {
            $content = Get-Content $t.FullName -Raw
            $tokensMatch = [regex]::Match($content, 'Input Tokens\s*\|\s*(\d+)')
            $inTokens = if ($tokensMatch.Success) { [int]$tokensMatch.Groups[1].Value } else { 0 }
            $outMatch = [regex]::Match($content, 'Output Tokens\s*\|\s*(\d+)')
            $outTokens = if ($outMatch.Success) { [int]$outMatch.Groups[1].Value } else { 0 }

            Add-Record -Instruction "Process turn in session $($s.Name)" `
                -Input $summary.Substring(0, [Math]::Min(500, $summary.Length)) `
                -Output $content `
                -Domain "DEV" `
                -Source "session-log" `
                -SourceRef $t.FullName
        }
    }
    Write-Host "  [FT] Collected $($turns.Count) turns from $($sessions.Count) sessions" -ForegroundColor Green
}

function Collect-Engram {
    Write-Host "  [FT] Collecting Engram observations..." -ForegroundColor Gray
    $memDir = Join-Path $ProjectRoot ".engram"
    if (-not (Test-Path $memDir)) { return }

    $files = Get-ChildItem $memDir -Recurse -Include "*.json","*.md" -ErrorAction SilentlyContinue
    $count = 0
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw
        if ($content.Length -lt 50) { continue }

        $domain = "DEV"
        if ($content -match "(?i)\b(BA|business analyst|requirements|explore)\b") { $domain = "BA" }
        elseif ($content -match "(?i)\b(SAD|architect|design|spec|proposal)\b") { $domain = "SAD" }
        elseif ($content -match "(?i)\b(QA|test|verify|validate|bug)\b") { $domain = "QA" }

        $title = if ($content -match "(?m)^#+\s+(.+)$") { $matches[1] } else { $f.BaseName }

        Add-Record -Instruction "Learn from past observation: $title" `
            -Input "Domain: $domain. Source: Engram memory." `
            -Output $content.Substring(0, [Math]::Min(1000, $content.Length)) `
            -Domain $domain `
            -Source "engram" `
            -SourceRef $f.FullName
        $count++
    }
    Write-Host "  [FT] Collected $count Engram observations" -ForegroundColor Green
}

function Collect-Skills {
    Write-Host "  [FT] Collecting skills..." -ForegroundColor Gray
    $regPath = Join-Path $ProjectRoot ".atl" "skill-registry.md"
    $embedPath = Join-Path $ProjectRoot ".atl" "skill-embeddings.json"

    if (Test-Path $regPath) {
        $content = Get-Content $regPath -Raw
        Add-Record -Instruction "Understand available skills for task routing" `
            -Input "Full skill registry" `
            -Output $content.Substring(0, [Math]::Min(2000, $content.Length)) `
            -Domain "BA" `
            -Source "skill-registry" `
            -SourceRef $regPath
    }
    if (Test-Path $embedPath) {
        $data = Get-Content $embedPath -Raw | ConvertFrom-Json
        $meta = "Skills: $($data.Count) | Terms: $($data.terms.Count)"
        Add-Record -Instruction "Embedding metadata for skill routing" `
            -Input $meta `
            -Output ($data | ConvertTo-Json -Depth 1 -Compress).Substring(0, 1000) `
            -Domain "DEV" `
            -Source "skill-embeddings" `
            -SourceRef $embedPath
    }
    Write-Host "  [FT] Collected skill registry + embeddings" -ForegroundColor Green
}

function Collect-RoutingLogs {
    Write-Host "  [FT] Collecting routing logs..." -ForegroundColor Gray
    $delPath = Join-Path $ProjectRoot "config" "auto-delegation.json"
    $qualPath = Join-Path $ProjectRoot ".session" "routing-quality-last.json"

    if (Test-Path $delPath) {
        $content = Get-Content $delPath -Raw
        Add-Record -Instruction "Route tasks to correct agent based on intent" `
            -Input "Auto-delegation configuration" `
            -Output $content.Substring(0, [Math]::Min(3000, $content.Length)) `
            -Domain "BA" `
            -Source "auto-delegation-config" `
            -SourceRef $delPath
    }
    if (Test-Path $qualPath) {
        $content = Get-Content $qualPath -Raw
        Add-Record -Instruction "Learn from past routing decisions and quality scores" `
            -Input "Routing quality metrics" `
            -Output $content.Substring(0, [Math]::Min(2000, $content.Length)) `
            -Domain "QA" `
            -Source "routing-quality" `
            -SourceRef $qualPath
    }
    Write-Host "  [FT] Collected routing configuration" -ForegroundColor Green
}

Write-Host "=== FT Data Collector ===" -ForegroundColor Cyan
$sources = if ($Source -eq "all") { @("session","engram","skills","routing") } else { @($Source) }
foreach ($s in $sources) {
    switch ($s) {
        "session" { Collect-SessionLogs }
        "engram"  { Collect-Engram }
        "skills"  { Collect-Skills }
        "routing" { Collect-RoutingLogs }
    }
}

$outputFile = Join-Path $OutputPath "ft-raw-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$results | ConvertTo-Json -Depth 3 | Out-File $outputFile -Encoding utf8

Write-Host ""
Write-Host "[FT] Complete: $($results.Count) records → $outputFile" -ForegroundColor Green
Write-Host "[FT] Domain breakdown:" -ForegroundColor Gray
$results | Group-Object domain | ForEach-Object { Write-Host "      $($_.Name): $($_.Count)" }
