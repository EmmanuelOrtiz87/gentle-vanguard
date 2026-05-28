$ErrorActionPreference = 'Stop'
$skillsPath = '.\gentle-vanguard\\skills'
$indexPath = '.\gentle-vanguard\\skills\SKILL_INDEX.md'

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

