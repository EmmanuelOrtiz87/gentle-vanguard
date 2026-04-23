<#
.SYNOPSIS
    Telemetry Dashboard - View and manage distributed tracing data
    
.DESCRIPTION
    Provides dashboard functionality to view traces, metrics, and reports
    
.PARAMETER Action
    Action to perform: show-summary, show-reports, generate-reports, export-data, view-traces
    
.PARAMETER Date
    Date for reports (default: today)
    
.PARAMETER OutputPath
    Output path for exports
    
.EXAMPLE
    .\telemetry-dashboard.ps1 -Action show-summary
    .\telemetry-dashboard.ps1 -Action generate-reports
    .\telemetry-dashboard.ps1 -Action show-reports
#>

param(
    [ValidateSet('show-summary', 'show-reports', 'generate-reports', 'export-data', 'view-traces', 'view-metrics', 'cleanup')]
    [string]$Action = 'show-summary',
    
    [DateTime]$Date = (Get-Date),
    [string]$OutputPath = ".telemetry",
    [switch]$Verbose
)

# ============================================================================
# LOAD MODULES
# ============================================================================

$reportGenPath = ".\skills\distributed-tracing-skill\report-generator.ps1"
$tracingCorePath = ".\skills\distributed-tracing-skill\distributed-tracing-core.ps1"

if (-not (Test-Path $reportGenPath)) {
    Write-Host "[DASHBOARD] ERROR: Report generator not found: $reportGenPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $tracingCorePath)) {
    Write-Host "[DASHBOARD] ERROR: Tracing core not found: $tracingCorePath" -ForegroundColor Red
    exit 1
}

. $reportGenPath
. $tracingCorePath

# ============================================================================
# DASHBOARD FUNCTIONS
# ============================================================================

function Show-TelemetrySummary {
    <#
    .SYNOPSIS
        Display telemetry summary
    #>
    param([string]$OutputPath = ".telemetry")
    
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DISTRIBUTED TRACING TELEMETRY DASHBOARD              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Count traces
    $tracesDir = "$OutputPath/traces"
    $traceCount = 0
    if (Test-Path $tracesDir) {
        $traceFiles = Get-ChildItem -Path $tracesDir -Filter "*.jsonl" -ErrorAction SilentlyContinue
        foreach ($file in $traceFiles) {
            $lines = @(Get-Content -Path $file.FullName -ErrorAction SilentlyContinue | Where-Object { $_ -match '\S' })
            $traceCount += $lines.Count
        }
    }
    
    # Count metrics
    $metricsDir = "$OutputPath/metrics"
    $metricCount = 0
    if (Test-Path $metricsDir) {
        $metricFiles = @(Get-ChildItem -Path $metricsDir -Filter "*.json" -ErrorAction SilentlyContinue)
        $metricCount = $metricFiles.Count
    }
    
    # Count reports
    $reportsDir = "$OutputPath/reports"
    $reportCount = 0
    if (Test-Path $reportsDir) {
        $reportFiles = @(Get-ChildItem -Path $reportsDir -Filter "*.md" -ErrorAction SilentlyContinue)
        $reportCount = $reportFiles.Count
    }
    
    # Count spans
    $spansDir = "$OutputPath/spans"
    $spanCount = 0
    if (Test-Path $spansDir) {
        $spanFiles = Get-ChildItem -Path $spansDir -Filter "*.json" -ErrorAction SilentlyContinue
        foreach ($file in $spanFiles) {
            try {
                $data = Get-Content -Path $file.FullName | ConvertFrom-Json
                $spanCount += $data.Spans.Count
            }
            catch {
                # Skip malformed files
            }
        }
    }
    
    Write-Host "`n📊 Telemetry Statistics`n" -ForegroundColor Green
    Write-Host "  Traces:     $traceCount" -ForegroundColor Gray
    Write-Host "  Metrics:    $metricCount" -ForegroundColor Gray
    Write-Host "  Spans:      $spanCount" -ForegroundColor Gray
    Write-Host "  Reports:    $reportCount" -ForegroundColor Gray
    
    Write-Host "`n📁 Telemetry Directory Structure`n" -ForegroundColor Green
    Write-Host "  Location: $OutputPath" -ForegroundColor Gray
    
    if (Test-Path $OutputPath) {
        $dirs = @(
            @{ Name = "traces"; Path = "$OutputPath/traces" },
            @{ Name = "metrics"; Path = "$OutputPath/metrics" },
            @{ Name = "reports"; Path = "$OutputPath/reports" },
            @{ Name = "spans"; Path = "$OutputPath/spans" }
        )
        
        foreach ($dir in $dirs) {
            $exists = Test-Path $dir.Path
            $status = if ($exists) { "✓" } else { "✗" }
            $color = if ($exists) { "Green" } else { "Yellow" }
            Write-Host "    [$status] $($dir.Name)" -ForegroundColor $color
        }
    }
    
    Write-Host "`n" -ForegroundColor Cyan
}

function Show-Reports {
    <#
    .SYNOPSIS
        Display available reports
    #>
    param([string]$OutputPath = ".telemetry")
    
    Show-ReportIndex -OutputPath "$OutputPath/reports"
}

function Generate-Reports {
    <#
    .SYNOPSIS
        Generate all reports for a date
    #>
    param(
        [DateTime]$Date = (Get-Date),
        [string]$OutputPath = ".telemetry"
    )
    
    $reportsPath = "$OutputPath/reports"
    
    if (-not (Test-Path $reportsPath)) {
        New-Item -ItemType Directory -Path $reportsPath -Force | Out-Null
    }
    
    Generate-AllReports -Date $Date -OutputPath $reportsPath
}

function Export-TelemetryData {
    <#
    .SYNOPSIS
        Export telemetry data
    #>
    param(
        [string]$OutputPath = ".telemetry",
        [string]$ExportPath = "telemetry-export"
    )
    
    Write-Host "[DASHBOARD] Exporting telemetry data..." -ForegroundColor Cyan
    
    if (-not (Test-Path $ExportPath)) {
        New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
    }
    
    # Copy all telemetry data
    Copy-Item -Path "$OutputPath/*" -Destination $ExportPath -Recurse -Force -ErrorAction SilentlyContinue
    
    # Create index
    $index = @{
        ExportDate = Get-Date -Format "o"
        SourcePath = $OutputPath
        ExportPath = $ExportPath
        Contents = @(
            "traces - Distributed trace data in JSONL format"
            "metrics - Performance metrics in JSON format"
            "reports - Generated analysis reports in Markdown format"
            "spans - Span hierarchy data in JSON format"
        )
    }
    
    $index | ConvertTo-Json -Depth 10 | Set-Content -Path "$ExportPath/INDEX.json" -Encoding UTF8
    
    Write-Host "[DASHBOARD] Telemetry data exported to: $ExportPath" -ForegroundColor Green
}

function View-Traces {
    <#
    .SYNOPSIS
        View trace data
    #>
    param(
        [string]$OutputPath = ".telemetry",
        [int]$Limit = 10
    )
    
    $tracesDir = "$OutputPath/traces"
    
    if (-not (Test-Path $tracesDir)) {
        Write-Host "[DASHBOARD] No traces found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n=== Recent Traces ===" -ForegroundColor Cyan
    
    $traceFiles = Get-ChildItem -Path $tracesDir -Filter "*.jsonl" -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime -Descending
    
    $count = 0
    foreach ($file in $traceFiles) {
        $lines = @(Get-Content -Path $file.FullName -ErrorAction SilentlyContinue | Where-Object { $_ -match '\S' })
        
        foreach ($line in $lines) {
            if ($count -ge $Limit) { break }
            
            try {
                $trace = $line | ConvertFrom-Json
                Write-Host "`n[$($trace.SpanType)] $($trace.Name)" -ForegroundColor Green
                Write-Host "  Duration: $([Math]::Round($trace.Duration, 2)) ms" -ForegroundColor Gray
                Write-Host "  Status: $($trace.Status)" -ForegroundColor Gray
                Write-Host "  Time: $($trace.StartTime)" -ForegroundColor Gray
                $count++
            }
            catch {
                # Skip malformed lines
            }
        }
        
        if ($count -ge $Limit) { break }
    }
    
    Write-Host "`n"
}

function View-Metrics {
    <#
    .SYNOPSIS
        View metrics data
    #>
    param(
        [string]$OutputPath = ".telemetry"
    )
    
    $metricsDir = "$OutputPath/metrics"
    
    if (-not (Test-Path $metricsDir)) {
        Write-Host "[DASHBOARD] No metrics found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n=== Recent Metrics ===" -ForegroundColor Cyan
    
    $metricFiles = Get-ChildItem -Path $metricsDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 5
    
    foreach ($file in $metricFiles) {
        try {
            $data = Get-Content -Path $file.FullName | ConvertFrom-Json
            Write-Host "`n📊 $($file.Name)" -ForegroundColor Green
            Write-Host "  Session: $($data.SessionId)" -ForegroundColor Gray
            Write-Host "  Correlation ID: $($data.CorrelationId)" -ForegroundColor Gray
            Write-Host "  Metric Count: $($data.Metrics.Count)" -ForegroundColor Gray
        }
        catch {
            # Skip malformed files
        }
    }
    
    Write-Host "`n"
}

function Cleanup-OldData {
    <#
    .SYNOPSIS
        Clean up old telemetry data
    #>
    param(
        [string]$OutputPath = ".telemetry",
        [int]$RetentionDays = 30
    )
    
    Write-Host "[DASHBOARD] Cleaning up telemetry data older than $RetentionDays days..." -ForegroundColor Cyan
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $deletedCount = 0
    
    $dirs = @("$OutputPath/traces", "$OutputPath/metrics", "$OutputPath/spans")
    
    foreach ($dir in $dirs) {
        if (Test-Path $dir) {
            $files = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                if ($file.LastWriteTime -lt $cutoffDate) {
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                    $deletedCount++
                }
            }
        }
    }
    
    Write-Host "[DASHBOARD] Deleted $deletedCount old files" -ForegroundColor Green
}

# ============================================================================
# MAIN
# ============================================================================

try {
    switch ($Action) {
        'show-summary' {
            Show-TelemetrySummary -OutputPath $OutputPath
        }
        'show-reports' {
            Show-Reports -OutputPath $OutputPath
        }
        'generate-reports' {
            Generate-Reports -Date $Date -OutputPath $OutputPath
        }
        'export-data' {
            Export-TelemetryData -OutputPath $OutputPath
        }
        'view-traces' {
            View-Traces -OutputPath $OutputPath
        }
        'view-metrics' {
            View-Metrics -OutputPath $OutputPath
        }
        'cleanup' {
            Cleanup-OldData -OutputPath $OutputPath
        }
    }
    
    exit 0
}
catch {
    Write-Host "[DASHBOARD] ERROR: $_" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
    exit 1
}