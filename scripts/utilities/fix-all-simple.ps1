# fix-all-simple.ps1 - Simple and robust markdown fix
# Only fixes: Spanish accents + broken links

$basePath = ".\foundation"
$totalFiles = 0
$fixedFiles = 0

Get-ChildItem -Path $basePath -Filter *.md -Recurse | ForEach-Object {
    $file = $_.FullName
    $totalFiles++
    $content = Get-Content -Path $file -Raw -Encoding UTF8
    $original = $content

    # 1. Fix Spanish accents
    $content = $content -replace 'automatizacin', 'automatizacion'
    $content = $content -replace 'configuracion', 'configuracion'
    $content = $content -replace 'revisin', 'revision'
    $content = $content -replace 'activacin', 'activacion'
    $content = $content -replace 'aceptacin', 'aceptacion'
    $content = $content -replace 'documentacion', 'documentacion'
    $content = $content -replace 'instalacion', 'instalacion'
    $content = $content -replace 'validacion', 'validacion'
    $content = $content -replace 'implementacion', 'implementacion'
    $content = $content -replace 'desarrollo profesional', 'desarrollo profesional'
    $content = $content -replace 'herramienta', 'herramienta'
    $content = $content -replace 'est activo', 'esta activo'
    $content = $content -replace 'slo con', 'solo con'
    $content = $content -replace 'slo cuando', 'solo cuando'
    $content = $content -replace 'desarrollo', 'desarrollo'

    # 2. Fix broken links - TECHNICAL-ONBOARDING
    $content = $content -replace 'docs/supplementary/TECHNICAL-ONBOARDING\.md', 'docs/guides/TECHNICAL-ONBOARDING.md'
    $content = $content -replace 'guides/TECHNICAL-ONBOARDING\.md(?!\.)', 'guides/TECHNICAL-ONBOARDING.md'

    # 3. Fix broken links - OPERATING-DECISIONS
    $content = $content -replace 'OPERATING-decisionS', 'OPERATING-DECISIONS'
    $content = $content -replace 'OPERATING-decisionS', 'OPERATING-DECISIONS'

    # 4. Fix broken links - DOCUMENTATION-STANDARDS
    $content = $content -replace 'DOCUMENTATION-STANDARDS\.md', 'TOKEN-CONTEXT-STANDARDS.md'
    $content = $content -replace 'docs/DOCUMENTATION-STANDARDS\.md', 'docs/guides/TOKEN-CONTEXT-STANDARDS.md'
    $content = $content -replace '\.\./DOCUMENTATION-STANDARDS\.md', './TOKEN-CONTEXT-STANDARDS.md'

    if ($content -ne $original) {
        Set-Content -Path $file -Value $content -Encoding UTF8
        Write-Host "[OK] Fixed: $file"
        $fixedFiles++
    }
}

Write-Host "`n========================================="
Write-Host "Total files processed: $totalFiles"
Write-Host "Files fixed: $fixedFiles"
Write-Host "========================================="
