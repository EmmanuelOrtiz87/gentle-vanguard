# codegraph-metrics-tracker.ps1
# Tracks CodeGraph usage metrics during sessions
# Integrates with session-metrics-tracker.ps1

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("record", "summary", "reset")]
    [string]$Action,
    [string]$ToolName = "",
    [int]$SymbolsReturned = 0,
    [int]$FilesAnalyzed = 0,
    [double]$QueryTimeMs = 0,
    [string]$ProjectRoot = "",
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

if (-not $ProjectRoot) {
    $ProjectRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) { $env:GV_BASE_DIR } else {
        $root = Split-Path -Parent $PSScriptRoot
        while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
        if (-not $root) { $root = $PSScriptRoot }
        $root
    }
}

$metricsDir = Join-Path $ProjectRoot ".session\metrics"
$codegraphMetricsFile = Join-Path $metricsDir "codegraph-usage.json"

if (-not (Test-Path $metricsDir)) {
    New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Silent) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

switch ($Action) {
    "record" {
        if (-not $ToolName) {
            Write-Log "ToolName required for record action" "ERROR"
            exit 1
        }

        $data = @{}
        if (Test-Path $codegraphMetricsFile) {
            $data = Get-Content $codegraphMetricsFile -Raw | ConvertFrom-Json
        } else {
            $data = @{
                sessionStart = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
                totalCalls = 0
                toolsUsed = @{}
                totalSymbolsReturned = 0
                totalFilesAnalyzed = 0
                totalQueryTimeMs = 0
                estimatedToolCallsSaved = 0
                lastUpdate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            }
        }

        $data.totalCalls++
        $data.totalSymbolsReturned += $SymbolsReturned
        $data.totalFilesAnalyzed += $FilesAnalyzed
        $data.totalQueryTimeMs += $QueryTimeMs
        $data.estimatedToolCallsSaved += [math]::Max(0, 30 - 1)
        $data.lastUpdate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")

        if (-not $data.toolsUsed) { $data.toolsUsed = @{} }
        if ($data.toolsUsed.PSObject.Properties[$ToolName]) {
            $data.toolsUsed.$ToolName.count++
            $data.toolsUsed.$ToolName.symbols += $SymbolsReturned
            $data.toolsUsed.$ToolName.files += $FilesAnalyzed
        } else {
            $data.toolsUsed | Add-Member -NotePropertyName $ToolName -NotePropertyValue @{
                count = 1
                symbols = $SymbolsReturned
                files = $FilesAnalyzed
            } -Force
        }

        $data | ConvertTo-Json -Depth 5 | Out-File -FilePath $codegraphMetricsFile -Encoding UTF8
        Write-Log "Recorded CodeGraph tool usage: $ToolName" "OK"
    }

    "summary" {
        if (-not (Test-Path $codegraphMetricsFile)) {
            Write-Host "No CodeGraph usage data recorded this session." -ForegroundColor Yellow
            exit 0
        }

        $data = Get-Content $codegraphMetricsFile -Raw | ConvertFrom-Json

        Write-Host ""
        Write-Host "=== CodeGraph Usage Summary ===" -ForegroundColor Cyan
        Write-Host "Session Start: $($data.sessionStart)" -ForegroundColor White
        Write-Host "Last Update:   $($data.lastUpdate)" -ForegroundColor White
        Write-Host ""
        Write-Host "Total Calls:             $($data.totalCalls)" -ForegroundColor White
        Write-Host "Total Symbols Returned:  $($data.totalSymbolsReturned)" -ForegroundColor White
        Write-Host "Total Files Analyzed:    $($data.totalFilesAnalyzed)" -ForegroundColor White
        Write-Host "Est. Tool Calls Saved:    $($data.estimatedToolCallsSaved)" -ForegroundColor Green
        Write-Host "Total Query Time (ms):   $($data.totalQueryTimeMs)" -ForegroundColor White
        Write-Host ""
        Write-Host "Tools Used:" -ForegroundColor White
        if ($data.toolsUsed) {
            foreach ($prop in $data.toolsUsed.PSObject.Properties) {
                Write-Host "  $($prop.Name): $($prop.Value.count) calls, $($prop.Value.symbols) symbols, $($prop.Value.files) files" -ForegroundColor Gray
            }
        }
    }

    "reset" {
        if (Test-Path $codegraphMetricsFile) {
            Remove-Item $codegraphMetricsFile -Force
            Write-Log "CodeGraph usage metrics reset" "OK"
        }
    }
}

exit 0