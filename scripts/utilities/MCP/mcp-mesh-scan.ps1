param(
  [ValidateSet('discover', 'status', 'sync')]
  [string]$Action = 'discover',
  [string]$RepoFilter,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$MESH_DIR = Join-Path $ROOT '.session' 'federation'
$MESH_REGISTRY = Join-Path $ROOT 'config' 'federation-config.json'
$MCP_REGISTRY = Join-Path $ROOT 'config' 'mcp-registry.json'
$TEMPLATES = Join-Path $ROOT 'config' 'mcp-templates.json'

function Write-Log($msg, $color = 'Cyan') {
  if (-not $Quiet) { Write-Host "[MESH] $msg" -ForegroundColor $color }
}

# Discover workspaces from mesh federation config
function Get-MeshWorkspaces {
  $workspaces = @()
  if (Test-Path $MESH_REGISTRY) {
    $cfg = Get-Content $MESH_REGISTRY -Raw | ConvertFrom-Json
    if ($cfg.PSObject.Properties['peers']) {
      $cfg.peers | ForEach-Object { $workspaces += $_ }
    }
    if ($cfg.PSObject.Properties['discovery'] -and $cfg.discovery.PSObject.Properties['knownWorkspaces']) {
      $cfg.discovery.knownWorkspaces | ForEach-Object { $workspaces += $_ }
    }
  }
  $local = @{ name = Split-Path $ROOT -Leaf; path = $ROOT }
  $workspaces = @($local) + $workspaces
  if ($RepoFilter) { $workspaces = $workspaces | Where-Object { $_.name -eq $RepoFilter -or $_.path -like "*$RepoFilter*" } }
  return $workspaces
}

# Read MCP registry from a workspace
function Read-McpRegistry($wsPath) {
  $regPath = Join-Path $wsPath 'config' 'mcp-registry.json'
  if (Test-Path $regPath) {
    return Get-Content $regPath -Raw | ConvertFrom-Json
  }
  return $null
}

switch ($Action) {
  'discover' {
    Write-Log "Scanning mesh workspaces for MCP registries..."
    $workspaces = Get-MeshWorkspaces
    $found = 0
    foreach ($ws in $workspaces) {
      $reg = Read-McpRegistry $ws.path
      if ($reg -and $reg.servers) {
        $found++
        $count = @($reg.servers).Count
        Write-Log "  $($ws.name) — $count server(s)" 'Green'
        if (-not $Quiet) {
          $reg.servers | ForEach-Object { Write-Host "    - $($_.name) ($($_.type))" -ForegroundColor Gray }
        }
      } else {
        Write-Log "  $($ws.name) — no MCP registry" 'Yellow'
      }
    }
    Write-Log "Discovered MCP servers in $found/$($workspaces.Count) workspaces." 'Green'
  }

  'status' {
    Write-Log "Checking MCP server health across mesh..."
    $workspaces = Get-MeshWorkspaces
    $allOk = $true
    foreach ($ws in $workspaces) {
      $reg = Read-McpRegistry $ws.path
      if (-not $reg -or -not $reg.servers) { continue }
      Write-Log "$($ws.name):" 'Cyan'
      foreach ($s in $reg.servers) {
        $lock = Join-Path $ws.path '.runtime' 'mcp' "$($s.name).pid"
        if (Test-Path $lock) {
          $pid = Get-Content $lock -Raw -ErrorAction SilentlyContinue
          $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
          if ($proc) {
            Write-Log "  ✅ $($s.name) — PID $pid" 'Green'
          } else {
            Write-Log "  ❌ $($s.name) — stale PID $pid" 'Red'; $allOk = $false
          }
        } else {
          if ($s.autoStart) { Write-Log "  ❌ $($s.name) — not running" 'Red'; $allOk = $false }
          else { Write-Log "  ⏸  $($s.name) — stopped" 'Yellow' }
        }
      }
    }
    if ($allOk) { Write-Log 'All mesh MCP servers healthy.' 'Green' }
    else { Write-Log 'Some mesh MCP servers need attention.' 'Yellow' }
  }

  'sync' {
    Write-Log "Syncing MCP templates across mesh..."
    if (-not (Test-Path $TEMPLATES)) { Write-Log "ERROR: templates not found at $TEMPLATES" 'Red'; exit 1 }
    $tpl = Get-Content $TEMPLATES -Raw | ConvertFrom-Json
    $workspaces = Get-MeshWorkspaces
    $synced = 0
    foreach ($ws in $workspaces) {
      $target = Join-Path $ws.path 'config' 'mcp-templates.json'
      Copy-Item -Path $TEMPLATES -Destination $target -Force -ErrorAction SilentlyContinue
      if ($?) { $synced++; Write-Log "  ✅ $($ws.name) — templates synced" 'Green' }
      else { Write-Log "  ❌ $($ws.name) — sync failed" 'Red' }
    }
    Write-Log "Templates synced to $synced/$($workspaces.Count) workspaces." 'Green'
  }
}
