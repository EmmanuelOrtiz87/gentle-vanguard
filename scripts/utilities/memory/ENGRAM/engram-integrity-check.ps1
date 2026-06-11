param(
    [ValidateSet("check", "repair", "checksums", "status")]
    [string]$Mode = "check",
    [string]$EngramDir = "",
    [string]$BackupDir = "",
    [switch]$AutoRepair,
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$script:RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
if (-not $EngramDir) { $EngramDir = Join-Path $script:RepoRoot ".engram" }
if (-not $BackupDir) { $BackupDir = Join-Path $script:RepoRoot ".backups/engram" }
$engramDataDir = Join-Path $script:RepoRoot ".engram-data"
$dbPath = Join-Path $engramDataDir "engram.db"
$checksumPath = Join-Path $EngramDir "checksums.sha256"
$manifestPath = Join-Path $EngramDir "manifest.json"

$global:exitCode = 0

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    if ($Quiet -and $Status -ne "ERR") { return }
    $color = @{INFO="Cyan"; OK="Green"; WARN="Yellow"; ERR="Red"; FATAL="Magenta"}
    Write-Host "[INTEGRITY::$Status] $Message" -ForegroundColor $color[$Status]
}

function Write-Result {
    param([string]$Test, [string]$Result)
    $icon = if ($Result -eq "PASS") { "[OK]" } else { "[FAIL]" }
    $color = if ($Result -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $icon $Test" -ForegroundColor $color
    if ($Result -ne "PASS") { $global:exitCode = 1 }
}

function New-Checksums {
    Write-Step "Generating SHA256 checksums..." "INFO"
    $checksums = @()
    $count = 0
    $chunksDir = Join-Path $EngramDir "chunks"
    if (Test-Path $chunksDir) {
        Get-ChildItem $chunksDir -Filter "*.jsonl.gz" | ForEach-Object {
            $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            $checksums += "$hash *$($_.Name)"
            $count++
        }
    }
    if (Test-Path $dbPath) {
        $hash = (Get-FileHash $dbPath -Algorithm SHA256).Hash
        $checksums += "$hash *engram.db"
        $count++
    }
    $checksums | Set-Content $checksumPath -Encoding UTF8
    Write-Step "Checksums written: $count files" "OK"
    return $checksums
}

function Verify-Checksums {
    Write-Step "Verifying checksums..." "INFO"
    if (-not (Test-Path $checksumPath)) {
        Write-Step "No checksums file found at $checksumPath" "WARN"
        Write-Result "Checksums file exists" "FAIL"
        return $false
    }
    $errors = 0
    $verified = 0
    Get-Content $checksumPath | ForEach-Object {
        if ($_ -match "^([0-9a-fA-F]{64}) \*(\S+)$") {
            $expectedHash = $Matches[1]
            $fileName = $Matches[2]
            $filePath = if ($fileName -eq "engram.db") { $dbPath } else { Join-Path $EngramDir "chunks/$fileName" }
            if (Test-Path $filePath) {
                $actualHash = (Get-FileHash $filePath -Algorithm SHA256).Hash
                if ($actualHash -eq $expectedHash) {
                    $verified++
                } else {
                    Write-Step "Hash MISMATCH: $fileName" "ERR"
                    Write-Result "Checksum: $fileName" "FAIL"
                    $errors++
                }
            } else {
                Write-Step "File not found: $fileName" "ERR"
                Write-Result "File exists: $fileName" "FAIL"
                $errors++
            }
        }
    }
    if ($errors -eq 0) {
        Write-Step "All $verified checksums verified OK" "OK"
        Write-Result "Checksum integrity" "PASS"
        return $true
    } else {
        Write-Step "$errors checksum mismatches found" "ERR"
        return $false
    }
}

function Verify-Manifest {
    Write-Step "Verifying manifest..." "INFO"
    if (-not (Test-Path $manifestPath)) {
        Write-Step "Manifest not found" "WARN"
        Write-Result "Manifest exists" "FAIL"
        return $false
    }
    try {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $valid = $manifest.version -eq 1 -and $manifest.chunks -ne $null
        if ($valid) {
            $chunksDir = Join-Path $EngramDir "chunks"
            foreach ($chunk in $manifest.chunks) {
                $chunkPath = Join-Path $chunksDir "$($chunk.id).jsonl.gz"
                if (-not (Test-Path $chunkPath)) {
                    Write-Step "Manifest references missing chunk: $($chunk.id)" "WARN"
                    Write-Result "Chunk $($chunk.id) exists" "FAIL"
                    $valid = $false
                }
            }
        }
        if ($valid) {
            Write-Result "Manifest integrity" "PASS"
        } else {
            Write-Step "Manifest validation failed" "ERR"
        }
        return $valid
    } catch {
        Write-Step "Manifest parse error: $_" "ERR"
        Write-Result "Manifest is valid JSON" "FAIL"
        return $false
    }
}

function Test-DbHeader {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false, "Not found" }
    $fi = Get-Item $Path
    if ($fi.Length -eq 0) { return $false, "Empty file" }
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        $header = New-Object byte[] 16
        $bytesRead = $stream.Read($header, 0, 16)
        $stream.Close()
        if ($bytesRead -lt 16) { return $false, "Too small" }
        $sqliteMagic = [byte[]]@(0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00)
        $isSqlite = $true
        for ($i = 0; $i -lt 16; $i++) { if ($header[$i] -ne $sqliteMagic[$i]) { $isSqlite = $false; break } }
        if ($isSqlite) { return $true, "$([math]::Round($fi.Length/1KB,1))KB" }
        return $false, "Not SQLite (header: $($header[0..3] -join ','))"
    } catch { return $false, "Unreadable: $_" }
}

function Verify-Database {
    Write-Step "Verifying SQLite database..." "INFO"
    if (-not (Test-Path $dbPath)) {
        Write-Step "engram.db not found" "WARN"
        Write-Result "engram.db exists" "FAIL"
        return $false
    }
    $ok, $detail = Test-DbHeader $dbPath
    if ($ok) {
        Write-Result "SQLite header: $detail" "PASS"
        return $true
    } else {
        Write-Step "engram.db check: $detail" "ERR"
        Write-Result "engram.db is valid SQLite" "FAIL"
        return $false
    }
}

function Invoke-IntegrityCheck {
    Write-Step "=== Full Integrity Check ===" "INFO"
    $allPass = $true

    Write-Step "1) Manifest" "INFO"
    if (-not (Verify-Manifest)) { $allPass = $false }

    Write-Step "2) Database" "INFO"
    if (-not (Verify-Database)) { $allPass = $false }

    Write-Step "3) Checksums" "INFO"
    $checksumsExist = Test-Path $checksumPath
    if ($checksumsExist) {
        if (-not (Verify-Checksums)) { $allPass = $false }
    } else {
        Write-Step "No checksums file  --  run with -Mode checksums to create" "WARN"
    }

    Write-Step "4) Chunks directory" "INFO"
    $chunksDir = Join-Path $EngramDir "chunks"
    if (-not (Test-Path $chunksDir)) {
        Write-Step "Chunks directory missing" "WARN"
        Write-Result "Chunks directory" "FAIL"
        $allPass = $false
    } else {
        $chunkCount = (Get-ChildItem $chunksDir -Filter "*.jsonl.gz").Count
        if ($chunkCount -gt 0) {
            Write-Result "Chunks directory ($chunkCount files)" "PASS"
        } else {
            Write-Step "Chunks directory is empty" "WARN"
            Write-Result "Chunks have content" "FAIL"
            $allPass = $false
        }
    }

    Write-Step "5) Backup verification" "INFO"
    $backupsExist = Test-Path $BackupDir
    if ($backupsExist) {
        $backupCount = (Get-ChildItem $BackupDir -Directory).Count
        $latestBackup = Get-ChildItem $BackupDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($latestBackup) {
            $backupDb = Get-ChildItem $latestBackup.FullName -Filter "*.db" | Select-Object -First 1
            if ($backupDb -and $backupDb.Length -gt 0) {
                Write-Result "Latest backup ($($latestBackup.Name), $([math]::Round($backupDb.Length/1KB))KB)" "PASS"
            } else {
                Write-Step "Latest backup may be incomplete" "WARN"
                Write-Result "Backup integrity" "FAIL"
                $allPass = $false
            }
        }
    } else {
        Write-Step "No backup directory found" "WARN"
        Write-Result "Backup exists" "FAIL"
    }

    if ($allPass) {
        Write-Step "INTEGRITY: ALL PASS" "OK"
    } else {
        Write-Step "INTEGRITY: $global:exitCode FAILURES DETECTED" "ERR"
    }
    return $allPass
}

function Invoke-AutoRepair {
    Write-Step "Attempting auto-repair..." "WARN"
    $repairs = 0

    if (-not (Test-Path $checksumPath)) {
        Write-Step "Generating new checksums..." "INFO"
        New-Checksums | Out-Null
        $repairs++
    }

    $chunksDir = Join-Path $EngramDir "chunks"
    if (-not (Test-Path $chunksDir)) {
        New-Item -ItemType Directory -Path $chunksDir -Force | Out-Null
        Write-Step "Created missing chunks directory" "OK"
        $repairs++
    }

    $manifest = $null
    if (Test-Path $manifestPath) {
        try { $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json } catch {}
    }
    if (-not $manifest) {
        $defaultManifest = @{ version = 1; chunks = @() }
        $defaultManifest | ConvertTo-Json | Set-Content $manifestPath -Encoding UTF8
        Write-Step "Rebuilt manifest" "OK"
        $repairs++
    }

    if ($repairs -gt 0) {
        Write-Step "Auto-repair completed: $repairs fixes" "OK"
    } else {
        Write-Step "No repairs needed" "INFO"
    }
    return $repairs
}

switch ($Mode) {
    "check" {
        Invoke-IntegrityCheck
        exit $global:exitCode
    }
    "repair" {
        $checkResult = Invoke-IntegrityCheck
        Invoke-AutoRepair
        if (-not $checkResult) {
            Write-Step "=== Re-checking after repair ===" "INFO"
            Invoke-IntegrityCheck
        }
        exit $global:exitCode
    }
    "checksums" {
        New-Checksums | Out-Null
        Write-Step "Checksums regenerated. Run 'check' to verify." "OK"
        exit 0
    }
    "status" {
        Write-Step "=== Engram Integrity Status ===" "INFO"
        $chunksDir = Join-Path $EngramDir "chunks"
        $chunkCount = if (Test-Path $chunksDir) { (Get-ChildItem $chunksDir -Filter "*.jsonl.gz").Count } else { 0 }
        $dbOk = Test-Path $dbPath
        $dbSize = if ($dbOk) { "{0:N0}" -f ((Get-Item $dbPath).Length / 1KB) } else { "N/A" }
        $checksumsOk = Test-Path $checksumPath
        $backupOk = Test-Path $BackupDir
        $backupCount = if ($backupOk) { (Get-ChildItem $BackupDir -Directory).Count } else { 0 }

        Write-Host "  Database: $(if($dbOk){'[OK] ' + $dbSize + 'KB'}else{'[FAIL] Not found'})"
        Write-Host "  Chunks: $chunkCount files"
        Write-Host "  Checksums: $(if($checksumsOk){'[OK] Present'}else{'[FAIL] Missing'})"
        Write-Host "  Backups: $backupCount snapshots"
        exit 0
    }
}
