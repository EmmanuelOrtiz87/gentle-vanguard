<#
.SYNOPSIS
    Autonomous Backup & Recovery Orchestrator with Encryption
.DESCRIPTION
    Provides secure, autonomous backup and recovery for the stack:
    1. Backup: Delegates to backup-engram.ps1 for real DB + sessions + SHA256 checksums
    2. Encrypted metadata: AES-256 backup of norms + session state
    3. Recovery: Restore from latest backup + decryption
    4. Security: Only the stack can decrypt (key derived from workspace)
.PARAMETER Action
    What to do: backup, restore, check
.PARAMETER Trigger
    What triggered this: session-start, session-close, manual
.EXAMPLE
    .\auto-backup-orchestrator.ps1 -Action backup -Trigger session-start
.NOTES
    Delegates actual DB backup to backup-engram.ps1.
    This script adds AES-256 encrypted metadata on top (norms, session state).
    .backups/ is in .gitignore — never commit backups.
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("backup", "restore", "check")]
    [string]$Action = "check",

    [Parameter(Mandatory=$false)]
    [ValidateSet("session-start", "session-close", "manual")]
    [string]$Trigger = "manual",

    [Parameter(Mandatory=$false)]
    [switch]$IncludeRepo,

    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput,

    [Parameter(Mandatory=$false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = $PSScriptRoot }
if (-not $scriptDir) { $scriptDir = Get-Location }
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$backupDir = Join-Path $repoRoot ".backups"
$backupEngramScript = Join-Path $repoRoot "scripts/utilities/ops/BACKUP-RESTORE/backup-engram.ps1"
$backupMetaFile = Join-Path $backupDir "backup-meta.json"
$logFile = Join-Path $repoRoot "logs/auto-backup-orchestrator.log"

if (-not (Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    $gitignore = Join-Path $repoRoot ".gitignore"
    if (Test-Path $gitignore) {
        $content = Get-Content $gitignore -Raw
        if ($content -notmatch '\.backups/') {
            Add-Content -Path $gitignore -Value "`n# Encrypted backups (security)`n.backups/`n"
        }
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] [$Level] $Message" -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($VerboseOutput -or ($Level -eq "ERR" -and -not $Quiet)) {
        $color = @{INFO="Cyan"; OK="Green"; WARN="Yellow"; ERR="Red"}
        Write-Host "[ORCH::$Level] $Message" -ForegroundColor $color[$Level]
    }
}

function Get-EncryptionKey {
    $workspaceId = "gentle-vanguard-2026"
    $machineId = $env:COMPUTERNAME
    $userSalt = "opencode-stack-salt-2026"
    $keyMaterial = "$workspaceId|$machineId|$userSalt"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($keyMaterial)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($bytes)
    $sha256.Dispose()
    $key = New-Object byte[] 32
    [Array]::Copy($hash, 0, $key, 0, 32)
    return $key
}

function Protect-Data {
    param([string]$PlainText)
    try {
        $key = Get-EncryptionKey
        $iv = New-Object byte[] 16
        [System.Security.Cryptography.RandomNumberGenerator]::Fill($iv)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key; $aes.IV = $iv
        $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
        $encryptor = $aes.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
        $encryptor.Dispose()
        $result = New-Object byte[] ($iv.Length + $encryptedBytes.Length)
        [Array]::Copy($iv, 0, $result, 0, $iv.Length)
        [Array]::Copy($encryptedBytes, 0, $result, $iv.Length, $encryptedBytes.Length)
        $aes.Dispose()
        return [Convert]::ToBase64String($result)
    } catch {
        Write-Log "Encryption failed: $_" "ERR"
        return $null
    }
}

function Unprotect-Data {
    param([string]$EncryptedBase64)
    try {
        $key = Get-EncryptionKey
        $combinedBytes = [Convert]::FromBase64String($EncryptedBase64)
        $iv = New-Object byte[] 16
        [Array]::Copy($combinedBytes, 0, $iv, 0, 16)
        $encryptedBytes = New-Object byte[] ($combinedBytes.Length - 16)
        [Array]::Copy($combinedBytes, 16, $encryptedBytes, 0, $encryptedBytes.Length)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key; $aes.IV = $iv
        $decryptor = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
        $decryptor.Dispose(); $aes.Dispose()
        return [System.Text.Encoding]::UTF8.GetString($plainBytes)
    } catch {
        Write-Log "Decryption failed: $_" "ERR"
        return $null
    }
}

function Invoke-Backup {
    Write-Log "Auto-backup started (Trigger: $Trigger)" "INFO"

    $backupData = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        trigger = $Trigger
        version = "1.1.0"
        components = @()
        errors = @()
    }

    # 1. Delegar backup real de DB + sessions a backup-engram.ps1
    Write-Log "Step 1: Running backup-engram.ps1..." "INFO"
    if (Test-Path $backupEngramScript) {
        $beResult = & $backupEngramScript -Mode backup -Quiet 2>&1
        $beExit = $LASTEXITCODE
        if ($beExit -eq 0) {
            $backupData.components += "engram-db+sessions+checksums"
            Write-Log "backup-engram.ps1 completed" "OK"
        } else {
            $errMsg = "backup-engram.ps1 exited with code $beExit"
            $backupData.errors += $errMsg
            Write-Log $errMsg "ERR"
        }
    } else {
        Write-Log "backup-engram.ps1 not found at $backupEngramScript" "WARN"
        $backupData.errors += "backup-engram.ps1 not found"
    }

    # 2. Encrypt and backup learned norms (AES-256)
    Write-Log "Step 2: Backing up learned norms (encrypted)..." "INFO"
    $adaptiveDir = Join-Path $repoRoot "rules/adaptive"
    if (Test-Path $adaptiveDir) {
        $normsBackup = Join-Path $backupDir "learned-norms.json"
        $normsContent = Get-Content (Join-Path $adaptiveDir "LEARNED-NORMS.md") -Raw -ErrorAction SilentlyContinue
        if ($normsContent) {
            $encrypted = Protect-Data -PlainText $normsContent
            if ($encrypted) {
                $encrypted | Out-File -FilePath "$normsBackup.enc" -Encoding UTF8
                $backupData.components += "learned-norms"
                Write-Log "Learned norms encrypted backup saved" "OK"
            }
        }
    }

    # 3. Encrypt and backup session state (AES-256)
    Write-Log "Step 3: Backing up session state (encrypted)..." "INFO"
    $sessionDir = Join-Path $repoRoot ".session"
    if (Test-Path $sessionDir) {
        $sessionBackup = Join-Path $backupDir "session-state.json"
        $sessions = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue | ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            @{ file = $_.Name; content = $content }
        }
        if ($sessions) {
            $sessionData = @{ sessions = $sessions; timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
            $json = $sessionData | ConvertTo-Json -Depth 10
            $encrypted = Protect-Data -PlainText $json
            if ($encrypted) {
                $encrypted | Out-File -FilePath "$sessionBackup.enc" -Encoding UTF8
                $backupData.components += "session-state"
                Write-Log "Session state encrypted backup saved" "OK"
            }
        }
    }

    # 4. Save backup metadata
    $backupData.hash = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($backupData.components -join "|")))
    $backupData | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupMetaFile -Encoding UTF8
    Write-Log "Backup metadata saved" "OK"

    Write-Log "Backup complete: $($backupData.components -join ', ')" "OK"
    return @{ status = if($backupData.errors.Count -eq 0){"SUCCESS"}else{"PARTIAL"}; components = $backupData.components; errors = $backupData.errors; timestamp = $backupData.timestamp }
}

function Invoke-Restore {
    Write-Log "Auto-restore started" "INFO"

    if (-not (Test-Path $backupMetaFile)) {
        Write-Log "No backup meta found at $backupMetaFile" "WARN"
        return @{ status = "NO_BACKUP"; restored = 0 }
    }

    $backupMeta = Get-Content $backupMetaFile -Raw | ConvertFrom-Json
    Write-Log "Found backup from: $($backupMeta.timestamp)" "INFO"
    Write-Log "Components: $($backupMeta.components -join ', ')" "INFO"

    $restored = 0

    # Restore learned norms
    $normsBackup = Join-Path $backupDir "learned-norms.json.enc"
    if (Test-Path $normsBackup) {
        Write-Log "Restoring learned norms..." "INFO"
        $encrypted = Get-Content $normsBackup -Raw
        $decrypted = Unprotect-Data -EncryptedBase64 $encrypted
        if ($decrypted) {
            $adaptiveDir = Join-Path $repoRoot "rules/adaptive"
            if (-not (Test-Path $adaptiveDir)) { New-Item -Path $adaptiveDir -ItemType Directory -Force | Out-Null }
            $decrypted | Out-File -FilePath (Join-Path $adaptiveDir "LEARNED-NORMS.md") -Encoding UTF8
            $restored++
            Write-Log "Learned norms restored" "OK"
        }
    }

    # Restore session state
    $sessionBackup = Join-Path $backupDir "session-state.json.enc"
    if (Test-Path $sessionBackup) {
        Write-Log "Restoring session state..." "INFO"
        $encrypted = Get-Content $sessionBackup -Raw
        $decrypted = Unprotect-Data -EncryptedBase64 $encrypted
        if ($decrypted) {
            $sessionDir = Join-Path $repoRoot ".session"
            if (-not (Test-Path $sessionDir)) { New-Item -Path $sessionDir -ItemType Directory -Force | Out-Null }
            try {
                $sessionData = $decrypted | ConvertFrom-Json
                foreach ($s in $sessionData.sessions) {
                    $s.content | Out-File -FilePath (Join-Path $sessionDir $s.file) -Encoding UTF8
                }
                $restored++
                Write-Log "Session state restored ($($sessionData.sessions.Count) files)" "OK"
            } catch {
                Write-Log "Failed to parse session state: $_" "WARN"
            }
        }
    }

    Write-Log "Restore complete: $restored components restored" "OK"
    return @{ status = "SUCCESS"; restored = $restored; backup_timestamp = $backupMeta.timestamp }
}

function Invoke-Check {
    Write-Log "Backup status check" "INFO"

    $backupEngramStatus = if (Test-Path $backupEngramScript) {
        $result = & $backupEngramScript -Mode status -Quiet 2>&1
        if ($LASTEXITCODE -eq 0) { "operational" } else { "error" }
    } else { "not-found" }

    if (-not (Test-Path $backupMetaFile)) {
        return @{ status = "NO_BACKUP"; backup_engram = $backupEngramStatus }
    }

    $backupMeta = Get-Content $backupMetaFile -Raw | ConvertFrom-Json
    $backupTime = [DateTime]::Parse($backupMeta.timestamp)
    $age = (Get-Date) - $backupTime
    $stale = $age.TotalHours -gt 24

    return @{
        status = "EXISTS"
        backup_engram = $backupEngramStatus
        timestamp = $backupMeta.timestamp
        age_hours = [math]::Round($age.TotalHours, 1)
        stale = $stale
        components = $backupMeta.components
        errors = if ($backupMeta.errors) { @($backupMeta.errors) } else { @() }
    }
}

switch ($Action) {
    "backup" { $result = Invoke-Backup }
    "restore" { $result = Invoke-Restore }
    "check" { $result = Invoke-Check }
}

return $result
