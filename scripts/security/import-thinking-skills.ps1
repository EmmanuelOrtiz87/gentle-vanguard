param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$SrcDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\.tmp\cc-thinking-skills\skills')
$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills')

$imports = @(
    @{ src='thinking-cynefin';          name='cynefin-skill';           triggers='"cynefin", "complexity classification", "problem domain", "complicated vs complex"' }
    @{ src='thinking-first-principles'; name='first-principles-skill';  triggers='"first principles", "fundamental reasoning", "break down problem", "physics thinking"' }
    @{ src='thinking-socratic';         name='socratic-skill';          triggers='"socratic", "questioning", "critical inquiry", "dialectical"' }
    @{ src='thinking-systems';          name='systems-thinking-skill';  triggers='"systems thinking", "system dynamics", "emergent behavior", "interconnections"' }
    @{ src='thinking-ooda';             name='ooda-loop-skill';         triggers='"ooda", "observe orient decide act", "rapid iteration", "decision cycle"' }
    @{ src='thinking-bayesian';         name='bayesian-skill';          triggers='"bayesian", "probability", "belief update", "prior evidence", "posterior"' }
    @{ src='thinking-debiasing';        name='debiasing-skill';         triggers='"debiasing", "cognitive bias", "bias awareness", "decision bias"' }
    @{ src='thinking-fermi-estimation'; name='fermi-skill';             triggers='"fermi", "estimation", "order of magnitude", "back of envelope", "approximation"' }
    @{ src='thinking-second-order';     name='second-order-skill';      triggers='"second order", "consequences", "ripple effects", "unintended consequences"' }
    @{ src='thinking-inversion';        name='inversion-skill';         triggers='"inversion", "invert problem", "reverse thinking", "avoid failure"' }
    @{ src='thinking-red-team';         name='red-team-skill';          triggers='"red team", "adversarial review", "attack simulation", "penetration thinking"' }
    @{ src='thinking-five-whys-plus';   name='five-whys-skill';         triggers='"five whys", "root cause", "why analysis", "cause analysis"' }
    @{ src='thinking-feedback-loops';   name='feedback-loops-skill';    triggers='"feedback loop", "reinforcing loop", "balancing loop", "system dynamics"' }
    @{ src='thinking-model-router';     name='model-router-skill';      triggers='"model router", "thinking model", "which model", "reasoning framework"' }
    @{ src='thinking-leverage-points';  name='leverage-points-skill';   triggers='"leverage point", "high impact", "intervention point", "system change"' }
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

        $gvDesc = "Imported from cc-thinking-skills. $($item.triggers -replace '"', '')."
        $newFrontmatter = @"
name: $($item.name)
description: >
  $gvDesc
metadata:
  source: cc-thinking-skills
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

Write-Host "`nImported $count / $($imports.Count) thinking skills" -ForegroundColor Cyan
