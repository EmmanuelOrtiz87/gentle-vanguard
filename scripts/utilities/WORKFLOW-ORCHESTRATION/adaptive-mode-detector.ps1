<#
.SYNOPSIS
    Adaptive Mode Detector - Detección automática de complejidad de tareas
    
.DESCRIPTION
    Analiza la descripción de una tarea y detecta si requiere Adaptive Mode Mejorado.
    Activa automáticamente Adaptive Mode cuando se detectan indicadores de alta complejidad.
    
.PARAMETER TaskDescription
    Descripción de la tarea a analizar
    
.PARAMETER ConfigPath
    Ruta al archivo de configuración del orquestador (default: config/orchestrator.json)
    
.PARAMETER AutoActivate
    Si es $true, activa automáticamente Adaptive Mode si se detecta complejidad alta
    
.PARAMETER Verbose
    Mostrar información detallada del análisis
    
.EXAMPLE
    .\adaptive-mode-detector.ps1 -TaskDescription "Implementar autenticación multi-fase con feedback loops" -AutoActivate
    
.EXAMPLE
    .\adaptive-mode-detector.ps1 -TaskDescription "Bugfix simple" -Verbose
#>

param(
    [string]$TaskDescription = "",
    [string]$ConfigPath = "config/orchestrator.json",
    [switch]$AutoActivate,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

# Indicadores de alta complejidad
$highComplexityIndicators = @(
    'multi-agent', 'multi-phase', 'feedback-loop', 'feedback loops',
    'rollback', 'rollback-required', 'cross-team', 'cross-phase',
    'high-risk', 'high risk', 'complex', 'orchestration',
    'coordination', 'multiple teams', 'multiple agents',
    'dependency', 'dependencies', 'integration', 'end-to-end',
    'e2e', 'quality assurance', 'qa cycle', 'governance',
    'security review', 'compliance', 'audit', 'deployment'
)

# Indicadores de complejidad media
$mediumComplexityIndicators = @(
    'refactor', 'architecture', 'design', 'api', 'database',
    'schema', 'migration', 'performance', 'optimization',
    'testing', 'test coverage', 'documentation', 'specification'
)

# Indicadores de baja complejidad
$lowComplexityIndicators = @(
    'bugfix', 'bug fix', 'hotfix', 'patch', 'typo',
    'simple', 'minor', 'quick', 'small', 'trivial'
)

function Analyze-TaskComplexity {
    param([string]$Description)
    
    $description = $Description.ToLower()
    $highScore = 0
    $mediumScore = 0
    $lowScore = 0
    
    # Contar indicadores de complejidad
    foreach ($indicator in $highComplexityIndicators) {
        if ($description -match [regex]::Escape($indicator)) {
            $highScore++
        }
    }
    
    foreach ($indicator in $mediumComplexityIndicators) {
        if ($description -match [regex]::Escape($indicator)) {
            $mediumScore++
        }
    }
    
    foreach ($indicator in $lowComplexityIndicators) {
        if ($description -match [regex]::Escape($indicator)) {
            $lowScore++
        }
    }
    
    # Calcular puntuación total
    $totalScore = ($highScore * 3) + ($mediumScore * 1) + ($lowScore * -1)
    
    # Determinar nivel de complejidad
    $complexity = if ($highScore -ge 2 -or $totalScore -ge 5) {
        'high'
    } elseif ($mediumScore -ge 2 -or $totalScore -ge 2) {
        'medium'
    } else {
        'low'
    }
    
    return @{
        complexity = $complexity
        high_score = $highScore
        medium_score = $mediumScore
        low_score = $lowScore
        total_score = $totalScore
        high_indicators = @($highComplexityIndicators | Where-Object { $description -match [regex]::Escape($_) })
        medium_indicators = @($mediumComplexityIndicators | Where-Object { $description -match [regex]::Escape($_) })
    }
}

function Get-OrchestratorConfig {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $null
    }
    
    try {
        return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to read orchestrator config: $_"
        return $null
    }
}

function Update-AdaptiveModeStatus {
    param(
        [string]$ConfigPath,
        [bool]$Enabled,
        [string]$Reason
    )
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "Config file not found: $ConfigPath"
        return $false
    }
    
    try {
        $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        if (-not $config.adaptive_mode) {
            $config | Add-Member -NotePropertyName 'adaptive_mode' -NotePropertyValue @{}
        }
        
        $config.adaptive_mode.enabled = $Enabled
        $config.adaptive_mode.auto_detected = $true
        $config.adaptive_mode.detection_reason = $Reason
        $config.adaptive_mode.detected_at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        return $true
    } catch {
        Write-Warning "Failed to update adaptive mode status: $_"
        return $false
    }
}

# Análisis principal
if ([string]::IsNullOrWhiteSpace($TaskDescription)) {
    Write-Host "[INFO] No task description provided. Skipping complexity analysis." -ForegroundColor Gray
    exit 0
}

if ($Verbose) {
    Write-Host "[ANALYSIS] Analyzing task complexity..." -ForegroundColor Cyan
    Write-Host "[ANALYSIS] Task: $TaskDescription" -ForegroundColor Gray
}

$analysis = Analyze-TaskComplexity -Description $TaskDescription

if ($Verbose) {
    Write-Host "[ANALYSIS] Complexity Level: $($analysis.complexity)" -ForegroundColor Cyan
    Write-Host "[ANALYSIS] High Indicators Found: $($analysis.high_score)" -ForegroundColor Gray
    Write-Host "[ANALYSIS] Medium Indicators Found: $($analysis.medium_score)" -ForegroundColor Gray
    Write-Host "[ANALYSIS] Total Score: $($analysis.total_score)" -ForegroundColor Gray
    
    if ($analysis.high_indicators.Count -gt 0) {
        Write-Host "[ANALYSIS] High Complexity Indicators:" -ForegroundColor Yellow
        foreach ($indicator in $analysis.high_indicators) {
            Write-Host "  - $indicator" -ForegroundColor Yellow
        }
    }
}

# Determinar si se debe activar Adaptive Mode
$shouldActivate = $analysis.complexity -eq 'high'
$reason = if ($shouldActivate) {
    "High complexity detected: $($analysis.high_score) high-complexity indicators found"
} else {
    "Complexity level is $($analysis.complexity) - Adaptive Mode not required"
}

if ($Verbose) {
    Write-Host "[DECISION] Should Activate Adaptive Mode: $shouldActivate" -ForegroundColor Cyan
    Write-Host "[DECISION] Reason: $reason" -ForegroundColor Gray
}

# Actualizar configuración si se solicita
if ($AutoActivate -and $shouldActivate) {
    $configFullPath = Join-Path $repoRoot $ConfigPath
    if (Update-AdaptiveModeStatus -ConfigPath $configFullPath -Enabled $true -Reason $reason) {
        Write-Host "[SUCCESS] Adaptive Mode activated automatically" -ForegroundColor Green
        Write-Host "[SUCCESS] Reason: $reason" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Failed to activate Adaptive Mode" -ForegroundColor Yellow
    }
}

# Retornar resultado en formato JSON
$result = @{
    complexity = $analysis.complexity
    should_activate_adaptive_mode = $shouldActivate
    reason = $reason
    high_complexity_indicators_count = $analysis.high_score
    medium_complexity_indicators_count = $analysis.medium_score
    detected_indicators = @{
        high = $analysis.high_indicators
        medium = $analysis.medium_indicators
    }
}

$result | ConvertTo-Json -Depth 5

exit 0