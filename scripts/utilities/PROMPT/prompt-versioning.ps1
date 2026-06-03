param(
    [Parameter(Mandatory=$true)][string]$Action,
    [string]$PromptName,
    [string]$Content,
    [string]$VersionDir,
    [string]$WorkspaceRoot = "."
)
if (-not $VersionDir) {
    $cfgPath = Join-Path $WorkspaceRoot "config/system-prompt-optimization.json"
    if (Test-Path $cfgPath) {
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        if ($cfg.versioning) { $VersionDir = Join-Path $WorkspaceRoot $cfg.versioning.directory }
    }
    if (-not $VersionDir) { $VersionDir = ".session/prompt-versions" }
}
if (-not(Test-Path $VersionDir)) { New-Item -ItemType Directory -Path $VersionDir -Force | Out-Null }
switch($Action) {
    "save"     { $v = (Get-Date -Format "yyyyMMdd-HHmmss"); $path = Join-Path $VersionDir "$PromptName-$v.md"; $Content | Set-Content $path; Write-Output "SAVED:$v" }
    "list"     { $versions = Get-ChildItem $VersionDir -Filter "$PromptName-*.md" | Sort-Object Name -Descending; Write-Output "VERSIONS:"; $versions | ForEach-Object { Write-Output $_.Name } }
    "diff"     { Write-Output "DIFF" }
    "rollback" { Write-Output "ROLLBACK" }
}
