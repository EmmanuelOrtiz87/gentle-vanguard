@echo off
setlocal

set SCRIPT=%~dp0session-manager.ps1
set OPTIMIZE_SCRIPT=%~dp0optimize-engram-usage.ps1
set TOKEN_GUARD_SCRIPT=%~dp0token-guard.ps1

echo === Session Autostart with Engram Optimization ===
echo.
echo.

REM 1. Validar y ejecutar session-manager
if not exist "%SCRIPT%" (
    echo [ERROR] session-manager.ps1 not found: %SCRIPT%
    echo [FALLBACK] Intentando wf.ps1...
    if exist ".\scripts\utilities\wf.ps1" (
        powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\utilities\wf.ps1" start-session
    ) else (
        echo [ERROR] No se encontro metodo alternativo de inicio de sesion
        exit /b 1
    )
    goto :session_end
)

echo [1/8] Running session-manager...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode AutoStart
if errorlevel 1 (
    echo [ERROR] session-manager.ps1 fallo con codigo: %errorlevel%
    exit /b 1
)
echo [OK] Session initialized

REM 2. Mostrar notificacion de zona horaria (configurable)
set NOTIFICATION_SCRIPT=%~dp0session-notification.ps1
if exist "%NOTIFICATION_SCRIPT%" (
    echo [2/8] Checking time-based notifications...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%NOTIFICATION_SCRIPT%" -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15 -Region "Argentina"
) else (
    echo [SKIP] Notification script not found
)

REM 3. Extraer SessionId del archivo de sesion mas reciente
set SESSION_ID=
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0get-session-id.ps1"') do set SESSION_ID=%%i
if defined SESSION_ID (
    echo [3/8] Session ID: %SESSION_ID%
) else (
    echo [WARNING] No se pudo obtener Session ID
)

REM 4. Engram Policy Enforcement
set ENGRAM_POLICY=%~dp0..\foundation\engram-policy.ps1
set ENGRAM_ORCHESTRATOR=%~dp0engram-orchestrator.ps1
set FAILURE_LEARNING=%~dp0..\adaptive\failure-learning-system.ps1

if exist "%ENGRAM_POLICY%" (
    echo [4/8] Enforcing Engram policy ^(always installed and active^)...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGRAM_POLICY%" -Action enforce
    if errorlevel 1 (
        echo [WARNING] Engram policy enforcement found issues, running orchestrator...
        if exist "%ENGRAM_ORCHESTRATOR%" (
            powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGRAM_ORCHESTRATOR%" -Action orchestrate
        )
    ) else (
        echo [OK] Engram policy enforced - engram active
    )
) else (
    echo [SKIP] Engram policy script not found
)

REM 5. Engram Optimization
if exist "%OPTIMIZE_SCRIPT%" (
    echo [5/8] Running Engram optimization...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local"
    if errorlevel 1 (
        echo [WARNING] Engram optimization completed with warnings
    ) else (
        echo [OK] Engram optimization completed
    )
) else (
    echo [SKIP] Engram optimization script not found
)

REM 6. Validacion cross-workspace
set CROSS_VALIDATOR=.\scripts\monitoring\cross-workspace-validator.ps1
if exist "%CROSS_VALIDATOR%" (
    echo [6/8] Validating cross-workspace consistency...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%CROSS_VALIDATOR%" -Detailed
    if errorlevel 1 (
        echo [WARNING] Cross-workspace validation found issues
    ) else (
        echo [OK] Cross-workspace validated
    )
) else (
    echo [SKIP] Cross-workspace validator not found
)

REM 7. Security Orchestrator
set SECURITY_SCRIPT=.\scripts\security\security-orchestrator.ps1
set SECURITY_CONFIG=config\security-privacy.json
if exist "%SECURITY_SCRIPT%" (
    echo [7/8] Initializing Security Orchestrator...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SECURITY_SCRIPT%" -Action init -AsJson
    if errorlevel 1 (
        echo [WARNING] Security Orchestrator initialized with warnings
    ) else (
        echo [OK] Security Orchestrator initialized
    )
) else (
    echo [SKIP] Security Orchestrator not found
)

REM 8. Skill Router / Auto-delegation
set SKILL_ROUTER=%~dp0skill-router.ps1
if exist "%SKILL_ROUTER%" (
    echo [8/8] Initializing Skill Router...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SKILL_ROUTER%" -Query "session-start"
    if errorlevel 1 (
        echo [WARNING] Skill Router validation issue
    ) else (
        echo [OK] Skill Router active
    )
) else (
    echo [SKIP] Skill Router not found
)

echo.
echo === Session Autostart Complete ===
echo [READY] Workspace ready for operations
exit /b 0

:session_end
echo.
echo === Session Autostart Complete ===
echo [READY] Workspace ready for operations
exit /b 0
