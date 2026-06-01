param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills')
$ConfigPath = Resolve-Path (Join-Path $PSScriptRoot '..\..\config\auto-delegation.json')
$IndexPath = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills\SKILL_INDEX.md')

# Map imported skill sources to agent profiles
$sourceToProfile = @{
    'anthropic-skills'           = 'DEV'
    'taste-skill'                = 'DOC'
    'academic-research-skills'   = 'BA'
    'claude-bughunter'           = 'GOV'
    'knowledge-work-plugins'     = @{}  # dept-specific mapping below
}

$deptToProfile = @{
    'bio-research'              = 'BA'
    'cowork-plugin-management'  = 'DEV'
    'customer-support'          = 'BA'
    'data'                      = 'DEV'
    'design'                    = 'DOC'
    'engineering'               = 'DEV'
    'enterprise-search'         = 'DEV'
    'finance'                   = 'FINANCE'
    'human-resources'           = 'HR'
    'legal'                     = 'LEGAL'
    'marketing'                 = 'MKT'
    'operations'                = 'OPS'
    'pdf-viewer'                = 'DEV'
    'product-management'        = 'BA'
    'productivity'              = 'DEV'
    'sales'                     = 'SALES'
    'small-business'            = 'BA'
}

# Read all imported skills from SKILL.md metadata
$imported = @()
$skillDirs = Get-ChildItem -LiteralPath $RootDir -Directory

foreach ($dir in $skillDirs) {
    $skillPath = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path $skillPath)) { continue }
    $content = Get-Content $skillPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    if ($content -match '(?s)source:\s*(\S+)') {
        $source = $matches[1]
        $department = ''
        if ($content -match 'department:\s*(\S+)') { $department = $matches[1] }
        
        if ($source -ne 'GV-native' -and $source -ne '') {
            if ($department -and $deptToProfile.ContainsKey($department)) {
                $profile = $deptToProfile[$department]
            } elseif ($sourceToProfile.ContainsKey($source)) {
                $profile = $sourceToProfile[$source]
            } else {
                $profile = 'DEV'
            }
            $imported += [PSCustomObject]@{
                Name = $dir.Name
                Source = $source
                Department = $department
                Profile = $profile
            }
        }
    }
}

Write-Host "Found $($imported.Count) imported skills" -ForegroundColor Cyan

# Update auto-delegation.json
$json = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json

$addCount = 0
$skipCount = 0
foreach ($skill in $imported) {
    $name = $skill.Name
    $profile = $skill.Profile
    
    # Check if already registered
    $existing = $json.skillToAgentProfile.PSObject.Properties | Where-Object { $_.Name -eq $name }
    if ($existing) {
        $skipCount++
        continue
    }
    
    if ($DryRun) {
        Write-Host "[DRYRUN] $name => $profile" -ForegroundColor Yellow
        continue
    }
    
    $json.skillToAgentProfile | Add-Member -NotePropertyName $name -NotePropertyValue $profile
    $addCount++
}

if ($DryRun) {
    Write-Host "[DRYRUN] Would add $addCount skills, skip $skipCount existing" -ForegroundColor Yellow
    exit
}

# Write updated JSON
$jsonString = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($ConfigPath, $jsonString)
Write-Host "Added $addCount skills to auto-delegation.json ($skipCount skipped)" -ForegroundColor Green

# Update SKILL_INDEX.md — add imported skills section
$importSections = $imported | Group-Object Source | Sort-Object Name

$newEntries = @()

foreach ($group in $importSections) {
    $source = $group.Name
    $sourceLabel = @{
        'anthropic-skills' = 'Anthropic Official Skills (anthropics/skills)'
        'taste-skill' = 'Taste/Design Quality Skills (taste-skill)'
        'academic-research-skills' = 'Academic Research Skills'
        'claude-bughunter' = 'Claude BugHunter — Security/Bug Bounty'
        'knowledge-work-plugins' = 'Knowledge Work Plugins (Anthropic)'
    }
    $label = if ($sourceLabel.ContainsKey($source)) { $sourceLabel[$source] } else { $source }
    
    $newEntries += "`n---`n`n### $label`n"
    
    # Group by department for knowledge-work-plugins
    if ($source -eq 'knowledge-work-plugins') {
        $deptGroups = $group.Group | Group-Object Department | Sort-Object Name
        foreach ($dg in $deptGroups) {
            if ($dg.Name) {
                $newEntries += "`n#### $($dg.Name) Department`n"
            }
            $dg.Group | Sort-Object Name | ForEach-Object {
                $newEntries += "- **$($_.Name)** — Imported from $source. Profile: $($_.Profile)"
            }
        }
    } else {
        $group.Group | Sort-Object Name | ForEach-Object {
            $newEntries += "- **$($_.Name)** — Imported from $source. Profile: $($_.Profile)"
        }
    }
}

$newBlock = $newEntries -join "`n"

# Append to SKILL_INDEX.md (need to find right spot — before EOF)
$indexContent = Get-Content -Raw -LiteralPath $IndexPath
$importedSection = "`n`n## Imported Skills`n$newBlock`n"
$indexContent += $importedSection

[System.IO.File]::WriteAllText($IndexPath, $indexContent)
Write-Host "Updated SKILL_INDEX.md with $($imported.Count) imported skills" -ForegroundColor Green

Write-Host "`n=== REGISTRATION COMPLETE ===" -ForegroundColor Cyan
Write-Host "Total registered: $addCount in auto-delegation.json" -ForegroundColor Green
Write-Host "Total documented: $($imported.Count) in SKILL_INDEX.md" -ForegroundColor Green
