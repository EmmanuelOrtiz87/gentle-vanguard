function Invoke-TokenBudgetGuard {
    param([string]$Task, [string]$Risk = 'medium', [int]$EstimatedChars = 0, [int]$ActualPromptTokens = 0, [int]$ActualCompletionTokens = 0)
    $guardScript = Join-Path $global:scriptDir '..\TELEMETRY-METRICS\token-budget-guard.ps1'
    if (-not (Test-Path $guardScript)) { return }
    $guardArgs = @{ Mode = 'check'; Task = $Task; Risk = $Risk; Record = $true; AsJson = $true; Quiet = $true }
    if ($EstimatedChars -gt 0) { $guardArgs['EstimatedChars'] = $EstimatedChars }
    if ($ActualPromptTokens -gt 0) { $guardArgs['ActualPromptTokens'] = $ActualPromptTokens }
    if ($ActualCompletionTokens -gt 0) { $guardArgs['ActualCompletionTokens'] = $ActualCompletionTokens }
    $guardResult = $null
    try { $guardRaw = & $guardScript @guardArgs; if ($guardRaw) { $guardResult = [string]$guardRaw | ConvertFrom-Json -ErrorAction Stop } }
    catch { $fallback = @('-Mode', 'check', '-Task', $Task, '-Risk', $Risk, '-Record'); if ($EstimatedChars -gt 0) { $fallback += @('-EstimatedChars', $EstimatedChars) }; & $guardScript @fallback; return }
    if ($guardResult -and $guardResult.status -ne 'PASS') { Write-Warning "Token guard: $($guardResult.status) projected=$($guardResult.projected_pct)% for $Task" }
    Invoke-TokenAutopilot -Task $Task -GuardResult $guardResult
}

function Get-TokenAutopilotPolicy {
    $defaults = [ordered]@{ enabled = $true; triggerStatuses = @('SOFT_LIMIT','HARD_LIMIT'); minConsecutiveAlerts = 2; autoApplyOnCommands = @('context-pack','compact-start','audit','publish','end-session','dispatch'); applyChatLevel = 'chat-compact'; stateFile = Join-Path $global:repoRoot '.session\token-autopilot-state.json' }
    $configPath = Join-Path $global:repoRoot 'config\context-efficiency.json'
    if (-not (Test-Path $configPath)) { return [pscustomobject]$defaults }
    try { $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json; if ($cfg.tokenAutopilot) { foreach ($k in $defaults.Keys) { if ($null -ne $cfg.tokenAutopilot.$k) { $defaults[$k] = $cfg.tokenAutopilot.$k } } } } catch {}
    [pscustomobject]$defaults
}

function Get-TokenAutopilotState { param([string]$StatePath); if (Test-Path $StatePath) { try { return Get-Content $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {} }; [pscustomobject]@{consecutiveAlerts=0;lastStatus='PASS';lastTask='';lastAppliedChatLevel='';lastAppliedAt=''} }

function Save-TokenAutopilotState { param([string]$StatePath, [pscustomobject]$State); $dir = Split-Path $StatePath -Parent; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }; $State | ConvertTo-Json -Depth 10 | Set-Content $StatePath -Encoding UTF8 }

function Set-TokenAutopilotProfile {
    param([string]$Profile)
    $configPath = Join-Path $global:repoRoot 'config\context-efficiency.json'
    if (-not (Test-Path $configPath)) { throw "config/context-efficiency.json not found" }
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $config.tokenAutopilot) { $config | Add-Member -NotePropertyName tokenAutopilot -NotePropertyValue ([pscustomobject]@{}) }
    if ($Profile -eq 'hard') { $config.tokenAutopilot.profile = 'hard'; $config.tokenAutopilot.triggerStatuses = @('HARD_LIMIT'); $config.tokenAutopilot.minConsecutiveAlerts = 1; $config.tokenAutopilot.applyChatLevel = 'chat-compact' }
    else { $config.tokenAutopilot.profile = 'balanced'; $config.tokenAutopilot.triggerStatuses = @('SOFT_LIMIT','HARD_LIMIT'); $config.tokenAutopilot.minConsecutiveAlerts = 2; $config.tokenAutopilot.applyChatLevel = 'chat-compact' }
    $config | ConvertTo-Json -Depth 30 | Set-Content $configPath -Encoding UTF8
}

function Invoke-TokenAutopilot {
    param([string]$Task, [pscustomobject]$GuardResult)
    if (-not $GuardResult) { return }
    $policy = Get-TokenAutopilotPolicy; if (-not $policy.enabled) { return }
    $normalized = if ($Task) { $Task.Trim().ToLowerInvariant() } else { 'general' }
    if (($policy.autoApplyOnCommands | ForEach-Object { [string]$_ }) -notcontains $normalized) { return }
    $status = [string]$GuardResult.status; $triggers = @($policy.triggerStatuses | ForEach-Object { [string]$_ })
    $statePath = Join-Path $global:repoRoot ([string]$policy.stateFile)
    $state = Get-TokenAutopilotState -StatePath $statePath
    if ($triggers -contains $status) { $state.consecutiveAlerts = [int]$state.consecutiveAlerts + 1 } else { $state.consecutiveAlerts = 0 }
    $state.lastStatus = $status; $state.lastTask = $normalized
    $required = [Math]::Max(1, [int]$policy.minConsecutiveAlerts)
    if (($triggers -contains $status) -and ([int]$state.consecutiveAlerts -ge $required)) {
        $modeScript = Join-Path $global:scriptDir '..\UTILITIES\response-mode.ps1'
        if (Test-Path $modeScript) { $chatLevel = [string]$policy.applyChatLevel; & $modeScript -Mode set-chat-level -ChatLevel $chatLevel -SkipEngramLog 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $state.lastAppliedChatLevel = $chatLevel; $state.lastAppliedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'); Write-Warning "Autopilot: chat-level=$chatLevel after $($state.consecutiveAlerts) alerts (status=$status)." } }
    }
    Save-TokenAutopilotState -StatePath $statePath -State $state
}

function Get-ContextEfficiencyPolicy {
    $defaults = @{ ProfileName='default'; WindowDays=7; PromptYellowMax=1200; PromptRedMax=1800; AdoptionYellowMin=70; AdoptionRedMin=40 }
    $policyPath = Join-Path $global:repoRoot 'config/context-efficiency.json'
    if (-not (Test-Path $policyPath)) { return $defaults }
    try {
        $policy = Get-Content $policyPath -Raw | ConvertFrom-Json; $source = $policy
        if ($policy.profiles) { $requested = if ($policy.activeProfile) {[string]$policy.activeProfile} else {'default'}; $avail = @($policy.profiles.PSObject.Properties.Name); if ($avail -contains $requested) { $source = $policy.profiles.$requested; $defaults.ProfileName = $requested } elseif ($avail -contains 'default') { $source = $policy.profiles.default; $defaults.ProfileName = 'default' } }
        if ($null -ne $source.windowDays) { $defaults.WindowDays = [int]$source.windowDays }
        if ($source.promptChars -and $null -ne $source.promptChars.yellowMax) { $defaults.PromptYellowMax = [int]$source.promptChars.yellowMax }
        if ($source.promptChars -and $null -ne $source.promptChars.redMax) { $defaults.PromptRedMax = [int]$source.promptChars.redMax }
        if ($source.adoptionPercent -and $null -ne $source.adoptionPercent.yellowMin) { $defaults.AdoptionYellowMin = [int]$source.adoptionPercent.yellowMin }
        if ($source.adoptionPercent -and $null -ne $source.adoptionPercent.redMin) { $defaults.AdoptionRedMin = [int]$source.adoptionPercent.redMin }
    } catch { Write-Warning "Invalid context efficiency policy; using defaults." }
    $defaults
}

function Get-ContextLiveAssistPolicy {
    $defaults = @{ Enabled = $true; ShowOnCommands = @('status','health','start-session','end-session','day-end-closure','review','audit','publish'); AutoRunOnStartSessionWhenRed = $false }
    $policyPath = Join-Path $global:repoRoot 'config/context-efficiency.json'
    if (-not (Test-Path $policyPath)) { return $defaults }
    try { $policy = Get-Content $policyPath -Raw | ConvertFrom-Json; if ($policy.liveAssist) { if ($null -ne $policy.liveAssist.enabled) { $defaults.Enabled = [bool]$policy.liveAssist.enabled }; if ($policy.liveAssist.showOnCommands) { $defaults.ShowOnCommands = @($policy.liveAssist.showOnCommands | ForEach-Object {[string]$_}) }; if ($null -ne $policy.liveAssist.autoRunOnStartSessionWhenRed) { $defaults.AutoRunOnStartSessionWhenRed = [bool]$policy.liveAssist.autoRunOnStartSessionWhenRed } } } catch { Write-Warning 'Invalid live-assist policy.' }
    $defaults
}

function Get-ContextMetricsSnapshot {
    param([int]$Days = 7)
    $policy = Get-ContextEfficiencyPolicy
    if ($Days -le 0) { $Days = $policy.WindowDays }
    $metricsPath = Join-Path $global:repoRoot 'docs/sessions/metrics/context-usage.csv'
    if (-not (Test-Path $metricsPath)) {
        return @{ HealthStatus='WARN (no data)'; Recommendation='Run compact-start to collect data.'; WindowDays=$Days; TotalEvents=0; ContextPackCount=0; CompactStartCount=0; AdoptionPercent=0; AvgObjectiveChars=0; AvgPromptChars=0; HasData=$false;
            Lines=@('| Metric | Value |','|---|---|',"| Policy | $($policy.ProfileName) |",'| Data | None collected yet |')
            TrendLines=@('| Metric | Current 7d | Prev 7d | Delta |','|---|---:|---:|---:|','| Events | 0 | 0 | 0 |','| Avg prompt | 0 | 0 | 0 |','| Adoption % | 0 | 0 | 0 |') }
    }
    $now = Get-Date; $currentStart = $now.AddDays(-$Days); $previousStart = $now.AddDays(-2*$Days)
    $allRows = Import-Csv $metricsPath
    $rows = @($allRows | Where-Object { [datetime]::Parse($_.timestamp) -ge $currentStart })
    $prevRows = @($allRows | Where-Object { $ts = [datetime]::Parse($_.timestamp); $ts -ge $previousStart -and $ts -lt $currentStart })
    if (-not $rows) {
        return @{ HealthStatus='WARN (no events)'; Recommendation='Run compact-start.'; WindowDays=$Days; TotalEvents=0; ContextPackCount=0; CompactStartCount=0; AdoptionPercent=0; HasData=$false; Lines=@('| Metric | Value |','|---|---|','| No events | in window |'); TrendLines=@() }
    }
    $total = $rows.Count; $pack = @($rows | Where-Object event -eq 'context-pack').Count; $compact = @($rows | Where-Object event -eq 'compact-start').Count
    $avgObjective = [math]::Round((($rows | Measure-Object -Property objective_chars -Average).Average),1)
    $avgPrompt = [math]::Round((($rows | Measure-Object -Property prompt_chars -Average).Average),1)
    $adoption = if ($total -gt 0) { [math]::Round(($compact*100.0)/$total,1) } else { 0 }
    $prevTotal = $prevRows.Count; $prevCompact = @($prevRows | Where-Object event -eq 'compact-start').Count; $prevAvgP = if ($prevTotal -gt 0) { [math]::Round((($prevRows | Measure-Object -Property prompt_chars -Average).Average),1) } else { 0 }; $prevAdopt = if ($prevTotal -gt 0) { [math]::Round(($prevCompact*100.0)/$prevTotal,1) } else { 0 }
    $health = 'GREEN'
    if ($avgPrompt -gt $policy.PromptRedMax -or $adoption -lt $policy.AdoptionRedMin) { $health = 'RED' }
    elseif ($avgPrompt -gt $policy.PromptYellowMax -or $adoption -lt $policy.AdoptionYellowMin) { $health = 'YELLOW' }
    $recommendation = if ($health -eq 'RED') { 'Enforce compact-start before handoffs.' } elseif ($health -eq 'YELLOW') { 'Increase compact-start adoption.' } else { 'Maintain current usage.' }
    @{ HealthStatus=$health; Recommendation=$recommendation; WindowDays=$Days; TotalEvents=$total; ContextPackCount=$pack; CompactStartCount=$compact; AdoptionPercent=$adoption; AvgObjectiveChars=$avgObjective; AvgPromptChars=$avgPrompt; HasData=$true
        Lines=@('| Metric | Value |','|---|---|',"| Profile | $($policy.ProfileName) |","| Thresholds | Y<=$($policy.PromptYellowMax) & >=$($policy.AdoptionYellowMin)% ; R<=$($policy.PromptRedMax) & >=$($policy.AdoptionRedMin)% |","| Window | $Days days |","| Events | $total |","| compact-start | $compact ($adoption%) |","| Avg prompt chars | $avgPrompt |")
        TrendLines=@('| Metric | Current 7d | Prev 7d | Delta |','|---|---:|---:|---:|',"| Events | $total | $prevTotal | $($total-$prevTotal) |","| Avg prompt | $avgPrompt | $prevAvgP | $([math]::Round($avgPrompt-$prevAvgP,1)) |","| Adoption % | $adoption | $prevAdopt | $([math]::Round($adoption-$prevAdopt,1)) |") }
}

function Invoke-ContextEfficiencyLiveAssist {
    param([string]$CommandName, [string]$Objective = '')
    $livePolicy = Get-ContextLiveAssistPolicy
    if (-not $livePolicy.Enabled) { return }
    $normalized = if ($CommandName) { $CommandName.Trim().ToLowerInvariant() } else { '' }
    if (-not $normalized) { return }
    if (@('help','context-pack','compact-start','context-metrics') -contains $normalized) { return }
    if (($livePolicy.ShowOnCommands | ForEach-Object {[string]$_}) -notcontains $normalized) { return }
    $metrics = Get-ContextMetricsSnapshot -Days 7
    $needsNudge = ($metrics.HealthStatus -like 'RED*') -or ($metrics.HealthStatus -like 'YELLOW*') -or ($metrics.HealthStatus -like 'WARN*')
    if (-not $needsNudge) { return }
    Write-Host "`n[Context Efficiency] Status: $($metrics.HealthStatus) | adoption: $($metrics.AdoptionPercent)% | avg: $($metrics.AvgPromptChars) chars"
    Write-Host "  Recommendation: $($metrics.Recommendation)" -ForegroundColor Yellow
    Write-Host "  Run: gv.ps1 compact-start '<objective>'" -ForegroundColor Cyan
    if ($livePolicy.AutoRunOnStartSessionWhenRed -and $normalized -eq 'start-session' -and ($metrics.HealthStatus -like 'RED*')) {
        $compactScript = Join-Path $global:scriptDir 'compact-start.ps1'
        $marker = Join-Path $global:repoRoot '.session\.compact-marker'
        $alreadyRun = $false
        if (Test-Path $marker) { try { $last = Get-Content $marker -Raw; if ($last -match '\d') { $t = [datetime]::Parse($last,[cultureinfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::AssumeUniversal); if ((Get-Date).ToUniversalTime() - $t -lt [timespan]::FromMinutes(60)) { $alreadyRun = $true } } } catch {} }
        if (-not $alreadyRun -and (Test-Path $compactScript)) { $autoObjective = if ($Objective) { $Objective } else { "resume work" }; & $compactScript -Objective $autoObjective | Out-Null; if ($LASTEXITCODE -eq 0) { Write-Success 'Auto compact-start completed.' } else { Write-Warning 'Auto compact-start failed.' } }
    }
}

