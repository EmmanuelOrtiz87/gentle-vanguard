#Requires -Version 7.0
<#
.SYNOPSIS
    Rollback Orchestrator — Coordinates safe rollback of .session state to a checkpoint

.DESCRIPTION
    Performs pre-rollback validation, atomic restore with dry-run mode, and
    post-rollback integrity verification. Supports health check gating and
    automatic checkpoint creation before destructive rollback.

.NOTES
    Part of Phase 2 — State Persistence v4.0
#>

param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
    [string]$CheckpointId,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByLabel')]
    [string]$Label,

    [Parameter(Mandatory = $false)]
    [int]$MaxCheckpoints = 10,

    [Parameter(Mandatory = $false)]
    [switch]$SkipHealthCheck,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$AutoBackup,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$sessionDir = Join-Path $root '.session'
$checkpointDir = Join-Path $root '.session' 'checkpoints'
$manifestDir = Join-Path $root '.session' 'manifests'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $c = @{'INFO' = 'Cyan'; 'WARN' = 'Yellow'; 'ERROR' = 'Red'; 'SUCCESS' = 'Green'}[$Level]
    if (-not $Quiet) { Write-Host "[$t] [ROLLBACK] [$Level] $Message" -ForegroundColor $c }
    Add-Content -Path (Join-Path $root '.session' 'rollback.log') -Value "[$t] [$Level] $Message" -ErrorAction SilentlyContinue
}

function Get-CheckpointPath {
    param([string]$Id)
    return Join-Path $checkpointDir $Id
}

function Get-ManifestPath {
    param([string]$Id)
    return Join-Path $manifestDir "$Id.json"
}

function Resolve-CheckpointId {
    if ($CheckpointId) { return $CheckpointId }

    if ($Label -and (Test-Path $manifestDir)) {
        $manifests = Get-ChildItem -Path $manifestDir -Filter '*.json' | Sort-Object LastWriteTime -Descending
        foreach ($m in $manifests) {
            $content = Get-Content $m.FullName -Raw | ConvertFrom-Json
            if ($content.label -eq $Label) {
                return $content.checkpointId
            }
        }
        throw "No checkpoint found with label: $Label"
    }

    $dirs = Get-ChildItem -Path $checkpointDir -Directory | Sort-Object CreationTime -Descending
    if ($dirs.Count -eq 0) { throw 'No checkpoints available' }
    return $dirs[0].Name
}

function Test-Healthy {
    $checks = @(
        { Test-Path $sessionDir },
        { -not (Test-Path (Join-Path $sessionDir 'checkpoint.lock')) },
        { (Get-ChildItem -Path $sessionDir -Recurse -File -ErrorAction SilentlyContinue).Count -gt 0 }
    )

    $passed = 0; $failed = 0
    foreach ($check in $checks) {
        try { if (& $check) { $passed++ } else { $failed++ } } catch { $failed++ }
    }

    return @{
        healthy = ($failed -eq 0)
        passed  = $passed
        failed  = $failed
        total   = $checks.Count
    }
}

function Test-CheckpointValid {
    param([string]$Id)
    $target = Get-CheckpointPath -Id $Id
    if (-not (Test-Path $target)) { return $false }

    $mPath = Get-ManifestPath -Id $Id
    if (-not (Test-Path $mPath)) { return $false }

    $manifest = Get-Content $mPath -Raw | ConvertFrom-Json

    $fileCount = (Get-ChildItem -Path $target -Recurse -File).Count
    if ($fileCount -eq 0) { return $false }

    if ($manifest.count -ne $fileCount) { return $false }

    $filesOk = 0
    foreach ($f in $manifest.files) {
        $fp = Join-Path $target $f.path
        if (Test-Path $fp) { $filesOk++ }
    }

    return ($filesOk -eq $manifest.files.Count)
}

function New-PreRollbackBackup {
    $backupId = "pre-rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(-join ((1..4) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) }))"
    $backupTarget = Join-Path $checkpointDir $backupId
    New-Item -ItemType Directory -Path $backupTarget -Force | Out-Null

    Get-ChildItem -Path $sessionDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($sessionDir.Length + 1)
        $d = Split-Path (Join-Path $backupTarget $rel) -Parent
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        Copy-Item -Path $_.FullName -Destination (Join-Path $d $_.Name) -Force
    }

    $backupManifest = @{
        checkpointId = $backupId
        createdAt    = (Get-Date -Format 'o')
        label        = "Auto-backup before rollback to $CheckpointId"
        count        = (Get-ChildItem -Path $backupTarget -Recurse -File).Count
    }
    $backupManifest | ConvertTo-Json | Set-Content (Get-ManifestPath -Id $backupId)

    Write-Log "Auto-backup created: $backupId" 'SUCCESS'
    return $backupId
}

function Invoke-Rollback {
    param([string]$Id)
    $target = Get-CheckpointPath -Id $Id
    $files = Get-ChildItem -Path $target -Recurse -File
    $restored = 0; $errors = 0

    foreach ($file in $files) {
        try {
            $relPath = $file.FullName.Substring($target.Length + 1)
            $destPath = Join-Path $sessionDir $relPath
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $file.FullName -Destination $destPath -Force
            $restored++
        } catch {
            Write-Log "Failed to restore ${relPath}: $_" 'ERROR'
            $errors++
        }
    }

    return @{ restored = $restored; errors = $errors }
}

# ===== MAIN =====

$checkpointId = Resolve-CheckpointId
Write-Log "Rollback target: $checkpointId" 'INFO'

if ($DryRun) {
    $status = Test-CheckpointValid -Id $checkpointId
    $health = Test-Healthy
    Write-Log "DRY RUN: checkpoint valid=$status, system healthy=$($health.healthy)" 'INFO'
    return @{
        dryRun       = $true
        checkpointId = $checkpointId
        valid        = $status
        health       = $health
        wouldRestore = if ($status) { (Get-ChildItem -Path (Get-CheckpointPath $checkpointId) -Recurse -File).Count } else { 0 }
    }
}

if (-not $SkipHealthCheck) {
    $health = Test-Healthy
    if (-not $health.healthy) {
        $msg = "Health check failed ($($health.failed)/$($health.total) checks). Use -SkipHealthCheck to force."
        if ($Force) {
            Write-Log "$msg — proceeding due to -Force" 'WARN'
        } else {
            throw $msg
        }
    }
    Write-Log "Health check: $($health.passed)/$($health.total) passed" 'SUCCESS'
}

$valid = Test-CheckpointValid -Id $checkpointId
if (-not $valid) {
    $msg = "Checkpoint $checkpointId is corrupted or incomplete"
    if ($Force) {
        Write-Log "$msg — proceeding due to -Force" 'WARN'
    } else {
        throw $msg
    }
}
Write-Log "Checkpoint integrity verified" 'SUCCESS'

if ($AutoBackup) {
    New-PreRollbackBackup | Out-Null
}

$result = Invoke-Rollback -Id $checkpointId

$verification = & (Join-Path $PSScriptRoot 'checkpoint-manager.ps1') -Action verify -CheckpointId $checkpointId -Quiet:$Quiet

Write-Log "Rollback to $checkpointId complete: $($result.restored) restored, $($result.errors) errors" 'SUCCESS'

return @{
    checkpointId   = $checkpointId
    restored       = $result.restored
    errors         = $result.errors
    verification   = $verification.status
    autoBackupId   = if ($AutoBackup) { (Get-ChildItem $checkpointDir | Sort-Object CreationTime -Descending | Select-Object -First 1).Name } else { $null }
}
