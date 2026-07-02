#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Jira REST API connector for Gentle-Vanguard Document Analysis.
.DESCRIPTION
    Connects to Jira API v3 to search projects and tickets relevant to requirements analysis.
    Supports basic auth (email + API token) for Atlassian Cloud.
.PARAMETER Action
    search | getProject | getTicket | listProjects. Default: search.
.PARAMETER Project
    Project key (e.g. "PROJ"). Required for search and ticket actions.
.PARAMETER Query
    JQL query string. Default: "project = {Project} ORDER BY created DESC".
.PARAMETER MaxResults
    Max results to return. Default: 20.
.PARAMETER Quiet
    Suppress verbose output.
.PARAMETER ConfigPath
    Path to Jira config JSON. Default: config/connectors/jira-config.json
#>

param(
    [ValidateSet('search', 'getProject', 'getTicket', 'listProjects')]
    [string]$Action = 'search',
    [string]$Project = '',
    [string]$Query = '',
    [int]$MaxResults = 20,
    [switch]$Quiet,
    [string]$ConfigPath = ''
)

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ScriptDir -Parent

if (-not $ConfigPath) {
    $configCandidates = @(
        Join-Path $ProjectRoot 'config' 'connectors' 'jira-config.json'
        Join-Path $ProjectRoot 'config' 'jira-config.json'
        Join-Path $env:USERPROFILE '.gentle-vanguard' 'jira-config.json'
    )
    foreach ($c in $configCandidates) { if (Test-Path $c) { $ConfigPath = $c; break } }
}

$config = @{}
if ($ConfigPath -and (Test-Path $ConfigPath)) {
    try { $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json } catch {}
}

$baseUrl = $config.baseUrl -or $env:JIRA_BASE_URL
$email = $config.email -or $env:JIRA_EMAIL
$apiToken = $config.apiToken -or $env:JIRA_API_TOKEN

if (-not $baseUrl) { $baseUrl = 'https://your-domain.atlassian.net' }
$baseUrl = $baseUrl.TrimEnd('/')

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    if (-not $Quiet) { Write-Host "[Jira] [$Level] $Message" -ForegroundColor $(if ($Level -eq 'ERROR') {'Red'} elseif ($Level -eq 'WARN') {'Yellow'} else {'Gray'}) }
}

function Invoke-JiraApi {
    param([string]$Endpoint, [string]$Method = 'GET', $Body = $null)
    $uri = "$baseUrl/rest/api/3/$Endpoint"
    $params = @{Uri = $uri; Method = $Method; ContentType = 'application/json'; UseBasicParsing = $true}
    if ($email -and $apiToken) {
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${email}:${apiToken}"))
        $params.Headers = @{Authorization = "Basic $auth"}
    }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Compress) }
    try {
        $response = Invoke-RestMethod @params -ErrorAction Stop
        return $response
    } catch {
        Write-Log "Jira API error: $($_.Exception.Message)" 'ERROR'
        return $null
    }
}

switch ($Action) {
    'search' {
        if (-not $Query) {
            if ($Project) { $Query = "project = '$Project' ORDER BY created DESC" }
            else { $Query = 'ORDER BY created DESC' }
        }
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($Query)
        $result = Invoke-JiraApi -Endpoint "search?jql=$encodedQuery&maxResults=$MaxResults"
        if ($result -and $result.issues) {
            $tickets = $result.issues | ForEach-Object {
                [PSCustomObject]@{
                    id = $_.id; key = $_.key; summary = $_.fields.summary
                    status = $_.fields.status.name; priority = $_.fields.priority.name
                    assignee = if ($_.fields.assignee) { $_.fields.assignee.displayName } else { 'Unassigned' }
                    created = $_.fields.created; updated = $_.fields.updated
                }
            }
            Write-Log "Encontrados $($tickets.Count) tickets"
            return $tickets | ConvertTo-Json -Depth 3
        }
        Write-Log "No se encontraron tickets" 'WARN'
        return '[]'
    }
    'getProject' {
        if (-not $Project) { Write-Log "Project parameter required" 'ERROR'; return $null }
        $result = Invoke-JiraApi -Endpoint "project/$Project"
        if ($result) {
            return [PSCustomObject]@{
                key = $result.key; name = $result.name; lead = $result.lead.displayName
                description = $result.description; projectTypeKey = $result.projectTypeKey
            } | ConvertTo-Json
        }
        return $null
    }
    'getTicket' {
        if (-not $Project) { Write-Log "Project parameter required" 'ERROR'; return $null }
        $result = Invoke-JiraApi -Endpoint "issue/$Project"
        if ($result) {
            return [PSCustomObject]@{
                id = $result.id; key = $result.key; summary = $result.fields.summary
                description = $result.fields.description; status = $result.fields.status.name
                priority = $result.fields.priority.name; assignee = if ($result.fields.assignee) { $result.fields.assignee.displayName } else { 'Unassigned' }
                created = $result.fields.created; updated = $result.fields.updated
                labels = $result.fields.labels; components = $result.fields.components.name
            } | ConvertTo-Json -Depth 3
        }
        return $null
    }
    'listProjects' {
        $result = Invoke-JiraApi -Endpoint 'project'
        if ($result) {
            return ($result | ForEach-Object {
                [PSCustomObject]@{key = $_.key; name = $_.name; lead = if ($_.lead) { $_.lead.displayName } else { '' }; projectTypeKey = $_.projectTypeKey}
            }) | ConvertTo-Json -Depth 2
        }
        return '[]'
    }
}
