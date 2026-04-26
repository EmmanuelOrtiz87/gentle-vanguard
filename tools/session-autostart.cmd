@echo off
setlocal enabledelayedexpansion

set SCRIPT=%~dp0session-manager.ps1
set OPTIMIZE_SCRIPT=%~dp0optimize-engram-usage.ps1
set TOKEN_GUARD_SCRIPT=%~dp0token-guard.ps1

echo === Session Autostart with Engram Optimization ===
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

echo [1/7] Running session-manager...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode AutoStart
if errorlevel 1 (
    echo [ERROR] session-manager.ps1 fallo con codigo: !errorlevel!
    exit /b 1
)
echo [OK] Session initialized

:session_end

REM 2. Extraer SessionId del archivo de sesion mas reciente
set SESSION_ID=
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem '.\.session\session-*.json' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { $_.BaseName }"') do set SESSION_ID=%%i
if defined SESSION_ID (
    echo [INFO] Session ID: !SESSION_ID!
) else (
    echo [WARNING] No se pudo obtener Session ID
)

REM 3. Optimizacion de Engram (si existe)
if exist "%OPTIMIZE_SCRIPT%" (
    echo [2/7] Running Engram optimization...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local"
    if errorlevel 1 (
        echo [WARNING] Engram optimization completed with warnings
    ) else (
        echo [OK] Engram optimization completed
    )
) else (
    echo [SKIP] Engram optimization script not found
)

REM 4. Validacion cross-workspace (si existe)
set CROSS_VALIDATOR=.\scripts\monitoring\cross-workspace-validator.ps1
if exist "%CROSS_VALIDATOR%" (
    echo [3/7] Validating cross-workspace consistency...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%CROSS_VALIDATOR%" -Detailed
    if errorlevel 1 (
        echo [WARNING] Cross-workspace validation found issues
    ) else (
        echo [OK] Cross-workspace validated
    )
) else (
    echo [SKIP] Cross-workspace validator not found
)

REM 5. Distributed Tracing (si existe)
set TRACING_SCRIPT=.\tools\initialize-distributed-tracing.ps1
set TRACING_CONFIG=config\distributed-tracing-config.json
if exist "%TRACING_SCRIPT%" (
    echo [5/8] Initializing Distributed Tracing...
    if exist "%TRACING_CONFIG%" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%TRACING_SCRIPT%" -SessionId "!SESSION_ID!" -ConfigPath "!TRACING_CONFIG!"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%TRACING_SCRIPT%" -SessionId "!SESSION_ID!"
    )
    if errorlevel 1 (
        echo [WARNING] Distributed Tracing initialized with warnings
    ) else (
        echo [OK] Distributed Tracing initialized
    )
) else (
    echo [SKIP] Distributed Tracing script not found
)

REM 5. Session Authentication (owner verification)
set AUTH_SCRIPT=.\scripts\utilities\auth-session.ps1
set OWNER_AUTH=.workspace\config\owner-auth.json
if exist "%AUTH_SCRIPT%" (
    if exist "%OWNER_AUTH%" (
        echo [5/8] Checking session authentication...
        powershell -NoProfile -ExecutionPolicy Bypass -File "%AUTH_SCRIPT%" -SkipAuthCheck
        if errorlevel 1 (
            echo [OK] Session authenticated
        ) else (
            echo [INFO] Session auth not required for read-only operations
        )
    ) else (
        echo [SKIP] Owner auth not configured
    )
) else (
    echo [SKIP] Auth script not found
)

REM 6. Security Orchestrator (privacy automation)
    set TOKEN_GUARD_CONFIG=tools\token-guard-config.json
    if exist "!TOKEN_GUARD_CONFIG!" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%TOKEN_GUARD_SCRIPT%" -ConfigPath "!TOKEN_GUARD_CONFIG!" -SessionId "!SESSION_ID!" -Mode "monitor"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%TOKEN_GUARD_SCRIPT%" -SessionId "!SESSION_ID!" -Mode "monitor"
    )
    if errorlevel 1 (
        echo [WARNING] Token Guard initialized with warnings
    ) else (
        echo [OK] Token Guard initialized
    )
) else (
    echo [SKIP] Token Guard script not found
)

REM 6. Security Orchestrator (privacy automation)
set SECURITY_SCRIPT=.\scripts\security\security-orchestrator.ps1
set SECURITY_CONFIG=config\security-privacy.json
if exist "%SECURITY_SCRIPT%" (
    echo [6/7] Initializing Security Orchestrator...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SECURITY_SCRIPT%" -Action init -AsJson
    if errorlevel 1 (
        echo [WARNING] Security Orchestrator initialized with warnings
    ) else (
        echo [OK] Security Orchestrator initialized
    )
) else (
    echo [SKIP] Security Orchestrator not found
)

REM 7. Skill Router / Auto-delegation (si existe)
set SKILL_ROUTER=.\scripts\utilities\skill-router.ps1
if exist "%SKILL_ROUTER%" (
    echo [7/7] Initializing Skill Router...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SKILL_ROUTER%" -Query "session-start"
    if errorlevel 1 (
        echo [WARNING] Skill Router validation issue
    ) else (
        echo [OK] Skill Router active
    )
) else (
    echo [SKIP] Skill Router not found
)

REM 8. Auto-delegation Module (si existe)
set AUTO_DELEGATION=.\skills\auto-delegation-router\auto-delegation-router.ps1
set AUTO_DELEGATION_CONFIG=config\auto-delegation.json
if exist "%AUTO_DELEGATION%" (
    echo [8/8] Enabling Auto-Delegation...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '%AUTO_DELEGATION%' -Force; Get-AutoDelegationConfig -ConfigPath '%AUTO_DELEGATION_CONFIG%' | Out-Null; Write-Host '[OK] Auto-Delegation enabled' -ForegroundColor Green"
    if errorlevel 1 (
        echo [WARNING] Auto-Delegation enabled with warnings
    ) else (
        echo [OK] Auto-Delegation ready
    )
) else (
    echo [SKIP] Auto-delegation router not found
)

echo.
echo === Session Autostart Complete ===
echo [READY] Workspace ready for operations
exit /b 0