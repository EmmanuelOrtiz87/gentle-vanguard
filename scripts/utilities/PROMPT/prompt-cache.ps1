param(
    [Parameter(Mandatory=$true)][string]$Action,
    [string]$PromptHash,
    [string]$PromptContent,
    [string]$CacheDir,
    [string]$WorkspaceRoot = "."
)
if (-not $CacheDir) {
    $cfgPath = Join-Path $WorkspaceRoot "config/system-prompt-optimization.json"
    if (Test-Path $cfgPath) {
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        if ($cfg.cache) { $CacheDir = Join-Path $WorkspaceRoot $cfg.cache.directory }
    }
    if (-not $CacheDir) { $CacheDir = ".session/prompt-cache" }
}
if (-not(Test-Path $CacheDir)) { New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null }
switch($Action) {
    "get"   { $path = Join-Path $CacheDir "$PromptHash.txt"; if (Test-Path $path) { Get-Content $path -Raw } else { $null } }
    "set"   { $path = Join-Path $CacheDir "$PromptHash.txt"; $PromptContent | Set-Content $path; Write-Host "Cached: $PromptHash" }
    "clear" { Remove-Item -Path "$CacheDir\*.txt" -Force -ErrorAction SilentlyContinue; Write-Host "Cache cleared" }
    "stats" { $count = (Get-ChildItem $CacheDir -Filter "*.txt" -ErrorAction SilentlyContinue).Count; Write-Host "Cached: $count prompts" }
}
