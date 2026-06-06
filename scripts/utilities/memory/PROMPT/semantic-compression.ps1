param(
    [string]$InputPath,
    [string]$OutputPath,
    [string]$ConfigPath = "config/system-prompt-optimization.json"
)
$content = Get-Content $InputPath -Raw
$configPath = Join-Path (Split-Path $InputPath -Parent) $ConfigPath
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    foreach ($prop in $cfg.abbreviations.PSObject.Properties) {
        $pattern = "\b$($prop.Name)\b"
        $content = $content -replace $pattern, $prop.Value
    }
} else {
    $content = $content -replace '\bimplementation\b', 'impl'
    $content = $content -replace '\bfunction\b', 'fn'
    $content = $content -replace '\bconfiguration\b', 'cfg'
}
$content | Set-Content $OutputPath
Write-Output "Compressed: $InputPath -> $OutputPath"
