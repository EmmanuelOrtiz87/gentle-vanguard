@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Descripción: Cierra sesión de trabajo
REM Autor: Sistema de Estabilización
REM Fecha: 2026-04-30
REM Versión: 1.0
REM ============================================================================

echo.
echo === Session Manual End ===
echo.

REM Validaciones previas
where powershell >nul 2>&1
if errorlevel 1 (
  echo [ERROR] PowerShell not found in PATH
  exit /b 1
)

REM Lógica principal
set "SCRIPT_DIR=%~dp0"
set "WF_SCRIPT=%SCRIPT_DIR%..\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1"

if not exist "!WF_SCRIPT!" (
  echo [ERROR] wf.ps1 not found at: !WF_SCRIPT!
  exit /b 1
)

echo [INFO] Ending session...
powershell -NoProfile -ExecutionPolicy Bypass -File "!WF_SCRIPT!" end-session

if errorlevel 1 (
  echo [ERROR] Session end failed with exit code !errorlevel!
  exit /b !errorlevel!
)

echo [SUCCESS] Session ended successfully
exit /b 0