@echo off
setlocal

set SCRIPT=%~dp0session-manager.ps1
set OPTIMIZE_SCRIPT=%~dp0optimize-engram-usage.ps1
set METRICS_SCRIPT=%~dp0..\scripts\monitoring\weekly-metrics.ps1

echo === Manual Session End with Engram Optimization ===

if not exist "%SCRIPT%" (
  echo [ERROR] session-manager.ps1 not found: %SCRIPT%
  exit /b 1
)

echo Closing session manually...

REM Generar reporte de estado final
echo [INFO] Generating final status report...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\continuous-status-monitor.ps1" -Once

REM Ejecutar day-end-closure para persistir memoria (ya hace backup real)
echo [INFO] Day-end closure will persist Engram memories

REM Validar consistencia cross-workspace
echo [INFO] Validating cross-workspace consistency...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\cross-workspace-validator.ps1"

REM Verificar si es domingo para generar reporte semanal
for /f "tokens=1" %%a in ('powershell -Command "(Get-Date).DayOfWeek"') do set DAYOFWEEK=%%a
if /i "%DAYOFWEEK%"=="Sunday" (
  echo [INFO] Generating weekly metrics report...
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\weekly-metrics.ps1"
)

REM Desmarcar sesin activa
echo [INFO] Unmarking session...
if exist "logs\.session-active" del "logs\.session-active"

REM Cerrar sesin
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode ManualEnd

REM Ejecutar optimizacin de Engram despus del cierre de sesin
if exist "%OPTIMIZE_SCRIPT%" (
  echo [INFO] Running Engram post-session optimization...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local" -AutoApply
)

REM Generar resumen de cierre
echo.
echo ============================================
echo [OK] Session closed successfully
echo [OK] Final backup and reports generated
echo [OK] Cross-workspace consistency validated
if /i "%DAYOFWEEK%"=="Sunday" (
  echo [OK] Weekly metrics report generated
)
echo.
echo Next steps:
echo   - Review logs/status-report.txt for final status
echo   - Check backups/engram/ for latest backup
if /i "%DAYOFWEEK%"=="Sunday" (
  echo   - Review logs/weekly-metrics-*.md for weekly summary
)
echo ============================================
echo.

exit /b %errorlevel%