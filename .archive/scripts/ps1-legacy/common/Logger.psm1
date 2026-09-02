# Logger.psm1 — Sistema de logging estructurado para Gentle-Vanguard
# Exporta: Write-Log

$script:logDir = $null
$script:sessionId = $null

function Initialize-Logger {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..') | Select-Object -ExpandProperty Path
    $script:logDir = Join-Path $repoRoot ".session" "logs"
    if (-not (Test-Path $script:logDir)) {
        New-Item -ItemType Directory -Path $script:logDir -Force | Out-Null
    }
    $sessionFile = Join-Path $repoRoot ".session" "session.json"
    if (Test-Path $sessionFile) {
        try {
            $session = Get-Content $sessionFile -Raw | ConvertFrom-Json
            $script:sessionId = $session.id
        } catch { $script:sessionId = "unknown" }
    }
    # Rotate logs older than 30 days
    $cutoff = (Get-Date).AddDays(-30)
    Get-ChildItem $script:logDir -Filter "*.jsonl" | Where-Object { $_.LastWriteTime -lt $cutoff } | Remove-Item -Force
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level,
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [string]$Component,
        [string]$SessionId = $script:sessionId,
        [hashtable]$Data = $null
    )
    if (-not $script:logDir) { Initialize-Logger }
    $entry = @{
        timestamp = (Get-Date -Format 'o')
        level = $Level
        component = $Component
        sessionId = $SessionId
        message = $Message
    }
    if ($Data) { $entry.data = $Data }
    $line = $entry | ConvertTo-Json -Compress -Depth 5
    $logFile = Join-Path $script:logDir "$Component.jsonl"
    Add-Content -Path $logFile -Value $line
}

Initialize-Logger

Export-ModuleMember -Function Write-Log
