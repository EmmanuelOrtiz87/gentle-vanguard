@echo off
setlocal

set SCRIPT=%~dp0session-manager.ps1
set OPTIMIZE_SCRIPT=%~dp0optimize-engram-usage.ps1

echo === Manual Session End with Engram Optimization ===

if not exist "%SCRIPT%" (
  echo [ERROR] session-manager.ps1 not found: %SCRIPT%
  exit /b 1
)

echo Closing session manually...

REM Generar reporte de estado final
echo [INFO] Generating final status report...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\continuous-status-monitor.ps1" -Once

REM Crear backup final de Engram
echo [INFO] Creating final Engram backup...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\engram-backup-manager.ps1" -Action backup

REM Validar consistencia cross-workspace
echo [INFO] Validating cross-workspace consistency...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\cross-workspace-validator.ps1"

REM Cerrar sesión
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode ManualEnd

REM Ejecutar optimización de Engram después del cierre de sesión
if exist "%OPTIMIZE_SCRIPT%" (
  echo [INFO] Running Engram post-session optimization...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local" -AutoApply
)

echo.
echo [OK] Session closed successfully
echo [OK] Final backup and reports generated
echo.

exit /b %errorlevel%
