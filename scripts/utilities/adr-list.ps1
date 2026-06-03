#!/usr/bin/env pwsh
<#
.SYNOPSIS
    ADR List - List and filter Architecture Decision Records.

.DESCRIPTION
    Lists all ADRs with filtering by status, date, author, and search terms.
    Supports JSON output for programmatic consumption.

.PARAMETER Status
    Filter by status: Proposed, Accepted, Deprecated

.PARAMETER Author
    Filter by author name

.PARAMETER Since
    Filter by date (YYYY-MM-DD)

.PARAMETER Format
    Output format: table|json|csv

.PARAMETER SortBy
    Sort field: number|date|status

.EXAMPLE
    adr-list.ps1
    adr-list.ps1 -Status Accepted
    adr-list.ps1 -Author "Security Team" -Format json
    adr-list.ps1 -Since 2026-01-01 -SortBy date
#>
param(
    [ValidateSet('Proposed','Accepted','Deprecated','All')]
    [string]$Status = 'All',
    [string]$Author = '',
    [string]$Since = '',
    [ValidateSet('table','json','csv')]
    [string]$Format = 'table',
    [ValidateSet('number','date','status')]
    [string]$SortBy = 'number'
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptDir
$adrDir = Join-Path $repoRoot 'docs\architecture\decisions'

if (-not (Test-Path $adrDir)) {
    Write-Error "ADR directory not found: $adrDir"
    exit 1
}

$adrs = @()
$files = Get-ChildItem -Path $adrDir -Filter 'ADR-*.md' | Sort-Object Name

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    
    # Parse ADR metadata
    $number = if ($file.BaseName -match 'ADR-(\d+)') { [int]$matches[1] } else { 0 }
    $adrStatus = if ($content -match '\*\*Status\*\*:\s*(\w+)') { $matches[1] } else { 'Unknown' }
    $date = if ($content -match '\*\*Date\*\*:\s*([\w\s]+)') { $matches[1].Trim() } else { '' }
    $adrAuthor = if ($content -match '\*\*Author\*\*:\s*(.+)') { $matches[1].Trim() } else { '' }
    $title = if ($content -match '# ADR-\d+:\s*(.+)') { $matches[1].Trim() } else { $file.BaseName }
    
    $adrs += [PSCustomObject]@{
        Number   = $number
        Filename = $file.Name
        Title    = $title
        Status   = $adrStatus
        Date     = $date
        Author   = $adrAuthor
        Path     = $file.FullName
    }
}

# Apply filters
if ($Status -ne 'All') {
    $adrs = $adrs | Where-Object { $_.Status -eq $Status }
}
if (-not [string]::IsNullOrWhiteSpace($Author)) {
    $adrs = $adrs | Where-Object { $_.Author -like "*$Author*" }
}
if (-not [string]::IsNullOrWhiteSpace($Since)) {
    # Simple date comparison (assumes dates are comparable as strings in yyyy-MM-dd format)
    $adrs = $adrs | Where-Object { 
        $_.Date -and ($_.Date -as [datetime]) -ge ([datetime]$Since) 
    }
}

# Sort
switch ($SortBy) {
    'number' { $adrs = $adrs | Sort-Object Number }
    'date'   { $adrs = $adrs | Sort-Object { [datetime]($_.Date -as [datetime]) } -Descending }
    'status' { $adrs = $adrs | Sort-Object Status, Number }
}

# Output
switch ($Format) {
    'table' {
        Write-Host "`n=== Architecture Decision Records ($($adrs.Count) found) ===" -ForegroundColor Cyan
        if ($adrs.Count -gt 0) {
            $adrs | Select-Object Number, Title, Status, Date, Author | Format-Table -AutoSize
            
            # Summary by status
            Write-Host "`nSummary by Status:" -ForegroundColor Gray
            $adrs | Group-Object Status | ForEach-Object {
                $color = switch ($_.Name) {
                    'Accepted'    { 'Green' }
                    'Proposed'    { 'Yellow' }
                    'Deprecated'  { 'Red' }
                    default       { 'Gray' }
                }
                Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $color
            }
        } else {
            Write-Host "No ADRs match the criteria" -ForegroundColor Yellow
        }
    }
    'json' {
        $adrs | Select-Object Number, Title, Status, Date, Author, Filename | ConvertTo-Json -Depth 5
    }
    'csv' {
        $adrs | Select-Object Number, Title, Status, Date, Author, Filename | ConvertTo-Csv -NoTypeInformation
    }
}

exit 0
