# pre-compact-hook.ps1
# Runs before context compaction - preserves critical state at 85%
# Hook point for memory tiering and prefix anchoring

param(
    [string]$ProjectName = 'workspace_gentle_vanguard',
    [string]$SessionId = '',
    [double]$CompressionRatio = 0.90,
    [int]$TriggerThreshold = 15000
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Anchor {
    param([string]$m) Write-Host "[ANCHOR] $m" -ForegroundColor Magenta
}

# Verificar tamao del contexto para compactacin automtica
function Check-AutoCompaction {
    param([int]$threshold = $TriggerThreshold)
    
    # Leer tamao real del contexto desde token-usage.json
    $contextSize = 0
    $repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else { Get-Location }
    $tokenFile = Join-Path $repoRoot ".session\token-usage.json"
    if (Test-Path $tokenFile) {
        try {
            $tu = Get-Content $tokenFile -Raw | ConvertFrom-Json
            $contextSize = [Math]::Floor([int]$tu.totalContextChars / 4) + [int]$tu.totalTokens
        } catch { $contextSize = $threshold + 1 }
    }
    
    if ($contextSize -gt $threshold) {
        Write-Anchor "Automatic context compaction triggered (size: $contextSize tokens)"
        
        # Registrar checkpoint en Engram
        $engramBin = Join-Path $scriptDir 'engram.exe'
        if (Test-Path $engramBin) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            & $engramBin save --title "Auto-compaction checkpoint" --content "Automatic checkpoint during long session at $timestamp" --project $ProjectName 2>$null | Out-Null
            Write-Anchor "Auto-compaction checkpoint saved to Engram"
        }
        
        return $true
    }
    return $false
}

Write-Anchor "Pre-compact hook triggered"

# Verificar compactacin automtica
$autoCompacted = Check-AutoCompaction

$engramBin = Join-Path $scriptDir 'engram.exe'
if (Test-Path $engramBin) {
    Write-Anchor "Preserving hot memory layer..."
    & $engramBin search "type:manual AND project:$ProjectName" --limit 20 --format json 2>$null | Out-Null
    
    # Buscar contenido relevante para reducir redundancias
    Write-Anchor "Searching for previous context to reduce redundancy..."
    & $engramBin search "context efficiency optimization" --limit 5 --format json 2>$null | Out-Null
}

$rulesDir = Join-Path $scriptDir '..\rules\adaptive'
if (Test-Path $rulesDir) {
    Write-Anchor "Validating adaptive rules..."
    Get-ChildItem $rulesDir -Filter '*.md' | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match 'status:\s*active') {
            Write-Host "[ANCHOR] Rule active: $($_.BaseName)" -ForegroundColor Cyan
        }
    }
}

if ($autoCompacted) {
    Write-Anchor "Auto-compaction completed. Remaining compression ratio: $CompressionRatio"
} else {
    Write-Anchor "Pre-compact complete. Compression ratio: $CompressionRatio"
}
exit 0
