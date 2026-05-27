param(
    [ValidateSet('start', 'assign', 'broadcast', 'report', 'collect', 'status', 'stop')]
    [string]$Action = 'status',
    [string]$TeamId = '',
    [string]$Leader = '',
    [string]$Members = '',
    [string]$Agent = '',
    [string]$Task = '',
    [string]$Payload = '',
    [string]$Subject = '',
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$teamDir = Join-Path $repoRoot '.runtime' 'teams'
$messageBus = Join-Path $repoRoot 'scripts\adaptive\agent-message-bus.ps1'
$dispatchScript = Join-Path $scriptDir 'dispatch-agent.ps1'

if (-not (Test-Path $teamDir)) { New-Item -ItemType Directory -Path $teamDir -Force | Out-Null }

function Write-TeamLine {
    param([string]$M, [string]$C = 'White')
    if (-not $Quiet) { Write-Host $M -ForegroundColor $C }
}

function Get-TeamFile {
    param([string]$Id)
    Join-Path $teamDir "team-$Id.json"
}

function Convert-PSObjectToHashtable {
    param([object]$InputObject)
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [hashtable]) { return $InputObject }
    if ($InputObject -is [string] -or $InputObject -is [valueType]) { return $InputObject }
    if ($InputObject -is [array]) {
        if ($InputObject.Count -eq 0) { return $null }
        $result = @($InputObject | ForEach-Object { Convert-PSObjectToHashtable $_ })
        return , $result
    }
    if ($InputObject -is [PSObject]) {
        $ht = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            if ($prop.Value -is [array] -and $prop.Value.Count -eq 0) {
                $ht[$prop.Name] = [object[]]::new(0)
            } else {
                $ht[$prop.Name] = Convert-PSObjectToHashtable $prop.Value
            }
        }
        return $ht
    }
    return $InputObject
}

function Read-Team {
    param([string]$Id)
    $path = Get-TeamFile -Id $Id
    if (-not (Test-Path $path)) { return $null }
    $raw = Get-Content $path -Raw -Encoding utf8 -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }
    $parsed = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (-not $parsed) { return $null }
    return Convert-PSObjectToHashtable $parsed
}

function Write-Team {
    param([string]$Id, [object]$Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content (Get-TeamFile -Id $Id) -Encoding UTF8 -Force
}

function New-TeamId {
    "team-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([System.IO.Path]::GetRandomFileName().Substring(0,6))"
}

switch ($Action) {
    'start' {
        if (-not $Leader) { Write-TeamLine "[ERROR] -Leader required" 'Red'; exit 1 }
        $teamId = if ($TeamId) { $TeamId } else { New-TeamId }
        $memberList = if ($Members) { $Members -split ',' | ForEach-Object { $_.Trim().ToUpper() } } else { @() }

        $team = @{
            team_id = $teamId
            leader = $Leader.ToUpper()
            members = $memberList
            status = 'active'
            created = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
            assignments = @{}
            reports = @{}
            logs = @()
        }
        Write-Team $teamId $team

        & $messageBus -Action send -Sender "TEAM-$teamId" -Recipient $Leader -Subject 'team.assigned' -Payload "You are leader of team $teamId" -MessageType event -Quiet

        Write-TeamLine "[TEAM] $teamId | Leader: $Leader | Members: $($memberList -join ',')" 'Green'
        if ($AsJson) { return ($team | ConvertTo-Json -Depth 5) }
    }

    'assign' {
        if (-not $TeamId -or -not $Agent -or -not $Task) {
            Write-TeamLine "[ERROR] -TeamId, -Agent, -Task required" 'Red'; exit 1
        }
        $team = Read-Team $TeamId
        if (-not $team) { Write-TeamLine "[ERROR] Team not found: $TeamId" 'Red'; exit 1 }

        $assignmentId = "assign-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')"
        $team.assignments[$assignmentId] = @{
            agent = $Agent.ToUpper()
            task = $Task
            status = 'assigned'
            assigned_at = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        }
        $team.logs += @{
            type = 'assign'
            assignment_id = $assignmentId
            agent = $Agent.ToUpper()
            timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        }

        & $messageBus -Action send -Sender "TEAM-$TeamId-Leader" -Recipient $Agent.ToUpper() -Subject 'task.assigned' -Payload $Task -ConversationId $TeamId -Quiet

        Write-Team $TeamId $team
        Write-TeamLine "[TEAM] $TeamId | Assigned $Agent -> $Task" 'Cyan'
        if ($AsJson) { return ($team.assignments[$assignmentId] | ConvertTo-Json -Depth 3) }
    }

    'broadcast' {
        if (-not $TeamId -or -not $Subject) {
            Write-TeamLine "[ERROR] -TeamId, -Subject required" 'Red'; exit 1
        }
        $team = Read-Team $TeamId
        if (-not $team) { Write-TeamLine "[ERROR] Team not found: $TeamId" 'Red'; exit 1 }

        $allAgents = @($team.leader) + $team.members
        foreach ($a in $allAgents) {
            & $messageBus -Action send -Sender "TEAM-$TeamId" -Recipient $a -Subject $Subject -Payload $Payload -MessageType broadcast -ConversationId $TeamId -Quiet
        }

        $team.logs += @{
            type = 'broadcast'
            subject = $Subject
            timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        }
        Write-Team $TeamId $team
        Write-TeamLine "[TEAM] $TeamId | Broadcast '$Subject' to $($allAgents.Count) agents" 'Green'
        if ($AsJson) { return (@{ status = 'broadcast'; team = $TeamId; recipients = $allAgents.Count } | ConvertTo-Json) }
    }

    'report' {
        if (-not $TeamId -or -not $Agent -or -not $Payload) {
            Write-TeamLine "[ERROR] -TeamId, -Agent, -Payload required" 'Red'; exit 1
        }
        $team = Read-Team $TeamId
        if (-not $team) { Write-TeamLine "[ERROR] Team not found: $TeamId" 'Red'; exit 1 }

        $reportId = "report-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')"
        $reportPayload = $Payload
        try { $reportPayload = $Payload | ConvertFrom-Json } catch {}
        $team.reports[$reportId] = @{
            agent = $Agent.ToUpper()
            payload = $reportPayload
            reported_at = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        }
        $team.logs += @{
            type = 'report'
            report_id = $reportId
            agent = $Agent.ToUpper()
            timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        }

        & $messageBus -Action send -Sender $Agent.ToUpper() -Recipient "TEAM-$TeamId-Leader" -Subject 'task.report' -Payload $Payload -ConversationId $TeamId -Quiet

        Write-Team $TeamId $team
        Write-TeamLine "[TEAM] $TeamId | Report from $Agent" 'Yellow'
        if ($AsJson) { return (@{ report_id = $reportId; status = 'received' } | ConvertTo-Json) }
    }

    'collect' {
        if (-not $TeamId) { Write-TeamLine "[ERROR] -TeamId required" 'Red'; exit 1 }
        $team = Read-Team $TeamId
        if (-not $team) { Write-TeamLine "[ERROR] Team not found: $TeamId" 'Red'; exit 1 }

        Write-TeamLine "=== TEAM REPORTS: $TeamId ===" 'Cyan'
        Write-TeamLine "Leader: $($team.leader) | Members: $($team.members -join ',')" 'White'
        foreach ($r in $team.reports.PSObject.Properties) {
            Write-Host "  [$($r.Value.agent)] $($r.Value.reported_at)" -ForegroundColor Yellow
            $payloadStr = if ($r.Value.payload -is [string]) { $r.Value.payload.Substring(0, [Math]::Min(200, $r.Value.payload.Length)) } else { ($r.Value.payload | ConvertTo-Json -Compress) }
            Write-Host "    $payloadStr" -ForegroundColor Gray
        }

        if ($AsJson) {
            return (@{
                team_id = $TeamId
                leader = $team.leader
                members = $team.members
                reports = @($team.reports.PSObject.Properties | ForEach-Object { $_.Value })
                report_count = @($team.reports.PSObject.Properties).Count
            } | ConvertTo-Json -Depth 5)
        }
    }

    'status' {
        $teams = @(Get-ChildItem $teamDir -Filter 'team-*.json' -ErrorAction SilentlyContinue)
        if ($TeamId) {
            $team = Read-Team $TeamId
            if (-not $team) { Write-TeamLine "[ERROR] Team not found: $TeamId" 'Red'; exit 1 }
            $assignCount = @($team.assignments.Keys).Count
            $reportCount = @($team.reports.Keys).Count
            Write-TeamLine "=== TEAM: $TeamId ===" 'Cyan'
            Write-Host "  Leader: $($team.leader)" -ForegroundColor White
            Write-Host "  Members: $($team.members -join ', ')" -ForegroundColor White
            Write-Host "  Status: $($team.status)" -ForegroundColor $(if ($team.status -eq 'active') { 'Green' } else { 'Gray' })
            Write-Host "  Assignments: $assignCount" -ForegroundColor Yellow
            Write-Host "  Reports: $reportCount" -ForegroundColor Yellow
            Write-Host "  Created: $($team.created)" -ForegroundColor Gray
            if ($AsJson) { return ($team | ConvertTo-Json -Depth 5) }
        } else {
            Write-TeamLine "=== ACTIVE TEAMS ($($teams.Count)) ===" 'Cyan'
            foreach ($f in $teams) {
                $t = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                Write-Host "  $($t.team_id) | Leader: $($t.leader) | Members: $($t.members -join ',') | Status: $($t.status)" -ForegroundColor $(if ($t.status -eq 'active') { 'Green' } else { 'Gray' })
            }
            if ($AsJson) {
                $teamList = @($teams | ForEach-Object { Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json })
                return (@{ teams = $teamList; count = $teamList.Count } | ConvertTo-Json -Depth 5)
            }
        }
    }

    'stop' {
        if (-not $TeamId) { Write-TeamLine "[ERROR] -TeamId required" 'Red'; exit 1 }
        $team = Read-Team $TeamId
        if (-not $team) { Write-TeamLine "[ERROR] Team not found: $TeamId" 'Red'; exit 1 }
        $team.status = 'completed'
        $team.completed = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        Write-Team $TeamId $team

        & $messageBus -Action send -Sender "ORCHESTRATOR" -Recipient $team.leader -Subject 'team.completed' -Payload "Team $TeamId completed" -MessageType event -Quiet

        Write-TeamLine "[TEAM] $TeamId stopped" 'Yellow'
        if ($AsJson) { return (@{ status = 'completed'; team_id = $TeamId } | ConvertTo-Json) }
    }
}
