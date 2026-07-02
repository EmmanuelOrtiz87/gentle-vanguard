#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Confluence REST API connector for Gentle-Vanguard Document Analysis.
.DESCRIPTION
    Connects to Confluence REST API to retrieve team info, specialist data, and project documentation
    that complements requirements analysis. Supports Confluence Cloud (basic auth) and Confluence Server.
.PARAMETER Action
    getSpace | getPage | search | getTeamInfo. Default: search.
.PARAMETER SpaceKey
    Space key to query (e.g. "TEAM").
.PARAMETER Query
    CQL search query.
.PARAMETER MaxResults
    Max results. Default: 20.
.PARAMETER Quiet
    Suppress verbose output.
.PARAMETER ConfigPath
    Path to Confluence config JSON.
#>

param(
    [ValidateSet('getSpace', 'getPage', 'search', 'getTeamInfo')]
    [string]$Action = 'search',
    [string]$SpaceKey = '',
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
        Join-Path $ProjectRoot 'config' 'connectors' 'confluence-config.json'
        Join-Path $ProjectRoot 'config' 'confluence-config.json'
        Join-Path $env:USERPROFILE '.gentle-vanguard' 'confluence-config.json'
    )
    foreach ($c in $configCandidates) { if (Test-Path $c) { $ConfigPath = $c; break } }
}

$config = @{}
if ($ConfigPath -and (Test-Path $ConfigPath)) {
    try { $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json } catch {}
}

$baseUrl = $config.baseUrl -or $env:CONFLUENCE_BASE_URL
$email = $config.email -or $env:CONFLUENCE_EMAIL -or $env:JIRA_EMAIL
$apiToken = $config.apiToken -or $env:CONFLUENCE_API_TOKEN -or $env:JIRA_API_TOKEN

if (-not $baseUrl) { $baseUrl = 'https://your-domain.atlassian.net/wiki' }
$baseUrl = $baseUrl.TrimEnd('/')

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    if (-not $Quiet) { Write-Host "[Confluence] [$Level] $Message" -ForegroundColor $(if ($Level -eq 'ERROR') {'Red'} elseif ($Level -eq 'WARN') {'Yellow'} else {'DarkCyan'}) }
}

function Invoke-ConfluenceApi {
    param([string]$Endpoint, [string]$Method = 'GET', $Body = $null)
    $apiVersion = if ($baseUrl -match 'atlassian\.net') { '/wiki/rest/api' } else { '/rest/api' }
    $uri = "$baseUrl$apiVersion/$Endpoint"
    $params = @{Uri = $uri; Method = $Method; ContentType = 'application/json'; UseBasicParsing = $true}
    if ($email -and $apiToken) {
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${email}:${apiToken}"))
        $params.Headers = @{Authorization = "Basic $auth"}
    }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Compress) }
    try {
        return Invoke-RestMethod @params -ErrorAction Stop
    } catch {
        Write-Log "Confluence API error: $($_.Exception.Message)" 'ERROR'
        return $null
    }
}

switch ($Action) {
    'search' {
        if (-not $Query -and $SpaceKey) { $Query = "space = $SpaceKey" }
        if (-not $Query) { $Query = 'type = page' }
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($Query)
        $result = Invoke-ConfluenceApi -Endpoint "content/search?cql=$encodedQuery&limit=$MaxResults"
        if ($result -and $result.results) {
            $pages = $result.results | ForEach-Object {
                [PSCustomObject]@{
                    id = $_.id; title = $_.title; space = $_.space.key
                    version = $_.version.number; created = $_.history.createdDate
                    url = "$baseUrl$($_.links.webui)"
                }
            }
            Write-Log "Encontradas $($pages.Count) paginas"
            return $pages | ConvertTo-Json -Depth 2
        }
        Write-Log "No se encontraron resultados" 'WARN'
        return '[]'
    }
    'getSpace' {
        if (-not $SpaceKey) { Write-Log "SpaceKey required" 'ERROR'; return $null }
        $result = Invoke-ConfluenceApi -Endpoint "space/$SpaceKey"
        if ($result) {
            return [PSCustomObject]@{
                key = $result.key; name = $result.name; description = $result.description.plain.value
                homepage = "$baseUrl$($result._links.webui)"
            } | ConvertTo-Json -Depth 2
        }
        return $null
    }
    'getPage' {
        if (-not $SpaceKey) { Write-Log "SpaceKey required (use page ID)" 'ERROR'; return $null }
        $result = Invoke-ConfluenceApi -Endpoint "content/$SpaceKey?expand=body.storage,version"
        if ($result) {
            $htmlContent = $result.body.storage.value
            $plainText = $htmlContent -replace '<[^>]+>', '' -replace '\s+', ' ' -replace '&nbsp;', ' '
            return [PSCustomObject]@{
                id = $result.id; title = $result.title; space = $result.space.key
                version = $result.version.number; content = $plainText.Substring(0, [Math]::Min(5000, $plainText.Length))
                url = "$baseUrl$($result._links.webui)"
            } | ConvertTo-Json -Depth 2
        }
        return $null
    }
    'getTeamInfo' {
        $teamData = @()
        $spaces = Invoke-ConfluenceApi -Endpoint 'space?limit=50'
        if ($spaces -and $spaces.results) {
            foreach ($space in $spaces.results) {
                if ($space.key -match 'TEAM|ENG|DEV|AREA|STUDIO') {
                    $detail = Invoke-ConfluenceApi -Endpoint "space/$($space.key)"
                    if ($detail) {
                        $teamData += [PSCustomObject]@{
                            key = $space.key; name = $space.name
                            description = if ($detail.description -and $detail.description.plain) { $detail.description.plain.value.Substring(0, [Math]::Min(500, [string]($detail.description.plain.value).Length)) } else { '' }
                        }
                    }
                }
            }
        }
        Write-Log "Encontrados $($teamData.Count) equipos"
        return ($teamData | ConvertTo-Json -Depth 2)
    }
}
