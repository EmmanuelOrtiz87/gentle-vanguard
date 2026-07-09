# Prevent commits when a merge/rebase/cherry-pick is in progress
$gitDir = (git rev-parse --git-dir) 2>$null
if (-not $gitDir) { exit 0 }

$mergeHead = Join-Path $gitDir 'MERGE_HEAD'
$rebaseApply = Join-Path $gitDir 'rebase-apply'
$rebaseMerge = Join-Path $gitDir 'rebase-merge'
$cherryPick = Join-Path $gitDir 'CHERRY_PICK_HEAD'
$unmergedFiles = @(git diff --name-only --diff-filter=U 2>$null)

if ((Test-Path $rebaseApply -ErrorAction SilentlyContinue) -or (Test-Path $rebaseMerge -ErrorAction SilentlyContinue)) {
    Write-Host "Commit blocked: rebase in progress. Finish or abort the rebase before committing." -ForegroundColor Red
    exit 1
}
if (Test-Path $cherryPick -PathType Leaf -ErrorAction SilentlyContinue) {
    Write-Host "Commit blocked: cherry-pick in progress (CHERRY_PICK_HEAD present). Resolve it before committing." -ForegroundColor Red
    exit 1
}
if ((Test-Path $mergeHead -PathType Leaf -ErrorAction SilentlyContinue) -and ($unmergedFiles.Count -gt 0)) {
    Write-Host "Commit blocked: merge has unresolved conflicts. Resolve them before committing." -ForegroundColor Red
    exit 1
}

exit 0
