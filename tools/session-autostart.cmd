@echo off
REM Session Autostart Script for Windows
REM Starts engram server for workspace-foundation

setlocal

set "ENGAM_EXE=%~dp0engram.exe"
set "CONFIG_FILE=%~dp0session-autostart.config.json"

REM Check if engram exists
if not exist "%ENGAM_EXE%" (
    echo [WARNING] engram.exe not found at %ENGAM_EXE%
    exit /b 0
)

REM Check if engram server is already running
netstat -ano | findstr ":7437" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Engram server already running on port 7437
    exit /b 0
)

REM Start engram server in background
echo [INFO] Starting engram server...
start "" /B "%ENGAM_EXE%" serve

echo [INFO] Engram server started
endlocal
