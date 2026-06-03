<#
.SYNOPSIS
  Dual-tier semantic search wrapper for CodeGraph: FTS5 + fuzzy synonym matching.

.DESCRIPTION
  Expands a natural-language query through a synonym map, runs codegraph query
  for each expanded term, deduplicates, and scores results by relevance.

.PARAMETER Query
  Natural language query string (required). e.g. "where do we handle authentication?"

.PARAMETER MaxResults
  Maximum number of ranked results to return (default: 20).

.PARAMETER MinScore
  Minimum relevance score threshold 0-1 (default: 0.3).

.EXAMPLE
  .\scripts\codegraph\codegraph-semantic-search.ps1 -Query "where is auth handled" -MaxResults 10
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$Query,

  [int]$MaxResults = 20,

  [float]$MinScore = 0.3
)

$synonymMap = @{
  'auth'    = @('authentication', 'login', 'signin', 'credential', 'token', 'session', 'jwt', 'oauth')
  'error'   = @('exception', 'fail', 'panic', 'crash', 'bug')
  'config'  = @('configuration', 'setting', 'option', 'param', 'env')
  'db'      = @('database', 'sql', 'query', 'schema', 'table', 'mongo', 'redis', 'postgres')
  'api'     = @('endpoint', 'route', 'handler', 'controller', 'rest', 'graphql')
  'test'    = @('spec', 'unit', 'integration', 'e2e', 'mock', 'assert')
  'ui'      = @('component', 'view', 'page', 'screen', 'template', 'widget')
  'cache'   = @('memoize', 'buffer', 'store', 'temp', 'redis')
  'net'     = @('network', 'http', 'tcp', 'request', 'response', 'socket')
}

function Expand-QueryTerms {
  param([string]$RawQuery)
  $tokens = $RawQuery -split '\s+' | Where-Object { $_ -match '\w' }
  $expanded = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($t in $tokens) {
    $null = $expanded.Add($t)
    $stem = $t.ToLowerInvariant()
    if ($synonymMap.ContainsKey($stem)) {
      foreach ($s in $synonymMap[$stem]) {
        $null = $expanded.Add($s)
      }
    }
  }
  return [string[]]@($expanded)
}

function Strip-ANSI {
  param([string]$Text)
  return $Text -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
}

function Parse-CodeGraphOutput {
  param([string[]]$Lines)
  $results = @()
  $state = 0
  $current = @{}
  foreach ($rawLine in $Lines) {
    $trimmed = (Strip-ANSI -Text "$rawLine").Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
    if ($trimmed -match '^Search\s+Results\s+for') { continue }

    if ($state -eq 0 -and $trimmed -match '^(\w+)\s+(\S+)\s+\(\d+%\)') {
      $current = @{ Symbol = $matches[2]; Term = $matches[1]; }
      $state = 1
    } elseif ($state -eq 1 -and $trimmed -match '^(.+\.\w+):(\d+)$') {
      $results += @{ Symbol = $current.Symbol; File = $matches[1].Trim(); Line = $matches[2] }
      $current = @{}
      $state = 0
    }
  }
  return $results
}

function Compute-FuzzyScore {
  param([string]$Symbol, [string]$Term)
  $s = $Symbol.ToLowerInvariant()
  $t = $Term.ToLowerInvariant()
  if ($s -eq $t) { return 1.0 }
  if ($s -match [regex]::Escape($t)) { return 0.9 }
  $maxLen = [Math]::Max($s.Length, $t.Length)
  if ($maxLen -eq 0) { return 1.0 }
  $lenDiff = [Math]::Abs($s.Length - $t.Length)
  $dist = $lenDiff
  for ($i = 0; $i -lt [Math]::Min($s.Length, $t.Length); $i++) {
    if ($s[$i] -ne $t[$i]) { $dist++ }
  }
  return [Math]::Round(1.0 - ($dist / $maxLen), 4)
}

function Get-MatchType {
  param([string]$Symbol, [string]$OriginalTerm, [string]$ExpandedTerm)
  if ($Symbol -like "*$OriginalTerm*") { return 'exact' }
  if ($Symbol -like "*$ExpandedTerm*") { return 'synonym' }
  return 'fuzzy'
}

$originalTokens = $Query -split '\s+' | Where-Object { $_ -match '\w' }
$searchTerms = Expand-QueryTerms -RawQuery $Query

Write-Progress -Activity "Semantic Search" -Status "Expanded '$Query' into $($searchTerms.Count) terms" -PercentComplete 10

$rawResults = [System.Collections.ArrayList]@()
$seen = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($term in $searchTerms) {
  $lines = codegraph query $term 2>&1
  if ($LASTEXITCODE -ne 0) { continue }
  $parsed = Parse-CodeGraphOutput -Lines $lines

  foreach ($entry in $parsed) {
    $symbol = $entry.Symbol
    $file   = $entry.File
    $lineNo = $entry.Line
    $key = "$symbol|$file|$lineNo"
    if ($seen.Contains($key)) { continue }
    $null = $seen.Add($key)

    $isOriginal = ($originalTokens -contains $term)
    $score = Compute-FuzzyScore -Symbol $symbol -Term $term
    $matchType = Get-MatchType -Symbol $symbol -OriginalTerm $Query -ExpandedTerm $term

    if ($isOriginal -and $score -lt 0.8) { $score = 0.8 }
    if ($matchType -eq 'exact') { $score = [Math]::Max($score, 0.85) }
    if ($symbol -like "*$term*") { $score = [Math]::Max($score, 0.85) }

    $null = $rawResults.Add([PSCustomObject]@{
      Symbol    = $symbol
      File      = $file
      Line      = $lineNo
      Score     = $score
      MatchType = $matchType
    })
  }
}

Write-Progress -Activity "Semantic Search" -Status "Scoring and ranking $($rawResults.Count) results" -PercentComplete 70

$ranked = $rawResults | Where-Object { $_.Score -ge $MinScore } | Sort-Object Score -Descending | Select-Object -First $MaxResults
Write-Progress -Activity "Semantic Search" -Status "Complete" -PercentComplete 100 -Completed

return $ranked
