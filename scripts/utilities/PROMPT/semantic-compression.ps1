param(
    [string]$InputPath,
    [string]$OutputPath
)
$content = Get-Content $InputPath -Raw
$compressed = $content -replace '\bimplementation\b', 'impl'
$compressed = $compressed -replace '\bfunction\b', 'fn'
$compressed = $compressed -replace '\bconfiguration\b', 'cfg'
$compressed | Set-Content $OutputPath
Write-Output "Compressed: $InputPath -> $OutputPath"