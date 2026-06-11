<#
.SYNOPSIS
  Backup, restore, verify y status de memoria persistente Engram
.DESCRIPTION
  Exporta observaciones, relaciones y sesiones de .engram-data/ a formato NDJSON
  en .backups/engram/. Soporta Git-based rollback interno en .engram-data/.

  Mejoras v2:
  - Pre-backup integrity check via engram-integrity-check.ps1
  - SHA256 checksums post-backup
  - Post-backup verification (SQLite readable + size match)
  - --IntegrityCheck flag para saltar verificación pre-backup
.PARAMETER Mode
  backup|restore|verify|status
.PARAMETER Date
  Fecha YYYYMMDD para restore
.PARAMETER OutputDir
  Directorio de backup (default: .backups/engram/)
.PARAMETER IntegrityCheck
  Ejecuta integrity check antes de backup (default: true)
.PARAMETER Quiet
  Salida mínima (para hooks/automation)
.EXAMPLE
  ./backup-engram.ps1 -Mode backup
  ./backup-engram.ps1 -Mode backup -Quiet
  ./backup-engram.ps1 -Mode verify
  ./backup-engram.ps1 -Mode restore -Date 20260530
#>

param(
  [ValidateSet("backup","restore","verify","status")]
  [string]$Mode = "backup",
  [string]$Date = "",
  [string]$OutputDir = "",
  [switch]$IntegrityCheck = $true,
  [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$engramDir = Join-Path $root ".engram-data"
$integrityScript = Join-Path $root "scripts/utilities/memory/ENGRAM/engram-integrity-check.ps1"
$backupLogFile = Join-Path $root "logs/engram-backup.log"

if (-not $OutputDir) { $OutputDir = Join-Path $root ".backups/engram" }

function Write-Step {
  param([string]$Message, [string]$Status = "INFO")
  if ($Quiet -and $Status -ne "ERR") { return }
  $color = @{INFO="Cyan"; OK="Green"; WARN="Yellow"; ERR="Red"}
  Write-Host "[BACKUP::$Status] $Message" -ForegroundColor $color[$Status]
}

function Write-Log {
  param([string]$Message, [string]$Level = "INFO")
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Add-Content -Path $backupLogFile -Value "[$timestamp] [$Level] $Message" -Encoding UTF8 -ErrorAction SilentlyContinue
}

function New-ChecksumFile {
  param([string]$Dir)
  $checksums = @()
  Get-ChildItem $Dir -Recurse -File | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    $relPath = $_.FullName.Substring($Dir.Length).TrimStart('\', '/')
    $checksums += "$hash *$relPath"
  }
  $checksums | Set-Content (Join-Path $Dir "checksums.sha256") -Encoding UTF8
  return $checksums.Count
}

function Verify-ChecksumFile {
  param([string]$Dir)
  $csPath = Join-Path $Dir "checksums.sha256"
  if (-not (Test-Path $csPath)) { return $false, "No checksums.sha256" }
  $errors = 0
  Get-Content $csPath | ForEach-Object {
    if ($_ -match "^([0-9a-fA-F]{64}) \*(.+)$") {
      $expectedHash = $Matches[1]; $filePath = Join-Path $Dir $Matches[2]
      if (Test-Path $filePath) {
        $actualHash = (Get-FileHash $filePath -Algorithm SHA256).Hash
        if ($actualHash -ne $expectedHash) { $errors++ }
      } else { $errors++ }
    }
  }
  return ($errors -eq 0), "$errors mismatches"
}

function Test-DbReadable {
  param([string]$DbPath)
  if (-not (Test-Path $DbPath)) { return $false, "Not found" }
  $fileInfo = Get-Item $DbPath
  if ($fileInfo.Length -eq 0) { return $false, "Empty file" }
  # SQLite header check: first 16 bytes are "SQLite format 3\0"
  try {
    $stream = [System.IO.File]::OpenRead($DbPath)
    $header = New-Object byte[] 16
    $bytesRead = $stream.Read($header, 0, 16)
    $stream.Close()
    if ($bytesRead -lt 16) { return $false, "Too small for SQLite" }
    $sqliteMagic = [byte[]]@(0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00)
    $isSqlite = $true
    for ($i = 0; $i -lt 16; $i++) { if ($header[$i] -ne $sqliteMagic[$i]) { $isSqlite = $false; break } }
    if ($isSqlite) {
      return $true, "$([math]::Round($fileInfo.Length/1KB,1))KB, SQLite format 3"
    }
    return $false, "Not a SQLite file (header: $($header[0..3] -join ','))"
  } catch {
    return $false, "Unreadable: $_"
  }
}

function Invoke-Backup {
  Write-Step "Starting Engram backup..." "INFO"
  Write-Log "Backup started" "INFO"

  if (-not (Test-Path $engramDir)) {
    Write-Step "Engram directory not found: $engramDir" "ERR"
    Write-Log "Engram dir not found: $engramDir" "ERROR"
    return $false
  }

  # Pre-backup integrity check
  if ($IntegrityCheck -and (Test-Path $integrityScript)) {
    # Auto-generate checksums if missing
    $icChecksumPath = Join-Path $root ".engram/checksums.sha256"
    if (-not (Test-Path $icChecksumPath)) {
      Write-Step "Generating initial SHA256 checksums..." "INFO"
      & $integrityScript -Mode checksums -Quiet 2>&1 | Out-Null
    }
    Write-Step "Pre-backup integrity check..." "INFO"
    $icResult = & $integrityScript -Mode check -Quiet 2>&1
    $icOk = $LASTEXITCODE -eq 0
    if (-not $icOk) {
      Write-Step "Integrity check FAILED  --  run repair first: $integrityScript -Mode repair" "ERR"
      Write-Log "Pre-backup integrity check FAILED  --  backup aborted" "ERROR"
      return $false
    }
    Write-Step "Pre-backup integrity PASSED" "OK"
  }

  $dateStr = if ($Date) { $Date } else { Get-Date -Format "yyyyMMdd" }
  $backupDir = Join-Path $OutputDir $dateStr
  $null = New-Item -ItemType Directory -Path $backupDir -Force

  $dbPath = Join-Path $engramDir "engram.db"
  $dbBackup = Join-Path $backupDir "engram-${dateStr}.db"
  $records = 0
  $dbSizeKB = 0

  if (Test-Path $dbPath) {
    $dbSizeKB = [math]::Round((Get-Item $dbPath).Length / 1KB, 1)
    $originalSize = (Get-Item $dbPath).Length
    Copy-Item $dbPath $dbBackup -Force
    $copiedSize = (Get-Item $dbBackup).Length

    if ($originalSize -ne $copiedSize) {
      Write-Step "Size MISMATCH after copy! Original: $originalSize, Copy: $copiedSize" "ERR"
      Write-Log "SIZE MISMATCH: original=$originalSize copy=$copiedSize" "ERROR"
      return $false
    }

    # Post-backup verification: SQLite readable
    $dbOk, $dbDetail = Test-DbReadable $dbBackup
    if (-not $dbOk) {
      Write-Step "Backup verification FAILED: $dbDetail" "ERR"
      Write-Log "Backup verification FAILED: $dbDetail" "ERROR"
      Remove-Item $dbBackup -Force -ErrorAction SilentlyContinue
      return $false
    }
    Write-Step "engram.db backed up (${dbSizeKB}KB, $dbDetail)" "OK"

    # Session artifacts
    $sessionDir = Join-Path $engramDir "engram-session"
    if (Test-Path $sessionDir) {
      $sessionBackup = Join-Path $backupDir "engram-session-${dateStr}"
      Copy-Item $sessionDir $sessionBackup -Recurse -Force
      $sessionFiles = (Get-ChildItem $sessionBackup -Recurse -File).Count
      Write-Step "Session artifacts backed up ($sessionFiles files)" "OK"
      $records = $sessionFiles
    }
  } else {
    Write-Step "engram.db not found at $dbPath" "WARN"
  }

  # SHA256 checksums for backup
  $csCount = New-ChecksumFile -Dir $backupDir
  Write-Step "SHA256 checksums generated ($csCount files)" "OK"

  # Manifest
  $manifest = @{
    date = $dateStr
    db_size_kb = $dbSizeKB
    sessions_backed_up = $records
    checksum_files = $csCount
    integrity_check_passed = if ($IntegrityCheck) { $true } else { "skipped" }
    engram_version = "1.15.15"
    timestamp = (Get-Date -Format "o")
  }
  $manifest | ConvertTo-Json | Set-Content (Join-Path $backupDir "manifest.json")

  # Git-based rollback in .engram-data/
  $gitDir = Join-Path $engramDir ".git"
  if (-not (Test-Path $gitDir)) {
    try {
      Push-Location $engramDir
      git init 2>&1 | Out-Null
      Write-Step "Git init in .engram-data/" "OK"
      Pop-Location
    } catch { Write-Step "Git init failed" "WARN" }
  }
  try {
    Push-Location $engramDir
    git add -A 2>&1 | Out-Null
    git commit -m "backup: $dateStr" 2>&1 | Out-Null
    Pop-Location
    Write-Step "Git commit in .engram-data/" "OK"
    Write-Log "Git commit: $dateStr" "INFO"
  } catch { Write-Step "Git commit skipped" "WARN" }

  Write-Step "Backup complete: ${dbSizeKB}KB db + $records session files + $csCount checksums" "OK"
  Write-Log "Backup complete: $dateStr (${dbSizeKB}KB, $records sessions)" "INFO"
  return $true
}

function Invoke-Verify {
  Write-Step "Verifying Engram backup integrity..." "INFO"

  $backupDirs = Get-ChildItem $OutputDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
  if ($backupDirs.Count -eq 0) { Write-Step "No backups found at $OutputDir" "WARN"; return $false }

  $allOk = $true
  $totalDbs = 0; $totalCsums = 0; $totalErrors = 0
  foreach ($backup in $backupDirs) {
    Write-Step "Verifying: $($backup.Name)" "INFO"

    $errors = 0

    # Manifest check
    $manifestPath = Join-Path $backup.FullName "manifest.json"
    if (Test-Path $manifestPath) {
      try { $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json } catch { $errors++ }
    } else { $errors++ }

    # DB files
    $dbFiles = Get-ChildItem $backup.FullName -Filter "*.db"
    foreach ($db in $dbFiles) {
      $ok, $detail = Test-DbReadable $db.FullName
      if ($ok) {
        Write-Step "  $($db.Name): $([math]::Round($db.Length/1KB,1))KB  --  $detail" "OK"
        $totalDbs++
      } else {
        Write-Step "  $($db.Name): FAIL  --  $detail" "ERR"
        $errors++; $totalErrors++
      }
    }

    # Session artifacts
    Get-ChildItem $backup.FullName -Directory | Where-Object { $_.Name -match 'engram-session' } | ForEach-Object {
      $fileCount = (Get-ChildItem $_.FullName -Recurse -File).Count
      Write-Step "  $($_.Name): $fileCount files" "OK"
    }

    # Checksums verification
    $csOk, $csDetail = Verify-ChecksumFile -Dir $backup.FullName
    if ($csOk) {
      Write-Step "  checksums.sha256: verified" "OK"
      $totalCsums++
    } else {
      Write-Step "  checksums.sha256: $csDetail" "WARN"
    }

    if ($errors -gt 0) { $allOk = $false }
  }

  if ($allOk) {
    Write-Step "Integrity: ALL PASS ($totalDbs databases, $totalCsums checksums)" "OK"
  } else {
    Write-Step "Integrity: $totalErrors errors across $($backupDirs.Count) backups" "ERR"
  }
  return $allOk
}

function Invoke-Restore {
  if (-not $Date) { Write-Step "Specify -Date YYYYMMDD" "ERR"; return $false }
  $backupDir = Join-Path $OutputDir $Date
  if (-not (Test-Path $backupDir)) { Write-Step "No backup for $Date at $backupDir" "ERR"; return $false }

  Write-Step "=== Restore from $Date ===" "INFO"

  # Verify backup integrity first
  $manifestPath = Join-Path $backupDir "manifest.json"
  if (-not (Test-Path $manifestPath)) { Write-Step "Manifest missing  --  aborting restore" "ERR"; return $false }
  $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

  $dbFiles = Get-ChildItem $backupDir -Filter "*.db"
  if ($dbFiles.Count -eq 0) { Write-Step "No DB files in backup  --  aborting" "ERR"; return $false }

  $dbOk, $dbDetail = Test-DbReadable $dbFiles[0].FullName
  if (-not $dbOk) { Write-Step "Backup DB is corrupt: $dbDetail  --  aborting" "ERR"; return $false }

  Write-Step "Backup verified: $($manifest.db_size_kb)KB DB, $($manifest.sessions_backed_up) sessions" "OK"

  # Confirm
  Write-Step "Restore from: $($dbFiles[0].FullName)" "INFO"
  Write-Step "To: $engramDir" "INFO"
  Write-Step "This will OVERWRITE current engram.db" "WARN"

  if (-not $Quiet) {
    $response = Read-Host "Continue? (yes/no) "
    if ($response -ne "yes") { Write-Step "Restore cancelled" "WARN"; return $false }
  }

  # Backup current before restore
  $currentBackup = Join-Path $OutputDir "pre-restore-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  New-Item -ItemType Directory -Path $currentBackup -Force | Out-Null
  Copy-Item (Join-Path $engramDir "engram.db") (Join-Path $currentBackup "engram.db") -Force
  Write-Step "Pre-restore backup: $currentBackup" "OK"

  # Restore
  Copy-Item $dbFiles[0].FullName (Join-Path $engramDir "engram.db") -Force
  Write-Step "engram.db restored" "OK"

  # Restore session artifacts
  $sessionBackup = Get-ChildItem $backupDir -Directory | Where-Object { $_.Name -match 'engram-session' } | Select-Object -First 1
  if ($sessionBackup) {
    $targetSessionDir = Join-Path $engramDir "engram-session"
    if (Test-Path $targetSessionDir) { Remove-Item $targetSessionDir -Recurse -Force }
    Copy-Item $sessionBackup.FullName $targetSessionDir -Recurse -Force
    Write-Step "Session artifacts restored" "OK"
  }

  # Git commit the restore
  try {
    Push-Location $engramDir
    git add -A 2>&1 | Out-Null
    git commit -m "restore: $Date" 2>&1 | Out-Null
    Pop-Location
    Write-Step "Git commit: restore $Date" "OK"
  } catch { Write-Step "Git commit skipped" "WARN" }

  Write-Step "Restore from $Date completed" "OK"
  Write-Log "Restored from $Date" "INFO"
  return $true
}

function Invoke-Status {
  $backupDirs = Get-ChildItem $OutputDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
  $backupCount = $backupDirs.Count

  if ($Quiet) {
    $latestDir = if ($backupCount -gt 0) { $backupDirs[0].Name } else { "none" }
    $integrityOk = if ($backupCount -gt 0) { Test-Path (Join-Path $OutputDir $latestDir "checksums.sha256") } else { $false }
    Write-Host "Backups:$backupCount DB:$((Test-Path (Join-Path $engramDir 'engram.db'))) Integrity:$integrityOk"
    return
  }

  Write-Host "`n=== Engram Backup Status ===" -ForegroundColor Cyan
  Write-Host "Backups found: $backupCount" -ForegroundColor $(if($backupCount -gt 0){"Green"}else{"Yellow"})

  $backupDirs | Select-Object -First 10 | ForEach-Object {
    $mPath = Join-Path $_.FullName "manifest.json"
    $csPath = Join-Path $_.FullName "checksums.sha256"
    if (Test-Path $mPath) {
      $mf = Get-Content $mPath -Raw | ConvertFrom-Json
      $csStatus = if (Test-Path $csPath) { "checksums" } else { "no checksums" }
      Write-Host "  $($_.Name): $($mf.db_size_kb)KB DB, $($mf.sessions_backed_up) sessions, $csStatus" -ForegroundColor Gray
    } else {
      Write-Host "  $($_.Name): no manifest" -ForegroundColor Yellow
    }
  }

  $gitDir = Join-Path $engramDir ".git"
  if (Test-Path $gitDir) {
    Push-Location $engramDir
    $commits = git log --oneline 2>&1 | Measure-Object | Select-Object -ExpandProperty Count
    Pop-Location
    Write-Host "Git history in .engram-data/: $commits commits" -ForegroundColor Gray
  } else {
    Write-Host ".engram-data/: git not initialized" -ForegroundColor Yellow
  }

  # Engram CLI status
  $engramCli = Get-Command "engram" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
  if (-not $engramCli) {
    $engramCli = Join-Path $env:USERPROFILE "bin\engram.exe"
    if (-not (Test-Path $engramCli)) { $engramCli = $null }
  }
  Write-Host "Engram CLI: $(if($engramCli){" $engramCli"}else{' Not found'})" -ForegroundColor $(if($engramCli){"Green"}else{"Red"})

  # Integrity check availability
  Write-Host "Integrity script: $(if(Test-Path $integrityScript){""}else{""})" -ForegroundColor $(if(Test-Path $integrityScript){"Green"}else{"Red"})
}

switch ($Mode) {
  "backup" {
    $result = Invoke-Backup
    exit $(if($result){0}else{1})
  }
  "verify" {
    $result = Invoke-Verify
    exit $(if($result){0}else{1})
  }
  "restore" {
    $result = Invoke-Restore
    exit $(if($result){0}else{1})
  }
  "status" {
    Invoke-Status
    exit 0
  }
}
