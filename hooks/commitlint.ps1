# commitlint.ps1 — validates conventional commit format
param([string]$CommitMsgFile)

if (-not $CommitMsgFile -or -not (Test-Path $CommitMsgFile)) {
    Write-Host "Usage: commitlint.ps1 <commit-msg-file>" -ForegroundColor Yellow
    exit 0
}

$msg = Get-Content $CommitMsgFile -Raw
$pattern = '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build)(\(.+\))?: .+'

if ($msg -notmatch $pattern) {
    Write-Host "ERROR: Commit message must follow conventional commits format:" -ForegroundColor Red
    Write-Host "  <type>(<scope>): <description>" -ForegroundColor Gray
    Write-Host "  Types: feat|fix|docs|style|refactor|test|chore|perf|ci|build" -ForegroundColor Gray
    exit 1
}
