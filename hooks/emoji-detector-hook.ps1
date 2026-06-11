param([string[]]$StagedFiles)
if ($StagedFiles.Count -eq 0 -or [string]::IsNullOrWhiteSpace($StagedFiles[0])) { exit 0 }
if ($StagedFiles.Count -eq 1 -and $StagedFiles[0].Contains(' ')) { $StagedFiles = $StagedFiles[0] -split ' ' }
$hasEmoji = $false
foreach ($file in $StagedFiles) {
  $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
  if (-not $content) { continue }
  # Check for actual emoji characters (not Spanish accents or box-drawing)
  for ($i = 0; $i -lt $content.Length; $i++) {
    $code = [int]$content[$i]
    if ($code -ge 0xD800 -and $code -le 0xDFFF) { $hasEmoji = $true; break }
    if ($code -ge 0x2600 -and $code -le 0x27BF) { $hasEmoji = $true; break }
    if ($code -ge 0x2B05 -and $code -le 0x2B55) { $hasEmoji = $true; break }
    if ($code -ge 0x1F300) { $hasEmoji = $true; break }
  }
  if ($hasEmoji) { break }
}
if ($hasEmoji) {
  Write-Host '[FAIL] Emojis found in script'
  exit 1
}
Write-Host '[OK] No emojis in script'
