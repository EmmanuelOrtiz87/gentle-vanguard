@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Session Autostart
REM Location: scripts/utilities/session-autostart.cmd
REM Resolves workspace root 2 levels up (scripts/utilities/ -> ./ )
REM ============================================================

REM === Phase 0: Workspace Detection ===
for %%I in ("%~dp0..\..") do set WORKSPACE_ROOT=%%~fI
set UTILS_DIR=%WORKSPACE_ROOT%\scripts\utilities

echo.
echo === Session Autostart ===
echo Workspace: %WORKSPACE_ROOT%
echo.

REM === Pre-flight Health Check ===
set HEALTH_CRITICAL=1

if not exist "%WORKSPACE_ROOT%\.git" (
    echo [CRITICAL] Not a git repository: %WORKSPACE_ROOT%
    set HEALTH_CRITICAL=0
) else ( echo [PASS] Git repository )

if not exist "%WORKSPACE_ROOT%\config\auto-delegation.json" (
    echo [CRITICAL] Missing routing config: config\auto-delegation.json
    set HEALTH_CRITICAL=0
) else ( echo [PASS] Routing config )

if not exist "%UTILS_DIR%\session-manager.ps1" (
    echo [CRITICAL] Missing session-manager.ps1
    set HEALTH_CRITICAL=0
) else ( echo [PASS] Session manager )

if not exist "%WORKSPACE_ROOT%\opencode.json" (
    echo [WARN] Missing opencode.json - AI config may be incomplete
)

if not exist "%UTILS_DIR%\token-guard.ps1" (
    echo [WARN] Missing token-guard.ps1 - token limits not enforced
)

echo.
if %HEALTH_CRITICAL% equ 0 (
    echo [ABORTED] Health check failed. Resolve critical issues and retry.
    exit /b 1
)
echo [HEALTH] All critical checks passed.
echo.

REM === Phase 1: Session Manager ===
echo [1/8] Initializing session manager...
powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\session-manager.ps1" -Mode AutoStart
if errorlevel 1 (
    echo [ERROR] session-manager.ps1 failed (code: !errorlevel!)
    echo [FALLBACK] Attempting wf.ps1...
    if exist "%UTILS_DIR%\wf.ps1" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\wf.ps1" start-session
    ) else (
        echo [FATAL] No fallback available. Aborting.
        exit /b 1
    )
) else ( echo [OK] Session initialized )

REM === Phase 2: Notifications ===
echo [2/8] Time-based notifications...
if exist "%UTILS_DIR%\session-notification.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\session-notification.ps1" -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15 -Region "Argentina"
    if errorlevel 1 ( echo [WARN] Notification check had warnings ) else ( echo [OK] Notifications checked )
) else ( echo [SKIP] session-notification.ps1 not found )

REM === Phase 3: Session ID ===
echo [3/8] Resolving session ID...
set SESSION_ID=
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\get-session-id.ps1"') do set SESSION_ID=%%i
if defined SESSION_ID (
    echo [OK] Session ID: %SESSION_ID%
) else ( echo [WARN] Could not resolve session ID )

REM === Phase 4: Engram Policy Enforcement ===
echo [4/8] Engram policy enforcement...
set ENGRAM_POLICY=%WORKSPACE_ROOT%\scripts\foundation\engram-policy.ps1
if exist "%ENGRAM_POLICY%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGRAM_POLICY%" -Action enforce
    if errorlevel 1 (
        echo [WARN] Engram policy issues detected
        if exist "%UTILS_DIR%\engram-orchestrator.ps1" (
            powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\engram-orchestrator.ps1" -Action orchestrate
        )
    ) else ( echo [OK] Engram policy enforced )
) else ( echo [SKIP] engram-policy.ps1 not found )

REM === Phase 5: Engram Optimization ===
echo [5/8] Engram optimization...
set OPTIMIZE_SCRIPT=%WORKSPACE_ROOT%\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-engram-usage.ps1
if exist "%OPTIMIZE_SCRIPT%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local"
    if errorlevel 1 ( echo [WARN] Optimization had warnings ) else ( echo [OK] Engram optimized )
) else ( echo [SKIP] optimize-engram-usage.ps1 not found )

REM === Phase 6: Cross-Workspace Validation ===
echo [6/8] Cross-workspace validation...
set CROSS_VALIDATOR=%WORKSPACE_ROOT%\scripts\monitoring\cross-workspace-validator.ps1
if exist "%CROSS_VALIDATOR%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%CROSS_VALIDATOR%" -Detailed
    if errorlevel 1 ( echo [WARN] Validation found issues ) else ( echo [OK] Cross-workspace validated )
) else ( echo [SKIP] cross-workspace-validator.ps1 not found )

REM === Phase 7: Security Orchestrator ===
echo [7/8] Security orchestrator...
set SECURITY_SCRIPT=%WORKSPACE_ROOT%\scripts\security\security-orchestrator.ps1
if exist "%SECURITY_SCRIPT%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SECURITY_SCRIPT%" -Action init -AsJson
    if errorlevel 1 ( echo [WARN] Security init had warnings ) else ( echo [OK] Security initialized )
) else ( echo [SKIP] security-orchestrator.ps1 not found )

REM === Phase 8: Skill Router ===
echo [8/8] Skill router...
set SKILL_ROUTER=%UTILS_DIR%\skill-router.ps1
if exist "%SKILL_ROUTER%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SKILL_ROUTER%" -Query "session-start"
    if errorlevel 1 ( echo [WARN] Skill router validation issue ) else ( echo [OK] Skill router active )
) else ( echo [SKIP] skill-router.ps1 not found )

REM === Phase 9: Post-Autostart Summary ===
echo [9/8] Generating startup summary...
powershell -NoProfile -ExecutionPolicy Bypass -File "%WORKSPACE_ROOT%\scripts\utilities\post-autostart-summary.ps1" -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15 -Region "Argentina"
if errorlevel 1 ( echo [WARN] Summary generation had warnings ) else ( echo [OK] Startup summary saved )

echo.
echo === Session Autostart Complete ===
echo [READY] Workspace ready for operations
exit /b 0
