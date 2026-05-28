param(
    [ValidateSet('init', 'verify', 'update', 'status', 'prune')]
    [string]$Action = 'status',
    [string]$Path = '',
    [string]$LineId = '',
    [string]$Content = '',
    [int]$LineNumber = 0,
    [string]$HashDb = '',
    [switch]$Fix,
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path

if (-not $HashDb) {
    $HashDb = Join-Path $repoRoot '.runtime' 'hashline-db.json'
}

$dbDir = Split-Path -Parent $HashDb
if (-not (Test-Path $dbDir)) { New-Item -ItemType Directory -Path $dbDir -Force | Out-Null }

function Write-HashLine {
    param([string]$M, [string]$C = 'White')
    if (-not $Quiet) { Write-Host $M -ForegroundColor $C }
}

function Read-Db {
    if (Test-Path $HashDb) {
        try { return Get-Content $HashDb -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable } catch { }
    }
    return @{ files = @{}; version = '1.0.0'; created = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK' }
}

function Write-Db {
    param([object]$Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content $HashDb -Encoding UTF8 -Force
}

function Get-LineHash {
    param([string]$Line)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Line)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return ($hash | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Get-FileLines {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return @() }
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    return $content -split '\r?\n'
}

function Get-RelativePath {
    param([string]$AbsolutePath)
    $fullRepo = (Resolve-Path $repoRoot).Path
    $fullFile = (Resolve-Path $AbsolutePath -ErrorAction SilentlyContinue).Path
    if (-not $fullFile) { return $AbsolutePath }
    if ($fullFile -match "^$([regex]::Escape($fullRepo))\\") {
        return $fullFile.Substring($fullRepo.Length + 1)
    }
    return $fullFile
}

# === ACTIONS ===

switch ($Action) {
    'init' {
        $targets = @()
        if ($Path) {
            if (Test-Path $Path -PathType Container) {
                $targets = Get-ChildItem $Path -Recurse -File | Where-Object {
                    $_.Extension -match '\.(ps1|psm1|psd1|ts|tsx|js|jsx|json|yml|yaml|md|css|scss|html|cs|go|py|rs|java|kt|swift)$'
                }
            } elseif (Test-Path $Path) {
                $targets = @(Get-Item $Path)
            } else {
                Write-HashLine "[ERROR] Path not found: $Path" 'Red'
                exit 1
            }
        } else {
            $targets = Get-ChildItem $repoRoot -Recurse -File | Where-Object {
                $_.FullName -notmatch '\\node_modules\\|\\\.git\\|\\dist\\|\\\.runtime\\|\\coverage\\|\\\.engram-data\\|\\session\\|\\\.event-bus\\|\\deprecated\\|\\tools\\' -and
                $_.Extension -match '\.(ps1|psm1|psd1|ts|tsx|js|jsx|json|yml|yaml|md|css|scss|html|cs|go|py|rs|java|kt|swift)$'
            }
        }

        $db = Read-Db
        $count = 0
        foreach ($file in $targets) {
            $relPath = Get-RelativePath -AbsolutePath $file.FullName
            $lines = Get-FileLines -FilePath $file.FullName
            if ($lines.Count -eq 0) { continue }

            $lineHashes = @{}
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $lineNum = $i + 1
                if ($lines[$i] -eq $null) { $lines[$i] = '' }
                $lineHashes["$lineNum"] = @{
                    line = $lineNum
                    hash = Get-LineHash -Line $lines[$i]
                    content_preview = if ($lines[$i].Length -gt 80) { $lines[$i].Substring(0, 80) } else { $lines[$i] }
                }
            }

            $db.files[$relPath] = @{
                path = $relPath
                total_lines = $lines.Count
                line_hashes = $lineHashes
                file_hash = Get-LineHash -Line ($lines -join "`n")
                updated = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
            }
            $count++
        }

        $db.$('last_init') = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        Write-Db $db
        Write-HashLine "[HASHLINE] Initialized $count files" 'Green'
        if ($AsJson) { return (@{ status = 'ok'; files_initialized = $count } | ConvertTo-Json) }
    }

    'verify' {
        $db = Read-Db
        if (-not $Path) {
            Write-HashLine "[ERROR] -Path required for verify" 'Red'
            exit 1
        }
        $relPath = Get-RelativePath -AbsolutePath $Path
        if (-not $db.files.$relPath) {
            Write-HashLine "[HASHLINE] No hash data for: $relPath. Run 'init' first." 'Yellow'
            if ($AsJson) { return (@{ status = 'no-data'; path = $relPath } | ConvertTo-Json) }
            exit 0
        }

        $lines = Get-FileLines -FilePath $Path
        $stored = $db.files.$relPath
        $issues = @()

        $maxLines = [Math]::Max($lines.Count, $stored.total_lines)
        for ($i = 0; $i -lt $maxLines; $i++) {
            $lineNum = $i + 1
            $currentLine = if ($i -lt $lines.Count) { $lines[$i] } else { $null }
            $storedLine = $stored.line_hashes."$lineNum"

            if ($currentLine -eq $null -and $storedLine) {
                $issues += @{ line = $lineNum; type = 'deleted'; stored_hash = $storedLine.hash }
            } elseif ($currentLine -ne $null -and -not $storedLine) {
                $issues += @{ line = $lineNum; type = 'added'; current_hash = Get-LineHash -Line $currentLine }
            } elseif ($currentLine -ne $null -and $storedLine) {
                $currentHash = Get-LineHash -Line $currentLine
                if ($currentHash -ne $storedLine.hash) {
                    $issues += @{
                        line = $lineNum
                        type = 'modified'
                        stored_hash = $storedLine.hash
                        current_hash = $currentHash
                        stored_preview = $storedLine.content_preview
                        current_preview = if ($currentLine.Length -gt 80) { $currentLine.Substring(0, 80) } else { $currentLine }
                    }
                }
            }
        }

        if ($issues.Count -eq 0 -and $lines.Count -eq $stored.total_lines) {
            Write-HashLine "[HASHLINE] OK: $relPath ($($lines.Count) lines, all hashes match)" 'Green'
            if ($AsJson) { return (@{ status = 'ok'; path = $relPath; issues = @() } | ConvertTo-Json) }
            return
        }

        Write-HashLine "[HASHLINE] ISSUES: $relPath ($($issues.Count) changes)" 'Yellow'
        foreach ($issue in $issues) {
            switch ($issue.type) {
                'modified' {
                    Write-Host "  L$($issue.line) MODIFIED" -ForegroundColor Yellow
                    Write-Host "    was: '$($issue.stored_preview)'" -ForegroundColor Gray
                    Write-Host "    now: '$($issue.current_preview)'" -ForegroundColor Gray
                }
                'deleted' {
                    Write-Host "  L$($issue.line) DELETED" -ForegroundColor Red
                }
                'added' {
                    Write-Host "  L$($issue.line) ADDED" -ForegroundColor Green
                }
            }
        }

        if ($Fix) {
            Write-HashLine "[HASHLINE] Updating hashes for $relPath..." 'Cyan'
            $newLineHashes = @{}
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $lineNum = $i + 1
                if ($lines[$i] -eq $null) { $lines[$i] = '' }
                $newLineHashes["$lineNum"] = @{
                    line = $lineNum
                    hash = Get-LineHash -Line $lines[$i]
                    content_preview = if ($lines[$i].Length -gt 80) { $lines[$i].Substring(0, 80) } else { $lines[$i] }
                }
            }
            $db.files.$relPath.line_hashes = $newLineHashes
            $db.files.$relPath.total_lines = $lines.Count
            $db.files.$relPath.file_hash = Get-LineHash -Line ($lines -join "`n")
            $db.files.$relPath.updated = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
            Write-Db $db
            Write-HashLine "[HASHLINE] Hashes updated for $relPath" 'Green'
        }

        if ($AsJson) {
            return (@{ status = if ($issues.Count -eq 0) { 'ok' } else { 'issues' }; path = $relPath; issues = $issues } | ConvertTo-Json)
        }
    }

    'update' {
        if (-not $Path) {
            Write-HashLine "[ERROR] -Path required for update" 'Red'
            exit 1
        }
        $relPath = Get-RelativePath -AbsolutePath $Path
        if (-not (Test-Path $Path)) {
            $db = Read-Db
            if ($db.files.$relPath) {
                $db.files.PSObject.Properties.Remove($relPath)
                Write-Db $db
                Write-HashLine "[HASHLINE] Removed deleted file: $relPath" 'Yellow'
            }
            if ($AsJson) { return (@{ status = 'removed'; path = $relPath } | ConvertTo-Json) }
            exit 0
        }

        $db = Read-Db
        $lines = Get-FileLines -FilePath $Path
        $lineHashes = @{}
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNum = $i + 1
            if ($lines[$i] -eq $null) { $lines[$i] = '' }
            $lineHashes["$lineNum"] = @{
                line = $lineNum
                hash = Get-LineHash -Line $lines[$i]
                content_preview = if ($lines[$i].Length -gt 80) { $lines[$i].Substring(0, 80) } else { $lines[$i] }
            }
        }
        $db.files[$relPath] = @{
            path = $relPath
            total_lines = $lines.Count
            line_hashes = $lineHashes
            file_hash = Get-LineHash -Line ($lines -join "`n")
            updated = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        }
        Write-Db $db
        Write-HashLine "[HASHLINE] Updated: $relPath ($($lines.Count) lines)" 'Green'
        if ($AsJson) { return (@{ status = 'updated'; path = $relPath; lines = $lines.Count } | ConvertTo-Json) }
    }

    'status' {
        $db = Read-Db
        $fileCount = @($db.files.PSObject.Properties).Count
        $totalLines = 0
        $totalHashes = 0
        foreach ($f in $db.files.PSObject.Properties) {
            $totalLines += $f.Value.total_lines
            $totalHashes += @($f.Value.line_hashes.PSObject.Properties).Count
        }
        $dbSize = if (Test-Path $HashDb) { "{0:N2} KB" -f ((Get-Item $HashDb).Length / 1KB) } else { '0 KB' }

        Write-HashLine "=== HASHLINE STATUS ===" 'Cyan'
        Write-Host "  Database: $HashDb ($dbSize)" -ForegroundColor Gray
        Write-Host "  Version: $($db.version)" -ForegroundColor White
        Write-Host "  Files tracked: $fileCount" -ForegroundColor White
        Write-Host "  Total lines: $totalLines" -ForegroundColor White
        Write-Host "  Total hashes: $totalHashes" -ForegroundColor White
        Write-Host "  Last init: $($db.last_init)" -ForegroundColor Gray

        if ($AsJson) {
            return (@{
                status = 'active'
                version = $db.version
                files_tracked = $fileCount
                total_lines = $totalLines
                total_hashes = $totalHashes
                database = $HashDb
                created = $db.created
                last_init = $db.last_init
            } | ConvertTo-Json)
        }
    }

    'prune' {
        $db = Read-Db
        $removed = 0
        $toRemove = @()
        foreach ($f in $db.files.PSObject.Properties) {
            $absPath = Join-Path $repoRoot $f.Name
            if (-not (Test-Path $absPath -ErrorAction SilentlyContinue)) {
                $toRemove += $f.Name
            }
        }
        foreach ($name in $toRemove) {
            $db.files.PSObject.Properties.Remove($name)
            $removed++
        }
        Write-Db $db
        Write-HashLine "[HASHLINE] Pruned $removed stale entries" 'Green'
        if ($AsJson) { return (@{ status = 'pruned'; removed = $removed } | ConvertTo-Json) }
    }
}
