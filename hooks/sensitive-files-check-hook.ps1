param([string[]]$StagedFiles)
if ($StagedFiles.Count -eq 0 -or [string]::IsNullOrWhiteSpace($StagedFiles[0])) { exit 0 }
if ($StagedFiles.Count -eq 1 -and $StagedFiles[0].Contains(' ')) { $StagedFiles = $StagedFiles[0] -split ' ' }
$StagedFiles | ForEach-Object {
  Get-Content -LiteralPath $_ -Raw | ConvertFrom-Json -ErrorAction Stop | Out-Null
}
Write-Host '[OK] All JSON valid'
