#!/usr/bin/env pwsh
<#
.SYNOPSIS
  GateGuard MCP pre-execution validation gate
.DESCRIPTION
  Validates MCP server is healthy before allowing tool execution.
  Implements pre: hook pattern with failure tracking and reconnect.
.PARAMETER Server
  MCP server name to check (e.g., codegraph, memory)
.PARAMETER Retry
  Allow one retry with backoff on first failure
.EXAMPLE
  ./gateguard-mcp.ps1 -Server codegraph
.EXAMPLE
  ./gateguard-mcp.ps1 -Server memory -Retry
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$Server,

  [switch]$Retry
)

$ErrorActionPreference = "Stop"
$script:stateFile = Join-Path $PSScriptRoot ".gateguard-state.json"

function ConvertTo-Hashtable {
  param([object]$InputObject)
  if ($InputObject -is [hashtable]) { return $InputObject }
  if ($InputObject -is [PSCustomObject]) {
    $ht = @{}
    $InputObject.PSObject.Properties | ForEach-Object { $ht[$_.Name] = $_.Value }
    return $ht
  }
  return @{}
}

function Get-GateGuardState {
  if (Test-Path $script:stateFile) {
    try {
      $raw = Get-Content $script:stateFile | ConvertFrom-Json
      $state = @{}
      $raw.PSObject.Properties | ForEach-Object {
        $server = $_.Name
        $val = $_.Value
        if ($val -is [PSCustomObject]) {
          $state[$server] = ConvertTo-Hashtable $val
        } else {
          $state[$server] = $val
        }
      }
      return $state
    } catch { }
  }
  return @{}
}

function Save-GateGuardState {
  param([object]$State)
  $State | ConvertTo-Json -Depth 3 | Set-Content $script:stateFile
}

$state = Get-GateGuardState
$serverState = $state.$Server
if (-not $serverState) {
  $serverState = @{ ConsecutiveFailures = 0; LastFailure = $null }
  $state.$Server = $serverState
}

if ($serverState.ConsecutiveFailures -ge 3) {
  $result = @{
    Server = $Server
    Status = "unhealthy"
    LatencyMs = 0
    LastFailure = $serverState.LastFailure
    Reason = "Marked unhealthy after $($serverState.ConsecutiveFailures) consecutive failures"
  }
  Write-Output ($result | ConvertTo-Json -Depth 3)
  exit 0
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$healthy = $false
$failureReason = $null

try {
  if ($Server -eq "codegraph") {
    $null = codegraph status 2>&1
    if ($LASTEXITCODE -eq 0) { $healthy = $true }
    else { throw "codegraph status returned exit code $LASTEXITCODE" }
  } else {
    $serverDir = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts/mcp"
    $serverJs = Join-Path $serverDir "$Server-server.js"
    if (Test-Path $serverJs) {
      $result = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | & "node" $serverJs 2>&1
      if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) { $healthy = $true }
      else { throw "Server process exited with code $LASTEXITCODE" }
    } else {
      $healthy = $true
    }
  }
  $sw.Stop()
  $latency = [math]::Round($sw.Elapsed.TotalMilliseconds, 0)
} catch {
  $sw.Stop()
  $latency = [math]::Round($sw.Elapsed.TotalMilliseconds, 0)
  $failureReason = $_.Exception.Message

  if ($Retry -and $serverState.ConsecutiveFailures -eq 0) {
    Start-Sleep -Milliseconds 500
    try {
      $swRetry = [System.Diagnostics.Stopwatch]::StartNew()
      if ($Server -eq "codegraph") {
        $null = codegraph status 2>&1
        if ($LASTEXITCODE -eq 0) { $healthy = $true }
      } elseif (Test-Path (Join-Path (Split-Path -Parent $PSScriptRoot) "scripts/mcp/$Server-server.js")) {
        $null = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | & "node" (Join-Path (Split-Path -Parent $PSScriptRoot) "scripts/mcp/$Server-server.js") 2>&1
        $healthy = $true
      }
      $swRetry.Stop()
      $latency = [math]::Round($swRetry.Elapsed.TotalMilliseconds, 0)
      $failureReason = $null
    } catch {
      $failureReason = "Retry failed: $($_.Exception.Message)"
    }
  }
}

if ($healthy) {
  $serverState.ConsecutiveFailures = 0
  $serverState.LastFailure = $null
} else {
  $serverState.ConsecutiveFailures++
  $serverState.LastFailure = @{ Timestamp = (Get-Date -Format "o"); Reason = $failureReason }
}

$state.$Server = $serverState
Save-GateGuardState -State $state

$result = @{
  Server = $Server
  Status = if ($healthy) { "healthy" } else { "unhealthy" }
  LatencyMs = $latency
  LastFailure = $serverState.LastFailure
}

Write-Output ($result | ConvertTo-Json -Depth 3)
