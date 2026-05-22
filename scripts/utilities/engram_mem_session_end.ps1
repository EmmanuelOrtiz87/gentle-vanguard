param(
    [string]$SessionId = "",
    [string]$ProjectName = "gentle-vanguard",
    [string]$WorkspaceRoot = "",
    [switch]$NoExit
)

$ErrorActionPreference = 'Continue'

if (-not $WorkspaceRoot) {
    $WorkspaceRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
        $root = Split-Path -Parent $PSScriptRoot
        while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
        if (-not $root) { $root = $PSScriptRoot }
        $root
    }
}

$engram = $null
$engramPaths = @(
    (Join-Path $env:USERPROFILE "bin\engram.exe"),
    (Join-Path $WorkspaceRoot "tools\engram.exe"),
    (Join-Path $WorkspaceRoot "engram.exe"),
    "engram.exe"
)
foreach ($path in $engramPaths) {
    if (Test-Path $path) { $engram = (Resolve-Path $path).Path; break }
}
if (-not $engram) { $engram = Get-Command "engram" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }

if (-not $SessionId) {
    $sessionDir = Join-Path $WorkspaceRoot "session"
    if (Test-Path $sessionDir) {
        $latest = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) {
            $sessionData = Get-Content $latest.FullName -Raw | ConvertFrom-Json
            $SessionId = $sessionData.sessionId
        }
    }
}

if (-not $SessionId) {
    $SessionId = "session-$(Get-Date -Format 'yyyy-MM-dd')-unknown"
}

# Update session file to ended
$sessionDir = Join-Path $WorkspaceRoot "session"
$sessionFile = Join-Path $sessionDir "session-$((Get-Date).ToString('yyyy-MM-dd'))-*.json"
$existingFile = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*$($SessionId -replace 'session-', '')*" } |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($existingFile) {
    try {
        $data = Get-Content $existingFile.FullName -Raw | ConvertFrom-Json
        $updated = [PSCustomObject]@{
            sessionId  = $data.sessionId
            project    = $data.project
            mode       = $data.mode
            startTime  = $data.startTime
            version    = if ($data.PSObject.Properties.Name -contains 'version') { $data.version } else { '2.0' }
            status     = "ended"
            endTime    = (Get-Date).ToString("o")
        }
        $updated | ConvertTo-Json | Out-File -FilePath $existingFile.FullName -Encoding UTF8
        Write-Host "[OK] Session file marked ended: $($existingFile.Name)" -ForegroundColor Green
    } catch {
        Write-Warning "Could not update session file: $_"
    }
}

# Save end observation to Engram if binary is available
if ($engram) {
    $content = "Session $SessionId closed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $result = & $engram save "Session end: $SessionId" $content --type session --project $ProjectName 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0 -or -not $exitCode) {
        Write-Host "[OK] Engram session end saved: $SessionId" -ForegroundColor Green
    } else {
        Write-Warning "Engram save returned code $exitCode"
    }
} else {
    Write-Warning "Engram binary not found — session end not persisted to Engram (session file updated)"
}

exit 0
