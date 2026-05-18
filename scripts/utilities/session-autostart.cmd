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

REM === Phase 0.5: Tool Detection (CRITICAL) ===
echo [0.5/10] Detecting tool/plugin...
set TOOL_DETECTION=%UTILS_DIR%\detect-tool.ps1
if exist "%TOOL_DETECTION%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ^
      "$json=& '%TOOL_DETECTION%' -AsJson | ConvertFrom-Json;" ^
      "$tool=$json.name;" ^
      "$platform=$json.os.platform;" ^
      "$config=$json.configFile;" ^
      "$prompt=$json.promptFile;" ^
      "$confidence=$json.confidence;" ^
      "[Environment]::SetEnvironmentVariable('GENTLE_VANGUARD_TOOL',$tool,'Process');" ^
      "[Environment]::SetEnvironmentVariable('GENTLE_VANGUARD_TOOL_CONFIG',$config,'Process');" ^
      "[Environment]::SetEnvironmentVariable('GENTLE_VANGUARD_TOOL_PROMPT',$prompt,'Process');" ^
      "[Environment]::SetEnvironmentVariable('GENTLE_VANGUARD_TOOL_CONFIDENCE',$confidence,'Process');" ^
      "Write-Host '[DETECT] Tool: ' -NoNewline -ForegroundColor Cyan;" ^
      "Write-Host $tool -NoNewline -ForegroundColor White;" ^
      "Write-Host (' (conf: ' + $confidence + ', platform: ' + $platform + ')') -ForegroundColor Gray;" ^
      "if ($tool -eq 'opencode') { Write-Host '[DETECT] Loading opencode profile...' -ForegroundColor Cyan }"
    if errorlevel 1 ( echo [WARN] Tool detection had issues ) else ( echo [OK] Tool detected and configuration loaded )
) else (
    echo [WARN] detect-tool.ps1 not found - using default configuration
)
echo.

REM === Phase 0.75: Orphan Session Cleanup ===
echo [0.75/10] Checking for orphaned sessions...
pwsh -NoProfile -ExecutionPolicy Bypass -Command ^
  "$stateFile='%WORKSPACE_ROOT%\.session\state.json';" ^
  "$activeFile='%WORKSPACE_ROOT%\logs\.session-active';" ^
  "$dayEnd='%WORKSPACE_ROOT%\scripts\utilities\session-manual-end.ps1';" ^
  "$orphan=$false;" ^
  "$sid='';" ^
  "if (Test-Path $stateFile) { try { $d=Get-Content $stateFile -Raw|ConvertFrom-Json; if ($d.status -eq 'active') { $orphan=$true; $sid=$d.sessionId } } catch {} };" ^
  "if (-not $orphan -and (Test-Path $activeFile)) { $orphan=$true; try { $d=Get-Content $activeFile -Raw|ConvertFrom-Json; $sid=$d.SessionId } catch {} };" ^
  "if ($orphan) { Write-Host '[WARN] Orphaned session detected: ' -NoNewline -ForegroundColor Yellow; if ($sid) { Write-Host $sid -ForegroundColor Yellow } else { Write-Host 'unknown' -ForegroundColor Yellow }; Write-Host '[INFO] Auto-closing orphan before new start...' -ForegroundColor Cyan; if (Test-Path $dayEnd) { & $dayEnd -SessionId $sid -Force -SkipValidation -SkipRotation -Quiet; Write-Host '[OK] Orphan session closed' -ForegroundColor Green } } else { Write-Host '[OK] No orphaned sessions found' -ForegroundColor Green }"
if errorlevel 1 ( echo [WARN] Orphan cleanup had issues ) else ( echo [OK] Orphan check complete )

REM === Phase 1: Session Manager ===
echo [1/10] Initializing session manager...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\session-manager.ps1" -Mode AutoStart
set SESSION_MANAGER_EXIT=%ERRORLEVEL%
if "%SESSION_MANAGER_EXIT%"=="0" goto session_manager_ok
echo [ERROR] session-manager.ps1 failed (code: %SESSION_MANAGER_EXIT%)
echo [FALLBACK] Attempting gv.ps1...
if exist "%UTILS_DIR%\gv.ps1" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\gv.ps1" start-session
) else (
    echo [FATAL] No fallback available. Aborting.
    exit /b 1
)
goto session_manager_done

:session_manager_ok
echo [OK] Session initialized

:session_manager_done

REM === Phase 2: Notifications ===
echo [2/10] Time-based notifications...
if exist "%UTILS_DIR%\session-notification.ps1" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\session-notification.ps1" -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15 -Region "Argentina"
    if errorlevel 1 ( echo [WARN] Notification check had warnings ) else ( echo [OK] Notifications checked )
) else ( echo [SKIP] session-notification.ps1 not found )

REM === Phase 3: Session ID ===
echo [3/10] Resolving session ID...
set SESSION_ID=
for /f "tokens=*" %%i in ('pwsh -NoProfile -ExecutionPolicy Bypass -File "%UTILS_DIR%\get-session-id.ps1"') do set SESSION_ID=%%i
if defined SESSION_ID (
    set GENTLE_VANGUARD_SESSION_ID=%SESSION_ID%
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
echo [4/10] Engram policy enforcement...
set ENGRAM_DATA_DIR=%WORKSPACE_ROOT%\.engram-data
set ENGRAM_POLICY=%UTILS_DIR%\engram-policy.ps1
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
echo [5/10] Engram optimization...
set OPTIMIZE_SCRIPT=%WORKSPACE_ROOT%\scripts\utilities\PERFORMANCE-OPTIMIZATION\optimize-engram-usage.ps1
if exist "%OPTIMIZE_SCRIPT%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_gentle_vanguard"
    if errorlevel 1 ( echo [WARN] Optimization had warnings ) else ( echo [OK] Engram optimized )
) else ( echo [SKIP] optimize-engram-usage.ps1 not found )

REM === Phase 6: Skill Registry Build ===
echo [6/10] Skill registry...
set SKILL_REGISTRY=%UTILS_DIR%\build-skill-registry.ps1
if exist "%SKILL_REGISTRY%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%SKILL_REGISTRY%" -Quiet
    if errorlevel 1 ( echo [WARN] Skill registry build had issues ) else ( echo [OK] Skill registry built )
) else ( echo [SKIP] build-skill-registry.ps1 not found )

REM === Phase 7: Plugin System Initialization ===
echo [7/10] Initializing plugin system...
set PLUGIN_LOADER=%UTILS_DIR%\SKILLS-TOOLS\plugin-loader.ps1
if exist "%PLUGIN_LOADER%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -Command ^
      ". '%PLUGIN_LOADER%';" ^
      "$r=Initialize-Plugins -Quiet;" ^
      "Write-Host ('[PLUGIN] Loaded: ' + $r.loaded + ', failed: ' + $r.failed + ', total: ' + $r.total) -ForegroundColor Cyan;" ^
      "[Environment]::SetEnvironmentVariable('GENTLE_VANGUARD_PLUGINS_LOADED',$r.loaded,'Process');" ^
      "[Environment]::SetEnvironmentVariable('GENTLE_VANGUARD_PLUGINS_TOTAL',$r.total,'Process')"
    if errorlevel 1 ( echo [WARN] Plugin initialization had issues ) else ( echo [OK] Plugin system initialized )
) else ( echo [SKIP] plugin-loader.ps1 not found )

REM === Phase 8: Enhanced Tool/Adapter Detection ===
echo [8/10] Running enhanced tool/adapter detection...
set ENHANCED_DETECT=%WORKSPACE_ROOT%\adapters\detection\enhanced-detect.ps1
if exist "%ENHANCED_DETECT%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%ENHANCED_DETECT%" -AsJson -Quiet > "%WORKSPACE_ROOT%\.session\enhanced-detect-result.json" 2>&1
    if errorlevel 1 ( echo [WARN] Enhanced detection had issues ) else (
        pwsh -NoProfile -ExecutionPolicy Bypass -Command ^
          "$j=Get-Content '%WORKSPACE_ROOT%\.session\enhanced-detect-result.json' -Raw | ConvertFrom-Json;" ^
          "Write-Host ('[DETECT] Tool: ' + $j.toolName + ' | MCP: ' + $j.adapterStatus.mcpBridge.available + ' | Adapter: ' + $j.adapterStatus.formatAdapter.available) -ForegroundColor Cyan"
        echo [OK] Enhanced detection complete
    )
) else ( echo [SKIP] enhanced-detect.ps1 not found - adapter detection not available )

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

REM === Phase 9.4: Adaptive Cursor Profile ===
echo [9.4/10] Adaptive Cursor profile...
set ADAPTIVE_CURSOR=%UTILS_DIR%\adaptive-cursor-profile.ps1
if exist "%ADAPTIVE_CURSOR%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%ADAPTIVE_CURSOR%" -Mode Auto -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15
    if errorlevel 1 ( echo [WARN] Adaptive Cursor profile had warnings ) else ( echo [OK] Adaptive Cursor profile checked )
) else ( echo [SKIP] adaptive-cursor-profile.ps1 not found )

REM === Phase 9.45: Adaptive Continue/Copilot Profile ===
echo [9.45/10] Adaptive Continue/Copilot profile...
set ADAPTIVE_CONTINUE=%UTILS_DIR%\adaptive-continue-copilot-profile.ps1
if exist "%ADAPTIVE_CONTINUE%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%ADAPTIVE_CONTINUE%" -Mode Auto -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15
    if errorlevel 1 ( echo [WARN] Adaptive Continue/Copilot profile had warnings ) else ( echo [OK] Adaptive Continue/Copilot profile checked )
) else ( echo [SKIP] adaptive-continue-copilot-profile.ps1 not found )

REM === Phase 9.5: Workspace State Warning ===
set WORKSPACE_STATE=unknown
set DIRTY_STATE_SCRIPT=%UTILS_DIR%\get-workspace-dirty-state.ps1
if exist "%DIRTY_STATE_SCRIPT%" (
    for /f "tokens=*" %%i in ('pwsh -NoProfile -ExecutionPolicy Bypass -File "%DIRTY_STATE_SCRIPT%" -RepoRoot "%WORKSPACE_ROOT%"') do set WORKSPACE_STATE=%%i
) else (
    for /f "tokens=*" %%i in ('pwsh -NoProfile -Command "if (git status --short 2>$null) { 'dirty-user' } else { 'clean' }"') do set WORKSPACE_STATE=%%i
)

if "!WORKSPACE_STATE!"=="dirty-user" (
    echo [WARN] =====================================================================
    echo [WARN]  Workspace has uncommitted changes from a previous session.
    echo [WARN]  Run 'git status' to review, or 'git stash' to shelve them.
    echo [WARN] =====================================================================
)
if "!WORKSPACE_STATE!"=="dirty-operational" (
    echo [INFO] Workspace has operational auto-managed changes; no user action required.
)
if "!WORKSPACE_STATE!"=="clean" (
    echo [OK] Workspace clean
)

REM === Phase 10: Watchtower Quick Check ===
echo [10/10] Watchtower quick health check...
set WATCHTOWER_SCRIPT=%UTILS_DIR%\watchtower.ps1
if exist "%WATCHTOWER_SCRIPT%" (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%WATCHTOWER_SCRIPT%" -Quiet
    if errorlevel 1 ( echo [WARN] Watchtower detected issues - run 'gv watchtower' for details ) else ( echo [OK] Watchtower all clear )
) else ( echo [SKIP] watchtower.ps1 not found )

echo.
echo === Session Autostart Complete ===
echo [READY] Workspace ready for operations
exit /b 0

