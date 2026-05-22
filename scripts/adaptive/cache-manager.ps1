#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gentle-Vanguard Intelligent Cache Manager — Multi-tier L1/L2/L3/Archive caching
    
.DESCRIPTION
    Implements a local-first multi-tier caching strategy:
    - L1: In-memory (process-scoped hashtable, <1ms access, 1-5 min TTL)
    - L2: Local file cache (disk-backed, <5ms access, 5-60 min TTL)  
    - L3: Persistent structured cache (JSONL, hours TTL, survives restarts)
    - Archive: Cold storage cache (compressed, indefinite, for large artifacts)
    
    No Redis/Memcached required — pure PowerShell, zero external dependencies.
    Cloud backends (Redis, Memcached) can be plugged in via adapters.
    
.PARAMETER Command
    get | set | invalidate | flush | stats | warm | gc
    
.PARAMETER Key
    Cache key (supports namespaces: "namespace:key")
    
.PARAMETER Value
    Value to cache (for 'set' command)
    
.PARAMETER Tier
    Target tier: L1 | L2 | L3 | Archive | auto (default: auto — writes to all, reads from fastest)
    
.PARAMETER TTL
    Time-to-live in seconds (0 = use tier default)
    
.PARAMETER Tag
    Tag(s) for group invalidation (comma-separated)

.EXAMPLE
    .\cache-manager.ps1 set --Key "skills:list" --Value $json --TTL 300
    .\cache-manager.ps1 get --Key "skills:list"
    .\cache-manager.ps1 invalidate --Tag "skills"
    .\cache-manager.ps1 stats
    .\cache-manager.ps1 gc
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet('get', 'set', 'invalidate', 'flush', 'stats', 'warm', 'gc')]
    [string]$Command = 'stats',

    [string]$Key,
    [string]$Value,
    [ValidateSet('L1', 'L2', 'L3', 'Archive', 'auto')]
    [string]$Tier = 'auto',
    [int]$TTL = 0,
    [string]$Tag = '',
    [switch]$Compress
)

$ErrorActionPreference = 'Stop'
$CACHE_VERSION = '1.0.0'

# ── Paths ──────────────────────────────────────────────────────────────────────
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Get-Location
}
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptRoot))
if (-not (Test-Path (Join-Path $WorkspaceRoot 'config'))) {
    $WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
}
$CacheRoot    = Join-Path $env:TEMP 'gentle-vanguard-cache'
$L2Dir        = Join-Path $CacheRoot 'l2'
$L3Dir        = Join-Path $CacheRoot 'l3'
$ArchiveDir   = Join-Path $CacheRoot 'archive'
$CacheMetaDir = Join-Path $CacheRoot '.meta'
$StatsFile    = Join-Path $CacheRoot 'cache-stats.json'

# ── Tier TTL defaults (seconds) ────────────────────────────────────────────────
$TierDefaults = @{
    L1      = 120    # 2 min  — process lifetime
    L2      = 1800   # 30 min — local file
    L3      = 14400  # 4 hr   — persistent
    Archive = 0      # indefinite
}

# ── L1: In-memory cache (persists for module/script lifetime) ──────────────────
# Uses a static hashtable keyed per process via global variable
if (-not $Global:Gentle-VanguardL1Cache) {
    $Global:Gentle-VanguardL1Cache = @{}
}
$L1 = $Global:Gentle-VanguardL1Cache

# ── Bootstrap dirs ─────────────────────────────────────────────────────────────
foreach ($dir in @($CacheRoot, $L2Dir, $L3Dir, $ArchiveDir, $CacheMetaDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ── Stats tracking ─────────────────────────────────────────────────────────────
function Get-Stats {
    if (Test-Path $StatsFile) {
        try { return Get-Content $StatsFile -Raw | ConvertFrom-Json -AsHashtable }
        catch {}
    }
    return @{ hits = @{L1=0;L2=0;L3=0;Archive=0}; misses = 0; sets = 0; evictions = 0; startedAt = (Get-Date -Format 'o') }
}

function Save-Stats { param([hashtable]$s) $s | ConvertTo-Json -Depth 4 | Set-Content $StatsFile -Encoding UTF8 }

function Increment-Stat {
    param([string]$stat, [string]$tier = '')
    $s = Get-Stats
    if ($tier -and $stat -eq 'hit') { $s.hits[$tier]++ }
    elseif ($stat -eq 'miss')   { $s.misses++ }
    elseif ($stat -eq 'set')    { $s.sets++ }
    elseif ($stat -eq 'evict')  { $s.evictions++ }
    Save-Stats $s
}

# ── Key sanitization ───────────────────────────────────────────────────────────
function Get-SafeKey {
    param([string]$k)
    return $k -replace '[^\w:.\-]', '_'
}

function Get-CacheFilePath {
    param([string]$k, [string]$tier)
    $safe = (Get-SafeKey $k) -replace ':', '__'
    $dir  = switch ($tier) { 'L2' { $L2Dir } 'L3' { $L3Dir } 'Archive' { $ArchiveDir } default { $L2Dir } }
    return Join-Path $dir "$safe.cache.json"
}

# ── Meta helpers ───────────────────────────────────────────────────────────────
function New-CacheEntry {
    param([string]$key, [string]$value, [int]$ttl, [string]$tier, [string]$tags)
    return @{
        key       = $key
        value     = $value
        tier      = $tier
        ttl       = $ttl
        createdAt = (Get-Date -Format 'o')
        expiresAt = if ($ttl -gt 0) { (Get-Date).AddSeconds($ttl).ToString('o') } else { $null }
        tags      = if ($tags) { $tags -split ',' | ForEach-Object { $_.Trim() } } else { @() }
        version   = $CACHE_VERSION
        compressed = $false
    }
}

function Test-Expired {
    param($entry)
    if (-not $entry.expiresAt) { return $false }
    return ([datetime]$entry.expiresAt) -lt (Get-Date)
}

# ── L1 operations ──────────────────────────────────────────────────────────────
function Get-L1 {
    param([string]$key)
    if ($L1.ContainsKey($key)) {
        $entry = $L1[$key]
        if (-not (Test-Expired $entry)) { return $entry }
        $L1.Remove($key)
    }
    return $null
}

function Set-L1 {
    param([string]$key, [string]$value, [int]$ttl, [string]$tags)
    $t = if ($ttl -gt 0) { $ttl } else { $TierDefaults.L1 }
    $L1[$key] = New-CacheEntry $key $value $t 'L1' $tags
}

# ── L2 operations ──────────────────────────────────────────────────────────────
function Get-L2 {
    param([string]$key)
    $path = Get-CacheFilePath $key 'L2'
    if (-not (Test-Path $path)) { return $null }
    try {
        $entry = Get-Content $path -Raw | ConvertFrom-Json
        if (Test-Expired $entry) { Remove-Item $path -Force; return $null }
        return $entry
    } catch { return $null }
}

function Set-L2 {
    param([string]$key, [string]$value, [int]$ttl, [string]$tags)
    $t = if ($ttl -gt 0) { $ttl } else { $TierDefaults.L2 }
    $entry = New-CacheEntry $key $value $t 'L2' $tags
    $entry | ConvertTo-Json -Depth 6 | Set-Content (Get-CacheFilePath $key 'L2') -Encoding UTF8
}

# ── L3 operations ──────────────────────────────────────────────────────────────
function Get-L3 {
    param([string]$key)
    $path = Get-CacheFilePath $key 'L3'
    if (-not (Test-Path $path)) { return $null }
    try {
        $entry = Get-Content $path -Raw | ConvertFrom-Json
        if (Test-Expired $entry) { Remove-Item $path -Force; return $null }
        return $entry
    } catch { return $null }
}

function Set-L3 {
    param([string]$key, [string]$value, [int]$ttl, [string]$tags)
    $t = if ($ttl -gt 0) { $ttl } else { $TierDefaults.L3 }
    $entry = New-CacheEntry $key $value $t 'L3' $tags
    $entry | ConvertTo-Json -Depth 6 | Set-Content (Get-CacheFilePath $key 'L3') -Encoding UTF8
}

# ── Archive operations ─────────────────────────────────────────────────────────
function Get-Archive {
    param([string]$key)
    $path = Get-CacheFilePath $key 'Archive'
    if (-not (Test-Path $path)) { return $null }
    try { return Get-Content $path -Raw | ConvertFrom-Json }
    catch { return $null }
}

function Set-Archive {
    param([string]$key, [string]$value, [string]$tags)
    $entry = New-CacheEntry $key $value 0 'Archive' $tags
    $entry | ConvertTo-Json -Depth 6 | Set-Content (Get-CacheFilePath $key 'Archive') -Encoding UTF8
}

# ── Auto-tier selection ─────────────────────────────────────────────────────────
function Get-AutoTier {
    param([int]$ttl, [string]$value)
    $size = [System.Text.Encoding]::UTF8.GetByteCount($value)
    if ($ttl -eq 0)         { return 'Archive' }
    if ($ttl -le 300)       { return 'L1' }   # ≤5 min
    if ($ttl -le 3600)      { return 'L2' }   # ≤1 hr
    if ($size -gt 1048576)  { return 'Archive' }  # >1MB → archive
    return 'L3'
}

# ══ COMMANDS ═══════════════════════════════════════════════════════════════════

function Invoke-Get {
    if (-not $Key) { throw "--Key is required." }
    $k = Get-SafeKey $Key
    
    # Read-through: L1 → L2 → L3 → Archive
    $entry = Get-L1 $k
    if ($entry) { Increment-Stat 'hit' 'L1'; Write-Output $entry.value; return }
    
    $entry = Get-L2 $k
    if ($entry) {
        Increment-Stat 'hit' 'L2'
        Set-L1 $k $entry.value $entry.ttl $($entry.tags -join ',')  # promote to L1
        Write-Output $entry.value; return
    }
    
    $entry = Get-L3 $k
    if ($entry) {
        Increment-Stat 'hit' 'L3'
        Set-L1 $k $entry.value $entry.ttl $($entry.tags -join ',')  # promote to L1
        Set-L2 $k $entry.value $entry.ttl $($entry.tags -join ',')  # promote to L2
        Write-Output $entry.value; return
    }
    
    $entry = Get-Archive $k
    if ($entry) {
        Increment-Stat 'hit' 'Archive'
        Write-Output $entry.value; return
    }
    
    Increment-Stat 'miss'
    return $null  # Cache miss — caller must fetch from source
}

function Invoke-Set {
    if (-not $Key)   { throw "--Key is required." }
    if (-not $Value) { throw "--Value is required." }
    
    $k = Get-SafeKey $Key
    $effectiveTier = if ($Tier -eq 'auto') { Get-AutoTier $TTL $Value } else { $Tier }
    $effectiveTTL  = if ($TTL -gt 0) { $TTL } else { $TierDefaults[$effectiveTier] }
    
    switch ($effectiveTier) {
        'L1'      { Set-L1 $k $Value $effectiveTTL $Tag }
        'L2'      { Set-L1 $k $Value ($effectiveTTL / 2) $Tag; Set-L2 $k $Value $effectiveTTL $Tag }
        'L3'      { Set-L1 $k $Value $TierDefaults.L1 $Tag; Set-L2 $k $Value $TierDefaults.L2 $Tag; Set-L3 $k $Value $effectiveTTL $Tag }
        'Archive' { Set-Archive $k $Value $Tag }
    }
    
    Increment-Stat 'set'
    Write-Host "[OK] Cached '$Key' → tier=$effectiveTier ttl=${effectiveTTL}s" -ForegroundColor Green
}

function Invoke-Invalidate {
    $removed = 0
    
    if ($Key) {
        $k = Get-SafeKey $Key
        if ($L1.ContainsKey($k)) { $L1.Remove($k); $removed++ }
        foreach ($tier in @('L2', 'L3', 'Archive')) {
            $p = Get-CacheFilePath $k $tier
            if (Test-Path $p) { Remove-Item $p -Force; $removed++ }
        }
        Write-Host "[OK] Invalidated key '$Key' ($removed entries removed)" -ForegroundColor Green
        return
    }
    
    if ($Tag) {
        $tags = $Tag -split ',' | ForEach-Object { $_.Trim() }
        # Scan L2/L3/Archive for tagged entries
        foreach ($dir in @($L2Dir, $L3Dir, $ArchiveDir)) {
            Get-ChildItem $dir -Filter '*.cache.json' -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $entry = Get-Content $_.FullName -Raw | ConvertFrom-Json
                    $entryTags = @($entry.tags)
                    $hasTag = $tags | Where-Object { $entryTags -contains $_ }
                    if ($hasTag) { Remove-Item $_.FullName -Force; $removed++ }
                } catch {}
            }
        }
        # Clear all L1 entries with matching tags
        $toRemove = @($L1.Keys | Where-Object {
            $entry = $L1[$_]
            $entryTags = @($entry.tags)
            ($tags | Where-Object { $entryTags -contains $_ }) -ne $null
        })
        $toRemove | ForEach-Object { $L1.Remove($_); $removed++ }
        Write-Host "[OK] Invalidated tag '$Tag' ($removed entries removed)" -ForegroundColor Green
        return
    }
    
    throw "Provide --Key or --Tag to invalidate specific entries, or use 'flush' to clear all."
}

function Invoke-Flush {
    $L1.Clear()
    @($L2Dir, $L3Dir, $ArchiveDir) | ForEach-Object {
        Get-ChildItem $_ -Filter '*.cache.json' -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    if (Test-Path $StatsFile) { Remove-Item $StatsFile -Force }
    Write-Host "[OK] All cache tiers flushed." -ForegroundColor Green
}

function Invoke-Stats {
    $stats  = Get-Stats
    $l2cnt  = (Get-ChildItem $L2Dir -Filter '*.cache.json' -ErrorAction SilentlyContinue | Measure-Object).Count
    $l3cnt  = (Get-ChildItem $L3Dir -Filter '*.cache.json' -ErrorAction SilentlyContinue | Measure-Object).Count
    $arccnt = (Get-ChildItem $ArchiveDir -Filter '*.cache.json' -ErrorAction SilentlyContinue | Measure-Object).Count
    
    $totalHits = ($stats.hits.L1 + $stats.hits.L2 + $stats.hits.L3 + $stats.hits.Archive)
    $totalOps  = $totalHits + $stats.misses
    $hitRate   = if ($totalOps -gt 0) { [math]::Round(($totalHits / $totalOps) * 100, 1) } else { 0 }
    
    Write-Host ""
    Write-Host "  Gentle-Vanguard Cache Manager v$CACHE_VERSION" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ("  {0,-18} {1,-10} {2,-10} {3}" -f "TIER", "ENTRIES", "HITS", "DETAILS") -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ("  {0,-18} {1,-10} {2,-10} {3}" -f "L1 (memory)", $L1.Count, $stats.hits.L1, "TTL: $($TierDefaults.L1)s default, process-scoped") -ForegroundColor White
    Write-Host ("  {0,-18} {1,-10} {2,-10} {3}" -f "L2 (file)", $l2cnt, $stats.hits.L2, "TTL: $($TierDefaults.L2)s default, dir: $L2Dir") -ForegroundColor White
    Write-Host ("  {0,-18} {1,-10} {2,-10} {3}" -f "L3 (persistent)", $l3cnt, $stats.hits.L3, "TTL: $($TierDefaults.L3)s default, survives restarts") -ForegroundColor White
    Write-Host ("  {0,-18} {1,-10} {2,-10} {3}" -f "Archive (cold)", $arccnt, $stats.hits.Archive, "TTL: indefinite") -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ("  {0,-18} {1,-10} {2,-10} {3}" -f "Total", ($L1.Count + $l2cnt + $l3cnt + $arccnt), $totalHits, "Hit rate: ${hitRate}%") -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Sets: $($stats.sets) | Misses: $($stats.misses) | Evictions: $($stats.evictions)" -ForegroundColor Gray
    Write-Host "  Started: $($stats.startedAt)" -ForegroundColor Gray
    Write-Host ""
}

function Invoke-GC {
    $removed = 0
    foreach ($dir in @($L2Dir, $L3Dir)) {
        Get-ChildItem $dir -Filter '*.cache.json' -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $entry = Get-Content $_.FullName -Raw | ConvertFrom-Json
                if (Test-Expired $entry) { Remove-Item $_.FullName -Force; $removed++; Increment-Stat 'evict' }
            } catch { Remove-Item $_.FullName -Force; $removed++ }
        }
    }
    # Evict expired L1 entries
    $expiredL1 = @($L1.Keys | Where-Object { Test-Expired $L1[$_] })
    $expiredL1 | ForEach-Object { $L1.Remove($_); $removed++; Increment-Stat 'evict' }
    
    Write-Host "[OK] GC complete: $removed expired entries evicted." -ForegroundColor Green
}

function Invoke-Warm {
    Write-Host "[INFO] Cache warm-up starting..." -ForegroundColor Cyan
    
    # Warm common Gentle-Vanguard data into L2/L3
    $warmSources = @(
        @{ key = 'gentle-vanguard:version'; file = (Join-Path $WorkspaceRoot 'VERSION'); tier = 'L3'; ttl = 86400 }
        @{ key = 'gentle-vanguard:skills-list'; dir = (Join-Path $WorkspaceRoot 'skills'); tier = 'L2'; ttl = 1800 }
        @{ key = 'gentle-vanguard:config-orchestrator'; file = (Join-Path $WorkspaceRoot 'config' 'orchestrator.json'); tier = 'L3'; ttl = 3600 }
    )
    
    $warmed = 0
    foreach ($src in $warmSources) {
        try {
            if ($src.file -and (Test-Path $src.file)) {
                $content = Get-Content $src.file -Raw
                $k = Get-SafeKey $src.key
                switch ($src.tier) {
                    'L2' { Set-L2 $k $content $src.ttl 'warmup' }
                    'L3' { Set-L3 $k $content $src.ttl 'warmup' }
                }
                $warmed++
                Write-Host "  [OK] Warmed: $($src.key)" -ForegroundColor Green
            } elseif ($src.dir -and (Test-Path $src.dir)) {
                $dirList = Get-ChildItem $src.dir -Directory | Select-Object -ExpandProperty Name | ConvertTo-Json -Compress
                $k = Get-SafeKey $src.key
                Set-L2 $k $dirList $src.ttl 'warmup'
                $warmed++
                Write-Host "  [OK] Warmed: $($src.key)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [WARN] Could not warm $($src.key): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "[OK] Warm-up complete: $warmed source(s) cached." -ForegroundColor Green
    Invoke-Stats
}

# ══ MAIN ═══════════════════════════════════════════════════════════════════════
switch ($Command) {
    'get'        { Invoke-Get }
    'set'        { Invoke-Set }
    'invalidate' { Invoke-Invalidate }
    'flush'      { Invoke-Flush }
    'stats'      { Invoke-Stats }
    'warm'       { Invoke-Warm }
    'gc'         { Invoke-GC }
    default      { Invoke-Stats }
}

