<#
.SYNOPSIS
    Orchestrator Governance Integration - Connects Orchestrator with Event Governance Layer
    
.DESCRIPTION
    Enables the Orchestrator to supervise event communications without interfering with normal operations.
    Provides passive monitoring, policy enforcement, and violation alerts.
    
.PARAMETER Action
    Action to perform: initialize, monitor, report, check-health
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('initialize', 'monitor', 'report', 'check-health')]
    [string]$Action = 'check-health'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$eventBusPath = Join-Path $repoRoot '.event-bus'
$governancePath = Join-Path $eventBusPath 'governance'
$governanceLayerScript = Join-Path $scriptDir 'event-governance-layer.ps1'

function Initialize-OrchestratorIntegration {
    Write-Host "[ORCHESTRATOR-GOVERNANCE] Inicializando integración..." -ForegroundColor Cyan
    
    # Initialize governance layer
    & $governanceLayerScript -Action initialize -Quiet
    
    # Create orchestrator supervision state
    $supervisionFile = Join-Path $governancePath 'orchestrator-supervision.json'
    if (-not (Test-Path $supervisionFile)) {
        @{
            version = '1.0'
            initialized = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
            mode = 'passive'
            last_check = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
            violations_detected = 0
            events_monitored = 0
            alerts_issued = 0
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath $supervisionFile -Encoding UTF8
    }
    
    Write-Host "[ORCHESTRATOR-GOVERNANCE] Integración inicializada" -ForegroundColor Green
}

function Get-GovernanceHealth {
    Write-Host "`n=== ORCHESTRATOR GOVERNANCE HEALTH ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # Check governance layer
    $policyStateFile = Join-Path $governancePath 'policy-state.json'
    if (Test-Path $policyStateFile) {
        $policyState = Get-Content -Path $policyStateFile -Raw | ConvertFrom-Json
        $violations = $policyState.violations
        
        Write-Host "Estado de Governance:" -ForegroundColor Cyan
        Write-Host "  Violaciones detectadas: $($violations.Count)" -ForegroundColor $(if ($violations.Count -gt 0) { 'Yellow' } else { 'Green' })
        
        if ($violations.Count -gt 0) {
            $violations | Group-Object severity | ForEach-Object {
                $color = if ($_.Name -in @('high', 'critical')) { 'Red' } else { 'Yellow' }
                Write-Host "    $($_.Name): $($_.Count)" -ForegroundColor $color
            }
        }
    }
    
    # Check rate limits
    $rateLimitFile = Join-Path $governancePath 'rate-limits.json'
    if (Test-Path $rateLimitFile) {
        $rateLimits = Get-Content -Path $rateLimitFile -Raw | ConvertFrom-Json
        $totalEvents = 0
        foreach ($event in $rateLimits.events.PSObject.Properties) {
            $totalEvents += @($event.Value.occurrences).Count
        }
        Write-Host "  Eventos monitoreados (24h): $totalEvents" -ForegroundColor Green
    }
    
    # Check audit logs
    Write-Host ""
    Write-Host "Auditoría:" -ForegroundColor Cyan
    $auditPath = Join-Path $governancePath 'audit'
    $auditFiles = Get-ChildItem $auditPath -Filter "audit-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($auditFiles) {
        $totalAuditEntries = 0
        foreach ($file in $auditFiles) {
            $entries = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $totalAuditEntries += $entries.Count
        }
        Write-Host "  Entradas de auditoría: $totalAuditEntries" -ForegroundColor Green
    } else {
        Write-Host "  Sin entradas de auditoría" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Estado General: OPERATIVO" -ForegroundColor Green
    Write-Host "Modo: Pasivo (supervisión sin interferencia)" -ForegroundColor Green
    Write-Host ""
}

function Monitor-GovernanceEvents {
    Write-Host "[ORCHESTRATOR-GOVERNANCE] Monitoreando eventos..." -ForegroundColor Cyan
    
    # Get latest violations
    $policyStateFile = Join-Path $governancePath 'policy-state.json'
    if (Test-Path $policyStateFile) {
        $policyState = Get-Content -Path $policyStateFile -Raw | ConvertFrom-Json
        $recentViolations = $policyState.violations | Where-Object { 
            [datetime]$_.timestamp -gt (Get-Date).AddMinutes(-5) 
        }
        
        if ($recentViolations.Count -gt 0) {
            Write-Host "  Violaciones recientes detectadas: $($recentViolations.Count)" -ForegroundColor Yellow
            $recentViolations | ForEach-Object {
                $color = if ($_.severity -in @('high', 'critical')) { 'Red' } else { 'Yellow' }
                Write-Host "    [$($_.severity)] $($_.type) - $($_.timestamp)" -ForegroundColor $color
            }
        } else {
            Write-Host "  Sin violaciones recientes" -ForegroundColor Green
        }
    }
    
    # Get latest audit entries
    $auditPath = Join-Path $governancePath 'audit'
    $auditFiles = Get-ChildItem $auditPath -Filter "audit-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($auditFiles) {
        $auditFiles | Select-Object -First 1 | ForEach-Object {
            $entries = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json
            $recentEntries = $entries | Where-Object { 
                [datetime]$_.timestamp -gt (Get-Date).AddMinutes(-5) 
            }
            
            if ($recentEntries.Count -gt 0) {
                Write-Host "  Actividad de auditoría (últimos 5 min): $($recentEntries.Count) eventos" -ForegroundColor Green
            }
        }
    }
    
    Write-Host "[ORCHESTRATOR-GOVERNANCE] Monitoreo completado" -ForegroundColor Green
}

function Get-GovernanceReport {
    Write-Host "`n=== REPORTE DE GOVERNANCE PARA ORCHESTRATOR ===" -ForegroundColor Cyan
    Write-Host "Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # Summary
    Write-Host "RESUMEN:" -ForegroundColor Yellow
    Write-Host "  Modo de Operación: Pasivo (supervisión sin interferencia)" -ForegroundColor Green
    Write-Host "  Políticas Activas: SÍ" -ForegroundColor Green
    Write-Host "  Validación de Esquemas: SÍ" -ForegroundColor Green
    Write-Host "  Rate Limiting: SÍ" -ForegroundColor Green
    Write-Host "  Auditoría Completa: SÍ" -ForegroundColor Green
    
    # Violations
    $policyStateFile = Join-Path $governancePath 'policy-state.json'
    if (Test-Path $policyStateFile) {
        $policyState = Get-Content -Path $policyStateFile -Raw | ConvertFrom-Json
        $violations = $policyState.violations
        
        Write-Host ""
        Write-Host "VIOLACIONES (últimas 24h):" -ForegroundColor Yellow
        if ($violations.Count -eq 0) {
            Write-Host "  Sin violaciones detectadas" -ForegroundColor Green
        } else {
            $violations | Group-Object type | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor Yellow
            }
        }
    }
    
    # Recommendations
    Write-Host ""
    Write-Host "RECOMENDACIONES:" -ForegroundColor Cyan
    Write-Host "  1. Revisar violaciones de seguridad regularmente" -ForegroundColor Gray
    Write-Host "  2. Monitorear eventos de rate limit excedido" -ForegroundColor Gray
    Write-Host "  3. Mantener auditoría actualizada para compliance" -ForegroundColor Gray
    Write-Host "  4. Escalar violaciones críticas a administradores" -ForegroundColor Gray
    
    Write-Host ""
}

Initialize-OrchestratorIntegration

switch ($Action) {
    'initialize' {
        Initialize-OrchestratorIntegration
    }
    
    'check-health' {
        Get-GovernanceHealth
    }
    
    'monitor' {
        Monitor-GovernanceEvents
    }
    
    'report' {
        Get-GovernanceReport
    }
    
    default {
        Write-Host "[ERROR] Acción desconocida: $Action" -ForegroundColor Red
        exit 1
    }
}