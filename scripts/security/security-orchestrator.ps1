# Security Orchestrator - Gentle-Vanguard
# Central security module for workflow automation
# Provides sanitization, privacy, and data control

#Requires -Version 5.1

param(
    [ValidateSet('init', 'sanitize', 'audit', 'block', 'status', 'enable', 'disable', 'scan')]
    [string]$Action = 'status',
    
    [string]$Content,
    
    [ValidateSet('prompt', 'log', 'error', 'audit')]
    [string]$Mode = 'prompt',
    
    [switch]$Verbose,
    
    [switch]$AsJson,
    
    [string]$ApiKey,
    
    [string[]]$Targets
)

$ErrorActionPreference = 'Stop'
$scriptPath = $PSCommandPath
$scriptDir = Split-Path -Parent $scriptPath
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$configDir = Join-Path $repoRoot 'config'
$runtimeDir = Join-Path $repoRoot '.runtime'
$workspaceDir = Join-Path $repoRoot '.workspace'
$securityConfigPath = Join-Path $configDir 'security-privacy.json'
$securityPolicyPath = Join-Path $configDir 'security-policy.json'
$auditLogPath = Join-Path $runtimeDir 'security-audit.log'
$statePath = Join-Path $runtimeDir 'security-state.json'
$ownerAuthPath = Join-Path $workspaceDir 'config\owner-auth.json'
$sessionAuthPath = Join-Path $workspaceDir 'config\session-auth.json'

# =============================================================================
# EXISTING AUTH SYSTEM INTEGRATION
# Uses: .workspace/config/owner-auth.json + auth-session.ps1
# =============================================================================

function Get-SessionAuth {
    if (Test-Path $sessionAuthPath) {
        $session = Get-Content $sessionAuthPath | ConvertFrom-Json
        if ($session.authenticated -and $session.expiresAt -gt (Get-Date)) {
            return $true
        }
    }
    return $false
}

function Get-OwnerApiKey {
    # Priority 1: Environment variable (most secure - not in repo)
    $envKey = $env:GV_OWNER_KEY
    if (-not [string]::IsNullOrWhiteSpace($envKey)) {
        return $envKey
    }
    
    # Priority 2: Encrypted DPAPI file
    $encryptedAuthPath = $ownerAuthPath + ".enc"
    if (Test-Path $encryptedAuthPath) {
        try {
            $encrypted = [System.IO.File]::ReadAllBytes($encryptedAuthPath)
            $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $encrypted,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )
            $auth = [System.Text.Encoding]::UTF8.GetString($decrypted) | ConvertFrom-Json
            if ($auth.apiKey -and $auth.apiKey -ne '__USE_ENV_VAR_GV_OWNER_KEY__') {
                return $auth.apiKey
            }
        }
        catch {
            # Fall through to plain file
        }
    }
    
    # Priority 3: Plain file (legacy fallback - avoid)
    if (Test-Path $ownerAuthPath) {
        $auth = Get-Content $ownerAuthPath -Raw | ConvertFrom-Json
        if ($auth.apiKey -and $auth.apiKey -ne '__USE_ENV_VAR_GV_OWNER_KEY__') {
            return $auth.apiKey
        }
    }
    
    return $null
}

function Test-OwnerApiKey {
    param([string]$Key)
    
    if ([string]::IsNullOrWhiteSpace($Key)) {
        return $false
    }
    
    # Check lockout first
    $secureAuthScript = Join-Path (Split-Path $scriptDir) 'scripts\security\secure-auth.ps1'
    if (Test-Path $secureAuthScript) {
        $lockStatus = & $secureAuthScript -Action status -AsJson 2>$null | ConvertFrom-Json
        if ($lockStatus.lockout.locked) {
            Write-Host "[LOCKED] Too many failed attempts. Wait $($lockStatus.lockout.remainingMinutes) min" -ForegroundColor Red
            return $false
        }
    }
    
    $expectedKey = Get-OwnerApiKey
    if ($null -eq $expectedKey) {
        Write-Host "[WARN] No owner API key configured. Set GV_OWNER_KEY env var." -ForegroundColor Yellow
        return $false
    }
    
    $valid = ($Key -eq $expectedKey)
    
    # Track failed attempts
    if (-not $valid) {
        & $secureAuthScript -Action status 2>$null | Out-Null
    }
    
    return $valid
}

function Test-OperationAuth {
    param(
        [string]$Operation,
        [string]$ApiKey
    )
    
    # Already authenticated in session?
    if (Get-SessionAuth) {
        return $true
    }
    
    # No auth required for read-only operations
    $noAuthOps = @('init', 'status', 'sanitize', 'scan', 'audit')
    if ($noAuthOps -contains $Operation) {
        return $true
    }
    
    # Auth required for modify operations
    $authReqOps = @('disable', 'enable', 'modify')
    if ($authReqOps -contains $Operation) {
        if ([string]::IsNullOrWhiteSpace($ApiKey)) {
            return $false
        }
        return Test-OwnerApiKey -Key $ApiKey
    }
    
    return $true
}

function Write-AuthRequired {
    param([string]$Operation)
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "[LOCK] AUTHENTICATION REQUIRED" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Operation '$Operation' requires owner authentication." -ForegroundColor White
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\scripts\security\security-orchestrator.ps1 -Action '$Operation' -ApiKey <your-api-key>" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Get API key: Set GV_OWNER_KEY env var (recommended)" -ForegroundColor Gray
    Write-Host "Or use: .\scripts\utilities\auth-session.ps1 -UseSecurityQuestions" -ForegroundColor Gray
    Write-Host "Or check: .workspace\config\owner-auth.json (legacy)" -ForegroundColor Gray
    Write-Host ""
}

# =============================================================================
# ESTADO GLOBAL (en memoria y persistido)
# =============================================================================

$script:SECURITY_STATE = @{
    enabled = $true
    autoSanitize = $true
    autoAudit = $true
    autoBlock = $true
    mode = 'enforced'  # enforced, permissive, disabled
    initialized = $null
    lastSanitize = $null
    violations = 0
    sanitizedCount = 0
}

function Initialize-SecurityState {
    param([switch]$Force)
    
    if ((Test-Path $statePath) -and -not $Force) {
        $saved = Get-Content $StatePath -Raw | ConvertFrom-Json
        $script:SECURITY_STATE.enabled = $saved.enabled
        $script:SECURITY_STATE.autoSanitize = $saved.autoSanitize
        $script:SECURITY_STATE.autoAudit = $saved.autoAudit
        $script:SECURITY_STATE.autoBlock = $saved.autoBlock
        $script:SECURITY_STATE.mode = $saved.mode
        $script:SECURITY_STATE.initialized = $saved.initialized
        return
    }
    
    if (-not (Test-Path $runtimeDir)) {
        New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
    }
    
    $script:SECURITY_STATE.initialized = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    Save-SecurityState
}

function Save-SecurityState {
    $script:SECURITY_STATE | ConvertTo-Json -Depth 3 | Set-Content $StatePath -Encoding UTF8
}

# =============================================================================
# PATRONES DE SANITIZACION
# =============================================================================

$PATTERNS = @{
    machineId = @{
        patterns = @(
            [System.Environment]::MachineName,
            $env:COMPUTERNAME,
            'COMPUTERNAME'
        )
        replacement = '<MACHINE>'
    }
    userId = @{
        patterns = @(
            $env:USERNAME,
            [System.Environment]::UserName,
            'USERNAME'
        )
        replacement = '<USER>'
    }
    homePath = @{
        patterns = @(
            [System.Environment]::GetFolderPath('UserProfile'),
            $env:USERPROFILE,
            $env:HOME,
            $env:APPDATA
        )
        replacement = '<HOME>'
    }
    fullPath = @{
        patterns = @(
            'C:\\Users\\[^\\]+',
            '/home/[^/]+',
            '\\\\[A-Za-z0-9_-]+\\'
        )
        replacement = '<PATH>'
    }
    envSecret = @{
        patterns = @(
            'API_KEY',
            'SECRET',
            'PASSWORD',
            'TOKEN',
            'AUTH'
        )
        replacement = '<SECRET>'
        type = 'credential'
    }
    apiKey = @{
        patterns = @(
            'sk_live_[0-9a-zA-Z]{24,}',
            'ghp_[A-Za-z0-9]{36}'
        )
        replacement = '<API_KEY>'
        type = 'credential'
    }
    awsKey = @{
        patterns = @(
            'AKIA[0-9A-Z]{16}',
            'aws_secret_access_key'
        )
        replacement = '<AWS_KEY>'
        type = 'credential'
    }
    ipAddress = @{
        patterns = @(
            '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
        )
        replacement = '<IP>'
    }
}

# =============================================================================
# FUNCIONES DE SANITIZACION
# =============================================================================

function Invoke-Sanitize {
    param(
        [Parameter(Mandatory)]
        [string]$Text,
        
        [ValidateSet('prompt', 'log', 'error', 'audit')]
        [string]$Mode = 'prompt'
    )
    
    if (-not $script:SECURITY_STATE.enabled) {
        return $Text
    }
    
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }
    
    $result = $Text
    
    switch ($Mode) {
        'prompt' {
            $result = Sanitize-MachineId -Text $result
            $result = Sanitize-UserId -Text $result
            $result = Sanitize-HomePath -Text $result
            $result = Sanitize-FullPaths -Text $result
            $result = Sanitize-EnvSecrets -Text $result
            $result = Sanitize-ApiKeys -Text $result
            $result = Sanitize-AwsKeys -Text $result
            $result = Sanitize-IPAddresses -Text $result
        }
        'log' {
            $result = Sanitize-MachineId -Text $result
            $result = Sanitize-UserId -Text $result
            $result = Sanitize-HomePath -Text $result
            $result = Sanitize-FullPaths -Text $result
            $result = Sanitize-EnvSecrets -Text $result
        }
        'error' {
            $result = Sanitize-MachineId -Text $result
            $result = Sanitize-UserId -Text $result
            $result = Sanitize-EnvSecrets -Text $result
            $result = Sanitize-FullPaths -Text $result
        }
        'audit' {
            # Full audit - keep original but mark what was sanitized
            $result = $result  # No replacement for audit
        }
    }
    
    $script:SECURITY_STATE.lastSanitize = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $script:SECURITY_STATE.sanitizedCount++
    
    return $result
}

function Sanitize-MachineId {
    param([string]$Text)
    foreach ($p in $PATTERNS.machineId.patterns) {
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            $Text = $Text -replace [regex]::Escape($p), $PATTERNS.machineId.replacement
        }
    }
    return $Text
}

function Sanitize-UserId {
    param([string]$Text)
    foreach ($p in $PATTERNS.userId.patterns) {
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            $Text = $Text -replace [regex]::Escape($p), $PATTERNS.userId.replacement
        }
    }
    return $Text
}

function Sanitize-HomePath {
    param([string]$Text)
    foreach ($p in $PATTERNS.homePath.patterns) {
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            $Text = $Text -replace [regex]::Escape($p), $PATTERNS.homePath.replacement
            $Text = $Text -replace [regex]::Escape($p.Replace('\', '\\')), $PATTERNS.homePath.replacement
        }
    }
    return $Text
}

function Sanitize-FullPaths {
    param([string]$Text)
    foreach ($p in $PATTERNS.fullPath.patterns) {
        $Text = $Text -replace $p, $PATTERNS.fullPath.replacement
    }
    return $Text
}

function Sanitize-EnvSecrets {
    param([string]$Text)
    foreach ($key in $PATTERNS.envSecret.patterns) {
        $regex = "(?i)(\`$$key|[A-Z_]+_KEY)\s*=\s*['\x22]*[^'\x22\s]+['\x22]*"
        $Text = $Text -replace $regex, "`$$key=<REDACTED>"
    }
    return $Text
}

function Sanitize-ApiKeys {
    param([string]$Text)
    foreach ($p in $PATTERNS.apiKey.patterns) {
        $Text = $Text -replace $p, $PATTERNS.apiKey.replacement
    }
    return $Text
}

function Sanitize-AwsKeys {
    param([string]$Text)
    foreach ($p in $PATTERNS.awsKey.patterns) {
        $Text = $Text -replace $p, $PATTERNS.awsKey.replacement
    }
    return $Text
}

function Sanitize-IPAddresses {
    param([string]$Text)
    $Text = $Text -replace $PATTERNS.ipAddress.patterns[0], $PATTERNS.ipAddress.replacement
    return $Text
}

# =============================================================================
# AUDITORIA
# =============================================================================

function Write-AuditLog {
    param(
        [string]$Event,
        [string]$Details,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'BLOCK')]
        [string]$Severity = 'INFO'
    )
    
    if (-not (Test-Path $runtimeDir)) {
        New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
    }
    
    $entry = @{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        event = $Event
        severity = $Severity
        machine = '<MACHINE>'
        user = '<USER>'
        details = if ($script:SECURITY_STATE.autoSanitize) { Invoke-Sanitize -Text $Details -Mode 'audit' } else { $Details }
    } | ConvertTo-Json -Compress
    
    Add-Content -Path $auditLogPath -Value $entry
}

# =============================================================================
# BLOQUEO DE PATRONES CRITICOS
# =============================================================================

$CRITICAL_PATTERNS = @(
    @{ Name = 'AWS Key'; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = 'GitHub Token'; Pattern = 'ghp_[A-Za-z0-9]{36}' },
    @{ Name = 'Stripe Key'; Pattern = 'sk_live_[0-9a-zA-Z]{24,}' },
    @{ Name = 'Private Key'; Pattern = '-----BEGIN .+ PRIVATE KEY-----' },
    @{ Name = 'Prompt Injection: Instruction Override'; Pattern = '(?i)(?:\bignore\s+(?:all\s+)?(?:previous\s+)?(?:instructions|commands|directions|rules|prompts?|constraints?|guidelines?))\b' },
    @{ Name = 'Prompt Injection: Prompt Leakage'; Pattern = '(?i)(?:\b(?:repeat|output|print|show|display|reveal|leak|dump|copy)\s+(?:your\s+)?(?:system\s+)?(?:prompt|instructions|rules))\b' },
    @{ Name = 'Prompt Injection: Jailbreak'; Pattern = '(?i)(?:DAN|do\s+anything\s+now|jailbreak|unrestricted\s+mode|developer\s+mode|no\s+(?:limits|restrictions|filter))' },
    @{ Name = 'Prompt Injection: Code Execution'; Pattern = '(?i)(?:\$?(?:exec|eval|system|shell|cmd|powershell|bash|os\.system|subprocess|child_process|execSync|spawn)\s*\()' },
    @{ Name = 'Prompt Injection: Role Takeover'; Pattern = '(?i)(?:\byou\s+(?:are\s+)?(?:now|must\s+act\s+as|will\s+pretend|shall\s+behave))\b' }
)

function Test-BlockCritical {
    param([string]$Text)
    
    foreach ($p in $CRITICAL_PATTERNS) {
        if ($Text -match $p.Pattern) {
            return @{
                blocked = $true
                pattern = $p.Name
            }
        }
    }
    
    return @{ blocked = $false }
}

# =============================================================================
# ACCIONES
# =============================================================================

function Invoke-Action {
    param(
        [string]$Action,
        [string]$Content,
        [string]$Mode,
        [string]$ApiKey
    )
    
    # Check authentication for restricted operations
    $authCheck = Test-OperationAuth -Operation $Action -ApiKey $ApiKey
    if (-not $authCheck) {
        Write-AuthRequired -Operation $Action
        return @{
            status = 'AUTH_REQUIRED'
            message = "Operation '$Action' requires authentication. Use -ApiKey parameter."
            requireAuth = $true
        }
    }
    
    switch ($Action) {
        'init' {
            Initialize-SecurityState -Force
            Write-AuditLog -Event 'INIT' -Details 'Security orchestrator initialized'
            return @{
                status = 'OK'
                message = 'Security orchestrator initialized'
                mode = $script:SECURITY_STATE.mode
            }
        }
        
        'sanitize' {
            if ([string]::IsNullOrWhiteSpace($Content)) {
                return @{ status = 'ERROR'; message = 'Content required for sanitize' }
            }
            
            $blocked = Test-BlockCritical -Text $Content
            if ($blocked.blocked) {
                $script:SECURITY_STATE.violations++
                Write-AuditLog -Event 'BLOCKED' -Details "Critical pattern: $($blocked.pattern)" -Severity 'BLOCK'
                return @{
                    status = 'BLOCKED'
                    message = "Critical pattern detected: $($blocked.pattern)"
                    pattern = $blocked.pattern
                }
            }
            
            $sanitized = Invoke-Sanitize -Text $Content -Mode $Mode
            
            if ($Verbose) {
                Write-AuditLog -Event 'SANITIZED' -Details "Mode: $Mode"
            }
            
            return @{
                status = 'OK'
                original = $Content
                sanitized = $sanitized
                mode = $Mode
            }
        }
        
        'audit' {
            Write-AuditLog -Event 'AUDIT' -Details $Content
            return @{
                status = 'OK'
                message = 'Audit logged'
            }
        }
        
        'block' {
            $blocked = Test-BlockCritical -Text $Content
            if ($blocked.blocked) {
                $script:SECURITY_STATE.violations++
                Write-AuditLog -Event 'BLOCKED' -Details "Critical: $($blocked.pattern)" -Severity 'BLOCK'
                return @{
                    status = 'BLOCKED'
                    message = "Blocked: $($blocked.pattern)"
                }
            }
            return @{ status = 'OK'; message = 'Allowed' }
        }
        
        'enable' {
            $script:SECURITY_STATE.enabled = $true
            $script:SECURITY_STATE.autoSanitize = $true
            $script:SECURITY_STATE.autoBlock = $true
            Save-SecurityState
            Write-AuditLog -Event 'ENABLED' -Details 'Security enabled'
            return @{ status = 'OK'; message = 'Security enabled' }
        }
        
        'disable' {
            $script:SECURITY_STATE.enabled = $false
            $script:SECURITY_STATE.autoSanitize = $false
            Save-SecurityState
            Write-AuditLog -Event 'DISABLED' -Details 'Security disabled'
            return @{ status = 'OK'; message = 'Security disabled' }
        }
        
        'status' {
            return @{
                status = 'OK'
                enabled = $script:SECURITY_STATE.enabled
                autoSanitize = $script:SECURITY_STATE.autoSanitize
                autoBlock = $script:SECURITY_STATE.autoBlock
                mode = $script:SECURITY_STATE.mode
                initialized = $script:SECURITY_STATE.initialized
                lastSanitize = $script:SECURITY_STATE.lastSanitize
                violations = $script:SECURITY_STATE.violations
                sanitizedCount = $script:SECURITY_STATE.sanitizedCount
            }
        }
        
        'scan' {
            if ($null -eq $Targets -or $Targets.Count -eq 0) {
                $Targets = @('.')
            }
            
            $results = @()
            foreach ($target in $Targets) {
                $files = Get-ChildItem -Path $target -Recurse -File -Include *.ps1,*.md,*.json,*.yaml,*.yml -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                    $blocked = Test-BlockCritical -Text $content
                    if ($blocked.blocked) {
                        $results += @{
                            file = $file.FullName
                            pattern = $blocked.pattern
                            severity = 'CRITICAL'
                        }
                        $script:SECURITY_STATE.violations++
                    }
                }
            }
            
            return @{
                status = 'OK'
                scanned = $Targets
                violations = $results
                totalViolations = $results.Count
            }
        }
    }
}

# =============================================================================
# MAIN
# =============================================================================

Initialize-SecurityState

$result = Invoke-Action -Action $Action -Content $Content -Mode $Mode -ApiKey $ApiKey

if ($AsJson) {
    $result | ConvertTo-Json -Depth 3
} else {
    switch ($Action) {
        'status' {
            Write-Host '=== SECURITY ORCHESTRATOR ===' -ForegroundColor Cyan
            Write-Host "Status: $(if($result.enabled){'ENABLED'}else{'DISABLED'})" -ForegroundColor $(if($result.enabled){'Green'}else{'Yellow'})
            Write-Host "Auto-Sanitize: $($result.autoSanitize)" -ForegroundColor White
            Write-Host "Auto-Block: $($result.autoBlock)" -ForegroundColor White
            Write-Host "Mode: $($result.mode)" -ForegroundColor White
            Write-Host "Initialized: $($result.initialized)" -ForegroundColor Gray
            Write-Host "Violations blocked: $($result.violations)" -ForegroundColor $(if($result.violations -gt 0){'Red'}else{'Gray'})
            Write-Host "Sanitized count: $($result.sanitizedCount)" -ForegroundColor Gray
        }
        'sanitize' {
            if ($result.status -eq 'BLOCKED') {
                Write-Host "[BLOCKED] $($result.message)" -ForegroundColor Red
            } else {
                Write-Output $result.sanitized
            }
        }
        default {
            Write-Host "[$($result.status)] $($result.message)" -ForegroundColor $(if($result.status -eq 'OK'){'Green'}else{'Yellow'})
        }
    }
}

