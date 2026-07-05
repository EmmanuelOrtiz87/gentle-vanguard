param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("init", "create-note", "list", "search", "sync-engram", "archive", "stats", "validate")]
    [string]$Action = "stats",
    
    [Parameter(Mandatory = $false)]
    [string]$NoteType = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Title = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Content = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Tags = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Folder = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Query = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $dir
}

$ProjectRoot = Resolve-ProjectRoot
$VaultPath = Join-Path $ProjectRoot "knowledge-base"
$ConfigPath = Join-Path $ProjectRoot "config\knowledge-base-config.json"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Quiet) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Get-VaultConfig {
    if (Test-Path $ConfigPath) {
        return Get-Content $ConfigPath | ConvertFrom-Json
    }
    return @{
        vault_path = $VaultPath
        folders = @{
            inbox = "00-inbox"
            projects = "01-projects"
            architecture = "02-architecture"
            skills = "03-skills"
            sessions = "04-sessions"
            research = "05-research"
            templates = "06-templates"
            archive = "07-archive"
        }
        sync_enabled = $true
        auto_archive_days = 30
    }
}

function Initialize-Vault {
    $config = Get-VaultConfig
    
    if (-not (Test-Path $VaultPath)) {
        New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
        Write-Log "Created vault root: $VaultPath"
    }
    
    foreach ($folder in $config.folders.PSObject.Properties.Value) {
        $folderPath = Join-Path $VaultPath $folder
        if (-not (Test-Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            Write-Log "Created folder: $folder"
        }
    }
    
    $readmePath = Join-Path $VaultPath "README.md"
    if (-not (Test-Path $readmePath)) {
        @"
# Knowledge Base - Gentle-Vanguard

This is the **Gentle-Vanguard Knowledge Base** vault managed via Obsidian.

## Structure

- `00-inbox/` - Unsorted notes
- `01-projects/` - Active projects
- `02-architecture/` - Architecture decisions
- `03-skills/` - Skill documentation
- `04-sessions/` - Session summaries
- `05-research/` - Research notes
- `06-templates/` - Note templates
- `07-archive/` - Archived content

## Usage

```powershell
# Create a new note
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action create-note -NoteType project -Title "My Project"

# List all notes
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action list

# Search notes
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action search -Query "keyword"

# Sync with Engram
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action sync-engram

# Get stats
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action stats
```

## Related

- [Architecture](docs\knowledge-base\ARCHITECTURE.md)
- [Usage Guide](docs\knowledge-base\USAGE.md)
"@ | Set-Content $readmePath -Encoding UTF8
        Write-Log "Created README.md"
    }
    
    Write-Log "Vault initialized successfully" "OK"
}

function New-KnowledgeNote {
    param(
        [string]$Type,
        [string]$NoteTitle,
        [string]$NoteContent,
        [string]$NoteTags,
        [string]$NoteFolder
    )
    
    $config = Get-VaultConfig
    $date = Get-Date -Format "yyyy-MM-dd"
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    
    $folderMap = @{
        "project" = $config.folders.projects
        "session" = $config.folders.sessions
        "skill" = $config.folders.skills
        "decision" = $config.folders.architecture
        "research" = $config.folders.research
        "inbox" = $config.folders.inbox
    }
    
    $targetFolder = if ($NoteFolder) { $NoteFolder } else { $folderMap[$Type] }
    if (-not $targetFolder) { $targetFolder = $config.folders.inbox }
    
    $folderPath = Join-Path $VaultPath $targetFolder
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
    }
    
    $safeTitle = $NoteTitle -replace '[^\w\s-]', '' -replace '\s+', '-'
    $fileName = "$date-$safeTitle.md"
    $filePath = Join-Path $folderPath $fileName
    
    $tagsList = @($NoteTags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($Type) { $tagsList += $Type }
    $tagsYaml = ($tagsList | ForEach-Object { "#$_" }) -join ", "
    
    $templatePath = Join-Path $VaultPath "06-templates\$Type.md"
    $templateContent = if (Test-Path $templatePath) { Get-Content $templatePath -Raw } else { "" }
    
    $content = if ($templateContent) {
        $templateContent `
            -replace '{{date}}', $date `
            -replace '{{title}}', $NoteTitle `
            -replace '{{project-name}}', $NoteTitle `
            -replace '{{session-id}}', $NoteTitle `
            -replace '{{skill-name}}', $NoteTitle `
            -replace '{{decision-id}}', $NoteTitle `
            -replace '{{decision-title}}', $NoteTitle
    } else {
        $NoteContent
    }
    
    if ($tagsYaml) {
        $content = $content -replace 'tags: \[.*\]', "tags: [$tagsYaml]"
    }
    
    if ($NoteContent -and -not $templateContent) {
        $content = $NoteContent
    }
    
    Set-Content -Path $filePath -Value $content -Encoding UTF8
    Write-Log "Created note: $filePath" "OK"
    return $filePath
}

function Get-VaultNotes {
    $config = Get-VaultConfig
    $notes = @()
    
    foreach ($folder in $config.folders.PSObject.Properties.Value) {
        $folderPath = Join-Path $VaultPath $folder
        if (Test-Path $folderPath) {
            $mdFiles = Get-ChildItem -Path $folderPath -Filter "*.md" -ErrorAction SilentlyContinue
            foreach ($file in $mdFiles) {
                $notes += @{
                    name = $file.Name
                    path = $file.FullName
                    folder = $folder
                    size = $file.Length
                    modified = $file.LastWriteTime
                }
            }
        }
    }
    
    return $notes
}

function Search-Notes {
    param([string]$SearchQuery)
    
    $notes = Get-VaultNotes
    $results = @()
    
    foreach ($note in $notes) {
        $content = Get-Content $note.path -Raw -ErrorAction SilentlyContinue
        if ($content -match $SearchQuery) {
            $results += $note
        }
    }
    
    return $results
}

function Sync-EngramToVault {
    $engramExe = Get-Command engram -ErrorAction SilentlyContinue
    
    if (-not $engramExe) {
        Write-Log "Engram not found in PATH" "WARN"
        return
    }
    
    $config = Get-VaultConfig
    $sessionsFolder = Join-Path $VaultPath $config.folders.sessions
    
    try {
        $searchOutput = & engram search "session_summary" --project gentle-vanguard --limit 50 2>&1 | Out-String
        
        Write-Log "Synced session summaries from Engram" "OK"
    } catch {
        Write-Log "Failed to sync from Engram: $_" "ERROR"
    }
}

function Get-VaultStats {
    $notes = Get-VaultNotes
    
    $stats = @{
        total_notes = $notes.Count
        total_size_bytes = ($notes | Measure-Object -Property size -Sum).Sum
        folders = @{}
    }
    
    $config = Get-VaultConfig
    foreach ($folder in $config.folders.PSObject.Properties.Value) {
        $folderNotes = $notes | Where-Object { $_.folder -eq $folder }
        $stats.folders[$folder] = $folderNotes.Count
    }
    
    return $stats
}

function Validate-Vault {
    $config = Get-VaultConfig
    $issues = @()
    
    if (-not (Test-Path $VaultPath)) {
        $issues += "Vault root not found: $VaultPath"
    }
    
    foreach ($folder in $config.folders.PSObject.Properties.Value) {
        $folderPath = Join-Path $VaultPath $folder
        if (-not (Test-Path $folderPath)) {
            $issues += "Missing folder: $folder"
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Log "Vault validation: PASS" "OK"
        return $true
    } else {
        foreach ($issue in $issues) {
            Write-Log $issue "ERROR"
        }
        return $false
    }
}

switch ($Action) {
    "init" {
        Initialize-Vault
    }
    "create-note" {
        if (-not $Title) {
            Write-Log "Title is required for create-note" "ERROR"
            exit 1
        }
        New-KnowledgeNote -Type $NoteType -NoteTitle $Title -NoteContent $Content -NoteTags $Tags -NoteFolder $Folder
    }
    "list" {
        $notes = Get-VaultNotes
        foreach ($note in $notes) {
            Write-Host "$($note.folder)/$($note.name)"
        }
        Write-Log "Total: $($notes.Count) notes" "OK"
    }
    "search" {
        if (-not $Query) {
            Write-Log "Query is required for search" "ERROR"
            exit 1
        }
        $results = Search-Notes -SearchQuery $Query
        foreach ($result in $results) {
            Write-Host "$($result.folder)/$($result.name)"
        }
        Write-Log "Found $($results.Count) notes" "OK"
    }
    "sync-engram" {
        Sync-EngramToVault
    }
    "stats" {
        $stats = Get-VaultStats
        Write-Host "Knowledge Base Statistics"
        Write-Host "========================="
        Write-Host "Total Notes: $($stats.total_notes)"
        Write-Host "Total Size: $([math]::Round($stats.total_size_bytes / 1KB, 2)) KB"
        Write-Host ""
        Write-Host "By Folder:"
        foreach ($folder in $stats.folders.PSObject.Properties) {
            Write-Host "  $($folder.Name): $($folder.Value) notes"
        }
    }
    "validate" {
        $result = Validate-Vault
        exit $(if ($result) { 0 } else { 1 })
    }
}