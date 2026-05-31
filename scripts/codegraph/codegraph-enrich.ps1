<#
.SYNOPSIS
  Enriches CodeGraph query output with layer detection, complexity tags, and metadata.

.DESCRIPTION
  Wraps codegraph query and augments each result with file stats,
  caller count, complexity tag, and architectural layer classification.

.PARAMETER Query
  CodeGraph query string to search for symbols.

.PARAMETER EnrichLevel
  Enrichment depth: 'light' (default) adds layer + complexity;
  'full' also fetches file size, last modified, and caller count.

.EXAMPLE
  .\scripts\codegraph\codegraph-enrich.ps1 -Query "session" -EnrichLevel full
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$Query,

  [ValidateSet('light', 'full')]
  [string]$EnrichLevel = 'light'
)

function Get-Layer {
  param([string]$FilePath)
  $p = $FilePath.ToLowerInvariant()
  $rules = @(
    @{ pattern = '(api|route|endpoint|controller|handler)';  layer = 'API' },
    @{ pattern = '(service|logic|manager|engine|core)';       layer = 'Service' },
    @{ pattern = '(model|schema|entity|repository|db|database|sql)'; layer = 'Data' },
    @{ pattern = '(component|view|page|ui|screen)';          layer = 'UI' },
    @{ pattern = '(util|helper|common|shared|types|config)';  layer = 'Utility' }
  )
  foreach ($r in $rules) {
    if ($p -match $r.pattern) { return $r.layer }
  }
  return 'Other'
}

function Get-ComplexityTag {
  param([int]$LineCount)
  if ($LineCount -le 50)  { return 'simple' }
  if ($LineCount -le 200) { return 'moderate' }
  return 'complex'
}

function Get-CallersCount {
  param([string]$Symbol)
  $output = codegraph callers $Symbol 2>&1
  if ($LASTEXITCODE -ne 0) { return 0 }
  $lines = @($output | Where-Object { "$_".Trim() -ne '' })
  return $lines.Count
}

function Strip-ANSI {
  param([string]$Text)
  return $Text -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
}

$rawOutput = codegraph query $Query 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Warning "codegraph query failed for: $Query"
  return @()
}

$results = [System.Collections.ArrayList]@()
$state = 0
$current = @{}
$symbolPattern = '^\w+\s+\S+\s+\(\d+%\)$'

foreach ($rawLine in $rawOutput) {
  $line = Strip-ANSI -Text "$rawLine"
  $trimmed = $line.Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }

  # Skip header: "Search Results for..."
  if ($trimmed -match '^Search\s+Results\s+for') { continue }

  if ($state -eq 0) {
    # Looking for: <type>  <symbol>  (<score>%)
    if ($trimmed -match '^(\w+)\s+(\S+)\s+\(\d+%\)') {
      $current = @{
        Symbol = $matches[2]
        Kind   = $matches[1]
      }
      $state = 1
    }
  } elseif ($state -eq 1) {
    # Looking for file:line
    if ($trimmed -match '^(.+\.\w+):(\d+)$') {
      $current.FilePath = $matches[1].Trim()
      $current.LineNo = $matches[2]
      $state = 2
    }
  } elseif ($state -eq 2) {
    # Got file:line - now wait for next symbol or end
    $filePath = $current.FilePath
    $lineNo = $current.LineNo
    $symbol = $current.Symbol
    $kind = $current.Kind

    $layer = Get-Layer -FilePath $filePath
    $isFull = ($EnrichLevel -eq 'full')
    $obj = [PSCustomObject]@{
      Symbol   = $symbol
      Kind     = $kind
      File     = $filePath
      Line     = $lineNo
      Layer    = $layer
      Complexity = if ($isFull) { 'pending' } else { 'N/A' }
      FileSizeKB   = if ($isFull) { 0 } else { $null }
      LastModified = if ($isFull) { $null } else { $null }
      CallersCount = if ($isFull) { 0 } else { $null }
    }

    if ($isFull -and -not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path -LiteralPath $filePath -ErrorAction SilentlyContinue)) {
      $fi = Get-Item -LiteralPath $filePath
      $lc = @(Get-Content -LiteralPath $filePath -ErrorAction SilentlyContinue).Count
      $obj.Complexity  = Get-ComplexityTag -LineCount $lc
      $obj.FileSizeKB  = [Math]::Round($fi.Length / 1KB, 2)
      $obj.LastModified = $fi.LastWriteTime
      $obj.CallersCount = Get-CallersCount -Symbol $symbol
    }

    $null = $results.Add($obj)
    $current = @{}
    $state = 0
  }
}

return $results
