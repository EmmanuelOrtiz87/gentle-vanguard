param(
    [string]$WorkspaceRoot = $(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

function Remove-TreeIfExists {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        Write-Host "Removed runtime state: $Path"
    }
}

$workspaceParent = Split-Path -Parent $WorkspaceRoot
$candidateRoots = @(
    (Join-Path $workspaceParent 'Engram\bitbucket-dashboard'),
    (Join-Path $WorkspaceRoot 'projects')
)

foreach ($root in $candidateRoots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -LiteralPath $root -Directory -Force -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq '.engram' } |
        ForEach-Object { Remove-TreeIfExists -Path $_.FullName }
}

Write-Host "Runtime cleanup complete."
