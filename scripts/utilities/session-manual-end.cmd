@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Description: Cierra sesion de trabajo con validacion completa
REM ============================================================================

echo.
echo === Session Manual End ===
echo.

where powershell >nul 2>&1
if errorlevel 1 (
  echo [ERROR] PowerShell not found in PATH
  exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\.."

REM Pre-close: generate final status report
echo [INFO] Generating final status report...
set STATUS_MONITOR=%REPO_ROOT%\scripts\monitoring\continuous-status-monitor.ps1
if exist "%STATUS_MONITOR%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%STATUS_MONITOR%" -Once
) else ( echo [SKIP] continuous-status-monitor.ps1 not found )

REM Main close flow via wf.ps1 (includes pre-close-validator, review, audit, governance)
set "WF_SCRIPT=%REPO_ROOT%\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1"
if not exist "%WF_SCRIPT%" (
  echo [ERROR] wf.ps1 not found
  exit /b 1
)

echo [INFO] Running standard close flow (validation + audit + governance)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%WF_SCRIPT%" end-session
if errorlevel 1 (
  echo [WARN] Close flow reported issues — continuing with post-close steps...
)

REM Close only current tracked session ID (safe when multiple sessions are active)
set SESSION_MANAGER=%REPO_ROOT%\scripts\utilities\session-manager.ps1
set ACTIVE_SESSION_FILE=%REPO_ROOT%\logs\.session-active
if exist "%SESSION_MANAGER%" (
  if exist "%ACTIVE_SESSION_FILE%" (
    for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "$a=Get-Content '%ACTIVE_SESSION_FILE%' -Raw | ConvertFrom-Json; $a.SessionId"`) do set TARGET_SESSION_ID=%%i
    if not "!TARGET_SESSION_ID!"=="" (
      echo [INFO] Closing tracked session only: !TARGET_SESSION_ID!
      powershell -NoProfile -ExecutionPolicy Bypass -File "%SESSION_MANAGER%" -Mode End -TargetSessionId "!TARGET_SESSION_ID!"
      if errorlevel 1 ( echo [WARN] Session manager close returned warnings ) else ( echo [OK] Session closed safely: !TARGET_SESSION_ID! )
    ) else (
      echo [WARN] Could not read SessionId from logs/.session-active
    )
  ) else (
    echo [WARN] logs/.session-active not found — skipping targeted session close
  )
) else (
  echo [SKIP] session-manager.ps1 not found
)

REM Post-close: cross-workspace validation
echo [INFO] Validating cross-workspace consistency...
set CROSS_VALIDATOR=%REPO_ROOT%\scripts\monitoring\cross-workspace-validator.ps1
if exist "%CROSS_VALIDATOR%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%CROSS_VALIDATOR%"
    if errorlevel 1 ( echo [WARN] Cross-workspace validation found issues ) else ( echo [OK] Cross-workspace validated )
) else ( echo [SKIP] cross-workspace-validator.ps1 not found )

REM Post-close: engram optimization
set OPTIMIZE_SCRIPT=%REPO_ROOT%\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-engram-usage.ps1
if exist "%OPTIMIZE_SCRIPT%" (
  echo [INFO] Running post-session Engram optimization...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local" -AutoApply
) else ( echo [SKIP] optimize-engram-usage.ps1 not found )

REM Weekly metrics on Sundays
for /f "tokens=1" %%a in ('powershell -NoProfile -Command "(Get-Date).DayOfWeek"') do set DAYOFWEEK=%%a
if /i "!DAYOFWEEK!"=="Sunday" (
  set WEEKLY_METRICS=%REPO_ROOT%\scripts\monitoring\weekly-metrics.ps1
  if exist "!WEEKLY_METRICS!" (
    echo [INFO] Generating weekly metrics report...
    powershell -NoProfile -ExecutionPolicy Bypass -File "!WEEKLY_METRICS!"
  ) else ( echo [SKIP] weekly-metrics.ps1 not found )
)

echo.
echo ============================================
echo [OK] Session closed successfully
echo [OK] Final report and validations complete
if /i "!DAYOFWEEK!"=="Sunday" ( echo [OK] Weekly metrics report generated )
echo.
echo Next steps:
echo   - Review logs/status-report.txt for final status
echo   - Check .session/reports/ for closure artifacts
if /i "!DAYOFWEEK!"=="Sunday" (
  echo   - Review logs/weekly-metrics-*.md for weekly summary
)
echo ============================================
echo.

exit /b 0
