# generate-management-report.ps1
# Generates monthly management report in CSV format
# Unified reporting system - single source of truth for all metrics

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceNewMonth,
    
    [Parameter(Mandatory=$false)]
    [switch]$OnDemand
)

$ErrorActionPreference = 'Stop'
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
} elseif (-not $OnDemand) {
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

# Reminder if near month end (only for automated runs)
if (-not $OnDemand) {
    $daysUntilMonthEnd = [DateTime]::DaysInMonth((Get-Date).Year, (Get-Date).Month) - (Get-Date).Day
    if ($daysUntilMonthEnd -le 3 -and $daysUntilMonthEnd -ge 0) {
        Write-Host "⚠️ REMINDER: Only $daysUntilMonthEnd day(s) left! Export: $reportFile"
    }
}

# Collect data from session files
Write-Host "📊 Collecting session data..."

$sessionDir = Join-Path $workspaceRoot ".session"
$telemetryDir = Join-Path $workspaceRoot ".telemetry"

# Load Engram observations once (improved method)
$engramObservations = @()
try {
    $engramExe = Join-Path $workspaceRoot "tools\engram.exe"
    if (Test-Path $engramExe) {
        # Run engram export silently - ignore all output
        $null = Start-Process -FilePath $engramExe -ArgumentList "export" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "nul" -RedirectStandardError "nul" -ErrorAction SilentlyContinue
        
        Start-Sleep -Milliseconds 500  # Wait for file to be written
        
        if (Test-Path "engram-export.json") {
            try {
                $engramJson = Get-Content "engram-export.json" -Raw -ErrorAction Stop
                if ($engramJson) {
                    $engramData = $engramJson | ConvertFrom-Json -ErrorAction Stop
                    if ($engramData.observations -and $engramData.observations.Count -gt 0) {
                        $engramObservations = $engramData.observations
                        Write-Host "   ✅ Engram data loaded: $($engramObservations.Count) observations"
                    }
                }
            } catch {
                Write-Host "   ⚠️ Engram parse error: $_"
            } finally {
                Remove-Item "engram-export.json" -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "   ⚠️ Engram export did not create file (check engram.exe)"
        }
    }
} catch {
    Write-Host "   ⚠️ Engram error: $_"
}

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
            $skillsUsed = ""
            $actionsPerformed = ""
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
            
            # Get Engram data for this session
            if ($engramObservations.Count -gt 0) {
                # Try multiple matching strategies
                $sessionObs = @()
                
                # Strategy 1: Exact session_id match
                $sessionObs = $engramObservations | Where-Object { $_.session_id -eq $sessionId }
                
                # Strategy 2: If not found, try matching by session_id containing session file name
                if (-not $sessionObs -or $sessionObs.Count -eq 0) {
                    $sessionObs = $engramObservations | Where-Object { 
                        $_.session_id -and ($_.session_id -is [string]) -and $_.session_id.Contains($sessionId) 
                    }
                }
                
                # Strategy 3: Try matching by session field (some observations use 'session' not 'session_id')
                if (-not $sessionObs -or $sessionObs.Count -eq 0) {
                    $sessionObs = $engramObservations | Where-Object { 
                        $_.session -and ($_.session -is [string]) -and $_.session.Contains($sessionId) 
                    }
                }
                
                # Strategy 4: Try matching by content (search in session_id, session, or title)
                if (-not $sessionObs -or $sessionObs.Count -eq 0) {
                    $sessionObs = $engramObservations | Where-Object { 
                        ($_ -and $_.session_id -and $_.session_id.ToString().Contains($sessionId)) -or
                        ($_ -and $_.PSObject.Properties['session'] -and $_.session.ToString().Contains($sessionId)) -or
                        ($_ -and $_.title -and $_.title.ToString().Contains($sessionId))
                    }
                }
                
                if ($sessionObs -and $sessionObs.Count -gt 0) {
                    Write-Host "   ✅ Found $($sessionObs.Count) observations for $sessionId"
                    
                    # Extract skills from observations
                    $skillTitles = $sessionObs | Where-Object { 
                        $_.type -eq 'skill' -or ($_.title -and $_.title -match 'skill|Skill') 
                    } | Select-Object -ExpandProperty title -Unique | Where-Object { $_ }
                    $skillsUsed = if ($skillTitles) { ($skillTitles -join ';') } else { "" }
        
                    # Extract actions from observations
                    $actionTitles = $sessionObs | Where-Object { 
                        $_.type -eq 'architecture' -or $_.type -eq 'manual' -or 
                        ($_.title -and $_.title -match 'Fixed|Created|Updated|Implemented|Validated') 
                    } | Select-Object -ExpandProperty title -Unique | Where-Object { $_ }
                    $actionsPerformed = if ($actionTitles) { ($actionTitles -join ';') } else { "" }
        
                    # Determine outcome
                    $hasEscalation = $sessionObs | Where-Object { $_.type -eq 'escalation' -or ($_.title -and $_.title -match 'ESCALATED|escalated') }
                    $outcome = if ($hasEscalation) { "ESCALATED" } else { "COMPLETE" }
                    
                    # Count issues
                    $issuesFound = ($sessionObs | Where-Object { 
                        $_.type -eq 'bugfix' -or $_.type -eq 'issue' -or 
                        ($_.title -and $_.title -match 'bug|issue|fix') 
                    }).Count
                } else {
                    Write-Host "   ⚠️ No observations found for $sessionId"
                }
            }
            
            # Alternative: Extract from session content directly if Engram failed
            if ([string]::IsNullOrEmpty($skillsUsed) -or [string]::IsNullOrEmpty($actionsPerformed)) {
                # Try to extract from session file content
                $sessionContent = Get-Content $sessionFile.FullName -Raw
                
                # Look for skills in session content
                if ([string]::IsNullOrEmpty($skillsUsed)) {
                    $skillMatches = [regex]::Matches($sessionContent, '"skill[^"]*":\s*"([^"]+)"')
                    if ($skillMatches.Count -gt 0) {
                        $extractedSkills = $skillMatches | ForEach-Object { $_.Groups[1].Value }
                        $skillsUsed = ($extractedSkills -join ';')
                        Write-Host "   ✅ Extracted skills from session file"
                    }
                }
            }
            
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
                Notes = "Auto-collected from session + Engram"
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
