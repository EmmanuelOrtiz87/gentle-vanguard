param([string[]]$StagedFiles)
if ($StagedFiles.Count -eq 0 -or [string]::IsNullOrWhiteSpace($StagedFiles[0])) { exit 0 }
if ($StagedFiles.Count -eq 1 -and $StagedFiles[0].Contains(' ')) { $StagedFiles = $StagedFiles[0] -split ' ' }
$content = Get-Content $StagedFiles -Raw
if ($content | Select-String -Pattern '[^\x00-\x7F]' -Quiet) {
  Write-Host '[FAIL] Emojis found in script'
  exit 1
}
Write-Host '[OK] No emojis in script'
