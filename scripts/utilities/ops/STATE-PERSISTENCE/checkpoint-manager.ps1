#Requires -Version 7.0
<#
.SYNOPSIS
    Checkpoint Manager — Creates and manages session state snapshots for rollback

.DESCRIPTION
    Provides atomic checkpoint creation, listing, restore, and pruning for session state.
    Each checkpoint stores the full .session directory state with SHA256 manifest.
    Integrates with Engram for integrity verification.

.NOTES
    Part of Phase 2 — State Persistence v4.0
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('create', 'list', 'restore', 'prune', 'verify', 'diff')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$CheckpointId,

    [Parameter(Mandatory = $false)]
    [int]$MaxCheckpoints = 10,

    [Parameter(Mandatory = $false)]
    [int]$MaxAgeHours = 72,

    [Parameter(Mandatory = $false)]
    [string]$Label,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$checkpointDir = Join-Path $root '.session' 'checkpoints'
$manifestDir = Join-Path $root '.session' 'manifests'
$sessionDir = Join-Path $root '.session'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $c = @{'INFO' = 'Cyan'; 'WARN' = 'Yellow'; 'ERROR' = 'Red'; 'SUCCESS' = 'Green'}[$Level]
    if (-not $Quiet) { Write-Host "[$t] [CKPT] [$Level] $Message" -ForegroundColor $c }
    Add-Content -Path (Join-Path $root '.session' 'checkpoint.log') -Value "[$t] [$Level] $Message" -ErrorAction SilentlyContinue
}

function New-CheckpointId {
    return "ckpt-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(-join ((1..6) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) }))"
}

function Get-CheckpointPath {
    param([string]$Id)
    return Join-Path $checkpointDir $Id
}

function Get-ManifestPath {
    param([string]$Id)
    return Join-Path $manifestDir "$Id.json"
}

function Compute-FileHash {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    }
    return $null
}

function Get-CheckpointSize {
    param([string]$Dir)
    if (Test-Path $Dir) {
        return (Get-ChildItem -Path $Dir -Recurse -File | Measure-Object -Property Length -Sum).Sum
    }
    return 0
}

switch ($Action) {
    'create' {
        $id = if ($CheckpointId) { $CheckpointId } else { New-CheckpointId }
        $target = Get-CheckpointPath -Id $id

        if (Test-Path $target) {
            if ($Force) {
                Remove-Item -Path $target -Recurse -Force
            } else {
                throw "Checkpoint $id already exists. Use -Force to overwrite."
            }
        }

    New-Item -ItemType Directory -Path $target -Force | Out-Null
    if (-not (Test-Path $manifestDir)) { New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null }

    $manifest = @{
        checkpointId = $id
        createdAt    = (Get-Date -Format 'o')
            label        = $Label
            files        = @()
            totalSize    = 0
            sessionId    = [Environment]::GetEnvironmentVariable('SESSION_ID', 'User')
        }

        $items = Get-ChildItem -Path $sessionDir -Recurse -File | Where-Object {
            $_.Extension -in '.json', '.log', '.md', '.txt', '.csv', '.yaml', '.yml', '.ps1', '.state.json'
        }

        foreach ($item in $items) {
            $relPath = $item.FullName.Substring($sessionDir.Length + 1)
            $destDir = Join-Path $target (Split-Path $relPath -Parent)
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $item.FullName -Destination (Join-Path $destDir $item.Name) -Force
            $hash = Compute-FileHash -Path $item.FullName
            $manifest.files += @{
                path = $relPath
                size = $item.Length
                sha256 = $hash
            }
            $manifest.totalSize += $item.Length
        }

        $manifest.totalSizeFormatted = if ($manifest.totalSize -gt 1MB) {
            "{0:N1} MB" -f ($manifest.totalSize / 1MB)
        } elseif ($manifest.totalSize -gt 1KB) {
            "{0:N1} KB" -f ($manifest.totalSize / 1KB)
        } else { "$($manifest.totalSize) B" }

        $manifest.count = $manifest.files.Count
        $manifest | ConvertTo-Json -Depth 10 | Set-Content (Get-ManifestPath -Id $id)

        Write-Log "Checkpoint $id created: $($manifest.count) files, $($manifest.totalSizeFormatted)" 'SUCCESS'
        return $manifest
    }

    'list' {
        $checkpoints = @()
        if (Test-Path $checkpointDir) {
            $dirs = Get-ChildItem -Path $checkpointDir -Directory | Sort-Object Name -Descending
            foreach ($dir in $dirs) {
                $mPath = Get-ManifestPath -Id $dir.Name
                $meta = if (Test-Path $mPath) { Get-Content $mPath -Raw | ConvertFrom-Json } else { $null }
                $checkpoints += @{
                    id        = $dir.Name
                    createdAt = if ($meta) { $meta.createdAt } else { $dir.CreationTime.ToString('o') }
                    label     = if ($meta) { $meta.label } else { $null }
                    count     = if ($meta) { $meta.count } else { 0 }
                    size      = if ($meta) { $meta.totalSizeFormatted } else { 'N/A' }
                }
            }
        }
        return $checkpoints
    }

    'restore' {
        if (-not $CheckpointId) { throw 'CheckpointId required for restore' }
        $target = Get-CheckpointPath -Id $CheckpointId
        if (-not (Test-Path $target)) { throw "Checkpoint $CheckpointId not found" }

        $mPath = Get-ManifestPath -Id $CheckpointId
        $manifest = if (Test-Path $mPath) { Get-Content $mPath -Raw | ConvertFrom-Json } else { $null }

        Write-Log "Restoring checkpoint $CheckpointId..." 'INFO'

        $files = Get-ChildItem -Path $target -Recurse -File
        $restored = 0
        $errors = 0

        foreach ($file in $files) {
            try {
                $relPath = $file.FullName.Substring($target.Length + 1)
                $destPath = Join-Path $sessionDir $relPath
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                Copy-Item -Path $file.FullName -Destination $destPath -Force
                if ($manifest) {
                    $expected = $manifest.files | Where-Object { $_.path -eq $relPath }
                    if ($expected) {
                        $actualHash = Compute-FileHash -Path $destPath
                        if ($actualHash -ne $expected.sha256) {
                            Write-Log "Hash mismatch for $relPath" 'WARN'
                            $errors++
                        }
                    }
                }
                $restored++
            } catch {
                Write-Log "Failed to restore $($file.Name): $_" 'ERROR'
                $errors++
            }
        }

        Write-Log "Restored $restored files from checkpoint $CheckpointId ($errors errors)" 'SUCCESS'
        return @{ restored = $restored; errors = $errors; checkpointId = $CheckpointId }
    }

    'prune' {
        $checkpoints = @()
        if (Test-Path $checkpointDir) {
            $dirs = Get-ChildItem -Path $checkpointDir -Directory | Sort-Object CreationTime -Descending
            if ($dirs.Count -gt $MaxCheckpoints) {
                $toDelete = $dirs | Select-Object -Skip $MaxCheckpoints
                foreach ($dir in $toDelete) {
                    Remove-Item -Path $dir.FullName -Recurse -Force
                    $mPath = Get-ManifestPath -Id $dir.Name
                    if (Test-Path $mPath) { Remove-Item -Path $mPath -Force }
                    $checkpoints += $dir.Name
                    Write-Log "Pruned checkpoint $($dir.Name)" 'INFO'
                }
            }
            $cutoff = (Get-Date).AddHours(-$MaxAgeHours)
            $dirs = Get-ChildItem -Path $checkpointDir -Directory | Where-Object { $_.CreationTime -lt $cutoff }
            foreach ($dir in $dirs) {
                Remove-Item -Path $dir.FullName -Recurse -Force
                $mPath = Get-ManifestPath -Id $dir.Name
                if (Test-Path $mPath) { Remove-Item -Path $mPath -Force }
                $checkpoints += $dir.Name
                Write-Log "Pruned expired checkpoint $($dir.Name) (age > ${MaxAgeHours}h)" 'INFO'
            }
        }
        return @{ pruned = $checkpoints.Count; ids = $checkpoints }
    }

    'verify' {
        if (-not $CheckpointId) { throw 'CheckpointId required for verify' }
        $mPath = Get-ManifestPath -Id $CheckpointId
        if (-not (Test-Path $mPath)) { throw "Manifest for $CheckpointId not found" }
        $manifest = Get-Content $mPath -Raw | ConvertFrom-Json

        $valid = 0; $invalid = 0; $missing = 0
        foreach ($f in $manifest.files) {
            $currentPath = Join-Path $sessionDir $f.path
            if (Test-Path $currentPath) {
                $hash = Compute-FileHash -Path $currentPath
                if ($hash -eq $f.sha256) { $valid++ } else { $invalid++ }
            } else { $missing++ }
        }

        $status = if ($invalid -eq 0 -and $missing -eq 0) { 'INTACT' } elseif ($invalid -gt 0) { 'CORRUPTED' } else { 'PARTIAL' }

        # Engram integrity integration: cross-check against Engram checksums
        $engramCheck = Join-Path $root 'scripts/utilities/memory/ENGRAM/engram-integrity-check.ps1'
        $engramStatus = 'not-checked'
        if (Test-Path $engramCheck) {
            $engramResult = & $engramCheck -Mode check -Quiet 2>&1
            $engramStatus = if ($LASTEXITCODE -eq 0) { 'passed' } else { 'failed' }
            Write-Log "Engram integrity: $engramStatus" 'INFO'
        }

        Write-Log "Checkpoint ${CheckpointId}: $status ($valid valid, $invalid corrupted, $missing missing)" 'INFO'
        return @{
            checkpointId  = $CheckpointId
            status        = $status
            valid         = $valid
            invalid       = $invalid
            missing       = $missing
            engramStatus  = $engramStatus
        }
    }

    'diff' {
        if (-not $CheckpointId) { throw 'CheckpointId required for diff' }
        $mPath = Get-ManifestPath -Id $CheckpointId
        if (-not (Test-Path $mPath)) { throw "Manifest for $CheckpointId not found" }
        $manifest = Get-Content $mPath -Raw | ConvertFrom-Json

        $added = @(); $modified = @(); $deleted = @()
        $checkpointPaths = @{}
        foreach ($f in $manifest.files) { $checkpointPaths[$f.path] = $f }

        $currentFiles = Get-ChildItem -Path $sessionDir -Recurse -File | Where-Object {
            $_.Extension -in '.json', '.log', '.md', '.txt', '.csv', '.yaml', '.yml', '.ps1', '.state.json'
        }

        $currentPaths = @{}
        foreach ($f in $currentFiles) {
            $rel = $f.FullName.Substring($sessionDir.Length + 1)
            $currentPaths[$rel] = $f
        }

        foreach ($rel in $currentPaths.Keys) {
            if (-not $checkpointPaths.ContainsKey($rel)) {
                $added += $rel
            } else {
                $hash = Compute-FileHash -Path $currentPaths[$rel].FullName
                if ($hash -ne $checkpointPaths[$rel].sha256) { $modified += $rel }
            }
        }

        foreach ($rel in $checkpointPaths.Keys) {
            if (-not $currentPaths.ContainsKey($rel)) { $deleted += $rel }
        }

        return @{
            checkpointId = $CheckpointId
            added = $added | Sort-Object
            modified = $modified | Sort-Object
            deleted = $deleted | Sort-Object
        }
    }
}
