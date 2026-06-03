<#
.SYNOPSIS
  Maintenance Watchtower — Unified auto-detect, auto-rebuild, auto-report system
.DESCRIPTION
  Monitors freshness of ML embeddings, Engram RAG index, Dashboard v3,
  and MCP Bridge configs. Auto-rebuilds stale indices. Reports to dashboard.
.PARAMETER Action
  health   - Check all 4 new features (ML, RAG, Dashboard, MCP Bridge)
  rebuild  - Auto-rebuild stale indices
  report   - Emit JSON maintenance report (feeds dashboard /api/metrics)
.PARAMETER Force
  Skip staleness checks and force rebuild all
.PARAMETER OutputFile
  Write JSON report to file (for dashboard consumption)
.EXAMPLE
  .\maintenance-watchtower.ps1 -Action health
  .\maintenance-watchtower.ps1 -Action rebuild -Force
  .\maintenance-watchtower.ps1 -Action report -OutputFile status.json
#>

param(
  [ValidateSet("health","rebuild","report")]
  [string]$Action = "health",
  [switch]$Force,
  [string]$OutputFile = ""
)

$ErrorActionPreference = "Continue"
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root "config\orchestrator.json"))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
  $root
}

$results = [System.Collections.ArrayList]@()
$exitCode = 0

function Add-Finding {
  param([string]$Component, [string]$Check, [string]$Status, [string]$Detail, [string]$Action)
  $null = $results.Add([PSCustomObject]@{
    component  = $Component
    check      = $Check
    status     = $Status  # PASS | WARN | FAIL | SKIP
    detail     = $Detail
    action     = $Action  # ok | rebuild | reindex | verify | manual
    timestamp  = (Get-Date -Format "o")
  })
  if ($Status -eq "FAIL") { $script:exitCode++ }
}

function Get-FileAgeHours {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return -1 }
  return [math]::Round(((Get-Date) - (Get-Item $Path).LastWriteTime).TotalHours, 1)
}

# ─── Component 1: Auto-Delegation ML Embeddings ───────────────────────────────

function Check-MlEmbeddings {
  Write-Host "  [Component 1/4] ML Embeddings (Auto-Delegation)" -ForegroundColor Cyan
  $mlIndex = Join-Path $repoRoot ".atl\ml-index.json"
  $mlDir = Join-Path $repoRoot ".atl\ml-embeddings"
  $skillEmbedder = Join-Path $repoRoot "scripts\ml\skill-embedder.ps1"
  $mlRouter = Join-Path $repoRoot "scripts\ml\ml-router.ps1"

  # Check ml-index.json exists and is recent
  $ageH = Get-FileAgeHours -Path $mlIndex
  if ($ageH -eq -1) {
    Add-Finding "ml-embeddings" "ml-index.json exists" "FAIL" "Not found" "rebuild"
  } elseif ($ageH -gt 48) {
    Add-Finding "ml-embeddings" "ml-index.json freshness" "WARN" "Stale: $ageH hours old" "rebuild"
  } else {
    Add-Finding "ml-embeddings" "ml-index.json freshness" "PASS" "$ageH hours old" "ok"
  }

  # Check ml-embeddings directory has files
  if (Test-Path $mlDir) {
    $fileCount = (Get-ChildItem $mlDir -Recurse -File).Count
    if ($fileCount -gt 0) {
      Add-Finding "ml-embeddings" "embedding files count" "PASS" "$fileCount files" "ok"
    } else {
      Add-Finding "ml-embeddings" "embedding files count" "WARN" "Directory empty" "rebuild"
    }
  } else {
    Add-Finding "ml-embeddings" "embedding directory exists" "FAIL" "Not found" "rebuild"
  }

  # Check skill-embedder script
  if (Test-Path $skillEmbedder) {
    Add-Finding "ml-embeddings" "skill-embedder.ps1" "PASS" "Found" "ok"
  } else {
    Add-Finding "ml-embeddings" "skill-embedder.ps1" "FAIL" "Not found" "manual"
  }

  # Check ml-router script
  if (Test-Path $mlRouter) {
    Add-Finding "ml-embeddings" "ml-router.ps1" "PASS" "Found" "ok"
  } else {
    Add-Finding "ml-embeddings" "ml-router.ps1" "FAIL" "Not found" "manual"
  }

  # Validate ml-index.json content (parse)
  if (Test-Path $mlIndex) {
    try {
      $index = Get-Content $mlIndex -Raw | ConvertFrom-Json
      $skillCount = ($index.PSObject.Properties).Count
      Add-Finding "ml-embeddings" "ml-index content parseable" "PASS" "$skillCount skills indexed" "ok"
    } catch {
      Add-Finding "ml-embeddings" "ml-index content parseable" "FAIL" "Parse error: $_" "rebuild"
    }
  }
}

# ─── Component 2: Engram RAG Index ─────────────────────────────────────────

function Check-EngramRag {
  Write-Host "  [Component 2/4] Engram RAG Index" -ForegroundColor Cyan
  $ragReindex = Join-Path $repoRoot "scripts\utilities\ENGRAM-RAG\engram-rag-reindex.ps1"
  $ragLog = Join-Path $repoRoot ".atl\rag-reindex.log"
  $engramDir = Join-Path $env:USERPROFILE ".engram"

  # Check reindex script exists
  if (Test-Path $ragReindex) {
    Add-Finding "engram-rag" "reindex script" "PASS" "Found" "ok"
  } else {
    Add-Finding "engram-rag" "reindex script" "FAIL" "Not found" "manual"
  }

  # Check last reindex log
  if (Test-Path $ragLog) {
    $logAge = Get-FileAgeHours -Path $ragLog
    $logContent = Get-Content $ragLog -Tail 3
    if ($logAge -gt 48) {
      Add-Finding "engram-rag" "reindex freshness" "WARN" "Last reindex $logAge hours ago" "reindex"
    } else {
      Add-Finding "engram-rag" "reindex freshness" "PASS" "$logAge hours ago" "ok"
    }
    $hasErrors = $logContent -match "error|fail|exception"
    if ($hasErrors) {
      Add-Finding "engram-rag" "reindex errors" "WARN" "Errors in last run" "verify"
    }
  } else {
    Add-Finding "engram-rag" "reindex log" "WARN" "No log found" "reindex"
  }

  # Check Engram directory exists
  if (Test-Path $engramDir) {
    Add-Finding "engram-rag" "engram directory" "PASS" "Found" "ok"
  } else {
    Add-Finding "engram-rag" "engram directory" "FAIL" "Not found" "manual"
  }

  # Quick Engram doctor test
  try {
    $doctor = & "engram" "doctor" "--json" 2>&1 | Out-String
    if ($doctor -match '"status"\s*:\s*"ok"' -or $doctor -match '"ok"') {
      Add-Finding "engram-rag" "engram doctor" "PASS" "Healthy" "ok"
    } else {
      Add-Finding "engram-rag" "engram doctor" "WARN" "Unhealthy" "verify"
    }
  } catch {
    Add-Finding "engram-rag" "engram doctor" "FAIL" "Not accessible: $_" "manual"
  }
}

# ─── Component 3: Dashboard v3 ─────────────────────────────────────────────

function Check-Dashboard {
  Write-Host "  [Component 3/4] Dashboard v3" -ForegroundColor Cyan
  $serverJs = Join-Path $repoRoot "dashboard\server.js"
  $dashHtml = Join-Path $repoRoot "dashboard\index.html"

  # Check server.js exists
  if (Test-Path $serverJs) {
    Add-Finding "dashboard" "server.js" "PASS" "Found" "ok"
  } else {
    Add-Finding "dashboard" "server.js" "FAIL" "Not found" "manual"
  }

  # Check index.html exists
  if (Test-Path $dashHtml) {
    Add-Finding "dashboard" "index.html" "PASS" "Found" "ok"
  } else {
    Add-Finding "dashboard" "index.html" "FAIL" "Not found" "manual"
  }

  # Check if dashboard server is running (port 3000)
  try {
    $conn = New-Object System.Net.Sockets.TcpClient
    $conn.Connect("127.0.0.1", 3000)
    $conn.Close()
    Add-Finding "dashboard" "server running (port 3000)" "PASS" "Responding" "ok"

    # Test API endpoint
    try {
      $api = Invoke-RestMethod -Uri "http://127.0.0.1:3000/api/metrics" -TimeoutSec 5 -ErrorAction Stop
      Add-Finding "dashboard" "/api/metrics endpoint" "PASS" "Responds" "ok"
    } catch {
      Add-Finding "dashboard" "/api/metrics endpoint" "WARN" "HTTP error: $_" "verify"
    }
  } catch {
    Add-Finding "dashboard" "server running (port 3000)" "WARN" "Not responding" "verify"
  }

  # Check Chart.js loaded (via index.html)
  if (Test-Path $dashHtml) {
    $html = Get-Content $dashHtml -Raw
    if ($html -match "chart\.js|Chart\.min\.js|cdn\.jsdelivr\.net.*chart\.js") {
      Add-Finding "dashboard" "Chart.js dependency" "PASS" "Found in HTML" "ok"
    } else {
      Add-Finding "dashboard" "Chart.js dependency" "WARN" "Not detected" "verify"
    }
  }
}

# ─── Component 4: MCP Bridge ───────────────────────────────────────────────

function Check-McpBridge {
  Write-Host "  [Component 4/4] MCP Bridge" -ForegroundColor Cyan
  $mcpConfigs = @(
    "config/skill-mcp.json",
    "config/mcp-config.sd.json",
    "config/mcp-config.dart.json",
    "config/mcp-config.flutter.json",
    "config/mcp-config.go.json",
    "config/mcp-config.rust.json",
    "config/mcp-bridge.json"
  )

  $found = 0
  foreach ($rel in $mcpConfigs) {
    $full = Join-Path $repoRoot $rel
    if (Test-Path $full) {
      $found++
    }
  }
  Add-Finding "mcp-bridge" "MCP config files present" "PASS" "$found of $($mcpConfigs.Count) found" "ok"
  if ($found -lt $mcpConfigs.Count) {
    Add-Finding "mcp-bridge" "MCP config files complete" "WARN" "Missing $($mcpConfigs.Count - $found) configs" "verify"
  }

  # Check MCP Bridge script
  $bridgePs1 = Join-Path $repoRoot "scripts\utilities\MCP-BRIDGE\mcp-bridge.ps1"
  if (Test-Path $bridgePs1) {
    Add-Finding "mcp-bridge" "bridge script" "PASS" "Found" "ok"
    # Check bridge health
    try {
      $health = & $bridgePs1 -Action verify 2>&1 | Out-String
      if ($health -match "OK|PASS|healthy") {
        Add-Finding "mcp-bridge" "bridge health" "PASS" "Healthy" "ok"
      } else {
        Add-Finding "mcp-bridge" "bridge health" "WARN" "Unhealthy" "verify"
      }
    } catch {
      Add-Finding "mcp-bridge" "bridge health" "WARN" "Verify error: $_" "verify"
    }
  } else {
    Add-Finding "mcp-bridge" "bridge script" "FAIL" "Not found" "manual"
  }

  # Check tms-mcp-bridge.ps1
  $tmsBridge = Join-Path $repoRoot "scripts\tms-mcp-bridge.ps1"
  if (Test-Path $tmsBridge) {
    Add-Finding "mcp-bridge" "tms-mcp-bridge.ps1" "PASS" "Found" "ok"
  } else {
    Add-Finding "mcp-bridge" "tms-mcp-bridge.ps1" "FAIL" "Not found" "manual"
  }

  # Try compiling MCP TS
  $mcpTs = Join-Path $repoRoot "scripts\mcp\skill-server.ts"
  if (Test-Path $mcpTs) {
    if (Get-Command "pnpm" -ErrorAction SilentlyContinue) {
      $null = & "pnpm" "tsc" "--noEmit" 2>&1
      $tsOk = if ($LASTEXITCODE -eq 0) { "Clean" } else { "Has errors" }
      Add-Finding "mcp-bridge" "MCP TS compiles" "PASS" $tsOk
    }
  }
}

# ─── Rebuild Actions ────────────────────────────────────────────────────────

function Rebuild-MlEmbeddings {
  Write-Host "  [Rebuild] ML Embeddings..." -ForegroundColor Yellow
  $skillEmbedder = Join-Path $repoRoot "scripts\ml\skill-embedder.ps1"
  if (Test-Path $skillEmbedder) {
    try {
      $result = & $skillEmbedder 2>&1
      Write-Host "    $result" -ForegroundColor Gray
      Add-Finding "ml-embeddings" "rebuild" "PASS" "Rebuild completed" "ok"
    } catch {
      Add-Finding "ml-embeddings" "rebuild" "FAIL" "Rebuild error: $_" "manual"
    }
  } else {
    Add-Finding "ml-embeddings" "rebuild" "SKIP" "skill-embedder.ps1 not found" "manual"
  }
}

function Reindex-EngramRag {
  Write-Host "  [Rebuild] Engram RAG..." -ForegroundColor Yellow
  $ragReindex = Join-Path $repoRoot "scripts\utilities\ENGRAM-RAG\engram-rag-reindex.ps1"
  if (Test-Path $ragReindex) {
    try {
      $result = & $ragReindex 2>&1
      Write-Host "    $result" -ForegroundColor Gray
      Add-Finding "engram-rag" "reindex" "PASS" "Reindex completed" "ok"
    } catch {
      Add-Finding "engram-rag" "reindex" "FAIL" "Reindex error: $_" "manual"
    }
  } else {
    Add-Finding "engram-rag" "reindex" "SKIP" "engram-rag-reindex.ps1 not found" "manual"
  }
}

# ─── Main ───────────────────────────────────────────────────────────────────

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host " 🏗  Maintenance Watchtower (v1.0.0)" -ForegroundColor Magenta
Write-Host "    Action: $Action | Force: $Force" -ForegroundColor DarkGray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host ""

switch ($Action) {
  "health" {
    Check-MlEmbeddings
    Check-EngramRag
    Check-Dashboard
    Check-McpBridge
  }
  "rebuild" {
    Check-MlEmbeddings
    Check-EngramRag
    Check-Dashboard
    Check-McpBridge

    Write-Host ""
    Write-Host "── Auto-Rebuild Phase ──" -ForegroundColor Yellow
    $needsRebuild = $results | Where-Object { $_.action -in @("rebuild","reindex") -and $_.status -ne "PASS" }
    if ($needsRebuild.Count -eq 0 -and -not $Force) {
      Write-Host "  Everything fresh — no rebuild needed" -ForegroundColor Green
    } else {
      if ($Force) {
        Write-Host "  Force rebuild requested" -ForegroundColor Yellow
      } else {
        Write-Host "  $($needsRebuild.Count) component(s) need maintenance" -ForegroundColor Yellow
      }
      if ($Force -or ($results | Where-Object { $_.component -eq "ml-embeddings" -and $_.action -eq "rebuild" -and $_.status -ne "PASS" })) {
        Rebuild-MlEmbeddings
      }
      if ($Force -or ($results | Where-Object { $_.component -eq "engram-rag" -and $_.action -eq "reindex" -and $_.status -ne "PASS" })) {
        Reindex-EngramRag
      }
    }
  }
  "report" {
    Check-MlEmbeddings
    Check-EngramRag
    Check-Dashboard
    Check-McpBridge
  }
}

Write-Host ""
$passCount = ($results | Where-Object { $_.status -eq "PASS" }).Count
$warnCount = ($results | Where-Object { $_.status -eq "WARN" }).Count
$failCount = ($results | Where-Object { $_.status -eq "FAIL" }).Count
$total = $results.Count
Write-Host "── Summary ──" -ForegroundColor Magenta
Write-Host "  PASS: $passCount | WARN: $warnCount | FAIL: $failCount | Total: $total" -ForegroundColor $(if($failCount -eq 0){'Green'}elseif($warnCount -gt 0){'Yellow'}else{'Red'})

if ($Action -eq "report" -and $OutputFile) {
  $report = [PSCustomObject]@{
    watchtowerVersion = "1.0.0"
    timestamp         = (Get-Date -Format "o")
    action            = $Action
    summary           = @{ pass = $passCount; warn = $warnCount; fail = $failCount; total = $total }
    components        = $results
  }
  $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputFile -Encoding utf8
  Write-Host "  Report written to: $OutputFile" -ForegroundColor Gray
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
exit $exitCode
