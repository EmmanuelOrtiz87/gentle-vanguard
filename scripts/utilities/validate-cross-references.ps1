param(
    [string]$RootPath = ".",
    [switch]$Quiet,
    [switch]$UnreferencedOnly,
    [switch]$BrokenRefsOnly
)

$ErrorActionPreference = 'Continue'
$RootPath = Resolve-Path $RootPath

# --- Helpers ---
function Write-Step { param([string]$m) if (-not $Quiet) { Write-Host "`n=== $m ===" -ForegroundColor Cyan } }
function Write-Ok   { param([string]$m) if (-not $Quiet) { Write-Host "  [OK] $m" -ForegroundColor Green } }
function Write-Warn { param([string]$m) if (-not $Quiet) { Write-Host "  [WARN] $m" -ForegroundColor Yellow } }
function Write-Issue { param([string]$m) Write-Host "  [ISSUE] $m" -ForegroundColor Red }
function Is-BareName  { param([string]$p) $p -notmatch '[\\/]' }
function Is-Glob      { param([string]$p) $p -match '[\*\?]' }

# Exclusions — never a real file path
$ExactBareSkiplist = @(
    # Commands resolved via PATH at runtime
    'engram', 'engram.exe', 'gv', 'gv.ps1', 'gh', 'git', 'pwsh', 'powershell',
    # Common runtime-created data files
    'connections.json', 'subscriptions.json', 'history.json',
    'appsettings.json', 'secrets.json', 'appsettings.Development.json',
    'echo-marker.txt', '.gitkeep'
)

# Runtime-only directory prefixes — files under these are created at runtime, not source
$RuntimeDirPrefixes = @(
    'reports\', 'reports/',
    'docs\sessions\', 'docs/sessions/',
    '.session\', '.session/',
    '.logs\', '.logs/',
    'bin\', 'bin/',
    'go\bin\', 'go/bin/',
    '.event-bus\', '.event-bus/',
    '.local\', '.local/'
)

function Is-RuntimeDir {
    param([string]$p)
    foreach ($prefix in $RuntimeDirPrefixes) {
        if ($p.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# --- Phase 0: Collect all files and build reference index ---
$allScripts = Get-ChildItem -Recurse -File -Path $RootPath -Include *.ps1,*.cmd,*.sh -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch 'node_modules|\.git|\\bin\\|\\obj\\'
}

# Reference-bearing files: anything that could reference a script by name
$refFiles = Get-ChildItem -Recurse -File -Path $RootPath -Include *.ps1,*.cmd,*.sh,*.json,*.yaml,*.yml,*.md -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch 'node_modules|\.git|\\bin\\|\\obj\\' -and $_.Length -lt 500KB
}

# Build combined content blob for fast name-matching (Phase 1)
$combinedContent = ''
$refFilePaths = @{}
foreach ($rf in $refFiles) {
    $refFilePaths[$rf.FullName] = $true
        try {
        $c = Get-Content -LiteralPath $rf.FullName -Raw -ErrorAction SilentlyContinue
        if ($c) { $combinedContent += "`n--FILE:$($rf.Name)--`n$c" }
    } catch { Write-Warning "Failed to read $($rf.Name): $_" }
}
$combinedLower = $combinedContent.ToLowerInvariant()

# --- Phase 1: Find unreferenced files ---
Write-Step "Phase 1: Unreferenced script files"

$nameMap = @{}
foreach ($s in $allScripts) {
    $key = $s.Name.ToLowerInvariant()
    if (-not $nameMap.Contains($key)) { $nameMap[$key] = @() }
    $nameMap[$key] += $s
}

$unreferenced = @()
$total = $allScripts.Count
foreach ($key in $nameMap.Keys) {
    # Word-boundary check: does the filename appear as a standalone word in any ref file?
    $pattern = '(?<![a-zA-Z0-9])' + [regex]::Escape($key) + '(?![a-zA-Z0-9])'
    if ($combinedLower -notmatch $pattern) {
        foreach ($s in $nameMap[$key]) {
            $unreferenced += @{ Path = $s.FullName; Name = $s.Name; Size = $s.Length }
        }
    }
}

$count = 0
foreach ($u in $unreferenced) {
    $count++
    Write-Issue "$count. $($u.Name) — $($u.Size) bytes, 0 refs in .ps1/.cmd/.sh/.json/.md"
}
if ($unreferenced.Count -eq 0) { Write-Ok "All $total script files have >=1 reference" }
else { Write-Warn "$($unreferenced.Count)/$total files have zero references — possible dead code" }

if ($UnreferencedOnly) { return $unreferenced }

# --- Phase 2: Find broken path references (with false-positive filters) ---
Write-Step "Phase 2: Broken path references"

$brokenRefs = @()
# Pattern captures:
#   Group 'jp'  → Join-Path $var 'second-arg'
#   Group 'sq'  → single-quoted string containing .ps1
#   Group 'dq'  → double-quoted string containing .ps1
$refPattern = [regex]::new(
    "(?:Join-Path\s+\$[^\s]+\s+'(?<jp>[^']+)')|'(?<sq>[^']*\.ps1[^']*)'|""(?<dq>[^""]*\.ps1[^""]*)"""
)

foreach ($s in $allScripts) {
    $content = Get-Content -LiteralPath $s.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $selfName = $s.Name

    $lineNum = 0
    foreach ($line in ($content -split "`n")) {
        $lineNum++
        $m = $refPattern.Match($line)
        if (-not $m.Success) { continue }

        $origin = ''
        $path = ''
        if ($m.Groups['jp'].Success) { $origin = 'Join-Path'; $path = $m.Groups['jp'].Value }
        elseif ($m.Groups['sq'].Success) { $origin = 'string'; $path = $m.Groups['sq'].Value }
        elseif ($m.Groups['dq'].Success) { $origin = 'string'; $path = $m.Groups['dq'].Value }

        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $path = $path.Trim()

        # --- FALSE POSITIVE FILTERS ---
        # 1. Runtime-resolved (contains $ or {)
        if ($path -match '^\$|^\{|\\\$') { continue }
        # 2. Self-reference (script referencing its own name)
        if ($path -eq $selfName) { continue }
        # 3. Glob patterns
        if (Is-Glob $path) { continue }
        # 4. Exact bare-name skip list
        if ($ExactBareSkiplist -contains $path) { continue }
        # 5. Bare names without directory separators are runtime-resolved (commands, data files)
        if (Is-BareName $path) { continue }
        # 6. Regex escapes posing as paths (e.g. '\.ps1$', '\\.ps1\'')
        if ($path -match '^\\.') { continue }

        # --- Resolve and check ---
        # 7. Runtime-only directories (data files created at runtime)
        if (Is-RuntimeDir $path) { continue }
        # 8. Environment variable refs (%VAR%) in .cmd/.bat — can't resolve statically
        if ($path -match '%\w+%') { continue }
        # 9. Help/usage parameter placeholders
        if ($path -match '<\w+>') { continue }

        # --- Resolve and check ---
        $resolved = $path -replace '^\.\\|^\.\/', ''
        $resolved = $resolved -replace '\\\\', [IO.Path]::DirectorySeparatorChar

        # For parent-relative paths (..\ or ../), try resolving from script's dir first
        $found = $false
        if ($resolved.StartsWith('..')) {
            $scriptDir = Split-Path -Parent $s.FullName
            $candidate = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($scriptDir, $resolved))
            if (Test-Path $candidate) { $found = $true }
        }

        if (-not $found) {
            $fullPath = Join-Path $RootPath $resolved
            if (-not (Test-Path $fullPath) -and -not (Test-Path $path)) {
                $brokenRefs += @{
                    Source = $s.FullName
                    Line = $lineNum
                    Ref = $path
                    Origin = $origin
                }
            }
        }
    }
}

$count = 0
foreach ($b in $brokenRefs) {
    $count++
    Write-Issue "$count. $($b.Source):$($b.Line) ($($b.Origin)) → '$($b.Ref)' — NOT FOUND"
}
if ($brokenRefs.Count -eq 0) { Write-Ok "No broken path references found" }
else { Write-Warn "$($brokenRefs.Count) broken reference(s)" }

if ($BrokenRefsOnly) { return $brokenRefs }

# --- Summary ---
Write-Step "Summary"
$issues = $unreferenced.Count + $brokenRefs.Count
if ($issues -eq 0) {
    Write-Ok "Cross-reference validation PASSED — 0 issues"
} else {
    Write-Warn "Cross-reference validation found $issues issue(s): $($unreferenced.Count) unreferenced, $($brokenRefs.Count) broken refs"
}

return @{
    Unreferenced = $unreferenced
    BrokenRefs = $brokenRefs
    Status = if ($issues -eq 0) { 'PASS' } else { 'FAIL' }
}

