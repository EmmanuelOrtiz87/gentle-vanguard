$ErrorActionPreference = 'Stop'
$skillsPath = '.\gentle-vanguard\\skills'
$indexPath = '.\gentle-vanguard\\skills\SKILL_INDEX.md'

# Get directories
$dirs = Get-ChildItem $skillsPath -Directory | Select-Object -ExpandProperty Name | Sort-Object

# Get INDEX entries
$content = Get-Content $indexPath
$inTable = $false
$indexSkills = @()
foreach($line in $content) {
    if($line -match '^\|') { $inTable = $true }
    if($inTable -and $line -match '\|(.+)\|(.+)\|') {
        $skillName = ($line -split '\|')[1].Trim()
        if($skillName -and $skillName -ne 'Skill Name') {
            $indexSkills += $skillName
        }
    }
}

Write-Host "Directories: $($dirs.Count)"
Write-Host "INDEX entries: $($indexSkills.Count)"
Write-Host "`nMissing from INDEX:"
foreach($d in $dirs) {
    if($d -notin $indexSkills) {
        Write-Host "  $d"
    }
}

