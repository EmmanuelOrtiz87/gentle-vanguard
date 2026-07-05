param(
    [ValidateSet('check','repair','full')][string]$Action = 'check',
    [string]$DbPath = "$env:LOCALAPPDATA\.engram\engram.db",
    [int]$MaxBackups = 5,
    [switch]$Quiet
)

$logFile = "C:\Workspace_local\gentle-vanguard\.session\engram-errors.log"
$fallbackDir = Split-Path $DbPath -Parent
$fallbackFile = Join-Path $fallbackDir "fallback.json"

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    if (-not $Quiet) { Write-Host $line }
    try { Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue } catch {}
}

function Test-EngramDb {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Log "DB not found at: $Path" 'WARN'; return $false }
    try {
        $r = & sqlite3 $Path "SELECT 1;" 2>&1
        return ($LASTEXITCODE -eq 0) -and ("$r".Trim() -eq '1')
    } catch { Write-Log "Exception: $($_.Exception.Message)" 'ERROR'; return $false }
}

function Test-EngramSchema {
    param([string]$Path)
    try {
        $info = sqlite3 $Path "PRAGMA table_info(observations);" 2>&1
        return @{ HasData = $info -match '\bdata\b'; HasContent = $info -match '\bcontent\b' }
    } catch { return $null }
}

function Repair-EngramDb {
    param([string]$Path)
    $backup = "$Path.bak.$(Get-Date -Format yyyyMMddHHmmss)"
    try { Copy-Item $Path $backup -Force; Write-Log "Backup: $backup" 'INFO' } catch {}
    $schema = Test-EngramSchema $Path
    if (-not $schema) { return $false }
    $ok = $false
    if (-not $schema.HasData) { & sqlite3 $Path "ALTER TABLE observations ADD COLUMN data TEXT;"; if ($LASTEXITCODE -eq 0) { Write-Log "data column added" 'INFO'; $ok = $true } }
    if (-not $schema.HasContent) { & sqlite3 $Path "ALTER TABLE observations ADD COLUMN content TEXT;"; if ($LASTEXITCODE -eq 0) { Write-Log "content column added" 'INFO'; $ok = $true } }
    Get-ChildItem (Split-Path $Path -Parent) "*.bak.*" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $MaxBackups | Remove-Item -Force
    return $ok
}

try { New-Item -ItemType Directory -Path (Split-Path $logFile -Parent) -Force | Out-Null } catch {}

if ($Action -eq 'check') {
    $h = Test-EngramDb $DbPath
    if ($h) { Write-Log "[PASS] DB OK" 'INFO'; exit 0 } else { Write-Log "[FAIL] DB unreachable" 'ERROR'; exit 1 }
}

if ($Action -eq 'repair' -or $Action -eq 'full') {
    if (Test-EngramDb $DbPath) { Write-Log "[SKIP] DB ya OK" 'INFO' }
    else {
        Repair-EngramDb $DbPath
        if (Test-EngramDb $DbPath) { Write-Log "[OK] Reparada" 'INFO' }
        else { Write-Log "[FAIL] No reparable - crear fallback" 'ERROR'; @{created=(Get-Date -Format 'o'); entries=@()} | ConvertTo-Json | Set-Content $fallbackFile }
    }
}

if ($Action -eq 'full') {
    $f = Test-EngramDb $DbPath; $s = Test-EngramSchema $DbPath
    Write-Log "DB=$f data=$($s.HasData) content=$($s.HasContent)" 'INFO'
}
exit 0
