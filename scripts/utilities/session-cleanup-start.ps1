param(
    [string]$WorkspaceRoot = ".",
    [switch]$SkipOrphanCleanup,
    [switch]$SkipCacheFlush,
    [switch]$SkipCompression,
    [switch]$Quiet
)
$ErrorActionPreference = "Continue"
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } `
    else { $WorkspaceRoot }
$sessionDir = Join-Path $repoRoot ".session"
$sessionDir2 = Join-Path $repoRoot "session"
function Write-Log { param([string]$M) if (-not $Quiet) { Write-Host "[CLEANUP] $M" -ForegroundColor Cyan } }
function Write-OK  { param([string]$M) if (-not $Quiet) { Write-Host "[CLEANUP] $M" -ForegroundColor Green } }
function Write-W   { param([string]$M) if (-not $Quiet) { Write-Host "[CLEANUP] $M" -ForegroundColor Yellow } }

# ---- 1. Close orphaned sessions ----
if (-not $SkipOrphanCleanup) {
    Write-Log "Closing orphaned sessions..."
    $mgr = Join-Path $repoRoot "scripts\utilities\session-manager.ps1"
    if (Test-Path $mgr) {
        $orphanResult = & $mgr -Mode Cleanup -OrphanMaxAgeHours 8 -NoExit 2>&1
        if ($LASTEXITCODE -eq 0) { Write-OK "Orphan cleanup done" } `
            else { Write-W "Orphan cleanup exit: $LASTEXITCODE" }
    }
    # Additionally remove stale session JSON files older than 8hrs
    if (Test-Path $sessionDir2) {
        $cutoff = (Get-Date).AddHours(-8)
        $stale = Get-ChildItem $sessionDir2 -Filter "*.json" | Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Name -notlike "*$(Get-Date -Format yyyy-MM-dd)*" }
        foreach ($f in $stale) {
            Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
            Write-OK "Removed stale: $($f.Name)"
        }
    }
}

# ---- 2. Flush caches ----
if (-not $SkipCacheFlush) {
    Write-Log "Flushing session caches..."
    $targets = @(
        @{Path=Join-Path $sessionDir "normativa-cache"; Type="dir"}
        @{Path=Join-Path $sessionDir "preprocess-response-cache.json"; Type="file"}
        @{Path=Join-Path $sessionDir "token-usage.json"; Type="file"}
        @{Path=Join-Path $sessionDir "prompt-cache"; Type="dir"}
    )
    $flushed = 0
    foreach ($t in $targets) {
        $p = $t.Path
        if ($t.Type -eq "dir" -and (Test-Path $p)) {
            Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            $flushed++
        } elseif ($t.Type -eq "file" -and (Test-Path $p)) {
            Remove-Item $p -Force -ErrorAction SilentlyContinue
            $flushed++
        }
    }
    # Recreate dirs
    foreach ($d in @("normativa-cache","prompt-cache")) {
        $fp = Join-Path $sessionDir $d
        if (-not (Test-Path $fp)) { New-Item -ItemType Directory -Path $fp -Force | Out-Null }
    }
    Write-OK "Flushed $flushed cache targets"

    # Reset token tracking
    $tokenFile = Join-Path $sessionDir "token-usage.json"
    $sid = "session-$(Get-Date -Format 'yyyy-MM-dd_HHmm')"
    @{sessionId=$sid; startTime=(Get-Date -Format "o"); messages=@(); totalInputTokens=0; totalOutputTokens=0; totalTokens=0; totalContextChars=0; messageCount=0} |
        ConvertTo-Json -Depth 10 | Set-Content $tokenFile
    Write-OK "Token tracking reset for $sid"
}

# ---- 3. Generate compressed CLAUDE.min.md ----
if (-not $SkipCompression) {
    Write-Log "Generating compressed CLAUDE.min.md..."
    $compressor = Join-Path $repoRoot "scripts\utilities\semantic-compression.ps1"
    if (Test-Path $compressor) {
        $claudePath = Join-Path $repoRoot "CLAUDE.md"
        $minPath = Join-Path $sessionDir "CLAUDE.min.md"
        if (Test-Path $claudePath) {
            $result = & $compressor -InputPath $claudePath -OutputPath $minPath -Aggressive 2>&1
            if (Test-Path $minPath) {
                $origSize = (Get-Item $claudePath).Length
                $minSize = (Get-Item $minPath).Length
                Write-OK "CLAUDE.min.md generated: ${origSize} -> ${minSize} chars ($([Math]::Round((1-$minSize/$origSize)*100,1))% reduction)"
            }
        }
    } else {
        Write-W "Compressor not found, skipping"
    }
}

Write-OK "Session cleanup complete"
return $true