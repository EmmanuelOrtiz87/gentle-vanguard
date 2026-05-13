<#
.SYNOPSIS
    Real-time webhook alerting for benchmark failures and traffic light status changes.

.DESCRIPTION
    Sends notifications to Slack, Microsoft Teams, Discord, or generic HTTP webhooks
    when:
    - Benchmark fails (RED traffic light)
    - Regression detected (YELLOW warning)
    - Status changes (PASS → FAIL, etc.)

.PARAMETER WebhookUrl
    Target webhook URL (Slack, Teams, Discord, or custom HTTP endpoint)

.PARAMETER Status
    Current status: RED, YELLOW, GREEN

.PARAMETER AlertType
    Type of alert: benchmark-fail, regression-warn, status-change, escalation

.PARAMETER Details
    Dictionary with alert details (incident, latency, agents, etc.)

.PARAMETER Provider
    Webhook provider: slack, teams, discord, generic

.EXAMPLE
    .\\webhook-alerting.ps1 -WebhookUrl "https://hooks.slack.com/services/..." `
        -Status RED -AlertType benchmark-fail -Provider slack `
        -Details @{incident="baseline regression"; latency_delta="35%"}
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WebhookUrl,

    [Parameter(Mandatory=$true)]
    [ValidateSet('RED', 'YELLOW', 'GREEN')]
    [string]$Status,

    [Parameter(Mandatory=$true)]
    [ValidateSet('benchmark-fail', 'regression-warn', 'status-change', 'escalation', 'sla-violation')]
    [string]$AlertType,

    [hashtable]$Details = @{},

    [ValidateSet('slack', 'teams', 'discord', 'generic')]
    [string]$Provider = 'slack',

    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

function Format-SlackMessage {
    param([string]$Status, [string]$AlertType, [hashtable]$Details)
    
    $color = @{
        'RED'    = '#FF0000'
        'YELLOW' = '#FFB900'
        'GREEN'  = '#00B050'
    }[$Status]
    
    $emoji = @{
        'RED'    = ':red_circle:'
        'YELLOW' = ':warning:'
        'GREEN'  = ':white_check_mark:'
    }[$Status]
    
    $title = switch($AlertType) {
        'benchmark-fail'   { "$emoji Benchmark Failed — Stack RED" }
        'regression-warn'  { "$emoji Regression Detected — Stack YELLOW" }
        'status-change'    { "$emoji Status Changed" }
        'escalation'       { "$emoji Auto-Escalation Triggered" }
        'sla-violation'    { "$emoji SLA Violation — $(($Details.sla_metric) ?? 'Uptime')" }
    }

    $fieldsJson = @()
    foreach ($key in $Details.Keys) {
        $fieldsJson += @{
            title = $key -replace '\_', ' ' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }
            value = [string]$Details[$key]
            short = $true
        }
    }

    $payload = @{
        attachments = @(
            @{
                color      = $color
                title      = $title
                title_link = $Details.dashboard_url ?? "http://localhost/dashboard"
                fields     = $fieldsJson
                ts         = [int](Get-Date -UFormat '%s')
            }
        )
    }

    return $payload
}

function Format-TeamsMessage {
    param([string]$Status, [string]$AlertType, [hashtable]$Details)
    
    $themeColor = @{
        'RED'    = 'FF0000'
        'YELLOW' = 'FFB900'
        'GREEN'  = '00B050'
    }[$Status]

    $title = switch($AlertType) {
        'benchmark-fail'   { "Benchmark Failed — Stack RED" }
        'regression-warn'  { "Regression Detected — Stack YELLOW" }
        'status-change'    { "Status Changed" }
        'escalation'       { "Auto-Escalation Triggered" }
        'sla-violation'    { "SLA Violation — $(($Details.sla_metric) ?? 'Uptime')" }
    }

    $facts = @()
    foreach ($key in $Details.Keys) {
        $facts += @{
            name  = $key -replace '\_', ' ' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }
            value = [string]$Details[$key]
        }
    }

    $payload = @{
        "@type"      = "MessageCard"
        "@context"   = "https://schema.org/extensions"
        summary      = $title
        themeColor   = $themeColor
        sections     = @(
            @{
                activityTitle = $title
                facts         = $facts
                markdown      = $true
            }
        )
        potentialAction = @(
            @{
                "@type" = "OpenUri"
                name    = "View Dashboard"
                targets = @(
                    @{ os = "default"; uri = $Details.dashboard_url ?? "http://localhost/dashboard" }
                )
            }
        )
    }

    return $payload
}

function Format-DiscordMessage {
    param([string]$Status, [string]$AlertType, [hashtable]$Details)
    
    $color = @{
        'RED'    = 16711680  # Red
        'YELLOW' = 16776960  # Yellow
        'GREEN'  = 65280     # Green
    }[$Status]

    $emoji = @{
        'RED'    = '🔴'
        'YELLOW' = '⚠️'
        'GREEN'  = '✅'
    }[$Status]

    $title = switch($AlertType) {
        'benchmark-fail'   { "$emoji Benchmark Failed — Stack RED" }
        'regression-warn'  { "$emoji Regression Detected — Stack YELLOW" }
        'status-change'    { "$emoji Status Changed" }
        'escalation'       { "$emoji Auto-Escalation Triggered" }
        'sla-violation'    { "$emoji SLA Violation — $(($Details.sla_metric) ?? 'Uptime')" }
    }

    $fieldsJson = @()
    foreach ($key in $Details.Keys) {
        $fieldsJson += @{
            name   = $key -replace '\_', ' ' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }
            value  = [string]$Details[$key]
            inline = $true
        }
    }

    $payload = @{
        embeds = @(
            @{
                title       = $title
                color       = $color
                fields      = $fieldsJson
                url         = $Details.dashboard_url ?? "http://localhost/dashboard"
                timestamp   = (Get-Date -Format 'o')
            }
        )
    }

    return $payload
}

# Build payload based on provider
$payload = switch($Provider) {
    'slack'  { Format-SlackMessage -Status $Status -AlertType $AlertType -Details $Details }
    'teams'  { Format-TeamsMessage -Status $Status -AlertType $AlertType -Details $Details }
    'discord' { Format-DiscordMessage -Status $Status -AlertType $AlertType -Details $Details }
    'generic' { $Details }
}

$jsonPayload = $payload | ConvertTo-Json -Depth 10

if ($DryRun) {
    Write-Host "=== DRY RUN: Webhook Alert ===" -ForegroundColor Cyan
    Write-Host "URL:      $WebhookUrl" -ForegroundColor Gray
    Write-Host "Provider: $Provider" -ForegroundColor Gray
    Write-Host "Status:   $Status" -ForegroundColor Gray
    Write-Host "Type:     $AlertType" -ForegroundColor Gray
    Write-Host "Payload:" -ForegroundColor Gray
    Write-Host $jsonPayload -ForegroundColor Gray
    exit 0
}

try {
    $response = Invoke-WebRequest -Uri $WebhookUrl `
        -Method POST `
        -ContentType 'application/json' `
        -Body $jsonPayload `
        -TimeoutSec 10 `
        -ErrorAction Stop

    if ($response.StatusCode -in @(200, 201, 202, 204)) {
        Write-Host "[OK] Webhook sent: $Provider - $AlertType ($Status)" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[WARN] Webhook response: $($response.StatusCode)" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "[ERROR] Webhook failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}
