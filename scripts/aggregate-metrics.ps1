# aggregate-metrics.ps1
# Aggregates audit data into metrics

param(
    [ValidateSet("daily", "weekly", "monthly", "auto")]
    [string]$Period = "auto",
    [datetime]$StartDate,
    [datetime]$EndDate,
    [switch]$Silent
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$auditDir = Join-Path $projectRoot ".audit"

if (-not (Test-Path $auditDir)) {
    if (-not $Silent) { Write-Warning "Audit directory not found. Run generate-session-audit.ps1 first." }
    exit 0
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

function Get-SessionsInRange {
    param([datetime]$Start, [datetime]$End)
    
    $sessionsPath = Join-Path $auditDir "sessions"
    if (-not (Test-Path $sessionsPath)) { return @() }
    
    $sessions = @()
    Get-ChildItem -Path $sessionsPath -Filter "*.json" | ForEach-Object {
        try {
            $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $timestamp = [DateTime]::Parse($content.timestamp)
            if ($timestamp -ge $Start -and $timestamp -le $End) {
                $sessions += $content
            }
        } catch {
            Write-Log "Could not parse session: $($_.FullName)" "WARN"
        }
    }
    return $sessions
}

function Get-MetricsPath {
    param([string]$Type)
    return Join-Path $auditDir "metrics\$Type.json"
}

function Save-Metrics {
    param([string]$Type, [object]$Data)
    
    $metricsDir = Join-Path $auditDir "metrics"
    if (-not (Test-Path $metricsDir)) {
        New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    }
    
    $path = Get-MetricsPath -Type $Type
    $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $path -Encoding UTF8
    Write-Log "Saved $Type metrics" "OK"
}

function Calculate-Metrics {
    param($Sessions, [datetime]$Start, [datetime]$End)
    
    $totalRequests = 0
    $totalTokens = 0
    $totalLinesAdded = 0
    $totalLinesRemoved = 0
    $filesCreated = 0
    $filesModified = 0
    $filesDeleted = 0
    $prsOpened = 0
    $prsMerged = 0
    $sessionsWithAi = 0
    $aiGeneratedLines = 0
    $activeUsers = @{}
    
    $byTool = @{
        claude = @{ requests = 0; tokens = 0 }
        opencode = @{ requests = 0; tokens = 0 }
        gentleAi = @{ requests = 0; tokens = 0 }
        gga = @{ invocations = 0 }
    }
    
    $actionBreakdown = @{
        codeGeneration = 0
        codeReview = 0
        refactoring = 0
        testGeneration = 0
        documentation = 0
    }
    
    foreach ($session in $Sessions) {
        $user = $session.user.userName
        if (-not $activeUsers.ContainsKey($user)) {
            $activeUsers[$user] = 0
        }
        $activeUsers[$user]++
        
        $totalLinesAdded += $session.activity.linesAdded
        $totalLinesRemoved += $session.activity.linesRemoved
        $filesCreated += $session.metrics.filesCreated
        $filesModified += $session.metrics.filesUpdated
        $filesDeleted += $session.metrics.filesDeleted
        $prsOpened += $session.metrics.prsCreated
        $prsMerged += $session.metrics.prsMerged
        
        $aiRequests = 0
        foreach ($tool in $session.aiTools.PSObject.Properties) {
            if ($byTool.ContainsKey($tool.Name)) {
                $byTool[$tool.Name].requests += $tool.Value.requests
                $byTool[$tool.Name].tokens += $tool.Value.tokensEstimated
                $totalTokens += $tool.Value.tokensEstimated
                $aiRequests += $tool.Value.requests
                $totalRequests += $tool.Value.requests
            }
        }
        
        if ($aiRequests -gt 0) {
            $sessionsWithAi++
            $aiGeneratedLines += $session.activity.linesAdded
        }
        
        foreach ($action in $session.activity.actions) {
            switch ($action.type) {
                "code-generation" { $actionBreakdown.codeGeneration++ }
                "code-review" { $actionBreakdown.codeReview++ }
                "refactor" { $actionBreakdown.refactoring++ }
                "test-generation" { $actionBreakdown.testGeneration++ }
                "documentation" { $actionBreakdown.documentation++ }
            }
        }
    }
    
    $days = ($End - $Start).Days + 1
    if ($days -lt 1) { $days = 1 }
    
    $claudeCost = [math]::Round($byTool.claude.tokens / 1000 * 0.018, 2)
    $opencodeCost = [math]::Round($byTool.opencode.tokens / 1000 * 0.005, 2)
    
    return @{
        generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        period = @{
            start = $Start.ToString("yyyy-MM-dd")
            end = $End.ToString("yyyy-MM-dd")
            days = $days
            type = $Period
        }
        summary = @{
            sessions = $Sessions.Count
            activeUsers = $activeUsers.Count
            totalRequests = $totalRequests
            totalTokens = $totalTokens
            linesAdded = $totalLinesAdded
            linesRemoved = $totalLinesRemoved
        }
        velocity = @{
            commits = @{
                total = $Sessions.Count
                withAiAssistance = $sessionsWithAi
                aiAssistanceRate = if ($Sessions.Count -gt 0) { [math]::Round($sessionsWithAi / $Sessions.Count * 100, 1) } else { 0 }
            }
            linesOfCode = @{
                added = $totalLinesAdded
                removed = $totalLinesRemoved
                netChange = $totalLinesAdded - $totalLinesRemoved
                aiGenerated = $aiGeneratedLines
                aiGenerationRate = if ($totalLinesAdded -gt 0) { [math]::Round($aiGeneratedLines / $totalLinesAdded * 100, 1) } else { 0 }
            }
            files = @{
                created = $filesCreated
                modified = $filesModified
                deleted = $filesDeleted
            }
            pullRequests = @{
                opened = $prsOpened
                merged = $prsMerged
            }
        }
        tools = $byTool
        actions = $actionBreakdown
        costs = @{
            total = $claudeCost + $opencodeCost
            claude = $claudeCost
            opencode = $opencodeCost
            dailyAverage = [math]::Round(($claudeCost + $opencodeCost) / $days, 2)
            monthlyProjected = [math]::Round(($claudeCost + $opencodeCost) / $days * 30, 2)
        }
        topUsers = ($activeUsers.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object { @{ name = $_.Key; sessions = $_.Value } })
    }
}

# Auto-detect period if not specified
if ($Period -eq "auto") {
    $dayOfWeek = (Get-Date).DayOfWeek
    if ($dayOfWeek -eq 'Sunday' -or $dayOfWeek -eq 'Monday') {
        $Period = "weekly"
    } else {
        $Period = "daily"
    }
}

# Set date range based on period
if (-not $StartDate -or -not $EndDate) {
    $EndDate = Get-Date
    switch ($Period) {
        "daily" { $StartDate = $EndDate.AddDays(-1).Date }
        "weekly" { $StartDate = $EndDate.AddDays(-7).Date }
        "monthly" { $StartDate = $EndDate.AddDays(-30).Date }
    }
}

Write-Log "Aggregating $Period metrics: $($StartDate.ToString('yyyy-MM-dd')) - $($EndDate.ToString('yyyy-MM-dd'))" "INFO"

$sessions = Get-SessionsInRange -Start $StartDate -End $EndDate

if ($sessions.Count -eq 0) {
    Write-Log "No session data found for the specified period." "WARN"
    exit 0
}

Write-Log "Found $($sessions.Count) sessions" "INFO"

$metrics = Calculate-Metrics -Sessions $sessions -Start $StartDate -End $EndDate
Save-Metrics -Type $Period -Data $metrics

if (-not $Silent) {
    Write-Host ""
    Write-Log "Metrics Summary:" "INFO"
    Write-Host "  Sessions: $($metrics.summary.sessions)" -ForegroundColor White
    Write-Host "  Active users: $($metrics.summary.activeUsers)" -ForegroundColor White
    Write-Host "  AI requests: $($metrics.summary.totalRequests)" -ForegroundColor White
    Write-Host "  Lines: +$($metrics.velocity.linesOfCode.added) / -$($metrics.velocity.linesOfCode.removed)" -ForegroundColor White
    Write-Host "  Est. cost: `$$($metrics.costs.total)" -ForegroundColor White
}
