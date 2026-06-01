param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$SrcDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\.tmp\superpowers\skills')
$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills')

$imports = @(
    @{ src='systematic-debugging';        name='systematic-debugging-skill';     triggers='"systematic debugging", "root cause", "debug process", "investigate fix verify defend"' }
    @{ src='subagent-driven-development'; name='subagent-driven-dev-skill';      triggers='"subagent", "fresh agent per task", "two-stage review", "agent isolation"' }
    @{ src='writing-plans';               name='writing-plans-skill';            triggers='"write plan", "task breakdown", "implementation plan", "plan tasks"' }
    @{ src='executing-plans';             name='executing-plans-skill';          triggers='"execute plan", "batch tasks", "checkpoint", "plan execution"' }
)

$count = 0
foreach ($item in $imports) {
    $srcPath = Join-Path $SrcDir "$($item.src)/SKILL.md"
    $dstDir = Join-Path $RootDir $item.name
    $dstPath = Join-Path $dstDir 'SKILL.md'

    if (-not (Test-Path $srcPath)) { Write-Warning "NOT FOUND: $srcPath"; continue }

    $content = Get-Content $srcPath -Raw -ErrorAction Stop
    $normalized = $content -replace "`r`n", "`n"

    if ($normalized -match '(?s)^---\s*\n(.*?)\n---\s*\n(.*)') {
        $body = $matches[2]
        $origName = if ($matches[1] -match 'name:\s*(.*)') { $matches[1].Trim() } else { $item.src }

        $gvDesc = "Imported from obra/superpowers. $($item.triggers -replace '"', '')."
        $newFrontmatter = @"
name: $($item.name)
description: >
  $gvDesc
metadata:
  source: superpowers
  original-name: $origName
"@
        $newContent = "---`n$newFrontmatter`n---`n$body"

        if ($DryRun) { Write-Host "[DRYRUN] $($item.name) ← $($item.src)"; continue }

        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        [System.IO.File]::WriteAllText($dstPath, $newContent)
        $count++
        Write-Host "IMPORTED: $($item.name)" -ForegroundColor Green
    } else {
        Write-Warning "PARSE ERROR: $srcPath"
    }
}

Write-Host "`nImported $count / $($imports.Count) superpowers skills" -ForegroundColor Cyan
