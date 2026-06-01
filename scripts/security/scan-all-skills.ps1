param(
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\..\reports\skill-security'),
    [int]$ThresholdScore = 50
)

$ErrorActionPreference = 'Continue'
$SkillsDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills')
$ReportDir = New-Item -ItemType Directory -Path $OutputDir -Force

$skillDirs = Get-ChildItem -LiteralPath $SkillsDir -Directory | Where-Object {
    $_.Name -notmatch '^_' -and (Test-Path (Join-Path $_.FullName 'SKILL.md'))
}

Write-Host "Scanning $($skillDirs.Count) skills with skillspector..." -ForegroundColor Cyan

$results = @()
$summary = @{ Total = $skillDirs.Count; Passed = 0; Failed = 0; Errors = 0; IssueCount = @{} }

foreach ($dir in $skillDirs) {
    $skillName = $dir.Name
    Write-Progress -Activity "Scanning skills" -Status $skillName -PercentComplete (($results.Count / $skillDirs.Count) * 100)

    $reportFile = Join-Path $ReportDir "$skillName.json"

    try {
        $result = & "$PSScriptRoot\scan-skill.ps1" -Path $dir.FullName -Format json -OutputPath $reportFile -ThresholdScore $ThresholdScore -PassThru
        if (-not $result) { continue }

        if ($result.Status -eq 'PASS') { $summary.Passed++ } else { $summary.Failed++ }
        $results += $result

        foreach ($issue in $result.Issues) {
            $cat = $issue.category
            if (-not $summary.IssueCount[$cat]) { $summary.IssueCount[$cat] = 0 }
            $summary.IssueCount[$cat]++
        }

        Write-Host "  $($result.Status) $skillName — Score: $($result.Score), Issues: $($result.IssueCount)"
    } catch {
        $summary.Errors++
        Write-Warning "  ERROR $skillName : $_"
    }
}

Write-Progress -Activity "Scanning skills" -Completed

# Summary report
$report = @"
# Skill Security Scan Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Total Skills**: $($summary.Total)
**Passed**: $($summary.Passed)
**Failed** (score >= $ThresholdScore): $($summary.Failed)
**Errors**: $($summary.Errors)

## Risk Score Distribution
"@
$groups = $results | Group-Object Severity | Sort-Object Name
foreach ($g in $groups) { $report += "`n- **$($g.Name)**: $($g.Count) skills" }

$report += "`n`n## Issue Categories"
foreach ($kv in ($summary.IssueCount.GetEnumerator() | Sort-Object Value -Descending)) {
    $report += "`n- **$($kv.Key)**: $($kv.Value) occurrences"
}

$report += "`n`n## Failed Skills (score >= $ThresholdScore)"
foreach ($fs in ($results | Where-Object Status -eq 'FAIL' | Sort-Object Score -Descending)) {
    $name = Split-Path $fs.Path -Leaf
    $report += "`n- **$name**: Score $($fs.Score) — $($fs.Recommendation)"
}

$report | Out-File (Join-Path $ReportDir 'SUMMARY.md') -Encoding utf8
Write-Host "`nReport: $ReportDir\SUMMARY.md" -ForegroundColor Cyan
return $summary
