# auto-update-skills.ps1
# FF-017: Auto-update mechanism for skills and native tools
# Scans skills/*/SKILL.md, tracks SHA256 hashes, reports changes

param(
    [ValidateSet('check', 'update', 'status')]
    [string]$Action = 'check',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ── Workspace root detection ────────────────────────────────────────────
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
# scripts/utilities/SKILLS-TOOLS -> up 3 levels
$workspaceRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$skillsDir = Join-Path $workspaceRoot 'skills'
$trackingFile = Join-Path $workspaceRoot '.skill-tracking.json'

# ── Helpers ─────────────────────────────────────────────────────────────

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Gray
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorLine {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Get-Sha256Hash {
    param([string]$FilePath)
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))
    return ($hashBytes | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Get-Timestamp {
    return (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
}

function Format-Date {
    param([datetime]$DateTime)
    return $DateTime.ToString('yyyy-MM-ddTHH:mm:sszzz')
}

function Load-TrackingFile {
    if (Test-Path $trackingFile) {
        try {
            $raw = Get-Content -Path $trackingFile -Raw -Encoding UTF8
            $data = $raw | ConvertFrom-Json
            return $data
        } catch {
            Write-Warn "Corrupt tracking file, starting fresh: $_"
            return $null
        }
    }
    return $null
}

function Save-TrackingFile {
    param([pscustomobject]$Data)
    if ($DryRun) {
        Write-Info "[DRY-RUN] Would write tracking file: $trackingFile"
        return
    }
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $trackingFile -Encoding UTF8
    Write-Success "Tracking file updated: $trackingFile"
}

function Get-NewTrackingFile {
    param()
    $obj = [pscustomobject]@{
        version       = 1
        last_updated  = Get-Timestamp
        skills        = [ordered]@{}
    }
    return $obj
}

function Get-TrackingSkills {
    param([pscustomobject]$Data)
    if ($null -eq $Data -or $null -eq $Data.skills) { return @{} }
    $skills = @{}
    $Data.skills.PSObject.Properties | ForEach-Object {
        $skills[$_.Name] = @{
            hash          = $_.Value.hash
            last_modified = $_.Value.last_modified
            first_tracked = $_.Value.first_tracked
        }
    }
    return $skills
}

# ── Scan skills ─────────────────────────────────────────────────────────

function Get-AllSkillFiles {
    if (-not (Test-Path $skillsDir)) {
        Write-ErrorLine "Skills directory not found: $skillsDir"
        exit 1
    }
    return Get-ChildItem -Path $skillsDir -Recurse -Filter 'SKILL.md' -File -ErrorAction SilentlyContinue
}

function Scan-Skills {
    $skillFiles = Get-AllSkillFiles
    $results = @()
    foreach ($file in $skillFiles) {
        $skillName = $file.Directory.Name
        $lastWrite = $file.LastWriteTime
        $hash = Get-Sha256Hash -FilePath $file.FullName

        $results += [pscustomobject]@{
            SkillName    = $skillName
            FilePath     = $file.FullName
            LastWrite    = $lastWrite
            Hash         = $hash
        }
    }
    return $results
}

# ── Classification ─────────────────────────────────────────────────────

function Classify-Skills {
    param(
        [array]$Scanned,
        [hashtable]$Tracked
    )

    $new = @()
    $changed = @()
    $uptodate = @()

    foreach ($s in $Scanned) {
        $name = $s.SkillName
        if (-not $Tracked.ContainsKey($name)) {
            $new += $s
        } elseif ($Tracked[$name].hash -ne $s.Hash) {
            $changed += [pscustomobject]@{
                SkillName    = $s.SkillName
                FilePath     = $s.FilePath
                LastWrite    = $s.LastWrite
                Hash         = $s.Hash
                OldHash      = $Tracked[$name].hash
            }
        } else {
            $uptodate += $s
        }
    }

    return [pscustomobject]@{
        New      = $new
        Changed  = $changed
        UpToDate = $uptodate
    }
}

# ── Actions ─────────────────────────────────────────────────────────────

function Invoke-ActionCheck {
    Write-Info "Scanning skills in: $skillsDir"
    $scanned = Scan-Skills
    $trackingData = Load-TrackingFile
    $tracked = Get-TrackingSkills -Data $trackingData

    $classified = Classify-Skills -Scanned $scanned -Tracked $tracked

    Write-Host "`n=== SKILL CHECK REPORT ===" -ForegroundColor Cyan
    Write-Host ""

    if ($classified.New.Count -gt 0) {
        Write-Host "NEW SKILLS ($($classified.New.Count)):" -ForegroundColor Green
        foreach ($s in $classified.New) {
            Write-Host "  [+] $($s.SkillName)" -ForegroundColor Green
            Write-Host "      Last modified: $($s.LastWrite.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        }
        Write-Host ""
    }

    if ($classified.Changed.Count -gt 0) {
        Write-Host "CHANGED SKILLS ($($classified.Changed.Count)):" -ForegroundColor Yellow
        foreach ($s in $classified.Changed) {
            $ageDays = [math]::Round(((Get-Date) - $s.LastWrite).TotalDays, 1)
            Write-Host "  [~] $($s.SkillName)" -ForegroundColor Yellow
            Write-Host "      Last modified: $($s.LastWrite.ToString('yyyy-MM-dd HH:mm:ss')) ($ageDays days ago)" -ForegroundColor Gray
        }
        Write-Host ""
    }

    if ($classified.UpToDate.Count -gt 0) {
        Write-Host "UP-TO-DATE SKILLS ($($classified.UpToDate.Count)):" -ForegroundColor DarkGray
        foreach ($s in $classified.UpToDate) {
            Write-Host "  [=] $($s.SkillName)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    Write-Host "Summary: $($scanned.Count) total | New: $($classified.New.Count) | Changed: $($classified.Changed.Count) | Up-to-date: $($classified.UpToDate.Count)" -ForegroundColor Cyan

    return $classified
}

function Invoke-ActionUpdate {
    $classified = Invoke-ActionCheck

    $totalNew = $classified.New.Count
    $totalChanged = $classified.Changed.Count

    if ($totalNew -eq 0 -and $totalChanged -eq 0) {
        Write-Info "All skills up-to-date. No tracking update needed."
        return
    }

    $trackingData = Load-TrackingFile
    if ($null -eq $trackingData) {
        $trackingData = Get-NewTrackingFile
    }

    $now = Get-Timestamp
    $trackingData.last_updated = $now

    foreach ($s in $classified.New) {
        $entry = [ordered]@{
            hash          = $s.Hash
            last_modified = Format-Date -DateTime $s.LastWrite
            first_tracked = $now
        }
        $trackingData.skills | Add-Member -MemberType NoteProperty -Name $s.SkillName -Value ([pscustomobject]$entry) -Force
    }

    foreach ($s in $classified.Changed) {
        $existing = $trackingData.skills.$($s.SkillName)
        $entry = [ordered]@{
            hash          = $s.Hash
            last_modified = Format-Date -DateTime $s.LastWrite
            first_tracked = $existing.first_tracked
        }
        $trackingData.skills | Add-Member -MemberType NoteProperty -Name $s.SkillName -Value ([pscustomobject]$entry) -Force
    }

    Save-TrackingFile -Data $trackingData
}

function Invoke-ActionStatus {
    $trackingData = Load-TrackingFile
    $scanned = Scan-Skills

    if ($null -eq $trackingData) {
        $tracked = @{}
        $trackedCount = 0
        $trackingAge = 'N/A'
    } else {
        $tracked = Get-TrackingSkills -Data $trackingData
        $trackedCount = $tracked.Count
        $trackFile = Get-Item -LiteralPath $trackingFile
        $trackingAgeDays = [math]::Round(((Get-Date) - $trackFile.LastWriteTime).TotalDays, 1)
        $trackingAge = "$trackingAgeDays days"
    }

    $classified = Classify-Skills -Scanned $scanned -Tracked $tracked

    $staleCount = 0
    $staleThresholdDays = 30
    foreach ($s in $scanned) {
        if ($tracked.ContainsKey($s.SkillName)) {
            $lastMod = [datetime]::Parse($tracked[$s.SkillName].last_modified)
            if (((Get-Date) - $lastMod).TotalDays -gt $staleThresholdDays) {
                $staleCount++
            }
        }
    }

    $now = Get-Date
    $totalSkills = $scanned.Count

    Write-Host "`n=== SKILL TRACKING STATUS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total skills scanned : $totalSkills" -ForegroundColor White
    Write-Host "Tracked in file      : $trackedCount" -ForegroundColor White
    Write-Host "New (untracked)      : $($classified.New.Count)" -ForegroundColor $(if ($classified.New.Count -gt 0) { 'Green' } else { 'Gray' })
    Write-Host "Changed (hash diff)  : $($classified.Changed.Count)" -ForegroundColor $(if ($classified.Changed.Count -gt 0) { 'Yellow' } else { 'Gray' })
    Write-Host "Up-to-date           : $($classified.UpToDate.Count)" -ForegroundColor $(if ($classified.UpToDate.Count -gt 0) { 'DarkGray' } else { 'Gray' })
    Write-Host "Stale (>30d no change): $staleCount" -ForegroundColor $(if ($staleCount -gt 0) { 'Magenta' } else { 'Gray' })
    Write-Host ""
    Write-Host "Tracking file        : $trackingFile" -ForegroundColor DarkGray
    Write-Host "Tracking file age    : $trackingAge" -ForegroundColor DarkGray
    Write-Host ""
}

# ── Main ────────────────────────────────────────────────────────────────

switch ($Action) {
    'check'  { Invoke-ActionCheck }
    'update' { Invoke-ActionUpdate }
    'status' { Invoke-ActionStatus }
}
