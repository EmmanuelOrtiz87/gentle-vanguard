@echo off
REM session-autostart.cmd ? Shim for src/session/session-autostart.ts (tools/)
REM The legacy PS1 was migrated to TypeScript; resolve repo root from shim location.
pushd "%~dp0.."
node --import tsx src/session/session-autostart.ts %*
set ERR=%ERRORLEVEL%
popd
if %ERR% neq 0 exit /b %ERR%
