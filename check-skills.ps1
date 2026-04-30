$ErrorActionPreference = 'Stop'
$skillsPath = 'C:\Workspace_local\workspace-foundation\skills'
$indexPath = 'C:\Workspace_local\workspace-foundation\skills\SKILL_INDEX.md'

# Get directories
$dirs = Get-ChildItem $skillsPath -Directory | Select-Object -ExpandProperty Name | Sort-Object

# Get INDEX content
$indexContent = Get-Content $indexPath -Raw

$missing = @()
foreach($d in $dirs) {
    if($indexContent -notmatch [regex]::Escape($d)) {
        $missing += $d
    }
}

Write-Host "Total directories: $($dirs.Count)"
Write-Host "Missing from INDEX: $($missing.Count)"
foreach($m in $missing) {
    Write-Host "  - $m"
}
