<#
.SYNOPSIS
    Event Governance Layer - Validates, enforces policies, and audits event communications
    
.DESCRIPTION
    Provides a governance layer that sits between the event bus and applications.
    Enforces security policies, validates schemas, implements rate limiting, and maintains audit trails.
    
.PARAMETER Action
    Action to perform: validate, enforce, audit, check-policy, report, initialize
    
.PARAMETER EventName
    Name of the event to validate or check
    
.PARAMETER Payload
    JSON payload of the event
    
.PARAMETER Actor
    The component/agent emitting or listening to the event
    
.PARAMETER ActionType
    Type of action: emit, listen
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('validate', 'enforce', 'audit', 'check-policy', 'report', 'initialize')]
    [string]$Action = 'report',
    
    [Parameter(Mandatory=$false)]
    [string]$EventName = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Payload = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Actor = '',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('emit', 'listen')]
    [string]$ActionType = 'emit',
    
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$eventBusPath = Join-Path $repoRoot '.event-bus'
$governancePath = Join-Path $eventBusPath 'governance'
$auditPath = Join-Path $governancePath 'audit'
$metricsPath = Join-Path $governancePath 'metrics'

$registryPath = Join-Path $repoRoot 'config/event-registry.json'
$governanceConfigPath = Join-Path $repoRoot 'config/event-governance-config.json'

# ======== INITIALIZATION ========

function Initialize-GovernanceLayer {
    Write-Host "[GOVERNANCE] Inicializando Event Governance Layer..." -ForegroundColor Cyan
    
    @($eventBusPath, $governancePath, $auditPath, $metricsPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    $rateLimitFile = Join-Path $governancePath 'rate-limits.json'
    if (-not (Test-Path $rateLimitFile)) {
        @{
            version = '1.0'
            last_reset = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
            events = @{}
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath $rateLimitFile -Encoding UTF8
    }
    
    $policyStateFile = Join-Path $governancePath 'policy-state.json'
    if (-not (Test-Path $policyStateFile)) {
        @{
            version = '1.0'
            violations = @()
            alerts = @()
            last_check = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath $policyStateFile -Encoding UTF8
    }
    
    Write-Host "[GOVERNANCE] Inicialización completada" -ForegroundColor Green
}

# ======== CONFIGURATION LOADING ========

function Get-EventRegistry {
    if (Test-Path $registryPath) {
        return (Get-Content -Path $registryPath -Raw | ConvertFrom-Json)
    }
    return $null
}

function Get-GovernanceConfig {
    if (Test-Path $governanceConfigPath) {
        return (Get-Content -Path $governanceConfigPath -Raw | ConvertFrom-Json)
    }
    return $null
}

# ======== SCHEMA VALIDATION ========

function Test-SchemaCompliance {
    param(
        [string]$EventName,
        [object]$Payload,
        [object]$EventDefinition
    )
    
    if (-not $EventDefinition.schema) {
        return @{ valid = $true; errors = @() }
    }
    
    $errors = @()
    $schema = $EventDefinition.schema
    
    if ($schema.required) {
        foreach ($field in $schema.required) {
            if (-not $Payload.PSObject.Properties[$field]) {
                $errors += "Campo requerido faltante: $field"
            }
        }
    }
    
    if ($schema.properties) {
        foreach ($prop in $schema.properties.PSObject.Properties) {
            $fieldName = $prop.Name
            $fieldDef = $prop.Value
            $fieldValue = $Payload.PSObject.Properties[$fieldName].Value
            
            if ($fieldValue) {
                if ($fieldDef.type -eq 'string' -and -not ($fieldValue -is [string])) {
                    $errors += "Campo '$fieldName' debe ser string"
                }
                elseif ($fieldDef.type -eq 'integer' -and -not ($fieldValue -is [int])) {
                    $errors += "Campo '$fieldName' debe ser integer"
                }
                
                if ($fieldDef.pattern -and $fieldValue -notmatch $fieldDef.pattern) {
                    $errors += "Campo '$fieldName' no coincide con patrón: $($fieldDef.pattern)"
                }
                
                if ($fieldDef.enum -and $fieldValue -notin $fieldDef.enum) {
                    $errors += "Campo '$fieldName' debe ser uno de: $($fieldDef.enum -join ', ')"
                }
            }
        }
    }
    
    return @{
        valid = ($errors.Count -eq 0)
        errors = $errors
    }
}

# ======== PERMISSION CHECKING ========

function Test-EmissionPermission {
    param(
        [string]$Actor,
        [string]$EventName,
        [object]$Registry
    )
    
    $permissions = $Registry.permissions.PSObject.Properties[$Actor]
    if (-not $permissions) {
        return @{ allowed = $false; reason = "Actor '$Actor' no encontrado" }
    }
    
    $canEmit = $permissions.Value.can_emit
    if ($EventName -in $canEmit) {
        return @{ allowed = $true; reason = "Permiso otorgado" }
    }
    
    return @{
        allowed = $false
        reason = "Actor '$Actor' no puede emitir '$EventName'"
    }
}

function Test-ListeningPermission {
    param(
        [string]$Actor,
        [string]$EventName,
        [object]$Registry
    )
    
    $permissions = $Registry.permissions.PSObject.Properties[$Actor]
    if (-not $permissions) {
        return @{ allowed = $false; reason = "Actor '$Actor' no encontrado" }
    }
    
    $canListen = $permissions.Value.can_listen
    if ($EventName -in $canListen) {
        return @{ allowed = $true; reason = "Permiso otorgado" }
    }
    
    return @{
        allowed = $false
        reason = "Actor '$Actor' no puede escuchar '$EventName'"
    }
}

# ======== RATE LIMITING ========

function Test-RateLimit {
    param(
        [string]$EventName,
        [object]$GovernanceConfig
    )
    
    if (-not $GovernanceConfig.governance.rate_limiting.enabled) {
        return @{ allowed = $true; reason = "Rate limiting deshabilitado" }
    }
    
    $rateLimitFile = Join-Path $governancePath 'rate-limits.json'
    $rateLimits = Get-Content -Path $rateLimitFile -Raw | ConvertFrom-Json
    
    $now = Get-Date
    $minuteAgo = $now.AddMinutes(-1)
    $hourAgo = $now.AddHours(-1)
    
    $limits = $GovernanceConfig.governance.rate_limiting.per_event_overrides.PSObject.Properties[$EventName]
    if (-not $limits) {
        return @{ allowed = $true; reason = "Sin límite de rate configurado" }
    }
    
    $maxPerMinute = $limits.Value.max_per_minute
    $maxPerHour = $limits.Value.max_per_hour
    
    if (-not $rateLimits.events.PSObject.Properties[$EventName]) {
        $rateLimits.events | Add-Member -NotePropertyName $EventName -NotePropertyValue @{
            occurrences = @()
        }
    }
    
    $eventOccurrences = $rateLimits.events.PSObject.Properties[$EventName].Value.occurrences
    $recentOccurrences = @($eventOccurrences | Where-Object { [datetime]$_ -gt $hourAgo })
    
    $minuteCount = @($recentOccurrences | Where-Object { [datetime]$_ -gt $minuteAgo }).Count
    if ($minuteCount -ge $maxPerMinute) {
        return @{
            allowed = $false
            reason = "Rate limit excedido: $minuteCount/$maxPerMinute por minuto"
            severity = "high"
        }
    }
    
    if ($recentOccurrences.Count -ge $maxPerHour) {
        return @{
            allowed = $false
            reason = "Rate limit excedido: $($recentOccurrences.Count)/$maxPerHour por hora"
            severity = "high"
        }
    }
    
    $recentOccurrences += (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    $rateLimits.events.PSObject.Properties[$EventName].Value.occurrences = $recentOccurrences
    $rateLimits | ConvertTo-Json -Depth 5 | Out-File -FilePath $rateLimitFile -Encoding UTF8
    
    return @{ allowed = $true; reason = "Dentro de límites" }
}

# ======== AUDIT LOGGING ========

function Add-AuditEntry {
    param(
        [string]$Action,
        [string]$Actor,
        [string]$Resource,
        [string]$Result,
        [object]$Details
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    $auditFile = Join-Path $auditPath "audit-$(Get-Date -Format 'yyyy-MM-dd').json"
    
    $entry = @{
        timestamp = $timestamp
        action = $Action
        actor = $Actor
        resource = $Resource
        result = $Result
        details = $Details
    }
    
    $auditLog = @()
    if (Test-Path $auditFile) {
        $auditLog = Get-Content -Path $auditFile -Raw | ConvertFrom-Json
    }
    
    $auditLog += $entry
    $auditLog | ConvertTo-Json -Depth 5 | Out-File -FilePath $auditFile -Encoding UTF8
}

function Add-Violation {
    param(
        [string]$ViolationType,
        [string]$Severity,
        [object]$Details
    )
    
    $policyStateFile = Join-Path $governancePath 'policy-state.json'
    $policyState = Get-Content -Path $policyStateFile -Raw | ConvertFrom-Json
    
    $violation = @{
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        type = $ViolationType
        severity = $Severity
        details = $Details
    }
    
    $policyState.violations += $violation
    $policyState | ConvertTo-Json -Depth 5 | Out-File -FilePath $policyStateFile -Encoding UTF8
    
    if ($Severity -in @('high', 'critical')) {
        Write-Host "[ALERT] Violación de seguridad: $ViolationType ($Severity)" -ForegroundColor Red
    }
}

# ======== VALIDATION & ENFORCEMENT ========

function Invoke-Validation {
    param(
        [string]$EventName,
        [string]$Payload,
        [string]$Actor,
        [string]$ActionType
    )
    
    $registry = Get-EventRegistry
    $govConfig = Get-GovernanceConfig
    
    if (-not $registry -or -not $govConfig) {
        return @{
            valid = $false
            errors = @("Configuración no disponible")
        }
    }
    
    $eventDef = $registry.registry.PSObject.Properties[$EventName]
    if (-not $eventDef) {
        return @{
            valid = $false
            errors = @("Evento no registrado: $EventName")
        }
    }
    
    $errors = @()
    
    # Permission check
    if ($ActionType -eq 'emit') {
        $permCheck = Test-EmissionPermission -Actor $Actor -EventName $EventName -Registry $registry
        if (-not $permCheck.allowed) {
            $errors += $permCheck.reason
            Add-Violation -ViolationType "unauthorized_emit" -Severity "high" -Details @{
                actor = $Actor
                event = $EventName
                reason = $permCheck.reason
            }
        }
    }
    elseif ($ActionType -eq 'listen') {
        $permCheck = Test-ListeningPermission -Actor $Actor -EventName $EventName -Registry $registry
        if (-not $permCheck.allowed) {
            $errors += $permCheck.reason
            Add-Violation -ViolationType "unauthorized_listen" -Severity "high" -Details @{
                actor = $Actor
                event = $EventName
                reason = $permCheck.reason
            }
        }
    }
    
    # Schema validation
    if ($Payload) {
        try {
            $payloadObj = $Payload | ConvertFrom-Json
            $schemaCheck = Test-SchemaCompliance -EventName $EventName -Payload $payloadObj -EventDefinition $eventDef.Value
            if (-not $schemaCheck.valid) {
                $errors += $schemaCheck.errors
                Add-Violation -ViolationType "schema_invalid" -Severity "medium" -Details @{
                    event = $EventName
                    errors = $schemaCheck.errors
                }
            }
        }
        catch {
            $errors += "Payload JSON inválido: $($_.Exception.Message)"
        }
    }
    
    # Rate limit check
    $rateCheck = Test-RateLimit -EventName $EventName -GovernanceConfig $govConfig
    if (-not $rateCheck.allowed) {
        $errors += $rateCheck.reason
        Add-Violation -ViolationType "rate_limit_exceeded" -Severity $rateCheck.severity -Details @{
            event = $EventName
            reason = $rateCheck.reason
        }
    }
    
    Add-AuditEntry -Action "validation" -Actor $Actor -Resource $EventName -Result $(if ($errors.Count -eq 0) { "success" } else { "failure" }) -Details @{
        action_type = $ActionType
        errors = $errors
    }
    
    return @{
        valid = ($errors.Count -eq 0)
        errors = $errors
    }
}

# ======== REPORTING ========

function Get-GovernanceReport {
    Write-Host "`n=== EVENT GOVERNANCE REPORT ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # Violations
    $policyStateFile = Join-Path $governancePath 'policy-state.json'
    if (Test-Path $policyStateFile) {
        $policyState = Get-Content -Path $policyStateFile -Raw | ConvertFrom-Json
        $violations = $policyState.violations
        
        Write-Host "Violaciones detectadas: $($violations.Count)" -ForegroundColor Yellow
        $violations | Group-Object severity | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $(if ($_.Name -in @('high', 'critical')) { 'Red' } else { 'Yellow' })
        }
    }
    
    # Rate limits
    $rateLimitFile = Join-Path $governancePath 'rate-limits.json'
    if (Test-Path $rateLimitFile) {
        $rateLimits = Get-Content -Path $rateLimitFile -Raw | ConvertFrom-Json
        Write-Host ""
        Write-Host "Rate Limits (últimas 24h):" -ForegroundColor Cyan
        foreach ($event in $rateLimits.events.PSObject.Properties) {
            $count = @($event.Value.occurrences).Count
            Write-Host "  $($event.Name): $count eventos" -ForegroundColor Gray
        }
    }
    
    # Audit entries
    Write-Host ""
    Write-Host "Auditoría (últimas 10 entradas):" -ForegroundColor Cyan
    $auditFiles = Get-ChildItem $auditPath -Filter "audit-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($auditFiles) {
        $auditFiles | Select-Object -First 1 | ForEach-Object {
            $entries = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json
            $entries | Select-Object -Last 10 | ForEach-Object {
                $color = if ($_.result -eq 'success') { 'Green' } else { 'Red' }
                Write-Host "  [$($_.timestamp)] $($_.action) - $($_.actor) - $($_.result)" -ForegroundColor $color
            }
        }
    }
    
    Write-Host ""
}

# ======== MAIN ========

Initialize-GovernanceLayer

switch ($Action) {
    'initialize' {
        Initialize-GovernanceLayer
    }
    
    'validate' {
        if ([string]::IsNullOrWhiteSpace($EventName) -or [string]::IsNullOrWhiteSpace($Actor)) {
            Write-Host "[ERROR] EventName y Actor son requeridos" -ForegroundColor Red
            exit 1
        }
        
        $result = Invoke-Validation -EventName $EventName -Payload $Payload -Actor $Actor -ActionType $ActionType
        
        if ($result.valid) {
            Write-Host "[OK] Validación exitosa" -ForegroundColor Green
        }
        else {
            Write-Host "[FAILED] Validación fallida:" -ForegroundColor Red
            $result.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            exit 1
        }
    }
    
    'enforce' {
        if ([string]::IsNullOrWhiteSpace($EventName) -or [string]::IsNullOrWhiteSpace($Actor)) {
            Write-Host "[ERROR] EventName y Actor son requeridos" -ForegroundColor Red
            exit 1
        }
        
        $result = Invoke-Validation -EventName $EventName -Payload $Payload -Actor $Actor -ActionType $ActionType
        
        if ($result.valid) {
            Write-Host "[OK] Política aplicada exitosamente" -ForegroundColor Green
        }
        else {
            Write-Host "[BLOCKED] Política rechazada:" -ForegroundColor Red
            $result.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            exit 1
        }
    }
    
    'audit' {
        Get-GovernanceReport
    }
    
    'report' {
        Get-GovernanceReport
    }
    
    'check-policy' {
        if ([string]::IsNullOrWhiteSpace($EventName)) {
            Write-Host "[ERROR] EventName requerido" -ForegroundColor Red
            exit 1
        }
        
        $registry = Get-EventRegistry
        $eventDef = $registry.registry.PSObject.Properties[$EventName]
        
        if ($eventDef) {
            Write-Host "`nPolítica para evento: $EventName" -ForegroundColor Cyan
            Write-Host "Descripción: $($eventDef.Value.description)" -ForegroundColor Gray
            Write-Host "Categoría: $($eventDef.Value.category)" -ForegroundColor Gray
            Write-Host "Severidad: $($eventDef.Value.severity)" -ForegroundColor Gray
            Write-Host "Emisores permitidos: $($eventDef.Value.emitters -join ', ')" -ForegroundColor Gray
            Write-Host "Escuchadores permitidos: $($eventDef.Value.listeners -join ', ')" -ForegroundColor Gray
            Write-Host "Políticas: $($eventDef.Value.policies -join ', ')" -ForegroundColor Gray
            Write-Host "Rate Limit: $($eventDef.Value.rate_limit.max_per_minute)/min, $($eventDef.Value.rate_limit.max_per_hour)/hora" -ForegroundColor Gray
        }
        else {
            Write-Host "[ERROR] Evento no encontrado: $EventName" -ForegroundColor Red
            exit 1
        }
    }
    
    default {
        Write-Host "[ERROR] Acción desconocida: $Action" -ForegroundColor Red
        exit 1
    }
}