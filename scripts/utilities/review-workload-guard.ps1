param(
    [string]$BaseBranch = "main",
    [string]$DiffTarget = "",
    [int]$MaxLines = 400,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Get-ChangedLines {
    param([string]$Target)

    if ($Target -ne "" -and (Test-Path $Target)) {
        # Count lines in a file or directory
        if ((Get-Item $Target).PSIsContainer) {
            $total = 0
            Get-ChildItem -Path $Target -Recurse -File | ForEach-Object { $total += (Get-Content $_.FullName -ReadCount 2000 | ForEach-Object { $_.Count }) }
            return $total
        } else {
            return (Get-Content $Target -ReadCount 2000 | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
        }
    }

    # Git diff comparison
    $diffArgs = @("diff", "--stat")
    if ($Target -ne "") { $diffArgs += $Target }
    else { $diffArgs += "$BaseBranch..." }

    $output = git @diffArgs 2>$null
    if (-not $output) { return 0 }

    $additions = 0; $deletions = 0; $files = 0
    foreach ($line in $output) {
        if ($line -match '(\d+) file') { $files = $Matches[1] }
        if ($line -match '(\d+) insertion') { $additions = $Matches[1] }
        if ($line -match '(\d+) delet') { $deletions = $Matches[1] }
    }
    return @{
        Files = $files
        Additions = [int]$additions
        Deletions = [int]$deletions
        Total = [int]$additions + [int]$deletions
    }
}

$result = Get-ChangedLines -Target $DiffTarget

if ($result -is [int]) {
    # File-based count
    $totalLines = $result
    $overBudget = $totalLines -gt $MaxLines

    if (-not $Quiet) {
        Write-Host "[REVIEW-WORKLOAD] Total lines: $totalLines"
        Write-Host "[REVIEW-WORKLOAD] Max budget: $MaxLines"
        if ($overBudget) {
            Write-Host "[REVIEW-WORKLOAD] ⚠ EXCEEDS BUDGET by $($totalLines - $MaxLines) lines"
            Write-Host "[REVIEW-WORKLOAD] → Recommend chained PRs (see skills/chained-pr/SKILL.md)"
        } else {
            Write-Host "[REVIEW-WORKLOAD] ✅ Within budget"
        }
    }

    return @{
        Status = if ($overBudget) { "OVER_BUDGET" } else { "OK" }
        TotalLines = $totalLines
        MaxLines = $MaxLines
        OverBy = [Math]::Max(0, $totalLines - $MaxLines)
        RecommendChained = $overBudget
    }
}

if (-not $result -or $result.Total -eq 0) {
    if (-not $Quiet) { Write-Host "[REVIEW-WORKLOAD] No changes detected or not a git repo" }
    return @{ Status = "NO_CHANGES"; Total = 0; MaxLines = $MaxLines; RecommendChained = $false }
}

$overBudget = $result.Total -gt $MaxLines

if (-not $Quiet) {
    Write-Host "[REVIEW-WORKLOAD] Files: $($result.Files) | +$($result.Additions)/-$($result.Deletions) = $($result.Total) lines"
    Write-Host "[REVIEW-WORKLOAD] Max budget: $MaxLines lines"
    if ($overBudget) {
        Write-Host "[REVIEW-WORKLOAD] ⚠ EXCEEDS BUDGET by $($result.Total - $MaxLines) lines"
        Write-Host "[REVIEW-WORKLOAD] → Recommend chained PRs (see skills/chained-pr/SKILL.md)"
        Write-Host "[REVIEW-WORKLOAD] → Suggested slices: $([Math]::Ceiling($result.Total / $MaxLines)) PRs"
    } else {
        Write-Host "[REVIEW-WORKLOAD] ✅ Within budget ($(($MaxLines - $result.Total)) lines remaining)"
    }
}

return @{
    Status = if ($overBudget) { "OVER_BUDGET" } else { "OK" }
    Files = $result.Files
    Additions = $result.Additions
    Deletions = $result.Deletions
    Total = $result.Total
    MaxLines = $MaxLines
    OverBy = [Math]::Max(0, $result.Total - $MaxLines)
    SuggestedSlices = if ($overBudget) { [Math]::Ceiling($result.Total / $MaxLines) } else { 1 }
    RecommendChained = $overBudget
}
