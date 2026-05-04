# Bulk cleanup of native/native-tools/Workspace-Skills references
# Run from workspace-foundation root

$root = "C:\Workspace_local\workspace-foundation"
$extensions = @("*.md", "*.ps1", "*.json", "*.cmd")

Get-ChildItem -Path $root -Recurse -Include $extensions -File | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
    if ($content -match 'native|gentleman guard angel|native-tools|gentleman skills|native-tools|Workspace-Skills|workspace-foundation') {
        $newContent = $content `
            -replace '\bgga\b', 'native' `
            -replace '\bGGA\b', 'native' `
            -replace 'native-tools', 'native-tools' `
            -replace 'native-tools', 'native-tools' `
            -replace 'Workspace-Skills', 'Workspace-Skills' `
            -replace 'workspace-foundation', 'workspace-foundation'
        Set-Content $file -Value $newContent -NoNewline -ErrorAction SilentlyContinue
    }
}

Write-Host "Bulk cleanup completed."
