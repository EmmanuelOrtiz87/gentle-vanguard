param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$SrcDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\.tmp\knowledge-work-plugins')
$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills')

$departments = Get-ChildItem -LiteralPath $SrcDir -Directory | Where-Object Name -notmatch '^\.'

$totalCount = 0
$deptCount = 0

foreach ($dept in $departments) {
    $skillsDir = Join-Path $dept.FullName 'skills'
    if (-not (Test-Path $skillsDir)) { continue }

    $skillDirs = Get-ChildItem -LiteralPath $skillsDir -Directory
    $deptName = $dept.Name
    $deptCount++

    foreach ($skillDir in $skillDirs) {
        $srcPath = Join-Path $skillDir.FullName 'SKILL.md'
        if (-not (Test-Path $srcPath)) { continue }

        $content = Get-Content $srcPath -Raw -ErrorAction Stop
        $normalized = $content -replace "`r`n", "`n"

        $skillName = "$($skillDir.Name)-skill"
        if ($skillName -match '-skill-skill$') { $skillName = $skillDir.Name }

        $dstDir = Join-Path $RootDir $skillName
        $dstPath = Join-Path $dstDir 'SKILL.md'

        if ($normalized -match '(?s)^---\s*\n(.*?)\n---\s*\n(.*)') {
            $body = $matches[2]
            $origName = $skillDir.Name

            $newFrontmatter = @"
name: $skillName
description: >
  Knowledge work plugin from $deptName department.
metadata:
  source: knowledge-work-plugins
  original-name: $origName
  department: $deptName
"@
            $newContent = "---`n$newFrontmatter`n---`n$body"

            if ($DryRun) { Write-Host "[DRYRUN] $skillName ($deptName)"; continue }

            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            Copy-Item -Path "$($skillDir.FullName)\*" -Destination $dstDir -Recurse -Force -ErrorAction SilentlyContinue
            [System.IO.File]::WriteAllText($dstPath, $newContent)
            Write-Host "IMPORTED: $skillName [$deptName]" -ForegroundColor Green
            $totalCount++
        } else {
            $origName = $skillDir.Name
            $newFrontmatter = @"
name: $skillName
description: >
  Knowledge work plugin from $deptName department.
metadata:
  source: knowledge-work-plugins
  original-name: $origName
  department: $deptName
"@
            $newContent = "---`n$newFrontmatter`n---`n$normalized"

            if ($DryRun) { Write-Host "[DRYRUN] $skillName ($deptName) [no frontmatter]"; continue }

            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            Copy-Item -Path "$($skillDir.FullName)\*" -Destination $dstDir -Recurse -Force -ErrorAction SilentlyContinue
            [System.IO.File]::WriteAllText($dstPath, $newContent)
            Write-Host "IMPORTED (raw): $skillName [$deptName]" -ForegroundColor Yellow
            $totalCount++
        }
    }
}

Write-Host "`n---" -ForegroundColor Cyan
Write-Host "Imported $totalCount skills across $deptCount departments from knowledge-work-plugins" -ForegroundColor Cyan
