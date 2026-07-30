param(
  [int]$Port = 3000,
  [switch]$Quiet
)

$LogPath = ".runtime/presentations-server.log"
$LogDir = Split-Path -Parent $LogPath

if (-not $Quiet) {
  Write-Host "  Stopping presentations server on port $Port..." -ForegroundColor Yellow
}

$Stopped = $false

$processes = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
  Where-Object { $_.State -eq 'Listen' } |
  Select-Object -ExpandProperty OwningProcess -Unique

foreach ($pid in $processes) {
  try {
    $proc = Get-Process -Id $pid -ErrorAction Stop
    if (-not $Quiet) {
      Write-Host "  Killing $($proc.ProcessName) (PID: $pid) on port $Port" -ForegroundColor Cyan
    }
    $proc.Kill()
    $Stopped = $true
  } catch {
    if (-not $Quiet) { Write-Host "  Could not kill PID $pid : $_" -ForegroundColor DarkGray }
  }
}

$jobs = Get-Job | Where-Object {
  $_.Name -match "HttpListener|PowerShell" -and $_.State -eq "Running"
} | ForEach-Object {
  if (-not $Quiet) { Write-Host "  Stopping job $($_.Id) ($($_.Name))" -ForegroundColor Cyan }
  Stop-Job -Id $_.Id
  Remove-Job -Id $_.Id
  $Stopped = $true
}

if (-not $Stopped -and -not $Quiet) {
  Write-Host "  No process found listening on port $Port." -ForegroundColor DarkGray
}

if (Test-Path -LiteralPath $LogPath) {
  $lines = Get-Content -Path $LogPath
  $keep = $lines | Select-Object -Last 5
  $keep | Set-Content -Path $LogPath -Encoding utf8
  if (-not $Quiet) {
    Write-Host "  Log trimmed to last 5 lines: $LogPath" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Last log entries:" -ForegroundColor DarkGray
    $keep | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
  }
} elseif (-not $Quiet) {
  Write-Host "  No log file found at $LogPath" -ForegroundColor DarkGray
}

if (-not $Quiet) { Write-Host "  Done." -ForegroundColor Green }
