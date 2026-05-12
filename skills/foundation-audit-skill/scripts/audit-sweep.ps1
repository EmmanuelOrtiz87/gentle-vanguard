#Requires -Version 5.1
<#
.SYNOPSIS
    Foundation Audit Sweep - Batch validation without agent tokens
.DESCRIPTION
    Performs comprehensive audit of Foundation: duplicates, links, skills, docs
    Zero agent tokens - pure PowerShell batch execution
.PARAMETER Scope
    quick | standard | full | deep
.PARAMETER Type
    duplicates | links | skills | docs | all
.PARAMETER Output
    text | json | markdown
.PARAMETER FailOnIssues
    Exit with code 1 if issues found
.EXAMPLE
    .\audit-sweep.ps1 -Scope quick
    .\audit-sweep.ps1 -Scope full -Output json
#>
param(
    [ValidateSet('quick', 'standard', 'full', 'deep')]
    [string]$Scope = 'standard',
    
    [ValidateSet('duplicates', 'links', 'skills', 'docs', 'all')]
    [string]$Type = 'all',
    
    [ValidateSet('text', 'json', 'markdown')]
    [string]$Output = 'text',
    
    [switch]$FailOnIssues,
    
    [string]$BasePath
)

# Auto-detect Foundation root if not specified
if (-not $BasePath) {
    $BasePath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

$ErrorActionPreference = 'Continue'
$Script:Issues = @()
$Script:Warnings = @()
$Script:StartTime = Get-Date

function Write-AuditHeader {
    param([string]$Message)
    if ($Output -eq 'text') {
        Write-Host "`n=== $Message ===" -ForegroundColor Cyan
    } elseif ($Output -eq 'markdown') {
        Write-Output "`n## $Message`n"
    }
}

function Add-Issue {
    param([string]$Category, [string]$Message, [string]$Path, [string]$Severity = 'warning')
    $issue = @{
        Category = $Category
        Message = $Message
        Path = $Path
        Severity = $Severity
        Timestamp = (Get-Date).ToString('o')
    }
    $Script:Issues += $issue
    if ($Output -eq 'text') {
        $color = if ($Severity -eq 'error') { 'Red' } else { 'Yellow' }
        Write-Host "  [$Severity] $Message" -ForegroundColor $color
        if ($Path) { Write-Host "          at: $Path" -ForegroundColor DarkGray }
    }
}

function Add-Warning {
    param([string]$Message)
    $Script:Warnings += $Message
    if ($Output -eq 'text') {
        Write-Host "  [info] $Message" -ForegroundColor DarkGray
    }
}

function Resolve-PathSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseDirectory,
        [Parameter(Mandatory = $true)]
        [string]$RelativeOrAbsolutePath
    )

    $pathWithoutAnchor = ($RelativeOrAbsolutePath -split '#')[0]
    $pathWithoutQuery = ($pathWithoutAnchor -split '\?')[0]
    if ([string]::IsNullOrWhiteSpace($pathWithoutQuery)) {
        return $null
    }

    try {
        if ([System.IO.Path]::IsPathRooted($pathWithoutQuery)) {
            return [System.IO.Path]::GetFullPath($pathWithoutQuery)
        }
        return [System.IO.Path]::GetFullPath((Join-Path $BaseDirectory $pathWithoutQuery))
    } catch {
        return $null
    }
}

# ============================================================================
# CHECK: Deprecated Skills Referenced
# ============================================================================
function Test-DeprecatedSkillReferences {
    param([string]$RootPath)
    
    Write-AuditHeader "Deprecated Skill References"
    
    $deprecated = @('sdd-skill')

    $rulesPath = Join-Path $RootPath 'config\audit-rules.json'
    if (-not (Test-Path $rulesPath)) {
        $rulesPath = Join-Path $PSScriptRoot 'config\audit-rules.json'
    }
    if (Test-Path $rulesPath) {
        try {
            $rules = Get-Content $rulesPath -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($rules.DeprecatedSkills) {
                $deprecated = @($rules.DeprecatedSkills)
            }
        } catch {
            Add-Warning "Could not parse audit rules at: $rulesPath"
        }
    }

    # Foundation contains active SDD skills by design; only flag legacy alias there.
    if ((Split-Path $RootPath -Leaf) -eq 'foundation') {
        $deprecated = $deprecated | Where-Object { $_ -in @('sdd-skill') }
    }
    
    $existingDeprecated = $deprecated | Where-Object { Test-Path (Join-Path $RootPath "skills\$_") }
    
    if ($existingDeprecated.Count -gt 0) {
        Add-Issue -Category 'deprecated' -Message "Found $($existingDeprecated.Count) deprecated skill directories that should be deleted" -Severity 'error'
        $existingDeprecated | ForEach-Object { Add-Warning "Deprecated: skills/$_" }
    } else {
        Write-Host "  [OK] No deprecated skills found" -ForegroundColor Green
    }
}

# ============================================================================
# CHECK: Broken Markdown Links
# ============================================================================
function Test-MarkdownLinks {
    param([string]$RootPath)
    
    Write-AuditHeader "Markdown Link Validation"
    
    $mdFiles = Get-ChildItem -Path $RootPath -Recurse -Filter '*.md' -File | Where-Object { $_.FullName -notmatch '\\tools\\|\\.opencode\\node_modules\\' }
    $brokenLinks = 0
    
    foreach ($file in $mdFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrEmpty($content)) { continue }
        $dir = $file.DirectoryName
        
        # Match markdown links: [text](path)
        $linkMatches = [regex]::Matches($content, '\[([^\]]+)\]\(([^)]+)\)')

        foreach ($match in $linkMatches) {
            $linkText = $match.Groups[1].Value
            $linkUrl = $match.Groups[2].Value

            # Skip external URLs and anchors
            if ($linkUrl -match '^(https?://|#|mailto:)' -or $linkUrl -match '^skills/') { continue }

            # Check if file exists
            $resolvedPath = Resolve-PathSafe -BaseDirectory $dir -RelativeOrAbsolutePath $linkUrl

            if ($null -eq $resolvedPath -or -not (Test-Path $resolvedPath)) {
                $brokenLinks++
                Add-Issue -Category 'links' -Message "Broken link: $linkText" -Path $file.FullName -Severity 'warning'
            }
        }
    }
    
    if ($brokenLinks -eq 0) {
        Write-Host "  [OK] No broken links found" -ForegroundColor Green
    } else {
        Add-Warning "Total broken links: $brokenLinks"
    }
}

# ============================================================================
# CHECK: Skill Structure
# ============================================================================
function Test-SkillStructure {
    param([string]$RootPath)
    
    Write-AuditHeader "Skill Structure Validation"
    
    $skillsPath = Join-Path $RootPath 'skills'
    $skillDirs = Get-ChildItem -Path $skillsPath -Directory -ErrorAction SilentlyContinue
    
    $issues = 0
    
    foreach ($dir in $skillDirs) {
        $skillMd = Join-Path $dir.FullName 'SKILL.md'
        
        # Check SKILL.md exists
        if (-not (Test-Path $skillMd)) {
            Add-Issue -Category 'skills' -Message "Missing SKILL.md" -Path $dir.FullName -Severity 'error'
            $issues++
            continue
        }
        
        # Check frontmatter
        $content = Get-Content $skillMd -Raw
        if ($content -notmatch '^---\s*\n') {
            Add-Issue -Category 'skills' -Message "Missing YAML frontmatter" -Path $skillMd -Severity 'error'
            $issues++
        }
        
        # Check for _shared references
        if ($content -match 'skills/_shared') {
            Add-Issue -Category 'skills' -Message "References non-existent _shared directory" -Path $skillMd -Severity 'error'
            $issues++
        }
    }
    
    if ($issues -eq 0) {
        Write-Host "  [OK] All skills have valid structure ($($skillDirs.Count) skills)" -ForegroundColor Green
    }
}

# ============================================================================
# CHECK: Duplicate File Content
# ============================================================================
function Test-DuplicateContent {
    param([string]$RootPath)
    
    Write-AuditHeader "Duplicate Content Detection"
    
    $ps1Files = Get-ChildItem -Path $RootPath -Recurse -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    $hashes = @{}
    $duplicates = 0
    
    foreach ($file in $ps1Files) {
        $hash = (Get-FileHash $file.FullName -Algorithm MD5).Hash
        if ($hashes.ContainsKey($hash)) {
            Add-Issue -Category 'duplicates' -Message "Duplicate content: $($file.Name)" -Path $file.FullName -Severity 'info'
            Add-Warning "Same as: $($hashes[$hash])"
            $duplicates++
        } else {
            $hashes[$hash] = $file.FullName
        }
    }
    
    if ($duplicates -eq 0) {
        Write-Host "  [OK] No duplicate scripts found" -ForegroundColor Green
    }
}

# ============================================================================
# CHECK: Orphaned Documentation
# ============================================================================
function Test-OrphanedDocs {
    param([string]$RootPath)
    
    Write-AuditHeader "Orphaned Documentation Check"
    
    $docsPath = Join-Path $RootPath 'docs'
    $allMdFiles = Get-ChildItem -Path $docsPath -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue
    $referenced = @{}
    
    # Scan all content for references (exclude node_modules and .git)
    $allFiles = Get-ChildItem -Path $RootPath -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' -and $_.FullName -notmatch '[\\/]\.git[\\/]' }
    foreach ($file in $allFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrEmpty($content)) { continue }
        $mdLinkMatches = [regex]::Matches($content, '\[[^\]]+\]\(([^)#]+\.md)(?:#[^)]+)?\)')
        foreach ($match in $mdLinkMatches) {
            $linkedPath = $match.Groups[1].Value
            $resolvedLinkedPath = Resolve-PathSafe -BaseDirectory $file.DirectoryName -RelativeOrAbsolutePath $linkedPath
            if ($resolvedLinkedPath) {
                $referenced[$resolvedLinkedPath] = $true
            }
        }
    }
    
    $orphaned = 0
    foreach ($doc in $allMdFiles) {
        $found = $referenced.ContainsKey($doc.FullName)
        if (-not $found -and $doc.Name -ne 'README.md') {
            $relPath = $doc.FullName -replace [regex]::Escape($RootPath), ''
            Add-Warning "Potentially orphaned: $relPath"
            $orphaned++
        }
    }
    
    if ($orphaned -eq 0) {
        Write-Host "  [OK] No orphaned docs found" -ForegroundColor Green
    }
}

# ============================================================================
# CHECK: README References
# ============================================================================
function Test-ReadmeReferences {
    param([string]$RootPath)
    
    Write-AuditHeader "README Reference Validation"
    
    $readmePath = Join-Path $RootPath 'README.md'
    if (-not (Test-Path $readmePath)) {
        Add-Issue -Category 'docs' -Message "README.md not found" -Severity 'error'
        return
    }
    
    $content = Get-Content $readmePath -Raw
    $dir = Split-Path $readmePath -Parent
    $broken = 0
    
    $links = [regex]::Matches($content, '\[([^\]]+)\]\(([^)]+\.md)\)')
    foreach ($match in $links) {
        $link = $match.Groups[2].Value
        if ($link -match '^(https?://|#|skills/)') { continue }
        
        $resolved = Resolve-PathSafe -BaseDirectory $dir -RelativeOrAbsolutePath $link
        
        if ($null -eq $resolved -or -not (Test-Path $resolved)) {
            Add-Issue -Category 'docs' -Message "Broken README link: $link" -Path $readmePath -Severity 'error'
            $broken++
        }
    }
    
    if ($broken -eq 0) {
        Write-Host "  [OK] All README links valid" -ForegroundColor Green
    }
}

# ============================================================================
# CHECK: SKILL_INDEX Sync
# ============================================================================
function Test-SkillIndexSync {
    param([string]$RootPath)
    
    Write-AuditHeader "SKILL_INDEX Synchronization"
    
    $skillsPath = Join-Path $RootPath 'skills'
    $indexPath = Join-Path $skillsPath 'SKILL_INDEX.md'
    $actualSkills = Get-ChildItem -Path $skillsPath -Directory | Select-Object -ExpandProperty Name
    
    # Skills that are directories but not skills
    $nonSkills = @('judgment-day', 'multi-agent-registry', 'skill-registry', 'branch-pr', 
                    'issue-creation', 'incident-response-plan', '_shared')
    
    $indexContent = if (Test-Path $indexPath) { Get-Content $indexPath -Raw } else { '' }
    
    $missing = 0
    foreach ($skill in $actualSkills) {
        if ($skill -in $nonSkills) { continue }
        if ($indexContent -notmatch [regex]::Escape($skill)) {
            Add-Warning "Not in SKILL_INDEX: $skill"
            $missing++
        }
    }
    
    if ($missing -eq 0) {
        Write-Host "  [OK] SKILL_INDEX synchronized ($($actualSkills.Count) skills)" -ForegroundColor Green
    } else {
        Add-Issue -Category 'skills' -Message "$missing skills not in SKILL_INDEX" -Severity 'warning'
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
function Invoke-AuditSweep {
    param([string]$RootPath, [string]$Scope)
    
    Write-Host "`n# Foundation Audit Sweep - $Scope" -ForegroundColor Magenta
    Write-Host "Started: $($Script:StartTime.ToString('HH:mm:ss'))"
    Write-Host "Base: $RootPath`n"
    
    # Scope definitions
    $scopeChecks = @{
        'quick'    = @('Test-DeprecatedSkillReferences', 'Test-SkillStructure')
        'standard' = @('Test-DeprecatedSkillReferences', 'Test-SkillStructure', 'Test-MarkdownLinks', 'Test-ReadmeReferences')
        'full'    = @('Test-DeprecatedSkillReferences', 'Test-SkillStructure', 'Test-MarkdownLinks', 
                      'Test-ReadmeReferences', 'Test-DuplicateContent', 'Test-SkillIndexSync')
        'deep'    = @('Test-DeprecatedSkillReferences', 'Test-SkillStructure', 'Test-MarkdownLinks', 
                      'Test-ReadmeReferences', 'Test-DuplicateContent', 'Test-SkillIndexSync', 'Test-OrphanedDocs')
    }
    
    $checks = if ($Type -eq 'all') { $scopeChecks[$Scope] } else {
        switch ($Type) {
            'duplicates' { @('Test-DuplicateContent') }
            'links' { @('Test-MarkdownLinks', 'Test-ReadmeReferences') }
            'skills' { @('Test-DeprecatedSkillReferences', 'Test-SkillStructure', 'Test-SkillIndexSync') }
            'docs' { @('Test-ReadmeReferences', 'Test-OrphanedDocs') }
        }
    }
    
    foreach ($check in $checks) {
        & $check -RootPath $RootPath
    }
}

function Get-AuditSummary {
    $elapsed = (Get-Date) - $Script:StartTime
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "AUDIT SUMMARY" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    $errors = $Script:Issues | Where-Object { $_.Severity -eq 'error' }
    $warnings = $Script:Issues | Where-Object { $_.Severity -eq 'warning' }
    $info = $Script:Issues | Where-Object { $_.Severity -eq 'info' }
    
    Write-Host "`nIssues Found: $($Script:Issues.Count)" -ForegroundColor $(if ($Script:Issues.Count -eq 0) { 'Green' } else { 'Yellow' })
    if ($errors.Count -gt 0) { Write-Host "  Errors: $($errors.Count)" -ForegroundColor Red }
    if ($warnings.Count -gt 0) { Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor Yellow }
    if ($info.Count -gt 0) { Write-Host "  Info: $($info.Count)" -ForegroundColor DarkGray }
    
    Write-Host "`nExecution Time: $($elapsed.TotalSeconds.ToString('0.0'))s"
    Write-Host "Timestamp: $((Get-Date).ToString('o'))"
    
    # Output format specific
    if ($Output -eq 'json') {
        $result = @{
            Summary = @{
                TotalIssues = $Script:Issues.Count
                Errors = $errors.Count
                Warnings = $warnings.Count
                ExecutionTimeSeconds = [math]::Round($elapsed.TotalSeconds, 2)
            }
            Issues = $Script:Issues
            Warnings = $Script:Warnings
        }
        $result | ConvertTo-Json -Depth 3
    } elseif ($Output -eq 'markdown') {
        Write-Output "`n## Audit Report`n"
        Write-Output "| Category | Message | Path | Severity |`n"
        Write-Output "|-----------|--------|------|----------|`n"
        foreach ($issue in $Script:Issues) {
            Write-Output "| $($issue.Category) | $($issue.Message) | $($issue.Path) | $($issue.Severity) |`n"
        }
    }
    
    # Exit code
    if ($FailOnIssues -and $Script:Issues.Count -gt 0) {
        exit 1
    }
}

# Run audit
Invoke-AuditSweep -RootPath $BasePath -Scope $Scope
Get-AuditSummary
