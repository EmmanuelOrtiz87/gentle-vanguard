# Prevent commits when a merge/rebase/cherry-pick is in progress
$gitDir = (git rev-parse --git-dir) 2>$null
if (-not $gitDir) { exit 0 }

$mergeHead = Join-Path $gitDir 'MERGE_HEAD'
$rebaseApply = Join-Path $gitDir 'rebase-apply'
$rebaseMerge = Join-Path $gitDir 'rebase-merge'
$cherryPick = Join-Path $gitDir 'CHERRY_PICK_HEAD'

if (Test-Path $mergeHead -PathType Leaf -ErrorAction SilentlyContinue -Verbose:$false -OutVariable v) {
    Write-Host "Commit blocked: merge in progress (MERGE_HEAD present). Resolve the merge before committing." -ForegroundColor Red
    exit 1
}
if (Test-Path $rebaseApply -ErrorAction SilentlyContinue -Verbose:$false) {
    Write-Host "Commit blocked: rebase in progress (rebase-apply present). Finish or abort rebase before committing." -ForegroundColor Red
    exit 1
}
if (Test-Path $rebaseMerge -ErrorAction SilentlyContinue -Verbose:$false) {
    Write-Host "Commit blocked: rebase in progress (rebase-merge present). Finish or abort rebase before committing." -ForegroundColor Red
    exit 1
}
if (Test-Path $cherryPick -ErrorAction SilentlyContinue -Verbose:$false) {
    Write-Host "Commit blocked: cherry-pick in progress (CHERRY_PICK_HEAD present). Resolve it before committing." -ForegroundColor Red
    exit 1
}

# No dangerous state detected
exit 0
