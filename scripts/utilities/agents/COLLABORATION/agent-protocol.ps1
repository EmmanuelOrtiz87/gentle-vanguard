<#
.SYNOPSIS
    Agent collaboration protocol for multi-agent coordination.
.DESCRIPTION
    Enables agents to communicate, delegate tasks, share context,
    and coordinate work across the Gentle-Vanguard stack.
.PARAMETER Action
    register: Register an agent with capabilities
    discover: Discover available agents
    send: Send a message to another agent
    inbox: Check inbox for messages
    delegate: Delegate a task to another agent
    status: Show agent status
.PARAMETER AgentName
    Name of the agent performing the action
.PARAMETER TargetAgent
    Target agent for send/delegate actions
.PARAMETER Message
    Message content (for send action)
.PARAMETER Task
    Task description (for delegate action)
.PARAMETER Quiet
    Suppress output.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('register','discover','send','inbox','delegate','status')]
    [string]$Action,
    [string]$AgentName = "",
    [string]$TargetAgent = "",
    [string]$Message = "",
    [string]$Task = "",
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$root = Split-Path -Parent $root
$protocolDir = Join-Path $root '.agent-protocol'
$agentsFile = Join-Path $protocolDir 'agents.json'
$messagesDir = Join-Path $protocolDir 'messages'
$logFile = Join-Path $protocolDir 'protocol-log.jsonl'

# Ensure directories exist
if (-not (Test-Path $protocolDir)) {
    New-Item -ItemType Directory -Path $protocolDir -Force | Out-Null
}
if (-not (Test-Path $messagesDir)) {
    New-Item -ItemType Directory -Path $messagesDir -Force | Out-Null
}

function Get-Agents {
    if (-not (Test-Path $agentsFile)) {
        return @{ version = "1.0"; agents = @{} }
    }
    return Get-Content $agentsFile -Raw | ConvertFrom-Json
}

function Save-Agents {
    param($Data)
    $Data | ConvertTo-Json -Depth 5 | Set-Content -Path $agentsFile -Encoding UTF8
}

function Get-AgentInbox {
    param([string]$Agent)
    $inboxFile = Join-Path $messagesDir "$Agent-inbox.json"
    if (-not (Test-Path $inboxFile)) { return @() }
    return (Get-Content $inboxFile -Raw | ConvertFrom-Json)
}

function Save-AgentInbox {
    param([string]$Agent, [array]$Messages)
    $inboxFile = Join-Path $messagesDir "$Agent-inbox.json"
    $Messages | ConvertTo-Json -Depth 5 | Set-Content -Path $inboxFile -Encoding UTF8
}

function Log-Action {
    param([string]$Action, [string]$Agent, [string]$Detail)
    $entry = @{
        timestamp = (Get-Date).ToString('o')
        action = $Action
        agent = $Agent
        detail = $Detail
    }
    $entry | ConvertTo-Json -Compress | Out-File -Append -FilePath $logFile -Encoding UTF8
}

$timestamp = (Get-Date).ToString('o')

switch ($Action) {
    'register' {
        if (-not $AgentName) {
            if (-not $Quiet) { Write-Host " [ERROR] AgentName required" -ForegroundColor Red }
            exit 1
        }

        $data = Get-Agents

        # Auto-detect capabilities based on agent name
        $capabilities = @()
        $agentLower = $AgentName.ToLower()
        if ($agentLower -match "dev|code|impl") { $capabilities += @("code-generation", "refactoring", "debugging") }
        if ($agentLower -match "test|qa|verify") { $capabilities += @("testing", "validation", "verification") }
        if ($agentLower -match "doc|write|readme") { $capabilities += @("documentation", "writing", "analysis") }
        if ($agentLower -match "ops|deploy|infra") { $capabilities += @("deployment", "infrastructure", "monitoring") }
        if ($agentLower -match "design|arch|sad") { $capabilities += @("architecture", "design", "planning") }
        if ($agentLower -match "explore|search|find") { $capabilities += @("exploration", "search", "analysis") }
        if ($agentLower -match "gov|audit|security") { $capabilities += @("governance", "security", "audit") }
        if ($agentLower -match "sdd") { $capabilities += @("sdd-workflow", "planning", "design") }
        if ($capabilities.Count -eq 0) { $capabilities += @("general") }

        $data.agents.$AgentName = @{
            name = $AgentName
            capabilities = $capabilities
            status = "online"
            registeredAt = $timestamp
            lastSeen = $timestamp
        }

        Save-Agents $data
        Log-Action "register" $AgentName "capabilities: $($capabilities -join ', ')"

        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Green
            Write-Host " [AC] Agent registered: $AgentName" -ForegroundColor Green
            Write-Host " Capabilities: $($capabilities -join ', ')" -ForegroundColor Gray
            Write-Host "============================================" -ForegroundColor Green
        }
    }

    'discover' {
        $data = Get-Agents
        $agents = $data.agents

        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " [AC] Available Agents ($($agents.Count))" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan

            foreach ($name in $agents.PSObject.Properties.Name) {
                $a = $agents.$name
                $caps = ($a.capabilities -join ', ')
                $color = if ($a.status -eq 'online') { 'Green' } else { 'Red' }
                Write-Host (" [{0}] {1,-20} {2}" -f $a.status.ToUpper(), $name, $caps) -ForegroundColor $color
            }
            Write-Host ""
        }

        $agents
    }

    'send' {
        if (-not $AgentName -or -not $TargetAgent -or -not $Message) {
            if (-not $Quiet) { Write-Host " [ERROR] AgentName, TargetAgent, and Message required" -ForegroundColor Red }
            exit 1
        }

        $data = Get-Agents
        if (-not $data.agents.$TargetAgent) {
            if (-not $Quiet) { Write-Host " [ERROR] Target agent not found: $TargetAgent" -ForegroundColor Red }
            exit 1
        }

        $msg = @{
            id = [guid]::NewGuid().ToString('N').Substring(0,8)
            from = $AgentName
            to = $TargetAgent
            type = "message"
            content = $Message
            timestamp = $timestamp
            read = $false
        }

        $inbox = Get-AgentInbox $TargetAgent
        $inbox += $msg
        Save-AgentInbox $TargetAgent $inbox

        # Update lastSeen
        $data.agents.$AgentName.lastSeen = $timestamp
        Save-Agents $data

        Log-Action "send" $AgentName "to=$TargetAgent msg=$($Message.Substring(0, [Math]::Min(50, $Message.Length)))"

        if (-not $Quiet) {
            Write-Host " [SENT] $AgentName → $TargetAgent: $($Message.Substring(0, [Math]::Min(60, $Message.Length)))..." -ForegroundColor Green
        }
    }

    'inbox' {
        if (-not $AgentName) {
            if (-not $Quiet) { Write-Host " [ERROR] AgentName required" -ForegroundColor Red }
            exit 1
        }

        $inbox = Get-AgentInbox $AgentName
        $unread = $inbox | Where-Object { -not $_.read }

        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " [AC] Inbox: $AgentName ($($unread.Count) unread / $($inbox.Count) total)" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan

            foreach ($msg in $inbox[-10..-1]) {
                $readIcon = if ($msg.read) { " " } else { "*" }
                Write-Host (" [{0}] {1} → {2}: {3}" -f $readIcon, $msg.from, $msg.to, $msg.content.Substring(0, [Math]::Min(50, $msg.content.Length))) -ForegroundColor $(if($msg.read){'Gray'}else{'White'})
            }
            Write-Host ""
        }

        $inbox
    }

    'delegate' {
        if (-not $AgentName -or -not $TargetAgent -or -not $Task) {
            if (-not $Quiet) { Write-Host " [ERROR] AgentName, TargetAgent, and Task required" -ForegroundColor Red }
            exit 1
        }

        $data = Get-Agents
        if (-not $data.agents.$TargetAgent) {
            if (-not $Quiet) { Write-Host " [ERROR] Target agent not found: $TargetAgent" -ForegroundColor Red }
            exit 1
        }

        $msg = @{
            id = [guid]::NewGuid().ToString('N').Substring(0,8)
            from = $AgentName
            to = $TargetAgent
            type = "delegate"
            content = $Task
            timestamp = $timestamp
            read = $false
            status = "pending"
        }

        $inbox = Get-AgentInbox $TargetAgent
        $inbox += $msg
        Save-AgentInbox $TargetAgent $inbox

        $data.agents.$AgentName.lastSeen = $timestamp
        Save-Agents $data

        Log-Action "delegate" $AgentName "to=$TargetAgent task=$($Task.Substring(0, [Math]::Min(50, $Task.Length)))"

        if (-not $Quiet) {
            Write-Host " [DELEGATED] $AgentName → $TargetAgent: $($Task.Substring(0, [Math]::Min(60, $Task.Length)))..." -ForegroundColor Yellow
        }
    }

    'status' {
        $data = Get-Agents
        $agents = $data.agents

        $totalMessages = 0
        foreach ($name in $agents.PSObject.Properties.Name) {
            $inbox = Get-AgentInbox $name
            $totalMessages += $inbox.Count
        }

        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " [AC] Protocol Status" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " Agents: $($agents.Count)" -ForegroundColor Gray
            Write-Host " Total messages: $totalMessages" -ForegroundColor Gray
            Write-Host " Protocol dir: $protocolDir" -ForegroundColor Gray
            Write-Host ""
        }

        @{
            agentCount = $agents.Count
            totalMessages = $totalMessages
            agents = $data.agents
        }
    }
}
