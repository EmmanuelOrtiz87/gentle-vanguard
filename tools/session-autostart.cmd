@echo off
REM session-autostart.cmd ? Shim for session-autostart.ps1 (tools/)
pwsh -NoProfile -ExecutionPolicy Bypass -File "..\scripts\utilities\SESSION\session-autostart.ps1" %*
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
