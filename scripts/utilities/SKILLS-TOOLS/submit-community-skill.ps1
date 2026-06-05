# submit-community-skill.ps1
# Packages a community skill for submission to the Gentle-Vanguard marketplace.
# Validates skill structure and creates a compressed archive for easy sharing.
#
# Usage:
#   .\submit-community-skill.ps1 -Name "my-awesome-skill" -Description "Does something cool" `
#       -Author "your-github-handle" -TriggerWords "api,openapi" -AgentType "general" `
#       -SkillMdPath "C:\path\to\SKILL.md"
#
# Parameters:
#   -Name          (required)  Skill name in kebab-case
#   -Description   (required)  Short description of what the skill does
#   -Author        (required)  Your GitHub username or name
#   -TriggerWords  (required)  Comma-separated trigger words/phrases
#   -AgentType     (required)  Target agent type (general, doc-agent, explore, etc.)
#   -SkillMdPath   (required)  Path to the SKILL.md file
#   -Tags          (optional)  Comma-separated tags
#   -Version       (optional)  Skill version (default: 1.0.0)
#   -License       (optional)  License identifier (default: MIT)
#   -OutputDir     (optional)  Directory for the output package (default: ./submissions)

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [string]$Author,

    [Parameter(Mandatory = $true)]
    [string]$TriggerWords,

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "general", "doc-agent", "explore", "finance-agent",
        "gov-agent", "hr-agent", "legal-agent", "mkt-agent",
        "ops-agent", "sales-agent", "session-agent",
        "sdd-design", "sdd-apply", "sdd-explore", "sdd-verify",
        "any"
    )]
    [string]$AgentType,

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "File not found: $_"
        }
        return $true
    })]
    [string]$SkillMdPath,

    [Parameter(Mandatory = $false)]
    [string]$Tags = "",

    [Parameter(Mandatory = $false)]
    [string]$Version = "1.0.0",

    [Parameter(Mandatory = $false)]
    [string]$License = "MIT",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "submissions"
}

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "[ERROR] $m" -ForegroundColor Red }

Write-Step "Validating skill: $Name"

# Validate skill name is kebab-case
if ($Name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    Write-Err "Skill name must be kebab-case (e.g., 'my-awesome-skill'). Got: '$Name'"
    exit 1
}

# Validate skill name uniqueness
$skillsDir = Join-Path $repoRoot "skills"
if (Test-Path $skillsDir) {
    $existingDirs = Get-ChildItem -Path $skillsDir -Directory | Select-Object -ExpandProperty Name
    if ($Name -in $existingDirs) {
        Write-Err "A skill with the name '$Name' already exists in skills/$Name"
        exit 1
    }
    $similar = $existingDirs | Where-Object { $_ -like "$Name*" -or $Name -like "$_*" }
    if ($similar) {
        Write-Warn "Found similar existing skill names: $($similar -join ', ')"
    }
}

Write-Step "Reading SKILL.md"
$skillContent = Get-Content -Path $SkillMdPath -Raw
if ([string]::IsNullOrWhiteSpace($skillContent)) {
    Write-Err "SKILL.md is empty"
    exit 1
}

Write-Step "Validating SKILL.md structure"

$errors = @()

# Check frontmatter
if ($skillContent -notmatch '^---') {
    $errors += "Missing YAML frontmatter (file must start with ---)"
}

$frontmatch = [regex]::Match($skillContent, '(?s)^---\s*\n(.*?)\n---')
if ($frontmatch.Success) {
    $fm = $frontmatch.Groups[1].Value
    if ($fm -notmatch 'name:\s*\S+') {
        $errors += "Frontmatter missing 'name' field"
    }
    if ($fm -notmatch 'description:\s*\S+') {
        $errors += "Frontmatter missing 'description' field"
    }
} else {
    $errors += "Could not parse YAML frontmatter"
}

# Check required sections
if ($skillContent -notmatch '##\s+Usage|##\s+When to Use') {
    $errors += "Missing '## Usage' or '## When to Use' section"
}

if ($skillContent -notmatch '##\s+Examples') {
    $errors += "Missing '## Examples' section"
}

if ($errors.Count -gt 0) {
    Write-Err "SKILL.md validation failed with $($errors.Count) error(s):"
    foreach ($err in $errors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
    exit 1
}

Write-Ok "SKILL.md structure is valid"

Write-Step "Creating submission package"

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Create a temporary directory for the package
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "gv-skill-submission-$Name"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Create the skill directory inside the package
$pkgSkillDir = Join-Path $tempDir $Name
New-Item -ItemType Directory -Path $pkgSkillDir -Force | Out-Null

# Copy SKILL.md
Copy-Item -Path $SkillMdPath -Destination (Join-Path $pkgSkillDir "SKILL.md")

# Copy reference files if they exist beside the SKILL.md
$sourceDir = Split-Path -Parent $SkillMdPath
$referencesDir = Join-Path $sourceDir "references"
if (Test-Path $referencesDir) {
    Copy-Item -Path $referencesDir -Destination $pkgSkillDir -Recurse
}

# Copy scripts if they exist beside the SKILL.md
$scriptsDir = Join-Path $sourceDir "scripts"
if (Test-Path $scriptsDir) {
    Copy-Item -Path $scriptsDir -Destination $pkgSkillDir -Recurse
}

# Copy examples if they exist beside the SKILL.md
$examplesDir = Join-Path $sourceDir "examples"
if (Test-Path $examplesDir) {
    Copy-Item -Path $examplesDir -Destination $pkgSkillDir -Recurse
}

# Generate submission manifest
$manifest = @{
    name        = $Name
    description = $Description
    author      = $Author
    version     = $Version
    license     = $License
    agentType   = $AgentType
    triggers    = ($TriggerWords -split ',' | ForEach-Object { $_.Trim() }) -join ', '
    tags        = if ($Tags) { ($Tags -split ',' | ForEach-Object { $_.Trim() }) -join ', ' } else { "" }
    submittedAt = (Get-Date -Format "o")
    files       = @(
        "SKILL.md"
    )
}

# Add optional directories to manifest
if (Test-Path "$pkgSkillDir/references") { $manifest.files += "references/" }
if (Test-Path "$pkgSkillDir/scripts") { $manifest.files += "scripts/" }
if (Test-Path "$pkgSkillDir/examples") { $manifest.files += "examples/" }

$manifest | ConvertTo-Json | Out-File -FilePath (Join-Path $pkgSkillDir "submission-manifest.json") -Encoding utf8

# Create the archive
$archiveName = "$Name-v$Version-submission.zip"
$archivePath = Join-Path $OutputDir $archiveName

# Remove existing archive if present
if (Test-Path $archivePath) {
    Remove-Item -Path $archivePath -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $archivePath)

# Clean up temp
Remove-Item -Path $tempDir -Recurse -Force

Write-Ok "Submission package created: $archivePath"
Write-Ok "Package size: $((Get-Item $archivePath).Length / 1KB) KB"

Write-Step "Submission summary"
Write-Host "Name:        $Name" -ForegroundColor Gray
Write-Host "Description: $Description" -ForegroundColor Gray
Write-Host "Author:      $Author" -ForegroundColor Gray
Write-Host "Agent Type:  $AgentType" -ForegroundColor Gray
Write-Host "Version:     $Version" -ForegroundColor Gray
Write-Host "License:     $License" -ForegroundColor Gray
Write-Host "Triggers:    $TriggerWords" -ForegroundColor Gray
if ($Tags) { Write-Host "Tags:        $Tags" -ForegroundColor Gray }
Write-Host "Package:     $archivePath" -ForegroundColor Cyan

Write-Step "Next Steps"
Write-Host "1. Create a new issue at https://github.com/$(try { (git config --get remote.origin.url) -replace '.*[\/:]' -replace '\.git$' } catch { 'your-org/gentle-vanguard' })/issues/new?template=skill-contribution.yml" -ForegroundColor Gray
Write-Host "2. Attach this zip file: $archivePath" -ForegroundColor Gray
Write-Host "3. Fill in the issue template with your skill details" -ForegroundColor Gray
Write-Host "4. Or: Open a PR adding your skill to the skills/ directory" -ForegroundColor Gray
