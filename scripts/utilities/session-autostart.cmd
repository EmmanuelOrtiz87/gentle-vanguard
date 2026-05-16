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

REM === Phase 0.5: Tool Detection (NEW - CRITICAL) ===
echo [0.5/9] Detecting tool/plugin...
set TOOL_DETECTION=%UTILS_DIR%\detect-tool.ps1
if exist "%TOOL_DETECTION%" (
    for /f "tokens=*" %%i in ('pwsh -NoProfile -ExecutionPolicy Bypass -File "%TOOL_DETECTION%" -AsJson ^| findstr "name"') do (
        echo %%i
    )
    echo [OK] Tool detected and configuration loaded
) else (
    echo [WARN] detect-tool.ps1 not found - using default configuration
)
echo.

REM === Phase 0.75: Orphan Session Cleanup ===
echo [0.75/10] Checking for orphaned sessions...
pwsh -NoProfile -ExecutionPolicy Bypass -Command ^
  "$stateFile='%WORKSPACE_ROOT%\.session\state.json';" ^
  "$activeFile='%WORKSPACE_ROOT%\logs\.session-active';" ^
  "$dayEnd='%WORKSPACE_ROOT%\scripts\utilities\UTILITIES\day-end-closure.ps1';" ^
  "$orphan=$false;" ^
  "$sid='';" ^
  "if (Test-Path $stateFile) { try { $d=Get-Content $stateFile -Raw|ConvertFrom-Json; if ($d.status -eq 'active') { $orphan=$true; $sid=$d.sessionId } } catch {} };" ^
  "if (-not $orphan -and (Test-Path $activeFile)) { $orphan=$true; try { $d=Get-Content $activeFile -Raw|ConvertFrom-Json; $sid=$d.SessionId } catch {} };" ^
  "if ($orphan) { Write-Host '[WARN] Orphaned session detected: ' -NoNewline -ForegroundColor Yellow; if ($sid) { Write-Host $sid -ForegroundColor Yellow } else { Write-Host 'unknown' -ForegroundColor Yellow }; Write-Host '[INFO] Auto-closing orphan before new start...' -ForegroundColor Cyan; if (Test-Path $dayEnd) { & $dayEnd -SessionId $sid -Force -SkipValidation -SkipRotation -Quiet; Write-Host '[OK] Orphan session closed' -ForegroundColor Green } } else { Write-Host '[OK] No orphaned sessions found' -ForegroundColor Green }"
if errorlevel 1 ( echo [WARN] Orphan cleanup had issues ) else ( echo [OK] Orphan check complete )

REM === Phase 1: Session Manager ===
REM Add WORKFLOW-ORCHESTRATION to PATH so 'foundation' CLI works
set WF_DIR=%WORKSPACE_ROOT%\scripts\utilities\WORKFLOW-ORCHESTRATION
if exist "%WF_DIR%" (
    set PATH=%WF_DIR%;%PATH%
) else (
    echo [WARN] WORKFLOW-ORCHESTRATION dir not found
)

echo [1/9] Initializing session manager...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\session-manager.ps1" -Mode AutoStart
set SESSION_MANAGER_EXIT=%ERRORLEVEL%
if "%SESSION_MANAGER_EXIT%"=="0" goto session_manager_ok
echo [ERROR] session-manager.ps1 failed (code: %SESSION_MANAGER_EXIT%)
echo [FALLBACK] Attempting foundation...
if exist "%WF_DIR%\foundation.ps1" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%WF_DIR%\foundation.ps1" start-session
) else (
    echo [FATAL] No fallback available. Aborting.
    exit /b 1
)
goto session_manager_done

:session_manager_ok
echo [OK] Session initialized

:session_manager_done

REM === Phase 2: Notifications ===
echo [2/9] Time-based notifications...
if exist "%UTILS_DIR%\session-notification.ps1" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\session-notification.ps1" -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15 -Region "Argentina"
    if errorlevel 1 ( echo [WARN] Notification check had warnings ) else ( echo [OK] Notifications checked )
) else ( echo [SKIP] session-notification.ps1 not found )

REM === Phase 3: Session ID ===
echo [3/9] Resolving session ID...
set SESSION_ID=
for /f "tokens=*" %%i in ('pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\get-session-id.ps1"') do set SESSION_ID=%%i
if defined SESSION_ID (
    set FOUNDATION_SESSION_ID=%SESSION_ID%
    set WFS_SESSION_ID=%SESSION_ID%
    echo [OK] Session ID: %SESSION_ID%
) else ( echo [WARN] Could not resolve session ID )

REM === Phase 3.5: Session Metrics Start ===
echo [3.5/10] Starting session metrics tracking...
set METRICS_SCRIPT=%UTILS_DIR%\session-metrics-tracker.ps1
if exist "%METRICS_SCRIPT%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%METRICS_SCRIPT%" -Action start -SessionId "%SESSION_ID%" -Silent
    if errorlevel 1 ( echo [WARN] Metrics tracking start had warnings ) else ( echo [OK] Session metrics active )
) else ( echo [SKIP] session-metrics-tracker.ps1 not found )

REM === Phase 4: Engram Policy Enforcement ===
echo [4/9] Engram policy enforcement...
set ENGRAM_DATA_DIR=%WORKSPACE_ROOT%\.engram-data
set ENGRAM_POLICY=%WORKSPACE_ROOT%\scripts\foundation\engram-policy.ps1
if exist "%ENGRAM_POLICY%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%ENGRAM_POLICY%" -Action enforce
    if errorlevel 1 (
        echo [WARN] Engram policy issues detected
        if exist "%UTILS_DIR%\engram-orchestrator.ps1" (
            pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\engram-orchestrator.ps1" -Action orchestrate
        )
    ) else ( echo [OK] Engram policy enforced )
) else ( echo [SKIP] engram-policy.ps1 not found )

REM === Phase 5: Engram Optimization ===
echo [5/9] Engram optimization...
set OPTIMIZE_SCRIPT=%WORKSPACE_ROOT%\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-engram-usage.ps1
if exist "%OPTIMIZE_SCRIPT%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local"
    if errorlevel 1 ( echo [WARN] Optimization had warnings ) else ( echo [OK] Engram optimized )
) else ( echo [SKIP] optimize-engram-usage.ps1 not found )

REM === Phase 6: Cross-Workspace Validation ===
echo [6/9] Cross-workspace validation...
set CROSS_VALIDATOR=%WORKSPACE_ROOT%\scripts\monitoring\cross-workspace-validator.ps1
if exist "%CROSS_VALIDATOR%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%CROSS_VALIDATOR%" -Detailed
    if errorlevel 1 ( echo [WARN] Validation found issues ) else ( echo [OK] Cross-workspace validated )
) else ( echo [SKIP] cross-workspace-validator.ps1 not found )

REM === Phase 7: Security Orchestrator ===
echo [7/9] Security orchestrator...
set SECURITY_SCRIPT=%WORKSPACE_ROOT%\scripts\security\security-orchestrator.ps1
if exist "%SECURITY_SCRIPT%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%SECURITY_SCRIPT%" -Action init -AsJson
    if errorlevel 1 ( echo [WARN] Security init had warnings ) else ( echo [OK] Security initialized )
) else ( echo [SKIP] security-orchestrator.ps1 not found )

REM === Phase 8: Skill Router + Registry Build ===
echo [8/9] Skill router...
set SKILL_ROUTER=%UTILS_DIR%\skill-router.ps1
if exist "%SKILL_ROUTER%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%SKILL_ROUTER%" -Query "session-start"
    if errorlevel 1 ( echo [WARN] Skill router validation issue ) else ( echo [OK] Skill router active )
) else ( echo [SKIP] skill-router.ps1 not found )

REM Build skill registry in background
set SKILL_REGISTRY=%UTILS_DIR%\build-skill-registry.ps1
if exist "%SKILL_REGISTRY%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%SKILL_REGISTRY%" -Quiet
    if errorlevel 1 ( echo [WARN] Skill registry build had issues ) else ( echo [OK] Skill registry built )
) else ( echo [SKIP] build-skill-registry.ps1 not found )

REM === Phase 9: Post-Autostart Summary ===
echo [9/10] Generating startup summary...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%WORKSPACE_ROOT%\scripts\utilities\post-autostart-summary.ps1" -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15 -Region "Argentina"
if errorlevel 1 ( echo [WARN] Summary generation had warnings ) else ( echo [OK] Startup summary saved )

REM === Phase 9.25: Adaptive OpenCode Profile ===
echo [9.25/10] Adaptive OpenCode profile...
set ADAPTIVE_OPENCODE=%UTILS_DIR%\adaptive-opencode-profile.ps1
if exist "%ADAPTIVE_OPENCODE%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%ADAPTIVE_OPENCODE%" -Mode Auto -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15
    if errorlevel 1 ( echo [WARN] Adaptive OpenCode profile had warnings ) else ( echo [OK] Adaptive OpenCode profile checked )
) else ( echo [SKIP] adaptive-opencode-profile.ps1 not found )

REM === Phase 9.3: Adaptive Codex/Windsurf Profile ===
echo [9.3/10] Adaptive Codex/Windsurf profile...
set ADAPTIVE_CW=%UTILS_DIR%\adaptive-codex-windsurf-profile.ps1
if exist "%ADAPTIVE_CW%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%ADAPTIVE_CW%" -Mode Auto -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15
    if errorlevel 1 ( echo [WARN] Adaptive Codex/Windsurf profile had warnings ) else ( echo [OK] Adaptive Codex/Windsurf profile checked )
) else ( echo [SKIP] adaptive-codex-windsurf-profile.ps1 not found )

REM === Phase 9.35: Adaptive Claude/Cline Profile ===
echo [9.35/10] Adaptive Claude/Cline profile...
set ADAPTIVE_CC=%UTILS_DIR%\adaptive-claude-cline-profile.ps1
if exist "%ADAPTIVE_CC%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%ADAPTIVE_CC%" -Mode Auto -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15
    if errorlevel 1 ( echo [WARN] Adaptive Claude/Cline profile had warnings ) else ( echo [OK] Adaptive Claude/Cline profile checked )
) else ( echo [SKIP] adaptive-claude-cline-profile.ps1 not found )

REM === Phase 9.5: Workspace State Warning ===
for /f "tokens=*" %%i in ('pwsh -NoProfile -Command "if (git status --short 2>$null) { 'dirty' } else { 'clean' }"') do set WORKSPACE_STATE=%%i
if "!WORKSPACE_STATE!"=="dirty" (
    echo [WARN] =====================================================================
    echo [WARN]  Workspace has uncommitted changes from a previous session.
    echo [WARN]  Run 'git status' to review, or 'git stash' to shelve them.
    echo [WARN] =====================================================================
)

REM === Phase 10: Watchtower Quick Check ===
echo [10/10] Watchtower quick health check...
set WATCHTOWER_SCRIPT=%WF_DIR%\..\watchtower.ps1
if exist "%WATCHTOWER_SCRIPT%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%WATCHTOWER_SCRIPT%" -Quiet
    if errorlevel 1 ( echo [WARN] Watchtower detected issues - run 'foundation watchtower' for details ) else ( echo [OK] Watchtower all clear )
) else ( echo [SKIP] watchtower.ps1 not found )

echo.
echo === Session Autostart Complete ===
echo [READY] Workspace ready for operations
exit /b 0
