# read-once-guard.ps1
# Checks Engram/Memory to see if a file has already been analyzed in this context.
# Usage: .\read-once-guard.ps1 -FilePath "src/main.go"

param([string]$FilePath)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$cacheFile = Join-Path $repoRoot '.engram-data\read-cache.json'

if (-not (Test-Path $cacheFile)) {
    New-Item -ItemType Directory -Path (Split-Path $cacheFile) -Force | Out-Null
    @{} | ConvertTo-Json | Set-Content $cacheFile
}

$cache = Get-Content $cacheFile | ConvertFrom-Json
$normalizedPath = $FilePath.Replace('\', '/').ToLower()

if ($cache.PSObject.Properties[$normalizedPath]) {
    echo "[HIT] File '$FilePath' already analyzed. Using cached summary."
    exit 0 # Signal to use cache
} else {
    echo "[MISS] File '$FilePath' not in cache. Proceeding with full read."
    # After reading, the agent must call this script again with -MarkRead to update cache
    exit 1 # Signal to read file
}
