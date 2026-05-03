# failure-learning-system.ps1
# Sistema de aprendizaje y criterio ante fallos de configuración
# Normaliza el comportamiento autónomo ante situaciones anormales

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('record', 'learn', 'apply-criteria', 'diagnose', 'report')]
    [string]$Action,
    
    [string]$FailureType,
    [string]$Context,
    [string]$Resolution,
    [string]$LearningDb = "C:\Workspace_local\workspace-foundation\scripts\adaptive\.failure-learning.json"
)

$ErrorActionPreference = "Continue"

# Inicializar base de datos de aprendizaje
function Initialize-LearningDb {
    if (-not (Test-Path $LearningDb)) {
        $initialData = @{
            failures = @()
            criteria = @{
                autonomous_actions = @{
                    engram_not_installed = @{ action = "install"; confidence = 0.95; min_occurrences = 2 }
                    engram_not_running = @{ action = "start"; confidence = 0.90; min_occurrences = 1 }
                    engram_corrupted = @{ action = "repair"; confidence = 0.85; min_occurrences = 1 }
                    config_mismatch = @{ action = "fix"; confidence = 0.80; min_occurrences = 2 }
                    path_not_found = @{ action = "relocate"; confidence = 0.75; min_occurrences = 1 }
                }
                escalation_rules = @{
                    max_retries = 3
                    retry_delay_seconds = 5
                    escalate_to = "manual-intervention"
                }
            }
            learned_patterns = @()
            last_updated = Get-Date -Format "o"
        }
        $initialData | ConvertTo-Json -Depth 10 | Set-Content $LearningDb
        Write-Host "[LEARNING] Initialized learning database" -ForegroundColor Green
    }
}

# Registrar un fallo
function Record-Failure {
    param(
        [string]$Type,
        [string]$Ctx,
        [string]$Res
    )
    
    Initialize-LearningDb
    $data = Get-Content $LearningDb -Raw | ConvertFrom-Json
    
    $failure = @{
        timestamp = Get-Date -Format "o"
        type = $Type
        context = $Ctx
        resolution = $Res
        session = $env:SESSION_ID
        autonomous = $false
        success = $false
    }
    
    $data.failures += $failure
    $data.last_updated = Get-Date -Format "o"
    $data | ConvertTo-Json -Depth 10 | Set-Content $LearningDb
    
    Write-Host "[LEARNING] Recorded failure: $Type" -ForegroundColor Yellow
}

# Aprender de fallos pasados
function Learn-FromFailures {
    Initialize-LearningDb
    $data = Get-Content $LearningDb -Raw | ConvertFrom-Json
    
    if ($data.failures.Count -eq 0) {
        Write-Host "[LEARNING] No failures recorded yet" -ForegroundColor Gray
        return
    }
    
    # Agrupar por tipo
    $grouped = $data.failures | Group-Object type
    
    foreach ($group in $grouped) {
        $type = $group.Name
        $count = $group.Count
        $successRate = ($group.Group | Where-Object { $_.success -eq $true }).Count / $count
        
        Write-Host "[LEARNING] Pattern: $type (occurrences: $count, success rate: $([math]::Round($successRate * 100))%)" -ForegroundColor Cyan
        
        # Actualizar criterio basado en aprendizaje
        if ($count -ge 3) {
            $criteria = $data.criteria.autonomous_actions.$type
            if ($criteria) {
                if ($successRate -gt 0.8) {
                    $criteria.confidence = [math]::Min(0.99, $criteria.confidence + 0.05)
                    Write-Host "  Updated confidence to: $($criteria.confidence)" -ForegroundColor Green
                } elseif ($successRate -lt 0.5) {
                    $criteria.confidence = [math]::Max(0.5, $criteria.confidence - 0.10)
                    Write-Host "  Reduced confidence to: $($criteria.confidence)" -ForegroundColor Yellow
                }
            }
        }
    }
    
    $data.last_updated = Get-Date -Format "o"
    $data | ConvertTo-Json -Depth 10 | Set-Content $LearningDb
    Write-Host "[LEARNING] Learning cycle completed" -ForegroundColor Green
}

# Aplicar criterio para decidir acción autónoma
function Apply-Criteria {
    param([string]$FailureType)
    
    Initialize-LearningDb
    $data = Get-Content $LearningDb -Raw | ConvertFrom-Json
    
    $criteria = $data.criteria.autonomous_actions.$FailureType
    if (-not $criteria) {
        Write-Host "[CRITERIA] No criteria found for: $FailureType" -ForegroundColor Yellow
        return $null
    }
    
    # Verificar si se debe actuar autónomamente
    $recentFailures = $data.failures | Where-Object { $_.type -eq $FailureType } | 
                      Where-Object { (Get-Date) - (Get-Date $_.timestamp).TotalHours -lt 24 }
    
    if ($recentFailures.Count -ge $criteria.min_occurrences) {
        Write-Host "[CRITERIA] AUTONOMOUS ACTION APPROVED: $($criteria.action)" -ForegroundColor Green
        Write-Host "  Confidence: $($criteria.confidence)" -ForegroundColor Cyan
        Write-Host "  Recent occurrences: $($recentFailures.Count)" -ForegroundColor Cyan
        return $criteria.action
    } else {
        Write-Host "[CRITERIA] Not enough occurrences for autonomous action" -ForegroundColor Yellow
        return $null
    }
}

# Diagnosticar situación anormal
function Diagnose-AbnormalSituation {
    param([string]$Context)
    
    Write-Host "[DIAGNOSE] Analyzing: $Context" -ForegroundColor Cyan
    
    $diagnosis = @{
        is_abnormal = $false
        severity = "normal"
        recommended_action = $null
        learning_applied = $false
    }
    
    # Detectar patrones anormales
    switch -Regex ($Context) {
        'engram.*not.*found' {
            $diagnosis.is_abnormal = $true
            $diagnosis.severity = "high"
            $diagnosis.recommended_action = Apply-Criteria -FailureType "path_not_found"
            $diagnosis.learning_applied = $true
        }
        'config.*mismatch|AGENTS\.md.*differ' {
            $diagnosis.is_abnormal = $true
            $diagnosis.severity = "medium"
            $diagnosis.recommended_action = "fix-config"
            $diagnosis.learning_applied = $true
        }
        'version.*mismatch' {
            $diagnosis.is_abnormal = $true
            $diagnosis.severity = "low"
            $diagnosis.recommended_action = "update"
        }
    }
    
    return $diagnosis
}

# Generar reporte
function Get-LearningReport {
    Initialize-LearningDb
    $data = Get-Content $LearningDb -Raw | ConvertFrom-Json
    
    Write-Host "`n=== FAILURE LEARNING REPORT ===" -ForegroundColor Cyan
    Write-Host "Last updated: $($data.last_updated)" -ForegroundColor Gray
    
    Write-Host "`n--- Failure Statistics ---" -ForegroundColor Yellow
    $grouped = $data.failures | Group-Object type
    foreach ($group in $grouped) {
        $successCount = ($group.Group | Where-Object { $_.success -eq $true }).Count
        Write-Host "  $($group.Name): $($group.Count) occurrences, $successCount successful" -ForegroundColor White
    }
    
    Write-Host "`n--- Autonomous Criteria ---" -ForegroundColor Yellow
    $data.criteria.autonomous_actions.PSObject.Properties | ForEach-Object {
        $action = $_.Name
        $config = $_.Value
        Write-Host "  $action => $($config.action) (confidence: $($config.confidence), min_occurrences: $($config.min_occurrences))" -ForegroundColor White
    }
    
    Write-Host "`n--- Learned Patterns ---" -ForegroundColor Yellow
    foreach ($pattern in $data.learned_patterns) {
        Write-Host "  $($pattern.type): $($pattern.description)" -ForegroundColor White
    }
}

# Ejecutar acción
switch ($Action) {
    'record' {
        Record-Failure -Type $FailureType -Ctx $Context -Res $Resolution
    }
    'learn' {
        Learn-FromFailures
    }
    'apply-criteria' {
        $action = Apply-Criteria -FailureType $FailureType
        if ($action) {
            Write-Host "[RESULT] Recommended action: $action" -ForegroundColor Green
        }
    }
    'diagnose' {
        $diagnosis = Diagnose-AbnormalSituation -Context $Context
        Write-Host "[DIAGNOSIS] Is abnormal: $($diagnosis.is_abnormal)" -ForegroundColor Cyan
        Write-Host "  Severity: $($diagnosis.severity)" -ForegroundColor Cyan
        Write-Host "  Recommended action: $($diagnosis.recommended_action)" -ForegroundColor Cyan
    }
    'report' {
        Get-LearningReport
    }
}
