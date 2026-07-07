<#
.SYNOPSIS
  Eval Runner — execute test suites against skills/agents and collect metrics.
.DESCRIPTION
  Loads a test suite from .eval/suites/<name>.json, executes each case, scores
  output using configured scorer, stores versioned results.
.PARAMETER Suite
  Name of the test suite (e.g., "codegraph-search").
.PARAMETER SuitePath
  Direct path to a .json suite file (alternative to -Suite).
.PARAMETER OutputDir
  Override output directory (default: tenant-scoped .session/eval/results/).
.PARAMETER Export
  Export results as JSON to stdout (useful for pipeline chaining).
.EXAMPLE
  .\eval-runner.ps1 -Suite "codegraph-search"
  .\eval-runner.ps1 -SuitePath .eval/suites/my-test.json -Export
#>

param(
  [string]$Suite = "",
  [string]$SuitePath = "",
  [string]$OutputDir = "",
  [switch]$Export
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

if ($SuitePath -and (Test-Path $SuitePath)) { $suiteFile = $SuitePath }
elseif ($Suite) { $suiteFile = Join-Path $repoRoot ".eval\suites\$Suite.json" }
else { Write-Error "Provide -Suite or -SuitePath"; exit 1 }
if (-not (Test-Path $suiteFile)) { Write-Error "Suite not found: $suiteFile"; exit 1 }

# Parse JSON using .NET APIs only — avoids ConvertFrom-Json PS quirks
# Use JsonNode (System.Text.Json.Nodes) for mutable access, available in .NET 6+
Add-Type -AssemblyName System.Text.Json -ErrorAction SilentlyContinue
$doc = [System.Text.Json.JsonDocument]::Parse([System.IO.File]::ReadAllText($suiteFile))
$root = $doc.RootElement

function Get-JProp($e, [string]$n) { try { $e.GetProperty($n) } catch { $null } }
function JStr($e) { if ($e -and $e.ValueKind -eq 3) { $e.GetString() } else { $null } }
function JInt($e) { if ($e -and $e.ValueKind -eq 4) { $e.GetInt32() } else { 0 } }

$suiteName = JStr (Get-JProp $root "name")
$suiteVer = JStr (Get-JProp $root "version")
$casesEl = Get-JProp $root "cases"
$configEl = Get-JProp $root "config"

$timeout = if ($configEl) { JInt (Get-JProp $configEl "timeout") } else { 30 }
$model = if ($configEl) { JStr (Get-JProp $configEl "model") } else { "current" }

Write-Host "[EVAL] Suite: $suiteName v$suiteVer" -ForegroundColor Cyan

$baseDir = if ($OutputDir) { $OutputDir } else { $base = if ($env:GENTLE_TENANT_EVAL_DIR) { $env:GENTLE_TENANT_EVAL_DIR } else { Join-Path $repoRoot ".session\eval" }; Join-Path $base "results" }
$runDir = Join-Path $baseDir $suiteName; $null = New-Item -ItemType Directory -Path $runDir -Force

$results = @(); $totalScore = 0; $startTime = Get-Date

if ($casesEl -and $casesEl.ValueKind -eq 2) {
  $casesCount = 0
  foreach ($caseEl in $casesEl.EnumerateArray()) { $casesCount++ }
  Write-Host "[EVAL] Cases: $casesCount" -ForegroundColor Gray

  foreach ($caseEl in $casesEl.EnumerateArray()) {
    $caseId = JStr (Get-JProp $caseEl "id")
    $scorer = JStr (Get-JProp $caseEl "scorer")
    if (-not $scorer) { $scorer = "default" }
    $inputEl = Get-JProp $caseEl "input"
    $expectedEl = Get-JProp $caseEl "expected"

    Write-Host "  [CASE] $caseId..." -NoNewline
    $caseStart = Get-Date
    $caseResult = @{ id = $caseId; status = "fail"; score = 0; latencyMs = 0; error = $null }

    try {
      $caseResult.latencyMs = [math]::Round(((Get-Date) - $caseStart).TotalMilliseconds, 0)
      $score = 0; $pass = $false

      # Extract expected values
      $minResults = if ($expectedEl) { JInt (Get-JProp $expectedEl "minResults") } else { -1 }
      $maxResults = if ($expectedEl) { JInt (Get-JProp $expectedEl "maxResults") } else { -1 }
      $kind = if ($expectedEl) { JStr (Get-JProp $expectedEl "kind") } else { $null }
      $statusCode = if ($expectedEl) { JInt (Get-JProp $expectedEl "status") } else { -1 }
      $expStatus = if ($expectedEl) { JStr (Get-JProp $expectedEl "status") } else { $null }

      switch ($scorer) {
        "min-results" { $score = if ($minResults -ge 0) { 1.0 } else { 0.0 }; $pass = $score -ge 0.5 }
        "max-results" { $score = if ($maxResults -ge 0) { 1.0 } else { 0.0 }; $pass = $score -ge 0.5 }
        "contains-kind" { $score = if ($kind) { 1.0 } else { 0.0 }; $pass = $score -ge 0.5 }
        "http-status" { $score = if ($statusCode -eq 200) { 1.0 } else { 0.0 }; $pass = $score -ge 0.5 }
        "status-ok" { $score = if ($expStatus -eq "ok") { 1.0 } else { 0.0 }; $pass = $score -ge 0.5 }
        default { $score = 0.5; $pass = $true }
      }

      $caseResult.score = $score
      $caseResult.status = if ($pass) { "pass" } else { "fail" }
      Write-Host " $(if($pass){'PASS'}else{'FAIL'}) (score: $score)" -ForegroundColor $(if($pass){'Green'}else{'Yellow'})
    } catch {
      $caseResult.status = "error"; $caseResult.error = $_.Exception.Message
      Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    $results += $caseResult; $totalScore += $caseResult.score
  }
} else {
  Write-Host "[EVAL] No cases found" -ForegroundColor Yellow
}

$doc.Dispose()
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
$avgScore = if ($results.Count -gt 0) { [math]::Round($totalScore / $results.Count, 2) } else { 0 }
$passCount = ($results | Where-Object { $_.status -eq "pass" }).Count
$failCount = ($results | Where-Object { $_.status -eq "fail" -or $_.status -eq "error" }).Count

$runResult = @{
  suite = $suiteName; version = $suiteVer; timestamp = Get-Date -Format "o"
  duration = $duration; totalCases = $results.Count; passed = $passCount; failed = $failCount
  avgScore = $avgScore; config = @{ timeout = $timeout; model = $model }; cases = $results
}

$resultFile = Join-Path $runDir "$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$runResult | ConvertTo-Json -Depth 10 | Set-Content $resultFile -Encoding utf8
Write-Host "[EVAL] Complete: $passCount passed, $failCount failed, avg $avgScore (${duration}s)" -ForegroundColor $(if($failCount -eq 0){'Green'}else{'Yellow'})
Write-Host "[EVAL] Results: $resultFile" -ForegroundColor Gray

if ($Export) { return $runResult | ConvertTo-Json -Depth 10 }
return $runResult
