param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDir,
    [Parameter(Mandatory = $true)]
    [string]$SourceName,
    [string]$SkillsSubdir = "skills",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills')
$SrcRoot = Resolve-Path $SourceDir

$srcSkillsDir = Join-Path $SrcRoot $SkillsSubdir
if (-not (Test-Path $srcSkillsDir)) {
    Write-Warning "Skills dir not found: $srcSkillsDir"
    exit 1
}

$skillDirs = Get-ChildItem -LiteralPath $srcSkillsDir -Directory
Write-Host "Found $($skillDirs.Count) skills in $SourceName/$SkillsSubdir" -ForegroundColor Cyan

$count = 0
foreach ($skillDir in $skillDirs) {
    $srcPath = Join-Path $skillDir.FullName 'SKILL.md'
    if (-not (Test-Path $srcPath)) {
        Write-Warning "No SKILL.md in $($skillDir.Name)"
        continue
    }

    $content = Get-Content $srcPath -Raw -ErrorAction Stop
    $normalized = $content -replace "`r`n", "`n"

    if ($normalized -match '(?s)^---\s*\n(.*?)\n---\s*\n(.*)') {
        $frontmatter = $matches[1]
        $body = $matches[2]

        $origName = if ($frontmatter -match 'name:\s*(.*)') { $matches[1].Trim() } else { $skillDir.Name }
        $origDesc = if ($frontmatter -match 'description:\s*(.*)') { $matches[1].Trim() } else { "Imported from $SourceName." }

        $skillName = "$($skillDir.Name)-skill"
        if ($skillName -match '-skill-skill$') { $skillName = $skillDir.Name }

        $dstDir = Join-Path $RootDir $skillName
        $dstPath = Join-Path $dstDir 'SKILL.md'

        $newFrontmatter = @"
name: $skillName
description: >
  $origDesc
metadata:
  source: $SourceName
  original-name: $origName
"@
        $newContent = "---`n$newFrontmatter`n---`n$body"

        if ($DryRun) {
            Write-Host "[DRYRUN] $skillName ← $($skillDir.Name)" -ForegroundColor Yellow
            continue
        }

        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        Copy-Item -Path "$($skillDir.FullName)\*" -Destination $dstDir -Recurse -Force -ErrorAction SilentlyContinue
        [System.IO.File]::WriteAllText($dstPath, $newContent)

        Write-Host "IMPORTED: $skillName" -ForegroundColor Green
        $count++
    } else {
        Write-Warning "PARSE ERROR (no frontmatter): $($skillDir.Name)"
        $skillName = "$($skillDir.Name)-skill"
        $dstDir = Join-Path $RootDir $skillName
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        Copy-Item -Path "$($skillDir.FullName)\*" -Destination $dstDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "COPIED (raw): $skillName" -ForegroundColor Yellow
        $count++
    }
}

Write-Host "`nImported $count / $($skillDirs.Count) skills from $SourceName" -ForegroundColor Cyan
