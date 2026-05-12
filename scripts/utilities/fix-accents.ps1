# Fix Spanish accents in all markdown files
$basePath = ".\foundation"
$totalFixed = 0

Get-ChildItem -Path $basePath -Filter *.md -Recurse | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -Path $file -Raw -Encoding UTF8
    $original = $content
    
    # Fix common Spanish accent issues
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
    
    if ($content -ne $original) {
        Set-Content -Path $file -Value $content -Encoding UTF8
        Write-Host "Fixed: $file"
        $totalFixed++
    }
}

Write-Host "Total files fixed: $totalFixed"
