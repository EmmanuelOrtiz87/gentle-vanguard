@echo off
REM session-autostart.cmd ? Shim for session-autostart.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0SESSION\session-autostart.ps1" %*
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
