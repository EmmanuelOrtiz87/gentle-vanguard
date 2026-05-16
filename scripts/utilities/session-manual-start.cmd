@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Description: Inicia sesion de trabajo manualmente
REM ============================================================================

echo.
echo === Session Manual Start ===
echo.

where powershell >nul 2>&1
if errorlevel 1 (
  echo [ERROR] PowerShell not found in PATH
  exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\.."

REM Pre-start: engram optimization
set OPTIMIZE_SCRIPT=%REPO_ROOT%\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-engram-usage.ps1
if exist "%OPTIMIZE_SCRIPT%" (
  echo [INFO] Running pre-session Engram optimization...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_gentle_vanguard"
)

REM Main start flow via gv.ps1
set "WF_SCRIPT=%REPO_ROOT%\scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1"
if not exist "%WF_SCRIPT%" (
  echo [ERROR] gv.ps1 not found
  exit /b 1
)

echo [INFO] Starting session...
powershell -NoProfile -ExecutionPolicy Bypass -File "%WF_SCRIPT%" start-session
if errorlevel 1 (
  echo [ERROR] Session start failed with exit code !errorlevel!
  exit /b !errorlevel!
)

echo [SUCCESS] Session started successfully
exit /b 0

