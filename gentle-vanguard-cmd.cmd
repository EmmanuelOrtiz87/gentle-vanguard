@echo off
REM Gentle-Vanguard CMS Launcher
REM Inicia el CMS de marketing sin necesidad de servidor externo

echo ============================================
echo   Gentle-Vanguard CMS Launcher
echo ============================================
echo.
echo Iniciando panel de control de marketing...
echo.

REM Obtener el directorio actual
set "CURRENT_DIR=%~dp0"
set "CMS_PATH=%CURRENT_DIR%docs\presentations\resources-index.html"

echo Verificando archivos...
if exist "%CMS_PATH%" (
    echo ✅ CMS encontrado: %CMS_PATH%
) else (
    echo ❌ Error: No se encuentra resources-index.html
    echo    Verifica que estés en el directorio raíz de gentle-vanguard
    pause
    exit /b 1
)

echo.
echo Opciones de inicio:
echo [1] Abrir CMS directamente (recomendado)
echo [2] Iniciar con servidor local (mejor experiencia)
echo [3] Ver documentación

echo.
set /p choice="Selecciona una opción (1, 2 o 3): "

if "%choice%"=="1" (
    echo.
    echo Abriendo CMS...
    echo Nota: El visor de markdown requiere servidor para algunos archivos.
    echo        Los contratos principales funcionan embebidos.
    start "" "%CMS_PATH%"
    echo ✅ CMS abierto en navegador
)

if "%choice%"=="2" (
    echo.
    echo Verificando Node.js...
    where node >nul 2>nul
    if %errorlevel% neq 0 (
        echo ❌ Node.js no encontrado.
        echo    Instálalo desde https://nodejs.org
        pause
        exit /b 1
    )
    
    echo ✅ Node.js encontrado
    echo.
    echo Instalando servidor...
    call npm install -g http-server
    
    echo.
    echo Iniciando servidor en puerto 8080...
    echo Accede desde: http://localhost:8080/docs/presentations/resources-index.html
    echo.
    echo Presiona Ctrl+C para detener el servidor
    echo.
    cd /d "%CURRENT_DIR%"
    http-server -p 8080 -o /docs/presentations/resources-index.html
)

if "%choice%"=="3" (
    echo.
    echo Documentación disponible:
    echo - ARCHITECTURE-STATUS.md: Estado general del proyecto
    echo - PENDIENTES-CRITICOS.md: Tareas prioritarias
    echo - docs/analysis/PENDING-AUDIT.md: Auditoría completa
    echo.
    pause
)

echo.
echo ============================================
echo   Gentle-Vanguard Marketing CMS
echo   100% Local • Sin Dependencias Cloud

echo ============================================
echo.
