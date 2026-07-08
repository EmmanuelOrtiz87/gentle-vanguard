param(
  [string]$Query,
  [string[]]$Sources = @('events', 'traces', 'feedback', 'checkpoints'),
  [int]$Limit = 20,
  [string]$TimeRange,
  [ValidateSet('json', 'text')]
  [string]$Format = 'text',
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$results = @()

function Add-Result($source, $id, $title, $content, $timestamp, $relevance) {
  $results += @{ source = $source; id = $id; title = $title; content = $content; timestamp = $timestamp; relevance = $relevance }
}

function Is-InTimeRange($ts) {
  if (-not $TimeRange) { return $true }
  $t = Get-Date $ts -ErrorAction SilentlyContinue
  if (-not $t) { return $true }
  if ($TimeRange -match '^-(\d+)([hd])\.\.now$') {
    $mult = @{ 'h' = 0; 'd' = 24 }[$matches[2]]
    $cutoff = (Get-Date).AddHours(-$mult * [int]$matches[1])
    return $t -ge $cutoff
  }
  return $true
}

function Score-Relevance($text) {
  if (-not $Query) { return 0.5 }
  $q = $Query.ToLower()
  $t = "$text".ToLower()
  if ($t -eq $q) { return 1.0 }
  if ($t.Contains($q)) { return 0.9 }
  $words = $q -split '\s+'
  $matchCount = ($words | Where-Object { $t.Contains($_) }).Count
  if ($words.Count -eq 0) { return 0.5 }
  return [math]::Round($matchCount / $words.Count, 2)
}

# Source: Engram (via .session/memories/ or engram CLI)
if ($Sources -contains 'engram') {
  $engramDirs = @(
    Join-Path $ROOT '.session' 'memories'
    Join-Path $ROOT '.engram'
  )
  $found = $false
  foreach ($ed in $engramDirs) {
    if (Test-Path $ed) {
      $found = $true
      Get-ChildItem -Path $ed -Recurse -Include '*.json', '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
          $txt = $content
          if (-not $Query -or $txt.ToLower().Contains($Query.ToLower())) {
            Add-Result -source 'engram' -id $_.BaseName -title $_.Name -content $txt.Substring(0, [Math]::Min(500, $txt.Length)) -timestamp $_.LastWriteTime.ToString('o') -relevance (Score-Relevance $txt)
          }
        }
      }
    }
  }
  # Fallback: context-log summaries
  if (-not $found) {
    $ctxDir = Join-Path $ROOT '.session' 'context-log'
    if (Test-Path $ctxDir) {
      Get-ChildItem -Path $ctxDir -Recurse -Filter 'context-summary.md' -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and (-not $Query -or $content.ToLower().Contains($Query.ToLower()))) {
          Add-Result -source 'engram' -id $_.Directory.Name -title "Session context" -content $content.Substring(0, [Math]::Min(500, $content.Length)) -timestamp $_.LastWriteTime.ToString('o') -relevance (Score-Relevance $content)
        }
      }
    }
  }
}

# Source: Events
if ($Sources -contains 'events') {
  $eventDir = Join-Path $ROOT '.session' 'event-store'
  if (Test-Path $eventDir) {
    Get-ChildItem -Path $eventDir -Filter '*.jsonl' | ForEach-Object {
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $evt = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($evt) {
          $txt = "$($evt.type) $($evt.aggregateId) $($evt.data | ConvertTo-Json -Compress)"
          if (-not $Query -or $txt.ToLower().Contains($Query.ToLower())) {
            Add-Result -source 'events' -id $evt.eventId -title $evt.type -content $txt -timestamp $evt.timestamp -relevance (Score-Relevance $txt)
          }
        }
      }
    }
  }
}

# Source: Traces
if ($Sources -contains 'traces') {
  $traceDir = Join-Path $ROOT '.telemetry' 'traces'
  if (Test-Path $traceDir) {
    Get-ChildItem -Path $traceDir -Filter '*.jsonl' | ForEach-Object {
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $trace = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($trace) {
          $txt = "$($trace.name) $($trace.spanId) $($trace.parentSpanId)"
          if (-not $Query -or $txt.ToLower().Contains($Query.ToLower())) {
            Add-Result -source 'traces' -id $trace.spanId -title $trace.name -content ($trace | ConvertTo-Json -Compress) -timestamp $trace.startTime -relevance (Score-Relevance $txt)
          }
        }
      }
    }
  }
}

# Source: Feedback
if ($Sources -contains 'feedback') {
  $fbDir = Join-Path $ROOT '.session' 'feedback'
  if (Test-Path $fbDir) {
    Get-ChildItem -Path $fbDir -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object {
      $fb = Get-Content $_.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
      if ($fb) {
        $txt = "$($fb.type) $($fb.message) $($fb.rating)"
        if (-not $Query -or $txt.ToLower().Contains($Query.ToLower())) {
          Add-Result -source 'feedback' -id $_.BaseName -title "$($fb.type) feedback" -content $txt -timestamp $fb.timestamp -relevance (Score-Relevance $txt)
        }
      }
    }
    Get-ChildItem -Path $fbDir -Filter '*.jsonl' -ErrorAction SilentlyContinue | ForEach-Object {
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $fb = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($fb) {
          $txt = "$($fb.type) $($fb.message) $($fb.rating)"
          if (-not $Query -or $txt.ToLower().Contains($Query.ToLower())) {
            Add-Result -source 'feedback' -id "$($_.BaseName)-$($fb.id)" -title "$($fb.type) feedback" -content $txt -timestamp $fb.timestamp -relevance (Score-Relevance $txt)
          }
        }
      }
    }
  }
}

# Source: Checkpoints
if ($Sources -contains 'checkpoints') {
  $ckptDir = Join-Path $ROOT '.session' 'checkpoints'
  if (Test-Path $ckptDir) {
    Get-ChildItem -Path $ckptDir -Directory | ForEach-Object {
      $manifest = Join-Path $ROOT '.session' 'manifests' "$($_.Name).json"
      $label = ''
      $ts = $_.LastWriteTime.ToString('o')
      if (Test-Path $manifest) {
        $m = Get-Content $manifest -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($m) { $label = $m.label; $ts = $m.createdAt }
      }
      $txt = "checkpoint $($_.Name) $label"
      if (-not $Query -or $txt.ToLower().Contains($Query.ToLower())) {
        Add-Result -source 'checkpoints' -id $_.Name -title "Checkpoint: $label" -content $txt -timestamp $ts -relevance (Score-Relevance $txt)
      }
    }
  }
}

# Filter by time range
if ($TimeRange) {
  $global:tr = $TimeRange
  $results = $results | Where-Object { Is-InTimeRange $_.timestamp }
}

# Sort by relevance desc, timestamp desc
$results = $results | Sort-Object { $_.relevance }, { $_.timestamp } -Descending | Select-Object -First $Limit

# Output
if ($Format -eq 'json') {
  $output = @{ query = $Query; sources = $Sources; total = $results.Count; results = $results }
  $output | ConvertTo-Json -Depth 5
} else {
  if ($results.Count -eq 0) { Write-Host "No results found for query: $Query" -ForegroundColor Yellow; return }
  Write-Host "Knowledge Query: '$Query'" -ForegroundColor Cyan
  Write-Host "Sources: $($Sources -join ', ')" -ForegroundColor Gray
  Write-Host "Results: $($results.Count)" -ForegroundColor Gray
  Write-Host ''
  $results | ForEach-Object {
    $color = @{ events = 'DarkCyan'; traces = 'Magenta'; feedback = 'Green'; checkpoints = 'Yellow'; engram = 'Red' }[$_.source]
    Write-Host "[$($_.source.ToUpper())] $($_.title)" -ForegroundColor $color
    Write-Host "  ID: $($_.id)" -ForegroundColor Gray
    Write-Host "  Time: $($_.timestamp)" -ForegroundColor Gray
    Write-Host "  Relevance: $($_.relevance)" -ForegroundColor Gray
    Write-Host "  $($_.content)" -ForegroundColor White
    Write-Host ''
  }
}
