# manage-backlog.ps1
# Manages the structured backlog (items.json)
# Usage: .\manage-backlog.ps1 -Action <add|triage|list|migrate> ...

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('add', 'triage', 'list', 'migrate', 'status')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Title,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('feature', 'tech-debt', 'optimization', 'docs')]
    [string]$Type = 'feature',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('high', 'medium', 'low')]
    [string]$Priority = 'medium',
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string]$Owner = 'unassigned'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$backlogDir = Join-Path $repoRoot 'docs\backlog'
$itemsFile = Join-Path $backlogDir 'items.json'
$legacyFile = Join-Path $repoRoot 'docs\reference\FUTURE-FEATURES-BACKLOG.md'

function Ensure-BacklogDir {
    if (-not (Test-Path $backlogDir)) {
        New-Item -ItemType Directory -Path $backlogDir -Force | Out-Null
    }
}

function Get-NextId {
    if (-not (Test-Path $itemsFile)) { return 1 }
    $items = Get-Content $itemsFile | ConvertFrom-Json
    if ($items.Count -eq 0) { return 1 }
    $maxId = ($items | ForEach-Object { [int]($_.id -replace 'BL-', '') } | Measure-Object -Maximum).Maximum
    return $maxId + 1
}

function Add-BacklogItem {
    param($Title, $Type, $Priority, $Description, $Owner)
    
    Ensure-BacklogDir
    $id = "BL-$(Get-NextId)"
    $date = Get-Date -Format 'yyyy-MM-dd'
    
    $item = @{
        id = $id
        title = $Title
        type = $Type
        priority = $Priority
        status = 'pending'
        created_at = $date
        owner = $Owner
        description = $Description
        value_prop = ''
        defer_reason = 'Deferred by user'
        trigger = 'Manual review'
        linked_sessions = @()
        linked_prs = @()
    }
    
    $items = @()
    if (Test-Path $itemsFile) {
        $items = Get-Content $itemsFile | ConvertFrom-Json
    }
    $items += $item
    
    $items | ConvertTo-Json -Depth 10 | Set-Content $itemsFile -Encoding UTF8
    Write-Host "[OK] Added $id: $Title" -ForegroundColor Green
}

function Migrate-LegacyBacklog {
    if (-not (Test-Path $legacyFile)) {
        Write-Host "[WARN] Legacy backlog file not found at $legacyFile" -ForegroundColor Yellow
        return
    }
    
    Write-Host "[INFO] Migrating legacy backlog from $legacyFile..." -ForegroundColor Cyan
    
    $content = Get-Content $legacyFile -Raw
    $lines = $content -split "`n"
    $inTable = $false
    $items = @()
    
    foreach ($line in $lines) {
        if ($line -match '^\| ID \| Date \|') { $inTable = $true; continue }
        if ($inTable -and $line -match '^\|---') { continue }
        if ($inTable -and $line -match '^\|') {
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            if ($cols.Count -ge 9) {
                $id = $cols[1]
                $date = $cols[2]
                $theme = $cols[3]
                $desc = $cols[4]
                $prio = $cols[5]
                $status = $cols[6]
                $owner = $cols[7]
                $trigger = $cols[8]
                
                # Map legacy status
                $newStatus = 'pending'
                if ($status -eq 'done') { $newStatus = 'done' }
                
                $items += @{
                    id = $id
                    title = $theme
                    type = 'feature'
                    priority = $prio
                    status = $newStatus
                    created_at = $date
                    owner = $owner
                    description = $desc
                    value_prop = ''
                    defer_reason = 'Legacy item'
                    trigger = $trigger
                    linked_sessions = @()
                    linked_prs = @()
                }
            }
        }
        if ($inTable -and $line -notmatch '^\|') { break }
    }
    
    if ($items.Count -gt 0) {
        Ensure-BacklogDir
        $items | ConvertTo-Json -Depth 10 | Set-Content $itemsFile -Encoding UTF8
        Write-Host "[OK] Migrated $($items.Count) items to $itemsFile" -ForegroundColor Green
        
        # Archive legacy
        $archiveDir = Join-Path $repoRoot 'docs\reference\archive'
        if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null }
        $archiveFile = Join-Path $archiveDir "FUTURE-FEATURES-BACKLOG-$(Get-Date -Format 'yyyyMMdd').md"
        Move-Item $legacyFile $archiveFile -Force
        Write-Host "[OK] Archived legacy file to $archiveFile" -ForegroundColor Gray
    } else {
        Write-Host "[WARN] No items found to migrate." -ForegroundColor Yellow
    }
}

function List-BacklogItems {
    if (-not (Test-Path $itemsFile)) {
        Write-Host "[INFO] Backlog is empty." -ForegroundColor Cyan
        return
    }
    
    $items = Get-Content $itemsFile | ConvertFrom-Json
    Write-Host "`n=== BACKLOG ITEMS ===" -ForegroundColor Cyan
    foreach ($item in $items) {
        $color = switch ($item.priority) {
            'high' { 'Red' }
            'medium' { 'Yellow' }
            'low' { 'Gray' }
        }
        Write-Host "[$($item.id)] $($item.title) (Priority: $($item.priority), Status: $($item.status))" -ForegroundColor $color
    }
}

switch ($Action) {
    'add' {
        if ([string]::IsNullOrWhiteSpace($Title)) {
            Write-Host "[ERROR] Title is required for 'add' action." -ForegroundColor Red
            exit 1
        }
        Add-BacklogItem -Title $Title -Type $Type -Priority $Priority -Description $Description -Owner $Owner
    }
    'migrate' {
        Migrate-LegacyBacklog
    }
    'list' {
        List-BacklogItems
    }
    'triage' {
        Write-Host "[INFO] Triage logic coming soon..." -ForegroundColor Cyan
    }
    'status' {
        if (Test-Path $itemsFile) {
            $items = Get-Content $itemsFile | ConvertFrom-Json
            Write-Host "[INFO] Total items: $($items.Count)" -ForegroundColor Cyan
        } else {
            Write-Host "[INFO] No backlog items found." -ForegroundColor Cyan
        }
    }
}
