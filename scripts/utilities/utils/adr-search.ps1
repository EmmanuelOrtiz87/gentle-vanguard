#!/usr/bin/env pwsh
<#
.SYNOPSIS
    ADR Search - Search within Architecture Decision Records.

.DESCRIPTION
    Full-text search across ADR content with support for multiple search modes.
    Can search in titles, content, decisions, consequences, or all sections.

.PARAMETER Query
    Search query string

.PARAMETER Mode
    Search mode: title|content|decision|consequences|all

.PARAMETER Status
    Limit search to ADRs with specific status

.PARAMETER CaseSensitive
    Enable case-sensitive search

.PARAMETER Format
    Output format: summary|full|json

.EXAMPLE
    adr-search.ps1 -Query "security"
    adr-search.ps1 -Query "API" -Mode title
    adr-search.ps1 -Query "database" -Mode decision -Status Accepted
    adr-search.ps1 -Query "rollback" -Mode consequences -Format full
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    [ValidateSet('title','content','decision','consequences','all')]
    [string]$Mode = 'all',
    [ValidateSet('Proposed','Accepted','Deprecated','All')]
    [string]$Status = 'All',
    [switch]$CaseSensitive,
    [ValidateSet('summary','full','json')]
    [string]$Format = 'summary'
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptDir
$adrDir = Join-Path $repoRoot 'docs\architecture\decisions'

if (-not (Test-Path $adrDir)) {
    Write-Error "ADR directory not found: $adrDir"
    exit 1
}

$regexOptions = if ($CaseSensitive) { 'None' } else { 'IgnoreCase' }
$searchRegex = [regex]::Escape($Query)

$results = @()
$files = Get-ChildItem -Path $adrDir -Filter 'ADR-*.md'

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    
    # Parse basic metadata
    $number = if ($file.BaseName -match 'ADR-(\d+)') { [int]$matches[1] } else { 0 }
    $adrStatus = if ($content -match '\*\*Status\*\*:\s*(\w+)') { $matches[1] } else { 'Unknown' }
    $title = if ($content -match '# ADR-\d+:\s*(.+)') { $matches[1].Trim() } else { $file.BaseName }
    
    # Status filter
    if ($Status -ne 'All' -and $adrStatus -ne $Status) { continue }
    
    $matchFound = $false
    $matchContext = @()
    $section = ''
    
    switch ($Mode) {
        'title' {
            $matchFound = [regex]::IsMatch($title, $searchRegex, $regexOptions)
            if ($matchFound) { $section = 'title' }
        }
        'content' {
            $matchFound = [regex]::IsMatch($content, $searchRegex, $regexOptions)
            if ($matchFound) { $section = 'content' }
        }
        'decision' {
            if ($content -match '(?s)## Decision(.+?)(?=##|$)') {
                $decisionSection = $matches[1]
                $matchFound = [regex]::IsMatch($decisionSection, $searchRegex, $regexOptions)
                if ($matchFound) { $section = 'decision' }
            }
        }
        'consequences' {
            if ($content -match '(?s)## Consequences(.+?)(?=##|$)') {
                $consequencesSection = $matches[1]
                $matchFound = [regex]::IsMatch($consequencesSection, $searchRegex, $regexOptions)
                if ($matchFound) { $section = 'consequences' }
            }
        }
        'all' {
            $matchFound = [regex]::IsMatch($content, $searchRegex, $regexOptions)
            if ($matchFound) { $section = 'all' }
        }
    }
    
    if ($matchFound) {
        # Extract context (lines around match)
        $lines = $content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ([regex]::IsMatch($lines[$i], $searchRegex, $regexOptions)) {
                $start = [Math]::Max(0, $i - 2)
                $end = [Math]::Min($lines.Count - 1, $i + 2)
                $contextLines = $lines[$start..$end] -join "`n"
                $matchContext += $contextLines
            }
        }
        
        $results += [PSCustomObject]@{
            Number      = $number
            Title       = $title
            Status      = $adrStatus
            Filename    = $file.Name
            Section     = $section
            Context     = $matchContext -join "`n---`n"
            MatchCount  = ($matchContext | Measure-Object).Count
        }
    }
}

# Output results
switch ($Format) {
    'summary' {
        Write-Host "`n=== ADR Search Results ===" -ForegroundColor Cyan
        Write-Host "Query: '$Query' (mode: $Mode)" -ForegroundColor Gray
        Write-Host "Found: $($results.Count) matches" -ForegroundColor $(if($results.Count -gt 0){'Green'}else{'Yellow'})
        
        if ($results.Count -gt 0) {
            Write-Host ""
            $results | ForEach-Object {
                $statusColor = switch ($_.Status) {
                    'Accepted'    { 'Green' }
                    'Proposed'    { 'Yellow' }
                    'Deprecated'  { 'Red' }
                    default       { 'Gray' }
                }
                Write-Host "ADR-$($_.Number.ToString('D3')): $($_.Title)" -ForegroundColor White -NoNewline
                Write-Host " [$($_.Status)]" -ForegroundColor $statusColor
                Write-Host "  Section: $($_.Section) | Matches: $($_.MatchCount)" -ForegroundColor Gray
            }
        }
    }
    'full' {
        Write-Host "`n=== ADR Search Results (Full) ===" -ForegroundColor Cyan
        Write-Host "Query: '$Query' (mode: $Mode)" -ForegroundColor Gray
        Write-Host "Found: $($results.Count) matches" -ForegroundColor $(if($results.Count -gt 0){'Green'}else{'Yellow'})
        
        foreach ($r in $results) {
            Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
            Write-Host "ADR-$($r.Number.ToString('D3')): $($r.Title)" -ForegroundColor Cyan
            Write-Host "Status: $($r.Status) | Section: $($r.Section)" -ForegroundColor Gray
            Write-Host "File: $($r.Filename)" -ForegroundColor Gray
            Write-Host "`nContext:" -ForegroundColor Yellow
            Write-Host $r.Context -ForegroundColor White
        }
    }
    'json' {
        $results | Select-Object Number, Title, Status, Filename, Section, MatchCount | ConvertTo-Json -Depth 5
    }
}

exit 0
