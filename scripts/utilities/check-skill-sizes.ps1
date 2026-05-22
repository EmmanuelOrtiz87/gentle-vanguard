param([switch]$WarnOnly, [int]$MaxTokens = 1000, [int]$MaxLines = 150)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$skillsDir = Join-Path $repoRoot "skills"

$over = @()
Get-ChildItem -Path $skillsDir -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $lines = (Get-Content $_.FullName | Measure-Object).Count
    $tokens = [math]::Round($_.Length / 4)
    if ($lines -gt $MaxLines -or $tokens -gt $MaxTokens) {
        $over += [PSCustomObject]@{
            Skill = $_.Directory.Name
            Lines = $lines
            Tokens = $tokens
            SizeKB = [math]::Round($_.Length / 1KB, 1)
            Issues = @(if ($lines -gt $MaxLines) { "lines:$lines/$MaxLines" }; if ($tokens -gt $MaxTokens) { "tokens:$tokens/$MaxTokens" }) -join "; "
        }
    }
}

$over = $over | Sort-Object Tokens -Descending

if ($over.Count -eq 0) {
    Write-Host "[OK] All $((Get-ChildItem -Path $skillsDir -Recurse -Filter 'SKILL.md').Count) skills within limits" -ForegroundColor Green
    exit 0
}

Write-Host "[WARN] $($over.Count) skills exceed limits (max $MaxTokens tokens / $MaxLines lines):" -ForegroundColor Yellow
$over | Select-Object Skill, Tokens, Lines, SizeKB, Issues | Format-Table -AutoSize

if (-not $WarnOnly) {
    Write-Host "[ACTION] Split large skills: move content to references/ directory" -ForegroundColor Yellow
}

exit 0
