param(
  [ValidateSet('start', 'stop', 'status', 'reload')]
  [string]$Action = 'status',
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$REGISTRY_PATH = Join-Path $ROOT 'config' 'mcp-registry.json'
$LOCK_DIR = Join-Path $ROOT '.runtime' 'mcp'

if (-not (Test-Path $LOCK_DIR)) { New-Item -ItemType Directory -Path $LOCK_DIR -Force | Out-Null }

function Read-Registry {
  if (-not (Test-Path $REGISTRY_PATH)) { return @{ servers = @() } }
  return Get-Content $REGISTRY_PATH -Raw | ConvertFrom-Json
}

function Get-ProcPath($name) {
  $lock = Join-Path $LOCK_DIR "$Name.pid"
  if (-not (Test-Path $lock)) { return $null }
  $pid = Get-Content $lock -Raw -ErrorAction SilentlyContinue
  if (-not ($pid -match '^\d+$')) { return $null }
  $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
  if (-not $proc) { Remove-Item $lock -Force -ErrorAction SilentlyContinue; return $null }
  return $proc
}

switch ($Action) {
  'start' {
    $reg = Read-Registry
    $count = 0
    foreach ($s in $reg.servers) {
      if (-not $s.enabled) { continue }
      $existing = Get-ProcPath $s.name
      if ($existing) {
        if (-not $Quiet) { Write-Host "  ⏩ $($s.name) — already running (PID $($existing.Id))" -ForegroundColor Yellow }
        continue
      }
      try {
        $proc = Start-Process -FilePath $s.command -ArgumentList $s.args -WindowStyle Hidden -PassThru -NoNewWindow
        Start-Sleep -Milliseconds 300
        $proc | Select-Object -ExpandProperty Id | Set-Content (Join-Path $LOCK_DIR "$($s.name).pid") -Encoding UTF8
        $count++
        if (-not $Quiet) { Write-Host "  ✅ $($s.name) — started (PID $($proc.Id))" -ForegroundColor Green }
      } catch {
        if (-not $Quiet) { Write-Host "  ❌ $($s.name) — failed: $_" -ForegroundColor Red }
      }
    }
    if (-not $Quiet) { Write-Host "Gateway: $count server(s) started." -ForegroundColor Cyan }
  }

  'stop' {
    $reg = Read-Registry
    $count = 0
    foreach ($s in $reg.servers) {
      $proc = Get-ProcPath $s.name
      if (-not $proc) { continue }
      try {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $LOCK_DIR "$($s.name).pid") -Force -ErrorAction SilentlyContinue
        $count++
        if (-not $Quiet) { Write-Host "  ⏹  $($s.name) — stopped" -ForegroundColor Green }
      } catch {
        if (-not $Quiet) { Write-Host "  ❌ $($s.name) — stop failed: $_" -ForegroundColor Red }
      }
    }
    # cleanup all pid files
    Get-ChildItem $LOCK_DIR -Filter '*.pid' | Remove-Item -Force -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host "Gateway: $count server(s) stopped." -ForegroundColor Cyan }
  }

  'status' {
    $reg = Read-Registry
    $result = @{ servers = @() }
    foreach ($s in $reg.servers) {
      $proc = Get-ProcPath $s.name
      $status = if ($proc) { 'running' } else { 'stopped' }
      $entry = @{
        name = $s.name
        type = $s.type
        transport = $s.transport
        command = $s.command
        args = @($s.args)
        enabled = $s.enabled
        autoStart = $s.autoStart
        description = $s.description
        pid = if ($proc) { $proc.Id } else { $null }
        status = $status
        uptime = if ($proc) { [math]::Round((Get-Date) - $proc.StartTime, 0) } else { 0 }
        toolsCount = 0
        lastError = $null
      }
      $result.servers += $entry
    }
    return $result
  }

  'reload' {
    & $PSScriptRoot\mcp-manager.ps1 -Action reload -Quiet:$Quiet
  }
}
