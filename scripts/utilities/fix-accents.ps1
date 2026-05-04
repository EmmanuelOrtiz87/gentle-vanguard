# Fix Spanish accents in all markdown files
$basePath = ".\workspace-foundation"
$totalFixed = 0

Get-ChildItem -Path $basePath -Filter *.md -Recurse | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -Path $file -Raw -Encoding UTF8
    $original = $content
    
    # Fix common Spanish accent issues
    $content = $content -replace 'automatizacin', 'automatización'
    $content = $content -replace 'configuracion', 'configuración'
    $content = $content -replace 'revisin', 'revisión'
    $content = $content -replace 'activacin', 'activación'
    $content = $content -replace 'aceptacin', 'aceptación'
    $content = $content -replace 'documentacion', 'documentación'
    $content = $content -replace 'instalacion', 'instalación'
    $content = $content -replace 'validacion', 'validación'
    $content = $content -replace 'implementacion', 'implementación'
    $content = $content -replace 'desarrollo profesional', 'desarrollo profesional'
    $content = $content -replace 'herramienta', 'herramienta'
    $content = $content -replace 'est activo', 'está activo'
    $content = $content -replace 'slo con', 'solo con'
    $content = $content -replace 'slo cuando', 'solo cuando'
    
    if ($content -ne $original) {
        Set-Content -Path $file -Value $content -Encoding UTF8
        Write-Host "Fixed: $file"
        $totalFixed++
    }
}

Write-Host "Total files fixed: $totalFixed"
