param(
    [ValidateSet("module", "callgraph", "dataflow", "all")]
    [string]$DiagramType = "all",
    [string]$OutputDir = "",
    [string]$DbPath = "",
    [switch]$Raw
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
if (-not $DbPath) { $DbPath = Join-Path $ProjectRoot ".codegraph\codegraph.db" }
if (-not $OutputDir) { $OutputDir = Join-Path $ProjectRoot "docs\diagrams" }

function Test-DbReady {
    if (-not (Test-Path $DbPath)) {
        Write-Error "CodeGraph DB not found at $DbPath. Run codegraph index first."
        return $false
    }
    return $true
}

function Get-NodeKindLabel {
    param([string]$Kind)
    return @{
        function = "func"
        method = "method"
        class = "class"
        interface = "interface"
        struct = "struct"
        type = "type"
        variable = "var"
        module = "module"
        route = "route"
        component = "comp"
    }[$Kind] -replace '^$', "sym"
}

function Get-ModuleDependencyDiagram {
    Write-Host "Generating module dependency diagram..." -ForegroundColor Cyan
    $query = @"
SELECT DISTINCT
    f1.path AS source_file,
    f2.path AS target_file,
    e.kind AS edge_kind
FROM edges e
JOIN nodes n1 ON e.source = n1.id
JOIN nodes n2 ON e.target = n2.id
JOIN files f1 ON n1.file_path = f1.path
JOIN files f2 ON n2.file_path = f2.path
WHERE f1.path != f2.path
  AND e.kind IN ('imports', 'calls', 'extends', 'implements')
  AND f1.language = f2.language
ORDER BY f1.path
"@
    $rows = sqlite3 $DbPath $query 2>$null
    $edges = @{}
    foreach ($row in $rows) {
        $parts = $row -split '\|'
        if ($parts.Count -ge 3) {
            $src = $parts[0]; $tgt = $parts[1]; $kind = $parts[2]
            $key = "$src|$tgt"
            if (-not $edges.ContainsKey($key)) { $edges[$key] = @{} }
            $edges[$key][$kind] = $true
        }
    }
    $files = sqlite3 $DbPath "SELECT path FROM files ORDER BY path" 2>$null
    $fileNodes = @{}
    $nodeId = 0
    foreach ($f in $files) {
        $short = $f -replace '^.*[/\\]src[/\\]', '' -replace '^.*[/\\]scripts[/\\]', '' -replace '^.*[/\\]skills[/\\]', ''
        $short = $short -replace '\.[^\.]+$', ''
        if (-not $fileNodes.ContainsKey($f)) {
            $fileNodes[$f] = "mod$nodeId"
            $nodeId++
        }
    }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("graph TD")
    [void]$sb.AppendLine("  classDef default fill:#1a2035,stroke:#00bfff,color:#e0e0e0")
    [void]$sb.AppendLine("  classDef root fill:#0d1117,stroke:#a855f7,color:#e0e0e0")
    [void]$sb.AppendLine()
    foreach ($f in $files) {
        $nid = $fileNodes[$f]
        $label = $f -replace '^.*[/\\]', ''
        $label = $label -replace '\.[^\.]+$', ''
        [void]$sb.AppendLine("  $nid[$label]")
    }
    [void]$sb.AppendLine()
    foreach ($entry in $edges.GetEnumerator()) {
        $parts = $entry.Key -split '\|'
        $srcId = $fileNodes[$parts[0]]
        $tgtId = $fileNodes[$parts[1]]
        if ($srcId -and $tgtId) {
            [void]$sb.AppendLine("  $srcId --> $tgtId")
        }
    }
    return $sb.ToString()
}

function Get-CallGraphDiagram {
    Write-Host "Generating call graph diagram..." -ForegroundColor Cyan
    $query = @"
SELECT
    n1.name AS caller,
    n1.kind AS caller_kind,
    n2.name AS callee,
    n2.kind AS callee_kind,
    e.kind AS edge_kind,
    n1.file_path AS caller_file
FROM edges e
JOIN nodes n1 ON e.source = n1.id
JOIN nodes n2 ON e.target = n2.id
WHERE e.kind IN ('calls', 'imports')
  AND n1.name != n2.name
ORDER BY n1.file_path
LIMIT 200
"@
    $rows = sqlite3 $DbPath $query 2>$null
    $nodes = @{}
    $nodeId = 0
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("flowchart LR")
    [void]$sb.AppendLine("  classDef default fill:#1a2035,stroke:#00bfff,color:#e0e0e0")
    [void]$sb.AppendLine("  classDef func fill:#1a2035,stroke:#00ff88,color:#e0e0e0")
    [void]$sb.AppendLine("  classDef method fill:#1a2035,stroke:#ffaa00,color:#e0e0e0")
    [void]$sb.AppendLine()
    $edges = @()
    foreach ($row in $rows) {
        $parts = $row -split '\|'
        if ($parts.Count -lt 5) { continue }
        $caller = $parts[0]; $callee = $parts[2]; $edgeKind = $parts[4]
        if ($caller -eq $callee) { continue }
        if (-not $nodes.ContainsKey($caller)) { $nodes[$caller] = "c$nodeId"; $nodeId++ }
        if (-not $nodes.ContainsKey($callee)) { $nodes[$callee] = "c$nodeId"; $nodeId++ }
        $edges += @{ from = $nodes[$caller]; to = $nodes[$callee]; kind = $edgeKind }
    }
    foreach ($entry in $nodes.GetEnumerator()) {
        $name = $entry.Key -replace '[^a-zA-Z0-9_]', ''
        if ($name.Length -gt 25) { $name = $name.Substring(0, 25) + ".." }
        [void]$sb.AppendLine("  $($entry.Value)[$name]")
    }
    [void]$sb.AppendLine()
    foreach ($e in $edges) {
        $style = if ($e.kind -eq 'calls') { " --> " } else { " -.-> " }
        [void]$sb.AppendLine("  $($e.from)$style$($e.to)")
    }
    return $sb.ToString()
}

function Get-DataFlowDiagram {
    Write-Host "Generating data flow diagram..." -ForegroundColor Cyan
    $query = @"
SELECT DISTINCT
    n1.file_path AS source_file,
    n2.file_path AS target_file,
    e.kind
FROM edges e
JOIN nodes n1 ON e.source = n1.id
JOIN nodes n2 ON e.target = n2.id
WHERE n1.file_path != n2.file_path
  AND e.kind IN ('imports', 'calls')
ORDER BY e.kind, n1.file_path
"@
    $rows = sqlite3 $DbPath $query 2>$null
    $langs = @{}
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("flowchart TD")
    [void]$sb.AppendLine("  classDef default fill:#1a2035,stroke:#00bfff,color:#e0e0e0")
    [void]$sb.AppendLine("  classDef js fill:#1a2035,stroke:#f7df1e,color:#e0e0e0")
    [void]$sb.AppendLine("  classDef py fill:#1a2035,stroke:#3572a5,color:#e0e0e0")
    [void]$sb.AppendLine("  classDef ps fill:#1a2035,stroke:#5391fe,color:#e0e0e0")
    [void]$sb.AppendLine("  classDef go fill:#1a2035,stroke:#00add8,color:#e0e0e0")
    [void]$sb.AppendLine()
    $flowEdges = @{}
    foreach ($row in $rows) {
        $parts = $row -split '\|'
        if ($parts.Count -lt 3) { continue }
        $src = $parts[0]; $tgt = $parts[1]; $kind = $parts[2]
        $srcLang = [System.IO.Path]::GetExtension($src)
        $tgtLang = [System.IO.Path]::GetExtension($tgt)
        $srcKey = $src -replace '^.*[/\\]scripts[/\\]', '' -replace '^.*[/\\]src[/\\]', '' -replace '^.*[/\\]skills[/\\]', ''
        $tgtKey = $tgt -replace '^.*[/\\]scripts[/\\]', '' -replace '^.*[/\\]src[/\\]', '' -replace '^.*[/\\]skills[/\\]', ''
        $srcKey = $srcKey -replace '\.[^\.]+$', ''
        $tgtKey = $tgtKey -replace '\.[^\.]+$', ''
        if (-not $langs.ContainsKey($srcKey)) { $langs[$srcKey] = @{ id = "d$($langs.Count)"; lang = $srcLang } }
        if (-not $langs.ContainsKey($tgtKey)) { $langs[$tgtKey] = @{ id = "d$($langs.Count)"; lang = $tgtLang } }
        $flowEdges["$srcKey|$tgtKey"] = $kind
    }
    foreach ($entry in $langs.GetEnumerator()) {
        $label = $entry.Key
        if ($label.Length -gt 30) { $label = $label.Substring(0, 30) + ".." }
        [void]$sb.AppendLine("  $($entry.Value.id)[$label]")
    }
    [void]$sb.AppendLine()
    foreach ($entry in $flowEdges.GetEnumerator()) {
        $parts = $entry.Key -split '\|'
        $srcId = $langs[$parts[0]].id
        $tgtId = $langs[$parts[1]].id
        if ($srcId -and $tgtId) {
            [void]$sb.AppendLine("  $srcId --> $tgtId")
        }
    }
    return $sb.ToString()
}

if (-not (Test-DbReady)) { exit 1 }

Write-Host "=== CodeGraph Diagram Generator ===" -ForegroundColor Magenta
Write-Host "DB: $DbPath" -ForegroundColor DarkGray
Write-Host "Output: $OutputDir" -ForegroundColor DarkGray
Write-Host ""

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$generated = @()

if ($DiagramType -in @('module', 'all')) {
    $mermaid = Get-ModuleDependencyDiagram
    $outPath = Join-Path $OutputDir "module-dependency.mmd"
    $mermaid | Set-Content -Path $outPath -Encoding UTF8
    $generated += $outPath
    Write-Host "  [OK] module-dependency.mmd" -ForegroundColor Green
}

if ($DiagramType -in @('callgraph', 'all')) {
    $mermaid = Get-CallGraphDiagram
    $outPath = Join-Path $OutputDir "call-graph.mmd"
    $mermaid | Set-Content -Path $outPath -Encoding UTF8
    $generated += $outPath
    Write-Host "  [OK] call-graph.mmd" -ForegroundColor Green
}

if ($DiagramType -in @('dataflow', 'all')) {
    $mermaid = Get-DataFlowDiagram
    $outPath = Join-Path $OutputDir "data-flow.mmd"
    $mermaid | Set-Content -Path $outPath -Encoding UTF8
    $generated += $outPath
    Write-Host "  [OK] data-flow.mmd" -ForegroundColor Green
}

$result = @{
    timestamp = (Get-Date -Format "o")
    dbPath = $DbPath
    outputDir = $OutputDir
    diagrams = $generated
    count = $generated.Count
}

if ($Raw) { $result | ConvertTo-Json -Depth 3; return }
Write-Host "`nGenerated $($generated.Count) diagrams in $OutputDir" -ForegroundColor Cyan
