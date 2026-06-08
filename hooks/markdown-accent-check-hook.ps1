param([string[]]$StagedFiles)
if ($StagedFiles.Count -eq 0 -or [string]::IsNullOrWhiteSpace($StagedFiles[0])) { exit 0 }
if ($StagedFiles.Count -eq 1 -and $StagedFiles[0].Contains(' ')) { $StagedFiles = $StagedFiles[0] -split ' ' }
$content = Get-Content $StagedFiles -Raw
if ($content | Select-String -Pattern '[áéíóúñ]' -Quiet) {
  Write-Host '[OK] Spanish accents found'
} else {
  Write-Host '[WARN] No Spanish accents detected'
}
