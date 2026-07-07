<#
.SYNOPSIS
  Cross-Workspace Mesh — discover and collaborate across workspace boundaries.

.DESCRIPTION
  Workspaces expose capabilities via .workspace/manifest.json. The mesh discovers
  peer workspaces via a shared seed file or environment variable, and enables
  task delegation between workspaces based on capability matching.

.PARAMETER Action
  discover — find peer workspaces on the mesh (default)
  manifest — generate/update this workspace's manifest
  delegate — delegate a task to a peer workspace
  status   — show mesh health and connected peers

.PARAMETER TargetWorkspace
  Target workspace name (for delegate action).

.PARAMETER TaskType
  Type of task to delegate (e.g., "code-review", "codegraph-search").

.PARAMETER Payload
  JSON payload for the delegated task.

.EXAMPLE
  .\cross-workspace-mesh.ps1 -Action discover
  .\cross-workspace-mesh.ps1 -Action delegate -TargetWorkspace "other-project" -TaskType "code-review" -Payload '{"pr":"123"}'
#>

param(
  [ValidateSet("discover", "manifest", "delegate", "status")]
  [string]$Action = "status",
  [string]$TargetWorkspace = "",
  [string]$TaskType = "",
  [string]$Payload = "{}"
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$workspaceManifestDir = Join-Path $repoRoot ".workspace"
$null = New-Item -ItemType Directory -Path $workspaceManifestDir -Force

$meshPort = $env:GENTLE_MESH_PORT
if (-not $meshPort) { $meshPort = 9091 }

switch ($Action) {
  "manifest" {
    # Generate capabilities from existing skills/config
    $capabilities = @()
    $autoDelegationPath = Join-Path $repoRoot "config\auto-delegation.json"
    if (Test-Path $autoDelegationPath) {
      $ad = Get-Content $autoDelegationPath -Raw | ConvertFrom-Json
      $capabilities = $ad.keywordMappings.PSObject.Properties.Name
    }

    $manifest = @{
      workspace = Split-Path -Leaf $repoRoot
      version = "1.0"
      generated = Get-Date -Format "o"
      capabilities = $capabilities
      agents = @()
      meshPort = $meshPort
    }

    # Scan for known agents
    $evalResultsDir = Join-Path $repoRoot ".session\eval\results"
    if (Test-Path $evalResultsDir) {
      Get-ChildItem -Directory $evalResultsDir | ForEach-Object {
        $latest = Get-ChildItem -Path $_.FullName -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) {
          $data = Get-Content $latest.FullName -Raw | ConvertFrom-Json
          $manifest.agents += @{
            id = $_.Name
            version = $data.version
            score = $data.avgScore
            lastEval = $data.timestamp
          }
        }
      }
    }

    $manifestFile = Join-Path $workspaceManifestDir "manifest.json"
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestFile -Encoding utf8
    Write-Host "[MESH] Manifest generated: $manifestFile" -ForegroundColor Green
    return $manifest
  }

  "discover" {
    Write-Host "[MESH] Discovering peer workspaces..." -ForegroundColor Cyan

    $peers = @()
    $meshSeed = $env:GENTLE_MESH_SEED
    if ($meshSeed -and (Test-Path $meshSeed)) {
      $seedContent = Get-Content $meshSeed -Raw | ConvertFrom-Json
      foreach ($ws in $seedContent.workspaces) {
        $manifestFile = Join-Path $ws.path ".workspace\manifest.json"
        if (Test-Path $manifestFile) {
          $peers += Get-Content $manifestFile -Raw | ConvertFrom-Json
        }
      }
    }

    # Also scan sibling directories
    $parentDir = Split-Path -Parent $repoRoot
    Get-ChildItem -Directory $parentDir | Where-Object { $_.Name -ne (Split-Path -Leaf $repoRoot) } | ForEach-Object {
      $siblingManifest = Join-Path $_.FullName ".workspace\manifest.json"
      if (Test-Path $siblingManifest) {
        $peers += Get-Content $siblingManifest -Raw | ConvertFrom-Json
      }
    }

    if ($peers.Count -eq 0) {
      Write-Host "[MESH] No peer workspaces discovered" -ForegroundColor Yellow
    } else {
      Write-Host "[MESH] Discovered $($peers.Count) peer(s):" -ForegroundColor Green
      foreach ($p in $peers) {
        Write-Host "  $($p.workspace) — capabilities: $($p.capabilities -join ', ')" -ForegroundColor Gray
      }
    }

    return $peers
  }

  "delegate" {
    if (-not $TargetWorkspace) { Write-Error "Provide -TargetWorkspace"; exit 1 }
    if (-not $TaskType) { Write-Error "Provide -TaskType (e.g., 'code-review')"; exit 1 }

    Write-Host "[MESH] Delegating task '$TaskType' to $TargetWorkspace..." -ForegroundColor Cyan

    $parsedPayload = $Payload | ConvertFrom-Json

    $delegation = @{
      from = Split-Path -Leaf $repoRoot
      to = $TargetWorkspace
      taskType = $TaskType
      payload = $parsedPayload
      timestamp = Get-Date -Format "o"
      status = "delegated"
    }

    # Log delegation
    $meshDir = Join-Path $repoRoot ".session\mesh"
    $null = New-Item -ItemType Directory -Path $meshDir -Force
    $delegationFile = Join-Path $meshDir "$(Get-Date -Format 'yyyyMMdd-HHmmss')-delegation.json"
    $delegation | ConvertTo-Json -Depth 10 | Set-Content $delegationFile -Encoding utf8

    Write-Host "[MESH] Task delegated — log: $delegationFile" -ForegroundColor Green
    return $delegation
  }

  "status" {
    $manifestFile = Join-Path $workspaceManifestDir "manifest.json"
    $manifest = if (Test-Path $manifestFile) { Get-Content $manifestFile -Raw | ConvertFrom-Json } else { $null }

    $peers = & $PSCommandPath -Action discover
    $delegations = Get-ChildItem -Path (Join-Path $repoRoot ".session\mesh") -Filter "*.json" -ErrorAction SilentlyContinue

    Write-Host "[MESH] Status:" -ForegroundColor Cyan
    Write-Host "  Workspace: $(Split-Path -Leaf $repoRoot)" -ForegroundColor White
    Write-Host "  Manifest: $(if($manifest){'OK'}else{'NOT GENERATED'})" -ForegroundColor $(if($manifest){'Green'}else{'Yellow'})
    Write-Host "  Mesh port: $meshPort" -ForegroundColor Gray
    Write-Host "  Peers: $($peers.Count)" -ForegroundColor $(if($peers.Count -gt 0){'Green'}else{'Gray'})
    Write-Host "  Delegations: $($delegations.Count)" -ForegroundColor $(if($delegations.Count -gt 0){'Green'}else{'Gray'})

    return @{
      workspace = Split-Path -Leaf $repoRoot
      manifest = ($manifest -ne $null)
      meshPort = $meshPort
      peers = $peers.Count
      delegations = $delegations.Count
    }
  }
}
