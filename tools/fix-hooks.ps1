# Fix hooks and session scripts - Spanish text and gentleman references
$root = "C:\Workspace_local\workspace-foundation"

# Fix pre-commit.ps1
$file = Join-Path $root "hooks\pre-commit.ps1"
$content = Get-Content $file -Raw -ErrorAction SilentlyContinue
if ($content) {
    $content = $content -replace '# 7 Dimensiones: Seguridad, Calidad, Arquitectura, Testing, API, Documentacion, Gitflow', '# 7 Dimensions: Security, Quality, Architecture, Testing, API, Documentation, Gitflow'
    $content = $content -replace 'Write-Host "[INFO] Ejecutando chequeos automaticos de las 7 dimensiones..." -ForegroundColor Cyan', 'Write-Host "[INFO] Running automated checks for 7 dimensions..." -ForegroundColor Cyan'
    $content = $content -replace '# Seguridad', '# Security'
    $content = $content -replace '# Calidad', '# Quality'
    $content = $content -replace '# Arquitectura', '# Architecture'
    $content = $content -replace '# Testing', '# Testing'
    $content = $content -replace '# API', '# API'
    $content = $content -replace '# Documentacion', '# Documentation'
    $content = $content -replace '# Gitflow', '# Gitflow'
    $content = $content -replace 'Write-Host "[OK] Chequeos de las 7 dimensiones completados."', 'Write-Host "[OK] 7 dimension checks completed."'
    $content = $content -replace '$env:GENTLEMAN_ROOT', '$env:FOUNDATION_ROOT'
    $content = $content -replace '.gentleman)', '.foundation)'
    $content = $content -replace 'Gentleman Foundation', 'Foundation'
    Set-Content $file -Value $content -Encoding UTF8
    Write-Host "Fixed: pre-commit.ps1"
}

# Fix session-manager.ps1
$file = Join-Path $root "scripts\utilities\SESSION-MANAGEMENT\session-manager.ps1"
$content = Get-Content $file -Raw -ErrorAction SilentlyContinue
if ($content) {
    $content = $content -replace 'Gestor de sesiones para workspace-foundation', 'Session manager for workspace-foundation'
    $content = $content -replace 'Asegurar que existe el directorio de sesion', 'Ensure session directory exists'
    $content = $content -replace 'Generar ID de sesion', 'Generate session ID'
    $content = $content -replace 'Crear archivo de sesion', 'Create session file'
    $content = $content -replace 'gentleman-foundation', 'workspace-foundation'
    $content = $content -replace 'sesion', 'session'
    $content = $content -replace 'sesiones', 'sessions'
    Set-Content $file -Value $content -Encoding UTF8
    Write-Host "Fixed: session-manager.ps1"
}

# Fix pre-commit-config-validation.ps1
$file = Join-Path $root "hooks\pre-commit-config-validation.ps1"
$content = Get-Content $file -Raw -ErrorAction SilentlyContinue
if ($content) {
    $content = $content -replace 'Pre-commit Hook - Valida cambios en configuraciones', 'Pre-commit Hook - Validate configuration changes'
    $content = $content -replace 'Hook que se ejecuta antes de hacer commit para validar', 'Hook that runs before commit to validate'
    $content = $content -replace 'que los archivos de configuracion sean correctos.', 'that configuration files are correct.'
    $content = $content -replace 'Pre-commit: Validando cambios en configuraciones...', 'Pre-commit: Validating configuration changes...'
    $content = $content -replace 'No hay cambios en configuracion', 'No configuration changes'
    $content = $content -replace 'Archivos de configuracion a validar', 'Configuration files to validate'
    $content = $content -replace 'Validando:', 'Validating:'
    $content = $content -replace 'JSON valido', 'Valid JSON'
    $content = $content -replace 'JSON invalido', 'Invalid JSON'
    $content = $content -replace 'Validando contra esquema...', 'Validating against schema...'
    $content = $content -replace 'Validacion de configuracion fallo', 'Configuration validation failed'
    $content = $content -replace 'Validacion de configuracion exitosa', 'Configuration validation passed'
    Set-Content $file -Value $content -Encoding UTF8
    Write-Host "Fixed: pre-commit-config-validation.ps1"
}

# Fix post-checkout.ps1
$file = Join-Path $root "hooks\post-checkout.ps1"
$content = Get-Content $file -Raw -ErrorAction SilentlyContinue
if ($content) {
    $content = $content -replace 'Gentleman Foundation', 'Foundation'
    Set-Content $file -Value $content -Encoding UTF8
    Write-Host "Fixed: post-checkout.ps1"
}

Write-Host "All fixes applied."
