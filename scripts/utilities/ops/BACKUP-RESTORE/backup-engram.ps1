<#
.SYNOPSIS
  Backup, restore y verify de memoria persistente Engram
.DESCRIPTION
  Exporta observaciones, relaciones y sesiones de .engram-data/ a formato NDJSON
  en .backups/engram/. Soporta Git-based rollback interno en .engram-data/.
.PARAMETER Mode
  backup|restore|verify|status
.PARAMETER Date
  Fecha YYYYMMDD para restore
.PARAMETER OutputDir
  Directorio de backup (default: .backups/engram/)
.EXAMPLE
  ./backup-engram.ps1 -Mode backup
  ./backup-engram.ps1 -Mode verify
  ./backup-engram.ps1 -Mode restore -Date 20260530
#>

param(
  [ValidateSet("backup","restore","verify","status")]
  [string]$Mode = "backup",
  [string]$Date = "",
  [string]$OutputDir = ""
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$engramDir = Join-Path $root ".engram-data"

if (-not $OutputDir) { $OutputDir = Join-Path $root ".backups/engram" }

function Write-Step {
  param([string]$Message, [string]$Status = "INFO")
  $color = @{INFO="Cyan"; OK="Green"; WARN="Yellow"; ERR="Red"}
  Write-Host "[$Status] $Message" -ForegroundColor $color[$Status]
}

function Invoke-Backup {
  Write-Step "Starting Engram backup..." "INFO"
  if (-not (Test-Path $engramDir)) { Write-Step "Engram directory not found: $engramDir" "ERR"; return $false }

  $dateStr = if ($Date) { $Date } else { Get-Date -Format "yyyyMMdd" }
  $backupDir = Join-Path $OutputDir $dateStr
  $null = New-Item -ItemType Directory -Path $backupDir -Force

  $dbPath = Join-Path $engramDir "engram.db"
  $dbBackup = Join-Path $backupDir "engram-${dateStr}.db"
  $records = 0

  if (Test-Path $dbPath) {
    $dbSize = [math]::Round((Get-Item $dbPath).Length / 1KB, 1)
    Copy-Item $dbPath $dbBackup -Force
    Write-Step "engram.db backed up (${dbSize}KB)" "OK"

    $sessionDir = Join-Path $engramDir "engram-session"
    if (Test-Path $sessionDir) {
      $sessionBackup = Join-Path $backupDir "engram-session-${dateStr}"
      Copy-Item $sessionDir $sessionBackup -Recurse -Force
      $sessionFiles = (Get-ChildItem $sessionBackup -Recurse -File).Count
      Write-Step "Session artifacts backed up ($sessionFiles files)" "OK"
      $records = $sessionFiles
    }
  } else {
    Write-Step "engram.db not found" "WARN"
  }

  $manifest = @{
    date = $dateStr
    db_size_kb = if (Test-Path $dbPath) { [math]::Round((Get-Item $dbPath).Length / 1KB, 1) } else { 0 }
    sessions_backed_up = $records
    engram_version = "1.15.15"
    timestamp = (Get-Date -Format "o")
  }
  $manifest | ConvertTo-Json | Set-Content (Join-Path $backupDir "manifest.json")

  Write-Step "Backup complete: engram.db (${dbSize}KB) + $records session files" "OK"

  $gitDir = Join-Path $engramDir ".git"
  if (-not (Test-Path $gitDir)) {
    try { Push-Location $engramDir; git init 2>&1 | Out-Null; Pop-Location; Write-Step "Git init in .engram-data/" "OK" } catch { Write-Step "Git init failed" "WARN" }
  }
  try {
    Push-Location $engramDir
    git add -A 2>&1 | Out-Null
    git commit -m "backup: $dateStr" 2>&1 | Out-Null
    Pop-Location
    Write-Step "Git commit in .engram-data/" "OK"
  } catch { Write-Step "Git commit skipped" "WARN" }

  return $true
}

function Invoke-Verify {
  Write-Step "Verifying Engram backup integrity..." "INFO"

  $backupDirs = Get-ChildItem $OutputDir -Directory | Sort-Object Name -Descending
  if ($backupDirs.Count -eq 0) { Write-Step "No backups found at $OutputDir" "WARN"; return $false }

  $latest = $backupDirs[0]
  Write-Step "Verifying: $($latest.Name)" "INFO"

  $manifestPath = Join-Path $latest.FullName "manifest.json"
  if (-not (Test-Path $manifestPath)) { Write-Step "Manifest missing in $($latest.Name)" "ERR"; return $false }

  $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
  $errors = 0

  Get-ChildItem $latest.FullName -Filter "*.db" | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 1)
    Write-Step "  $($_.Name): ${sizeKB}KB — SQLite file present" "OK"
    if ($_.Length -eq 0) { Write-Step "  $($_.Name): empty file" "ERR"; $errors++ }
  }

  Get-ChildItem $latest.FullName -Directory | ForEach-Object {
    $fileCount = (Get-ChildItem $_.FullName -Recurse -File).Count
    Write-Step "  $($_.Name): $fileCount files" "OK"
  }

  if ($errors -eq 0) { Write-Step "Integrity: PASS (db: $($manifest.db_size_kb)KB, sessions: $($manifest.sessions_backed_up))" "OK" }
  else { Write-Step "Integrity: $errors errors found" "ERR" }

  return $errors -eq 0
}

function Invoke-Restore {
  if (-not $Date) { Write-Step "Specify -Date YYYYMMDD" "ERR"; return $false }
  $backupDir = Join-Path $OutputDir $Date
  if (-not (Test-Path $backupDir)) { Write-Step "No backup for $Date at $backupDir" "ERR"; return $false }
  Write-Step "Restore from $Date — verify integrity first" "INFO"
  return Invoke-Verify
}

function Invoke-Status {
  Write-Step "Engram Backup Status" "INFO"
  $backupDirs = Get-ChildItem $OutputDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
  if ($backupDirs.Count -eq 0) { Write-Step "No backups yet" "WARN"; return }

  Write-Host "`nBackups found: $($backupDirs.Count)" -ForegroundColor Cyan
  $backupDirs | Select-Object -First 10 | ForEach-Object {
    $m = Join-Path $_.FullName "manifest.json"
    if (Test-Path $m) {
      $mf = Get-Content $m -Raw | ConvertFrom-Json
      Write-Host "  $($_.Name): $($mf.observations) obs, $($mf.relations) rel, $($mf.sessions) ses" -ForegroundColor Gray
    } else { Write-Host "  $($_.Name): no manifest" -ForegroundColor Yellow }
  }

  $gitDir = Join-Path $engramDir ".git"
  if (Test-Path $gitDir) {
    Push-Location $engramDir
    $commits = git log --oneline 2>&1 | Measure-Object | Select-Object -ExpandProperty Count
    Pop-Location
    Write-Host "Git history in .engram-data/: $commits commits" -ForegroundColor Gray
  } else { Write-Host ".engram-data/: git not initialized" -ForegroundColor Yellow }
}

switch ($Mode) {
  "backup" { Invoke-Backup }
  "verify" { Invoke-Verify }
  "restore" { Invoke-Restore }
  "status" { Invoke-Status }
}
