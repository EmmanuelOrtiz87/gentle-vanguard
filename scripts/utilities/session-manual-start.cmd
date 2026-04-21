@echo off
setlocal

set SCRIPT=%~dp0session-manager.ps1
set OPTIMIZE_SCRIPT=%~dp0optimize-engram-usage.ps1

echo === Manual Session Start with Engram Optimization ===

if not exist "%SCRIPT%" (
  echo [ERROR] session-manager.ps1 not found: %SCRIPT%
  exit /b 1
)

REM Ejecutar optimización de Engram antes del inicio de sesión
if exist "%OPTIMIZE_SCRIPT%" (
  echo [INFO] Running Engram optimization pre-session...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local"
)

echo Starting manual session flow...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode ManualStart
exit /b %errorlevel%