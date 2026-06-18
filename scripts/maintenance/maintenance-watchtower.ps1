<#
.SYNOPSIS
  Maintenance Watchtower — Orquestador central de health checks, auto-healing y monitoreo continuo
.DESCRIPTION
  Unifica maintenance-watchtower.ps1 + health-check.ps1 + stack-health-check.ps1 en un solo
  orquestador. Verifica todos los componentes del stack, auto-repara componentes caídos,
  y puede ejecutarse en modo continuo como daemon.

  Integra componentes:
  - Dashboard WS server (watchdog + health)
  - MCP Server + Bridge
  - Engram (integridad + RAG)
  - ML Embeddings
  - CodeGraph index
  - Session pipeline
  - Configs, hooks, tool configs
  - Security
  - Governance

.PARAMETER Action
  health     - Check all components (default)
  rebuild    - Health check + auto-rebuild stale indices
  report     - Health check + JSON report
  autoheal   - Health check + auto-restart failed components
  continuous - Loop continuo con health + autoheal cada N segundos
  all        - Health + rebuild + autoheal (completo)

.PARAMETER Interval
  Segundos entre ciclos en modo continuous (default: 60)

.PARAMETER OutputFile
  Ruta para JSON report en modo report

.PARAMETER Force
  Skip freshness checks, force rebuild all

.PARAMETER Quiet
  Minimal output

.EXAMPLE
  .\maintenance-watchtower.ps1 -Action health
  .\maintenance-watchtower.ps1 -Action autoheal
  .\maintenance-watchtower.ps1 -Action continuous -Interval 30
  .\maintenance-watchtower.ps1 -Action report -OutputFile status.json
#>

param(
  [ValidateSet("health","rebuild","report","autoheal","continuous","all")]
  [string]$Action = "health",
  [int]$Interval = 60,
  [string]$OutputFile = "",
  [switch]$Force,
  [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$script:exitCode = 0
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root "config\orchestrator.json"))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
  $root
}

$results = [System.Collections.ArrayList]@()

# ─── Helpers ────────────────────────────────────────────────────────────────

function Log {
  param([string]$M, [string]$C = "White")
  if (-not $Quiet) { Write-Host $M -ForegroundColor $C }
}

function Add-Finding {
  param([string]$Component, [string]$Check, [string]$Status, [string]$Detail, [string]$Action, [switch]$Critical)
  $null = $results.Add([PSCustomObject]@{
    component  = $Component
    check      = $Check
    status     = $Status
    detail     = $Detail
    action     = $Action
    timestamp  = (Get-Date -Format "o")
  })
  if ($Status -eq "FAIL" -and $Critical) { $script:exitCode++ }
}

function Get-FileAgeHours {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return -1 }
  return [math]::Round(((Get-Date) - (Get-Item $Path).LastWriteTime).TotalHours, 1)
}

function Test-Port {
  param([int]$Port)
  try {
    $conn = New-Object System.Net.Sockets.TcpClient
    $conn.Connect("127.0.0.1", $Port)
    $conn.Close()
    return $true
  } catch { return $false }
}

function Test-Http {
  param([string]$Url)
  try {
    $r = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    return $r.StatusCode -eq 200
  } catch { return $false }
}

# ─── Component: Dashboard WS ────────────────────────────────────────────────

function Check-DashboardWs {
  Log "  [Dashboard WS] Checking..." Cyan
  $ports = $null
  $portsFile = Join-Path $repoRoot ".runtime" "dashboard-ports.json"
  if (Test-Path $portsFile) { $ports = Get-Content $portsFile -Raw | ConvertFrom-Json }

  $wsPort = if ($ports -and $ports.wsPort) { $ports.wsPort } else { 8080 }
  $pidFile = Join-Path $repoRoot ".runtime" "dashboard-ws.pid"
  $running = Test-Port -Port $wsPort
  $httpOk = Test-Http -Url "http://127.0.0.1:$wsPort/api/metrics"

  if ($httpOk) {
    Add-Finding "dashboard-ws" "HTTP API (port $wsPort)" "PASS" "Responding" "ok"
  } elseif ($running) {
    Add-Finding "dashboard-ws" "HTTP API (port $wsPort)" "WARN" "Port open but HTTP not responding" "verify"
  } else {
    Add-Finding "dashboard-ws" "HTTP API (port $wsPort)" "FAIL" "Not responding" "restart"
  }

  $watchdogPid = $null
  $wPidFile = Join-Path $repoRoot ".runtime" "dashboard-ws-watchdog.pid"
  if (Test-Path $wPidFile) {
    $watchdogPid = (Get-Content $wPidFile -Raw).Trim()
    $wAlive = Get-Process -Id $watchdogPid -ErrorAction SilentlyContinue
    if ($wAlive) {
      Add-Finding "dashboard-ws" "watchdog process" "PASS" "PID $watchdogPid running" "ok"
    } else {
      Add-Finding "dashboard-ws" "watchdog process" "FAIL" "PID $watchdogPid not running" "restart"
    }
  } else {
    Add-Finding "dashboard-ws" "watchdog process" "WARN" "No PID file" "start"
  }

  $wsPid = $null
  if (Test-Path $pidFile) {
    $wsPid = (Get-Content $pidFile -Raw).Trim()
    $alive = Get-Process -Id $wsPid -ErrorAction SilentlyContinue
    if ($alive) {
      Add-Finding "dashboard-ws" "WS server process" "PASS" "PID $wsPid running" "ok"
    } else {
      Add-Finding "dashboard-ws" "WS server process" "FAIL" "PID $wsPid not running" "restart"
    }
  } else {
    Add-Finding "dashboard-ws" "WS server process" "WARN" "No PID file" "start"
  }

  Add-Finding "dashboard-ws" "build (dist/index.html)" "$(if(Test-Path (Join-Path $repoRoot 'apps/web-dashboard/dist/index.html')){'PASS'}else{'FAIL'})" "" "ok"
}

# ─── Component: CodeGraph ───────────────────────────────────────────────────

function Check-CodeGraph {
  Log "  [CodeGraph] Checking..." Cyan
  $cgPid = $null
  $nodeProcs = Get-Process -Name "node" -ErrorAction SilentlyContinue
  $cgRunning = $false
  foreach ($p in $nodeProcs) {
    try {
      $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue).CommandLine
      if ($cmd -match "codegraph.*serve|codegraph.*mcp") { $cgRunning = $true; $cgPid = $p.Id; break }
    } catch {}
  }
  if ($cgRunning) {
    Add-Finding "codegraph" "server process" "PASS" "PID $cgPid running" "ok"
  } else {
    Add-Finding "codegraph" "server process" "WARN" "Not running (MCP mode)" "verify"
  }
  $indexOk = Test-Path (Join-Path $repoRoot ".codegraph" "codegraph.db")
  Add-Finding "codegraph" "index database" "$(if($indexOk){'PASS'}else{'FAIL'})" "" "rebuild"
}

# ─── Component: ML Embeddings ───────────────────────────────────────────────

function Check-MlEmbeddings {
  Log "  [ML Embeddings] Checking..." Cyan
  $mlIndex = Join-Path $repoRoot ".atl\ml-index.json"
  $mlDir = Join-Path $repoRoot ".atl\ml-embeddings"
  $skillEmbedder = Join-Path $repoRoot "scripts\utilities\agents\AUTO-DELEGATION\skill-embedder.ps1"
  $mlRouter = Join-Path $repoRoot "scripts\utilities\agents\AUTO-DELEGATION\ml-router.ps1"

  $ageH = Get-FileAgeHours -Path $mlIndex
  if ($ageH -eq -1) {
    Add-Finding "ml-embeddings" "ml-index.json" "FAIL" "Not found" "rebuild"
  } elseif ($ageH -gt 48) {
    Add-Finding "ml-embeddings" "ml-index.json freshness" "WARN" "Stale: $ageH hours" "rebuild"
  } else {
    Add-Finding "ml-embeddings" "ml-index.json freshness" "PASS" "$ageH hours" "ok"
  }

  if (Test-Path $mlDir) {
    $fc = (Get-ChildItem $mlDir -Recurse -File).Count
    Add-Finding "ml-embeddings" "embedding files" "$(if($fc -gt 0){'PASS'}else{'WARN'})" "$fc files" "rebuild"
  } else {
    Add-Finding "ml-embeddings" "embedding directory" "FAIL" "Not found" "rebuild"
  }

  foreach ($s in @($skillEmbedder, $mlRouter)) {
    $name = Split-Path $s -Leaf
    Add-Finding "ml-embeddings" "$name" "$(if(Test-Path $s){'PASS'}else{'FAIL'})" "" "manual"
  }

  if (Test-Path $mlIndex) {
    try { $idx = Get-Content $mlIndex -Raw | ConvertFrom-Json; $cnt = ($idx.PSObject.Properties).Count; Add-Finding "ml-embeddings" "index parseable" "PASS" "$cnt skills" "ok" }
    catch { Add-Finding "ml-embeddings" "index parseable" "FAIL" "Parse error" "rebuild" -Critical }
  }
}

# ─── Component: Engram ──────────────────────────────────────────────────────

function Check-Engram {
  Log "  [Engram] Checking..." Cyan
  $ragReindex = Join-Path $repoRoot "scripts\utilities\memory\ENGRAM-RAG\engram-rag-reindex.ps1"
  $ragLog = Join-Path $repoRoot ".atl\rag-reindex.log"
  $engramDir = Join-Path $env:USERPROFILE ".engram"

  Add-Finding "engram" "reindex script" "$(if(Test-Path $ragReindex){'PASS'}else{'FAIL'})" "" "manual"

  if (Test-Path $ragLog) {
    $logAge = Get-FileAgeHours -Path $ragLog
    $lc = Get-Content $ragLog -Tail 3
    Add-Finding "engram" "reindex freshness" "$(if($logAge -le 48){'PASS'}else{'WARN'})" "$logAge hours" "reindex"
    if ($lc -match "error|fail|exception") { Add-Finding "engram" "reindex errors" "WARN" "Errors in last run" "verify" }
  } else {
    Add-Finding "engram" "reindex log" "WARN" "Not found" "reindex"
  }

  Add-Finding "engram" "engram directory" "$(if(Test-Path $engramDir){'PASS'}else{'FAIL'})" "" "manual"

  try {
    $doctor = & "engram" "doctor" "--json" 2>&1 | Out-String
    $ok = $doctor -match '"status"\s*:\s*"ok"' -or $doctor -match '"ok"'
    Add-Finding "engram" "doctor" "$(if($ok){'PASS'}else{'WARN'})" "Healthy=$ok" "verify"
  } catch {
    Add-Finding "engram" "doctor" "FAIL" "Not accessible: $_" "manual" -Critical
  }
}

# ─── Component: MCP ─────────────────────────────────────────────────────────

function Check-Mcp {
  Log "  [MCP] Checking..." Cyan
  $mcpJs = Join-Path $repoRoot "dist/scripts/mcp/skill-server.js"
  $mcpTs = Join-Path $repoRoot "scripts/mcp/skill-server.ts"
  $bridgePs1 = Join-Path $repoRoot "scripts\mcp-bridge\mcp-bridge.ps1"
  $bridgeTs = Join-Path $repoRoot "apps\web-dashboard\server\mcp-bridge.ts"
  $mcpConfigs = @("config/skill-mcp.json","config/mcp-bridge.json","config/mcp-config.sd.json")

  Add-Finding "mcp" "skill-server.js" "$(if(Test-Path $mcpJs){'PASS'}else{'FAIL'})" "" "build"
  Add-Finding "mcp" "skill-server.ts" "$(if(Test-Path $mcpTs){'PASS'}else{'FAIL'})" "" "manual"
  Add-Finding "mcp" "mcp-bridge.ps1" "$(if(Test-Path $bridgePs1){'PASS'}else{'FAIL'})" "" "manual"
  Add-Finding "mcp" "mcp-bridge.ts (dashboard)" "$(if(Test-Path $bridgeTs){'PASS'}else{'WARN'})" "" "manual"

  $found = ($mcpConfigs | Where-Object { Test-Path (Join-Path $repoRoot $_) }).Count
  Add-Finding "mcp" "config files" "$(if($found -eq $mcpConfigs.Count){'PASS'}else{'WARN'})" "$found of $($mcpConfigs.Count)" "verify"

  try {
    $health = & $bridgePs1 -Action verify 2>&1
    $healthOk = ($health -match 'OK|PASS|healthy|Bridge status: OK|^True$')
    Add-Finding "mcp" "bridge health" "$(if($healthOk){'PASS'}else{'WARN'})" "" "verify"
  } catch { Add-Finding "mcp" "bridge health" "WARN" "Not accessible" "verify" }
}

# ─── Component: Session Pipeline ────────────────────────────────────────────

function Check-SessionPipeline {
  Log "  [Session] Checking..." Cyan
  $scripts = @(
    "scripts/utilities/session-start-optimized.ps1",
    "scripts/utilities/session-manager.ps1",
    "scripts/utilities/pre-process-input.ps1",
    "scripts/utilities/session/session-start-optimized.ps1",
    "scripts/utilities/session/session-cleanup-start.ps1"
  )
  foreach ($s in $scripts) {
    $name = Split-Path $s -Leaf
    Add-Finding "session" "$name" "$(if(Test-Path (Join-Path $repoRoot $s)){'PASS'}else{'FAIL'})" "" "manual"
  }
  $configOk = Test-Path (Join-Path $repoRoot "config/session-autostart.config.json")
  Add-Finding "session" "autostart config" "$(if($configOk){'PASS'}else{'FAIL'})" "" "manual"
}

# ─── Component: Git Hooks ───────────────────────────────────────────────────

function Check-Hooks {
  Log "  [Hooks] Checking..." Cyan
  Add-Finding "hooks" ".lefthook.yml" "$(if(Test-Path (Join-Path $repoRoot '.lefthook.yml')){'PASS'}else{'FAIL'})" "" "manual"
  try {
    $null = & "lefthook" "validate" 2>&1
    Add-Finding "hooks" "lefthook validate" "$(if($LASTEXITCODE -eq 0){'PASS'}else{'FAIL'})" "" "manual"
  } catch { Add-Finding "hooks" "lefthook validate" "FAIL" "Not installed" "manual" }
}

# ─── Component: Configs ─────────────────────────────────────────────────────

function Check-Configs {
  Log "  [Configs] Checking..." Cyan
  $configs = @(
    "config/orchestrator.json","config/auto-delegation.json","config/session-autostart.config.json",
    "config/security-policy.json","config/trusted-users-policy.json",
    "config/security-privacy.json","config/sre-error-budgets.json",
    "config/dashboard-alerts.json","opencode.json","renovate.json"
  )
  foreach ($cfg in $configs) {
    $full = Join-Path $repoRoot $cfg
    if (Test-Path $full) {
      try { $null = Get-Content $full -Raw | ConvertFrom-Json; Add-Finding "configs" $cfg "PASS" "" "ok" }
      catch { Add-Finding "configs" $cfg "FAIL" "Invalid JSON" "fix" -Critical }
    } else {
      Add-Finding "configs" $cfg "WARN" "Not found" "manual"
    }
  }
}

# ─── Component: Tool Configs ────────────────────────────────────────────────

function Check-ToolConfigs {
  Log "  [Tool Configs] Checking..." Cyan
  $files = @("CLAUDE.md","AGENTS.md",".clinerules",".cursorrules","SECURITY.md",".nvmrc",".node-version")
  foreach ($f in $files) {
    Add-Finding "tool-configs" $f "$(if(Test-Path (Join-Path $repoRoot $f)){'PASS'}else{'WARN'})" "" "manual"
  }
  $windsurfCfg = Join-Path $repoRoot ".windsurf/config.json"
  if (Test-Path $windsurfCfg) {
    try { $null = Get-Content $windsurfCfg -Raw | ConvertFrom-Json; Add-Finding "tool-configs" ".windsurf/config.json" "PASS" "" "ok" }
    catch { Add-Finding "tool-configs" ".windsurf/config.json" "FAIL" "Invalid JSON" "fix" }
  } else {
    Add-Finding "tool-configs" ".windsurf/config.json" "WARN" "Not found" "manual"
  }
}

# ─── Component: Security ────────────────────────────────────────────────────

function Check-Security {
  Log "  [Security] Checking..." Cyan
  $secFiles = @(
    "config/owner-auth.json.enc","config/owner-auth.json.integrity",
    "scripts/security/privacy-gateway.ps1","scripts/security/security-orchestrator.ps1",
    "SECURITY.md",".github/CODEOWNERS",".github/dependabot.yml"
  )
  foreach ($f in $secFiles) {
    Add-Finding "security" $f "$(if(Test-Path (Join-Path $repoRoot $f)){'PASS'}else{'WARN'})" "" "manual"
  }
}

# ─── Component: Governance ──────────────────────────────────────────────────

function Check-Governance {
  Log "  [Governance] Checking..." Cyan
  $govFiles = @(
    "rules/NORMATIVAS-PERFORMANCE.md","rules/SDD-STRICT-TDD.md","rules/PER-PHASE-MODEL-ROUTING.md",
    "openspec/config.yaml","rules/NORMATIVA-PNPM-SECURITY.md"
  )
  foreach ($f in $govFiles) {
    Add-Finding "governance" $f "$(if(Test-Path (Join-Path $repoRoot $f)){'PASS'}else{'WARN'})" "" "manual"
  }
  try {
    $pv = (Get-Module -ListAvailable Pester | Where-Object { $_.Version -ge [version]'5.0.0' }).Version
    Add-Finding "governance" "Pester >= 5.0" "$(if($pv){'PASS'}else{'FAIL'})" "v$($pv)" "install"
  } catch { Add-Finding "governance" "Pester >= 5.0" "FAIL" "Not found" "install" }
}

# ─── Rebuild Actions ────────────────────────────────────────────────────────

function Rebuild-MlEmbeddings {
  Log "  [Rebuild] ML Embeddings..." Yellow
  $skillEmbedder = Join-Path $repoRoot "scripts\utilities\agents\AUTO-DELEGATION\skill-embedder.ps1"
  if (Test-Path $skillEmbedder) {
    try { $r = & $skillEmbedder 2>&1; Add-Finding "ml-embeddings" "rebuild" "PASS" "Completed" "ok" }
    catch { Add-Finding "ml-embeddings" "rebuild" "FAIL" "Error: $_" "manual" -Critical }
  } else {
    Add-Finding "ml-embeddings" "rebuild" "SKIP" "Not found" "manual"
  }
}

function Reindex-EngramRag {
  Log "  [Rebuild] Engram RAG..." Yellow
  $ragReindex = Join-Path $repoRoot "scripts\utilities\memory\ENGRAM-RAG\engram-rag-reindex.ps1"
  if (Test-Path $ragReindex) {
    try { $r = & $ragReindex 2>&1; Add-Finding "engram" "reindex" "PASS" "Completed" "ok" }
    catch { Add-Finding "engram" "reindex" "FAIL" "Error: $_" "manual" -Critical }
  } else {
    Add-Finding "engram" "reindex" "SKIP" "Not found" "manual"
  }
}

# ─── Auto-Heal ──────────────────────────────────────────────────────────────

function AutoHeal {
  Log "`n── Auto-Heal Phase ──" Yellow
  $needsRestart = $results | Where-Object { $_.action -eq "restart" -and $_.status -ne "PASS" }
  $needsStart   = $results | Where-Object { $_.action -eq "start" -and $_.status -ne "PASS" }
  $healed = 0; $failed = 0

  if ($needsRestart.Count -eq 0 -and $needsStart.Count -eq 0) {
    Log "  No components need healing" Green; return
  }

  # Dashboard WS server restart
  $dashFail = $needsRestart + $needsStart | Where-Object { $_.component -eq "dashboard-ws" }
  if ($dashFail) {
    Log "  [Heal] Restarting Dashboard WS server..." Yellow
    $wsAutostart = Join-Path $PSScriptRoot "..\utilities\dashboard\dashboard-ws-autostart.ps1"
    if (Test-Path $wsAutostart) {
      try {
        $p = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", $wsAutostart, "-Quiet" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 5
        if (-not $p.HasExited) {
          Log "    PID $($p.Id) started" Green
          Add-Finding "dashboard-ws" "autoheal" "PASS" "Restarted PID $($p.Id)" "ok"
          $healed++
        } else {
          Log "    Process exited immediately" Red
          Add-Finding "dashboard-ws" "autoheal" "FAIL" "Restart failed" "manual" -Critical
          $failed++
        }
      } catch {
        Log "    Error: $_" Red
        Add-Finding "dashboard-ws" "autoheal" "FAIL" "Error: $_" "manual" -Critical
        $failed++
      }
    } else {
      Log "    dashboard-ws-autostart.ps1 not found" Red
      $failed++
    }
  }

  # CodeGraph server restart
  $cgFail = $needsRestart | Where-Object { $_.component -eq "codegraph" }
  if ($cgFail) {
    Log "  [Heal] Restarting CodeGraph serve..." Yellow
    try {
      $p = Start-Process -FilePath "npx.cmd" -ArgumentList "codegraph", "serve", "--mcp" -WindowStyle Hidden -PassThru
      Start-Sleep -Seconds 3
      if (-not $p.HasExited) {
        Log "    PID $($p.Id) started" Green
        Add-Finding "codegraph" "autoheal" "PASS" "Restarted PID $($p.Id)" "ok"
        $healed++
      } else {
        Log "    Process exited" Red; $failed++
      }
    } catch { Log "    Error: $_" Red; $failed++ }
  }

  Log "  Healed: $healed | Failed: $failed" $(if($failed -eq 0){'Green'}else{'Red'})
}

# ─── Summary ────────────────────────────────────────────────────────────────

function Show-Summary {
  Log "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta
  $pass = ($results | Where-Object { $_.status -eq "PASS" }).Count
  $warn = ($results | Where-Object { $_.status -eq "WARN" }).Count
  $fail = ($results | Where-Object { $_.status -eq "FAIL" }).Count
  $skip = ($results | Where-Object { $_.status -eq "SKIP" }).Count
  $total = $results.Count
  Log "  PASS: $pass | WARN: $warn | FAIL: $fail | SKIP: $skip | Total: $total" $(if($fail -eq 0){'Green'}elseif($warn -gt 0){'Yellow'}else{'Red'})

  $byComponent = $results | Group-Object component | ForEach-Object {
    $fails = @($_.Group | Where-Object { $_.status -eq "FAIL" }).Count
    [PSCustomObject]@{ Component = $_.Name; Status = if($fails -eq 0){'OK'}else{'ISSUES'}; Fails = $fails }
  }
  foreach ($c in $byComponent) {
    $clr = if ($c.Fails -eq 0) { "Green" } else { "Red" }
    Log "    $($c.Component): $($c.Status)" $clr
  }

  if ($Action -eq "report" -and $OutputFile) {
    $report = [PSCustomObject]@{
      watchtowerVersion = "2.0.0"
      timestamp         = (Get-Date -Format "o")
      action            = $Action
      summary           = @{ pass = $pass; warn = $warn; fail = $fail; skip = $skip; total = $total }
      byComponent       = $byComponent
      findings          = $results
    }
    $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputFile -Encoding utf8
    Log "  Report: $OutputFile" Gray
  }
}

function Run-AllChecks {
  Check-DashboardWs
  Check-CodeGraph
  Check-MlEmbeddings
  Check-Engram
  Check-Mcp
  Check-SessionPipeline
  Check-Hooks
  Check-Configs
  Check-ToolConfigs
  Check-Security
  Check-Governance
}

# ─── Main ───────────────────────────────────────────────────────────────────

Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta
Log " 🏗  Maintenance Watchtower (v2.0.0)" Magenta
Log "    Action: $Action | Force: $Force | Interval: ${Interval}s" DarkGray
Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta

switch ($Action) {
  "health" { Run-AllChecks; Show-Summary }
  "rebuild" {
    Run-AllChecks
    Log "`n── Auto-Rebuild Phase ──" Yellow
    $needsRebuild = $results | Where-Object { $_.action -in @("rebuild","reindex") -and $_.status -ne "PASS" }
    if ($needsRebuild.Count -eq 0 -and -not $Force) {
      Log "  Everything fresh" Green
    } else {
      if ($Force) { Log "  Force rebuild" Yellow }
      else { Log "  $($needsRebuild.Count) component(s) need rebuild" Yellow }
      if ($Force -or ($results | Where-Object { $_.component -eq "ml-embeddings" -and $_.action -eq "rebuild" -and $_.status -ne "PASS" })) { Rebuild-MlEmbeddings }
      if ($Force -or ($results | Where-Object { $_.component -eq "engram" -and $_.action -eq "reindex" -and $_.status -ne "PASS" })) { Reindex-EngramRag }
    }
    Show-Summary
  }
  "autoheal" {
    Run-AllChecks
    AutoHeal
    Show-Summary
  }
  "all" {
    Run-AllChecks
    AutoHeal
    Log "`n── Rebuild Phase ──" Yellow
    if ($Force -or ($results | Where-Object { $_.component -eq "ml-embeddings" -and $_.action -eq "rebuild" -and $_.status -ne "PASS" })) { Rebuild-MlEmbeddings }
    if ($Force -or ($results | Where-Object { $_.component -eq "engram" -and $_.action -eq "reindex" -and $_.status -ne "PASS" })) { Reindex-EngramRag }
    Show-Summary
  }
  "continuous" {
    Log "Continuous mode: Interval=${Interval}s (Ctrl+C to stop)" Yellow
    $cycle = 0
    while ($true) {
      $cycle++
      Log "`n=== Cycle $cycle ($(Get-Date -Format 'HH:mm:ss')) ===" Cyan
      $results.Clear()
      Run-AllChecks
      AutoHeal
      Show-Summary
      Log "  Next cycle in ${Interval}s..." DarkGray
      Start-Sleep -Seconds $Interval
    }
  }
  "report" {
    Run-AllChecks
    Show-Summary
  }
}

Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta
exit $script:exitCode
