param(
    [int]$MaxTokens = 1000,
    [int]$MaxLines = 150,
    [int]$KeepLines = 100,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$skillsDir = Join-Path $repoRoot "skills"
$splitCount = 0; $errorCount = 0; $skippedCount = 0

$over = @()
Get-ChildItem -Path $skillsDir -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $lines = (Get-Content $_.FullName | Measure-Object).Count
    $tokens = [math]::Round($_.Length / 4)
    if ($lines -gt $MaxLines -or $tokens -gt $MaxTokens) {
        $over += [PSCustomObject]@{ Skill = $_.Directory.Name; Path = $_.FullName; Lines = $lines; Tokens = $tokens }
    }
}

$over = $over | Sort-Object Tokens -Descending

Write-Host "[INFO] Processing $($over.Count) oversized skills..." -ForegroundColor Cyan

foreach ($skill in $over) {
    $allLines = Get-Content $skill.Path
    $totalLines = $allLines.Count
    $refDir = Join-Path (Split-Path $skill.Path) "references"
    $refFile = Join-Path $refDir "detail.md"

    if ($totalLines -le $KeepLines) {
        Write-Host "  [SKIP] $($skill.Skill) — only $totalLines lines, keeping as-is" -ForegroundColor Gray
        $skippedCount++
        continue
    }

    # Detect frontmatter end
    $frontmatterEnd = -1
    if ($allLines[0] -eq '---') {
        for ($i = 1; $i -lt $totalLines; $i++) {
            if ($allLines[$i] -eq '---') { $frontmatterEnd = $i; break }
        }
    }

    $splitLine = if ($frontmatterEnd -ge 0) { $frontmatterEnd + $KeepLines } else { $KeepLines }
    if ($splitLine -ge $totalLines) { $splitLine = [math]::Max($KeepLines, 80) }

    $keepEnd = [math]::Min($splitLine, $totalLines - 1)
    $refStart = $keepEnd + 1

    # Use ArrayList to avoid type issues
    $keepList = [System.Collections.ArrayList]@()
    for ($i = 0; $i -le $keepEnd; $i++) { [void]$keepList.Add($allLines[$i]) }

    $refList = [System.Collections.ArrayList]@()
    for ($i = $refStart; $i -lt $totalLines; $i++) { [void]$refList.Add($allLines[$i]) }

    if ($refList.Count -eq 0) {
        Write-Host "  [SKIP] $($skill.Skill) — nothing to move" -ForegroundColor Gray
        $skippedCount++
        continue
    }

    # Add reference link at bottom of kept content
    [void]$keepList.Add("")
    [void]$keepList.Add("---")
    [void]$keepList.Add("")
    [void]$keepList.Add("> **Referencia detallada**: [`references/detail.md`](references/detail.md)")

    if ($DryRun) {
        Write-Host "  [DRY-RUN] $($skill.Skill) — $totalLines → $($keepList.Count) SKILL.md + $($refList.Count) refs" -ForegroundColor Yellow
        $splitCount++
    } else {
        try {
            if (-not (Test-Path $refDir)) { New-Item -ItemType Directory -Path $refDir -Force | Out-Null }
            $refContent = $refList -join "`n"
            Microsoft.PowerShell.Management\Set-Content -Path $refFile -Value $refContent -NoNewline
            $keepContent = $keepList -join "`n"
            Microsoft.PowerShell.Management\Set-Content -Path $skill.Path -Value $keepContent -NoNewline
            Write-Host "  [OK] $($skill.Skill) — $totalLines → $($keepList.Count) SKILL.md + $($refList.Count) refs" -ForegroundColor Green
            $splitCount++
        } catch {
            Write-Host "  [ERR] $($skill.Skill) — $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY-RUN: $splitCount would be split, $skippedCount skipped, $errorCount errors" -ForegroundColor Yellow
} else {
    Write-Host "Split: $splitCount | Skipped: $skippedCount | Errors: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
}
exit $errorCount
