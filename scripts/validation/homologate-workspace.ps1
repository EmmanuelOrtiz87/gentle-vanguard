param(
    [switch]$Apply,
    [switch]$OrganizeRootDocs,
    [switch]$SkipReferenceUpdate,
    [switch]$SkipArtifactCleanup,
    [switch]$SkipTempCleanup,
    [switch]$SkipEmptyDirCleanup
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

function To-RepoRelative {
    param([string]$Path)
    return $Path.Replace(($repoRoot + '\\'), '').Replace('\\', '/')
}

function Write-Action {
    param(
        [string]$Kind,
        [string]$Message
    )
    Write-Host "[$Kind] $Message"
}

function Get-UniquePath {
    param(
        [string]$DesiredPath
    )

    if (-not (Test-Path $DesiredPath)) {
        return $DesiredPath
    }

    $dir = Split-Path $DesiredPath -Parent
    $base = [System.IO.Path]::GetFileNameWithoutExtension($DesiredPath)
    $ext = [System.IO.Path]::GetExtension($DesiredPath)

    $i = 1
    while ($true) {
        $candidate = Join-Path $dir ("{0}-migrated-{1}{2}" -f $base, $i, $ext)
        if (-not (Test-Path $candidate)) {
            return $candidate
        }
        $i++
    }
}

function Add-RenameMapping {
    param(
        [hashtable]$Map,
        [string]$OldPath,
        [string]$NewPath
    )
    $oldRel = To-RepoRelative -Path $OldPath
    $newRel = To-RepoRelative -Path $NewPath
    $Map[$oldRel] = $newRel
}

$renameMap = @{}
$removedCount = 0
$movedCount = 0
$updatedRefCount = 0
$cleanedDirCount = 0

# 1) Artifact homologation (rename old-format artifacts to HHmmss or remove duplicates)
if (-not $SkipArtifactCleanup) {
    $artifactRoots = @(
        (Join-Path $repoRoot 'docs/audits'),
        (Join-Path $repoRoot 'docs/sessions'),
        (Join-Path $repoRoot 'docs/code-reviews')
    )

    $artifactFiles = foreach ($root in $artifactRoots) {
        if (Test-Path $root) {
            Get-ChildItem -Path $root -File -ErrorAction SilentlyContinue
        }
    }

    foreach ($file in $artifactFiles) {
        $newName = $null

        if ($file.Name -match '^(\d{4}-\d{2}-\d{2})-audit\.md$') {
            $newName = "{0}-audit.md" -f $file.LastWriteTime.ToString('yyyy-MM-dd-HHmmss')
        } elseif ($file.Name -match '^(\d{4}-\d{2}-\d{2})-(\d{4})-context-pack\.md$') {
            $newName = "{0}-context-pack.md" -f $file.LastWriteTime.ToString('yyyy-MM-dd-HHmmss')
        } elseif ($file.Name -match '^(\d{4}-\d{2}-\d{2})-session-review\.md$') {
            $newName = "{0}-session-review.md" -f $file.LastWriteTime.ToString('yyyy-MM-dd-HHmmss')
        } elseif ($file.Name -match '^(\d{4}-\d{2}-\d{2})-session-start(?:-\d{6})?\.md$') {
            $newName = "{0}-session-start.md" -f $file.LastWriteTime.ToString('yyyy-MM-dd-HHmmss')
        }

        if (-not $newName -or $newName -eq $file.Name) {
            continue
        }

        $targetPath = Join-Path $file.DirectoryName $newName
        if (Test-Path $targetPath) {
            $oldHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
            $newHash = (Get-FileHash -Path $targetPath -Algorithm SHA256).Hash

            if ($oldHash -eq $newHash) {
                Write-Action -Kind 'DELETE' -Message ("duplicate old-format artifact {0}" -f (To-RepoRelative -Path $file.FullName))
                Add-RenameMapping -Map $renameMap -OldPath $file.FullName -NewPath $targetPath
                if ($Apply) {
                    Remove-Item -Path $file.FullName -Force
                }
                $removedCount++
                continue
            }

            $targetPath = Get-UniquePath -DesiredPath $targetPath
        }

        Write-Action -Kind 'RENAME' -Message ("{0} -> {1}" -f (To-RepoRelative -Path $file.FullName), (To-RepoRelative -Path $targetPath))
        Add-RenameMapping -Map $renameMap -OldPath $file.FullName -NewPath $targetPath
        if ($Apply) {
            Move-Item -Path $file.FullName -Destination $targetPath -Force
        }
        $movedCount++
    }
}

# 2) Optional root markdown organization
if ($OrganizeRootDocs) {
    $rootDocMap = @{
        'CROSS-PLATFORM-SETUP.md' = 'docs/getting-started/CROSS-PLATFORM-SETUP.md'
        'STACK-SETUP.md'          = 'docs/getting-started/STACK-SETUP.md'
        'SUITE-OVERVIEW.md'       = 'docs/reference/SUITE-OVERVIEW.md'
        'VALIDATION-REPORT.md'    = 'docs/reference/VALIDATION-REPORT.md'
    }

    foreach ($sourceName in $rootDocMap.Keys) {
        $sourcePath = Join-Path $repoRoot $sourceName
        if (-not (Test-Path $sourcePath)) {
            continue
        }

        $targetRel = $rootDocMap[$sourceName]
        $targetPath = Join-Path $repoRoot $targetRel
        $targetDir = Split-Path $targetPath -Parent
        if (-not (Test-Path $targetDir)) {
            if ($Apply) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
        }

        if (Test-Path $targetPath) {
            $oldHash = (Get-FileHash -Path $sourcePath -Algorithm SHA256).Hash
            $newHash = (Get-FileHash -Path $targetPath -Algorithm SHA256).Hash
            if ($oldHash -eq $newHash) {
                Write-Action -Kind 'DELETE' -Message ("root duplicate {0}" -f $sourceName)
                Add-RenameMapping -Map $renameMap -OldPath $sourcePath -NewPath $targetPath
                if ($Apply) {
                    Remove-Item -Path $sourcePath -Force
                }
                $removedCount++
                continue
            }

            $targetPath = Get-UniquePath -DesiredPath $targetPath
        }

        Write-Action -Kind 'MOVE' -Message ("{0} -> {1}" -f $sourceName, (To-RepoRelative -Path $targetPath))
        Add-RenameMapping -Map $renameMap -OldPath $sourcePath -NewPath $targetPath
        if ($Apply) {
            Move-Item -Path $sourcePath -Destination $targetPath -Force
        }
        $movedCount++
    }
}

# 3) Remove temporary / deprecated files
if (-not $SkipTempCleanup) {
    $tempFiles = Get-ChildItem -Path $repoRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '\\.git\\' -and
            $_.Name -match '\\.(tmp|bak|old|orig)$'
        }

    foreach ($tmp in $tempFiles) {
        Write-Action -Kind 'DELETE' -Message ("temp file {0}" -f (To-RepoRelative -Path $tmp.FullName))
        if ($Apply) {
            Remove-Item -Path $tmp.FullName -Force
        }
        $removedCount++
    }
}

# 4) Update references after moves/renames
if (-not $SkipReferenceUpdate -and $renameMap.Count -gt 0) {
    $docAliasMap = @{
        'CROSS-PLATFORM-SETUP.md' = '/docs/getting-started/CROSS-PLATFORM-SETUP.md'
        'STACK-SETUP.md'          = '/docs/getting-started/STACK-SETUP.md'
        'SUITE-OVERVIEW.md'       = '/docs/reference/SUITE-OVERVIEW.md'
        'VALIDATION-REPORT.md'    = '/docs/reference/VALIDATION-REPORT.md'
    }

    $targets = Get-ChildItem -Path $repoRoot -Recurse -File -Include *.md,*.ps1,*.json,*.yml,*.yaml,*.sh -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '\\.git\\' -and
            $_.FullName -notmatch '\\node_modules\\'
        }

    foreach ($f in $targets) {
        $raw = Get-Content -Path $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $raw) { continue }

        $updated = $raw

        foreach ($oldRel in $renameMap.Keys) {
            $newRel = $renameMap[$oldRel]
            if ($updated.Contains($oldRel)) {
                $updated = $updated.Replace($oldRel, $newRel)
            }

            $oldName = Split-Path $oldRel -Leaf
            $newName = Split-Path $newRel -Leaf
            if ($updated.Contains($oldName)) {
                $updated = $updated.Replace($oldName, $newName)
            }
        }

        foreach ($alias in $docAliasMap.Keys) {
            $canonical = $docAliasMap[$alias]
            $updated = $updated.Replace("($alias)", "($canonical)")
            $updated = $updated.Replace("(./$alias)", "($canonical)")
            $updated = $updated.Replace("(../$alias)", "($canonical)")
            $updated = $updated.Replace("(../../$alias)", "($canonical)")
        }

        if ($updated -ne $raw) {
            Write-Action -Kind 'UPDATE' -Message ("references in {0}" -f (To-RepoRelative -Path $f.FullName))
            if ($Apply) {
                Set-Content -Path $f.FullName -Value $updated -Encoding UTF8
            }
            $updatedRefCount++
        }
    }
}

# 5) Remove empty timestamp directories left from old layouts
if (-not $SkipEmptyDirCleanup) {
    $sessionDir = Join-Path $repoRoot 'docs/sessions'
    if (Test-Path $sessionDir) {
        $candidateDirs = Get-ChildItem -Path $sessionDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}-\d{4,6}$' }

        foreach ($dir in $candidateDirs) {
            $children = Get-ChildItem -Path $dir.FullName -Force -ErrorAction SilentlyContinue
            if (-not $children -or $children.Count -eq 0) {
                Write-Action -Kind 'DELETE' -Message ("empty dir {0}" -f (To-RepoRelative -Path $dir.FullName))
                if ($Apply) {
                    Remove-Item -Path $dir.FullName -Force
                }
                $cleanedDirCount++
            }
        }
    }
}

Write-Host ''
Write-Host '=== Homologation Summary ===' -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($Apply) { 'APPLY' } else { 'DRY-RUN' })))
Write-Host ("Moved/Renamed: {0}" -f $movedCount)
Write-Host ("Removed: {0}" -f $removedCount)
Write-Host ("Files with reference updates: {0}" -f $updatedRefCount)
Write-Host ("Empty dirs removed: {0}" -f $cleanedDirCount)

if (-not $Apply) {
    Write-Host 'Run again with -Apply to execute changes.' -ForegroundColor Yellow
}
