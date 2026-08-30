@echo off
REM session-autostart.cmd — Shim for src/session/session-autostart.ts
REM node-direct via in-process tsx loader (no npx.cmd chain, no extra consoles)
node --import tsx src/session/session-autostart.ts %*
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
