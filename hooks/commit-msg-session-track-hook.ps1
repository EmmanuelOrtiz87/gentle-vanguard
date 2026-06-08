param([string]$CommitMsgFile)
if ([string]::IsNullOrWhiteSpace($CommitMsgFile)) { exit 0 }
$msg = Get-Content -LiteralPath $CommitMsgFile -Raw
if ($msg -match '^(feat|fix|docs|chore|refactor|test|style|perf|build|ci|revert)(\([a-z]+\))?:') {
  Write-Host '[OK] Conventional commit'
} else {
  Write-Host '[FAIL] Not conventional commit'
  exit 1
}
