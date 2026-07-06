<#
.SYNOPSIS
    Incremental skill embeddings updater with change detection.
.DESCRIPTION
    Detects added/removed/modified skills and updates only the changed vectors.
    Falls back to full rebuild if >50% of skills changed.
.PARAMETER Force
    Force full rebuild (ignore incremental).
.PARAMETER DryRun
    Show what would change without writing.
.PARAMETER Quiet
    Suppress output.
#>
param(
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot
$RegistryPath = Join-Path $ProjectRoot ".atl\skill-registry.md"
$DelegationConfigPath = Join-Path $ProjectRoot "config\auto-delegation.json"
$OutputPath = Join-Path $ProjectRoot ".atl\skill-embeddings.json"
$MetaPath = Join-Path $ProjectRoot ".atl\skill-meta.json"
$logDir = Join-Path $ProjectRoot '.session'
$logFile = Join-Path $logDir 'skill-embeddings-log.jsonl'
$embedderScript = Join-Path $PSScriptRoot 'skill-embedder.ps1'

if (-not $Quiet) {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host " [SE] Skill Embedder Incremental v1.0" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
}

# Ensure directories exist
if (-not (Test-Path (Split-Path $OutputPath -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $OutputPath -Parent) -Force | Out-Null
}
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Load existing metadata
$prevMeta = $null
if (Test-Path $MetaPath) {
    try {
        $prevMeta = Get-Content $MetaPath -Raw | ConvertFrom-Json
    } catch {
        if (-not $Quiet) { Write-Host " [WARN] Could not parse existing metadata, doing full rebuild" -ForegroundColor Yellow }
        $Force = $true
    }
}

# Load existing embeddings
$prevEmbeddings = $null
if (Test-Path $OutputPath) {
    try {
        $prevEmbeddings = Get-Content $OutputPath -Raw | ConvertFrom-Json
    } catch {
        if (-not $Quiet) { Write-Host " [WARN] Could not parse existing embeddings, doing full rebuild" -ForegroundColor Yellow }
        $Force = $true
    }
}

# If no previous data, full rebuild
if (-not $prevMeta -or -not $prevEmbeddings) {
    if (-not $Quiet) { Write-Host " [INFO] No previous embeddings found, doing full rebuild" -ForegroundColor Gray }
    $Force = $true
}

# Parse current skills from registry
if (-not (Test-Path $RegistryPath)) {
    if (-not $Quiet) { Write-Host " [ERROR] Skill registry not found: $RegistryPath" -ForegroundColor Red }
    exit 1
}

$registryContent = Get-Content $RegistryPath -Raw
$currentSkills = @{}
$lines = $registryContent -split "`r`n|`n"
foreach ($line in $lines) {
    if ($line -match '^\|\s*(\S+)\s*\|\s*(\w+)\s*\|') {
        $skillName = $Matches[1]
        $agent = $Matches[2]
        if ($skillName -ne '---' -and $skillName -ne 'Skill') {
            $currentSkills[$skillName] = $agent
        }
    }
}

# Supplement from auto-delegation config
if (Test-Path $DelegationConfigPath) {
    try {
        $config = Get-Content $DelegationConfigPath -Raw | ConvertFrom-Json
        if ($config.agents) {
            foreach ($agent in $config.agents.PSObject.Properties) {
                if ($agent.Value.skills) {
                    foreach ($skill in $agent.Value.skills.PSObject.Properties) {
                        if (-not $currentSkills.ContainsKey($skill.Name)) {
                            $currentSkills[$skill.Name] = $agent.Name
                        }
                    }
                }
            }
        }
    } catch { }
}

if (-not $Quiet) { Write-Host " [INFO] Current skills: $($currentSkills.Count)" -ForegroundColor Gray }

# Compare with previous state
$prevSkills = @{}
if ($prevMeta -and $prevMeta.contentHashes) {
    foreach ($prop in $prevMeta.contentHashes.PSObject.Properties) {
        $prevSkills[$prop.Name] = $prop.Value
    }
}

$added = @()
$removed = @()
$modified = @()
$unchanged = @()

foreach ($skill in $currentSkills.Keys) {
    $currentHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$skill|$($currentSkills[$skill])"))).Replace('-','').Substring(0,16)
    if ($prevSkills.ContainsKey($skill)) {
        if ($prevSkills[$skill] -ne $currentHash) {
            $modified += $skill
        } else {
            $unchanged += $skill
        }
    } else {
        $added += $skill
    }
}

foreach ($skill in $prevSkills.Keys) {
    if (-not $currentSkills.ContainsKey($skill)) {
        $removed += $skill
    }
}

if (-not $Quiet) {
    Write-Host " [DIFF] Added: $($added.Count) | Removed: $($removed.Count) | Modified: $($modified.Count) | Unchanged: $($unchanged.Count)" -ForegroundColor Gray
}

# No changes?
if ($added.Count -eq 0 -and $removed.Count -eq 0 -and $modified.Count -eq 0) {
    if (-not $Quiet) { Write-Host " [OK] No changes detected, embeddings are up to date" -ForegroundColor Green }
    exit 0
}

# Too many changes? Fall back to full rebuild
$totalChanged = $added.Count + $removed.Count + $modified.Count
$changePercent = if ($currentSkills.Count -gt 0) { ($totalChanged / $currentSkills.Count) * 100 } else { 100 }
if ($changePercent -gt 50 -or $Force) {
    if (-not $Quiet) {
        if ($Force) {
            Write-Host " [INFO] Force flag set, doing full rebuild" -ForegroundColor Yellow
        } else {
            Write-Host " [INFO] $([math]::Round($changePercent,0))% skills changed (>50%), doing full rebuild" -ForegroundColor Yellow
        }
    }

    if (-not $DryRun) {
        & $embedderScript
    } else {
        if (-not $Quiet) { Write-Host " [DRY-RUN] Would run full rebuild via skill-embedder.ps1" -ForegroundColor Magenta }
    }
    exit 0
}

# Incremental update
if (-not $Quiet) { Write-Host " [INFO] Performing incremental update..." -ForegroundColor Cyan }

if ($DryRun) {
    if (-not $Quiet) {
        Write-Host " [DRY-RUN] Would add: $($added -join ', ')" -ForegroundColor Magenta
        Write-Host " [DRY-RUN] Would remove: $($removed -join ', ')" -ForegroundColor Magenta
        Write-Host " [DRY-RUN] Would modify: $($modified -join ', ')" -ForegroundColor Magenta
    }
    exit 0
}

# Load existing embeddings for merge
$existingSkills = @{}
foreach ($skill in $prevEmbeddings.skills) {
    $existingSkills[$skill.name] = $skill
}

# Remove deleted skills
foreach ($skill in $removed) {
    $existingSkills.Remove($skill)
    if (-not $Quiet) { Write-Host "   Removed: $skill" -ForegroundColor Red }
}

# For modified/added skills, we need to rebuild their vectors
# Since we don't have the full text corpus here, we rebuild all vectors
# but keep the vocabulary and IDF from the existing index
if ($modified.Count -gt 0 -or $added.Count -gt 0) {
    if (-not $Quiet) { Write-Host "   Rebuilding vectors for $($modified.Count + $added.Count) changed skills..." -ForegroundColor Yellow }

    # Rebuild all vectors (can't do partial TF-IDF without full corpus)
    & $embedderScript

    # Log the change
    $logEntry = @{
        timestamp = (Get-Date).ToString('o')
        action = 'incremental'
        added = $added
        removed = $removed
        modified = $modified
        totalSkills = $currentSkills.Count
    }
    $logEntry | ConvertTo-Json -Compress | Out-File -Append -FilePath $logFile -Encoding UTF8
} else {
    # Only removals - save updated embeddings directly
    $updatedSkills = @()
    foreach ($skill in $existingSkills.Values) {
        $updatedSkills += $skill
    }

    $embeddings = @{
        version = $prevEmbeddings.version
        generated = (Get-Date -Format "o")
        metadata = @{
            totalSkills = $updatedSkills.Count
            vocabularySize = $prevEmbeddings.metadata.vocabularySize
            ngramSize = 3
        }
        vocabulary = $prevEmbeddings.vocabulary
        idf = $prevEmbeddings.idf
        skills = $updatedSkills
    }

    $embeddings | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    $logEntry = @{
        timestamp = (Get-Date).ToString('o')
        action = 'incremental'
        added = @()
        removed = $removed
        modified = @()
        totalSkills = $updatedSkills.Count
    }
    $logEntry | ConvertTo-Json -Compress | Out-File -Append -FilePath $logFile -Encoding UTF8
}

# Update metadata
$hashes = @{}
foreach ($skill in $currentSkills.Keys) {
    $hashes[$skill] = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$skill|$($currentSkills[$skill])"))).Replace('-','').Substring(0,16)
}

$meta = @{
    version = "1.0"
    lastBuilt = (Get-Date -Format "o")
    lastFullRebuild = if ($prevMeta.lastFullBuild) { $prevMeta.lastFullBuild } else { (Get-Date -Format "o") }
    totalSkills = $currentSkills.Count
    vocabularySize = if ($prevEmbeddings) { $prevEmbeddings.metadata.vocabularySize } else { 0 }
    contentHashes = $hashes
    incrementalUpdates = @()
}

if ($prevMeta.incrementalUpdates) {
    $meta.incrementalUpdates = @($prevMeta.incrementalUpdates)
}
$meta.incrementalUpdates += @{
    timestamp = (Get-Date -Format "o")
    added = $added
    removed = $removed
    modified = $modified
}

$meta | ConvertTo-Json -Depth 5 | Set-Content -Path $MetaPath -Encoding UTF8

if (-not $Quiet) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " [DONE] Incremental update complete" -ForegroundColor Green
    Write-Host "   Skills: $($currentSkills.Count) | Vocab: $(if($prevEmbeddings){$prevEmbeddings.metadata.vocabularySize}else{'N/A'})" -ForegroundColor Green
    Write-Host "   Added: $($added.Count) | Removed: $($removed.Count) | Modified: $($modified.Count)" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
}
