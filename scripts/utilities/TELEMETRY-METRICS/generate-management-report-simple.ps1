# generate-management-report-simple.ps1
# Generates monthly management report in CSV format
# Simplified version - works without Engram if needed

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceNewMonth
)

$ErrorActionPreference = 'Stop'
# Correctly resolve workspace root: go up 3 levels from scripts/utilities/TELEMETRY-METRICS/
$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path | Split-Path

# Ensure reports directory exists
$reportsPath = Join-Path $workspaceRoot $OutputDir
if (-not (Test-Path $reportsPath)) {
    New-Item -Path $reportsPath -ItemType Directory | Out-Null
}

# Get current month/year
$currentMonth = Get-Date -Format "yyyy-MM"
$reportFile = Join-Path $reportsPath "MANAGEMENT-REPORT-$currentMonth.csv"

# Check if we need a new file (month changed or force)
$needNewFile = $false
if ($ForceNewMonth -or -not (Test-Path $reportFile)) {
    $needNewFile = $true
} else {
    try {
        $firstLine = Get-Content $reportFile -First 1
        $fileMonth = ($firstLine -split ',')[1] -replace '"', '' -replace '-.*$', ''
        if ($fileMonth -ne $currentMonth) {
            Write-Host "⚠️ Month changed! Please export: $reportFile"
            Write-Host "   Then re-run with -ForceNewMonth to start new file"
            exit 0
        }
    } catch { }
}

# Create new file with headers if needed
if ($needNewFile) {
    $headers = "SessionID,Date,User,Project,TokensIn,TokensOut,SkillsUsed,SystemsTriggered,ActionsPerformed,Outcome,IssuesFound,Duration(min),Cost(USD),Notes"
    $headers | Out-File $reportFile -Encoding UTF8
    Write-Host "✅ Created new report: $reportFile"
}

# Reminder if near month end
$daysUntilMonthEnd = [DateTime]::DaysInMonth((Get-Date).Year, (Get-Date).Month) - (Get-Date).Day
if ($daysUntilMonthEnd -le 3 -and $daysUntilMonthEnd -ge 0) {
    Write-Host "⚠️ REMINDER: Only $daysUntilMonthEnd day(s) left! Export: $reportFile"
}

# Collect data from session files
Write-Host "📊 Collecting session data..."

$sessionDir = Join-Path $workspaceRoot ".session"
$telemetryDir = Join-Path $workspaceRoot ".telemetry"

if (Test-Path $sessionDir) {
    $sessionFiles = Get-ChildItem $sessionDir -Filter "session-*.json" | Where-Object { 
        $_.LastWriteTime.Month -eq (Get-Date).Month -and $_.LastWriteTime.Year -eq (Get-Date).Year 
    }
    
    foreach ($sessionFile in $sessionFiles) {
        try {
            $sessionData = Get-Content $sessionFile.FullName | ConvertFrom-Json
            $sessionId = $sessionFile.BaseName
            
            # Defaults
            $tokensIn = 0
            $tokensOut = 0
            $skillsUsed = "auto-reporting"
            $actionsPerformed = "Session tracking"
            $outcome = "COMPLETE"
            $issuesFound = 0
            $duration = 0
            $cost = 0.0
            
            # Get telemetry data
            $telemetryFile = Get-ChildItem $telemetryDir -Filter "initialization-$sessionId.json" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($telemetryFile) {
                $telemetryData = Get-Content $telemetryFile.FullName | ConvertFrom-Json
                if ($telemetryData.PSObject.Properties['TokensIn']) { $tokensIn = $telemetryData.TokensIn }
                if ($telemetryData.PSObject.Properties['TokensOut']) { $tokensOut = $telemetryData.TokensOut }
            }
            
            # Calculate duration
            $startTime = [DateTime]$sessionData.startTime
            $endTime = if ($sessionData.PSObject.Properties['endTime']) { [DateTime]$sessionData.endTime } else { Get-Date }
            $duration = [math]::Round(($endTime - $startTime).TotalMinutes, 2)
            
            # Calculate cost
            $cost = [math]::Round(($tokensIn + $tokensOut) * 0.0001, 4)
            
            # Format duration and cost with invariant culture
            $durationStr = $duration.ToString([System.Globalization.CultureInfo]::InvariantCulture)
            $costStr = $cost.ToString([System.Globalization.CultureInfo]::InvariantCulture)
            
            # Create CSV row
            $row = [PSCustomObject]@{
                SessionID = $sessionId
                Date = $startTime.ToString('yyyy-MM-dd')
                User = $env:USERNAME
                Project = $sessionData.project
                TokensIn = $tokensIn
                TokensOut = $tokensOut
                SkillsUsed = $skillsUsed
                SystemsTriggered = "auto-backup,auto-norm-enforcer,auto-doc-drift-detector"
                ActionsPerformed = $actionsPerformed
                Outcome = $outcome
                IssuesFound = $issuesFound
                'Duration(min)' = $durationStr
                'Cost(USD)' = $costStr
                Notes = "Auto-collected (simplified)"
            }
            
            # Append to CSV
            $row | Export-Csv -Path $reportFile -Append -NoTypeInformation -Encoding UTF8
            Write-Host "   ✅ Added: $sessionId"
            
        } catch {
            Write-Host "   ⚠️ Error processing $($sessionFile.Name): $_"
        }
    }
}

Write-Host "✅ Report updated: $reportFile"
if (Test-Path $reportFile) {
    $rowCount = (Get-Content $reportFile).Count - 1
    Write-Host "   Total rows: $rowCount"
}

# Show preview
Write-Host "`n📊 Preview (first 3 rows):"
if (Test-Path $reportFile) {
    Get-Content $reportFile -TotalCount 4 | ForEach-Object { Write-Host $_ }
}
