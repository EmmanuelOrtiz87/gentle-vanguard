# model-router.ps1
# Model Router v2.0 — Agent-to-model binding + temperature management + admin auth
# Dot-source: . .\scripts\utilities\MODEL-ROUTER\model-router.ps1
# Standalone: & .\scripts\utilities\MODEL-ROUTER\model-router.ps1 -Action <action> [params...]

param(
    [ValidateSet('list', 'show', 'set', 'reset', 'defaults', 'admin-status', 'admin-auth', 'admin-register-pc', 'tui')]
    [string]$Action = '',
    [string]$Agent = '',
    [string]$Model = '',
    [string]$Provider = '',
    [string]$Temperature = '',
    [string]$AdminPassword = '',
    [string]$AdminKeyFile = '',
    [string]$ConfigPath = '',
    [switch]$JSON,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# --- Paths ---
if (-not $ConfigPath) {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $repoRoot = (Resolve-Path (Join-Path $scriptRoot '..\..\..')).Path
    $ConfigPath = Join-Path $repoRoot 'config\model-router.json'
}
$repoRootGlobal = if ($PSScriptRoot) { (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path } else { (Get-Location).Path }
$keyFilePath = Join-Path $repoRootGlobal 'keys\master.key'
$cloudAgentsPath = Join-Path $repoRootGlobal 'config\cloud-agents.json'
$autoDelegationPath = Join-Path $repoRootGlobal 'config\auto-delegation.json'
$sessionDir = Join-Path $repoRootGlobal '.session'
$sessionFile = Join-Path $sessionDir 'model-router-auth.json'
$auditLogDir = Join-Path $repoRootGlobal '.logs'
$auditLogFile = Join-Path $auditLogDir 'model-router-audit.jsonl'

# All supported agent codes
$script:ALL_AGENTS = @('BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC', 'SESSION', 'MKT', 'SALES', 'FINANCE', 'HR', 'LEGAL', 'BUS-TELE', 'PREMORTEM', 'SCRIPT-GOV', 'GITFLOW-BRANCH', 'GITFLOW-PR', 'GITFLOW-HOOKS', 'GITFLOW-MERGE', 'GITFLOW-WORKFLOW', 'GITFLOW-COMMIT', 'GITFLOW-CONFLICT')

# ============================================================================
# PUBLIC API
# ============================================================================

function Get-ModelRouterConfig {
    param([string]$Path = $ConfigPath)
    if (-not (Test-Path $Path)) {
        Write-Error "Model router config not found: $Path. Run 'route defaults --init' first."
        return $null
    }
    return Get-Content $Path -Raw | ConvertFrom-Json
}

function Save-ModelRouterConfig {
    param(
        [PSObject]$Config,
        [string]$Path = $ConfigPath
    )
    $backupPath = "$Path.bak"
    if (Test-Path $Path) { Copy-Item $Path $backupPath -Force }
    $Config | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
    Write-AuditEntry -Action 'config.saved' -Detail "Config saved to $Path"
}

function Get-AvailableProviders {
    if (-not (Test-Path $cloudAgentsPath)) {
        Write-Warning "cloud-agents.json not found"
        return @()
    }
    $cloud = Get-Content $cloudAgentsPath -Raw | ConvertFrom-Json
    return $cloud.providers.PSObject.Properties | Where-Object { $_.Value.enabled -or $_.Name -eq 'anthropic' } | ForEach-Object {
        [PSCustomObject]@{
            code    = $_.Name
            name    = $_.Value.description
            model   = $_.Value.model
            local   = if ($_.Value.PSObject.Properties.Match('local')) { $_.Value.local } else { $false }
            enabled = $_.Value.enabled
        }
    }
}

function Resolve-AgentModelBinding {
    param(
        [string]$AgentCode,
        [string]$ConfigPath = $ConfigPath
    )
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config) { return $null }
    if (-not $config.enabled) {
        return [PSCustomObject]@{
            agent            = $AgentCode
            model            = $config.defaults.model
            provider         = $config.defaults.provider
            temperature      = $config.defaults.temperature
            source           = 'defaults (router disabled)'
        }
    }
    $binding = $config.agentBindings.$AgentCode
    $resolved = [PSCustomObject]@{
        agent             = $AgentCode
        model             = if ($binding.model) { $binding.model } else { $config.defaults.model }
        provider          = if ($binding.provider) { $binding.provider } else { $config.defaults.provider }
        temperature       = if ($binding.temperature -ne $null -and $binding.temperature -ne '') { [double]$binding.temperature } else { [double]$config.defaults.temperature }
        hallucinationGuard = if ($binding.hallucinationGuard) { $binding.hallucinationGuard } else { $config.defaults.hallucinationGuard }
        source            = if ($binding.model) { 'agent-override' } else { 'defaults' }
    }
    return $resolved
}

function Get-AgentBinding {
    param(
        [string]$AgentCode,
        [string]$ConfigPath = $ConfigPath
    )
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config) { return $null }
    if ($AgentCode) {
        $binding = $config.agentBindings.$AgentCode
        if (-not $binding) { Write-Error "Unknown agent: $AgentCode. Valid: $($script:ALL_AGENTS -join ', ')"; return $null }
        $effective = Resolve-AgentModelBinding -AgentCode $AgentCode -ConfigPath $ConfigPath
        return [PSCustomObject]@{
            agent              = $AgentCode
            effectiveModel     = $effective.model
            effectiveProvider  = $effective.provider
            effectiveTemperature = $effective.temperature
            overrideModel      = $binding.model
            overrideProvider   = $binding.provider
            overrideTemperature = $binding.temperature
            source             = $effective.source
        }
    }
    $result = @()
    foreach ($agent in $script:ALL_AGENTS) {
        $effective = Resolve-AgentModelBinding -AgentCode $agent -ConfigPath $ConfigPath
        $binding = $config.agentBindings.$agent
        $result += [PSCustomObject]@{
            agent              = $agent
            effectiveModel     = $effective.model
            effectiveProvider  = $effective.provider
            effectiveTemperature = $effective.temperature
            overrideModel      = $binding.model
            overrideProvider   = $binding.provider
            overrideTemperature = $binding.temperature
            source             = $effective.source
        }
    }
    return $result
}

function Set-AgentBinding {
    param(
        [string]$AgentCode,
        [string]$Model = '',
        [string]$Provider = '',
        [string]$Temperature = '',
        [string]$ConfigPath = $ConfigPath
    )
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config) { return $false }
    if ($config.agentBindings.$AgentCode -eq $null) {
        Write-Error "Unknown agent: $AgentCode. Valid: BA, SAD, DEV, QA, OPS, GOV, DOC"
        return $false
    }
    $changes = @()
    if ($Model) {
        $config.agentBindings.$AgentCode.model = $Model
        $changes += "model=$Model"
    }
    if ($Provider) {
        $config.agentBindings.$AgentCode.provider = $Provider
        $changes += "provider=$Provider"
    }
    if ($Temperature -ne '') {
        $tempVal = [double]$Temperature
        $range = $config.temperaturePolicy.validationRange
        if ($tempVal -lt $range.min -or $tempVal -gt $range.max) {
            Write-Error "Temperature $tempVal out of range [$($range.min)..$($range.max)]"
            return $false
        }
        $config.agentBindings.$AgentCode.temperature = $tempVal
        $changes += "temperature=$tempVal"
    }
    $config.lastModified = (Get-Date -Format 'o')
    Save-ModelRouterConfig -Config $config -Path $ConfigPath
    Write-AuditEntry -Action 'binding.set' -Detail "Agent=$AgentCode Changes=$($changes -join ', ')"
    return $true
}

function Reset-AgentBinding {
    param(
        [string]$AgentCode,
        [string]$ConfigPath = $ConfigPath
    )
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config) { return $false }
    if ($AgentCode) {
        if ($config.agentBindings.$AgentCode -eq $null) {
            Write-Error "Unknown agent: $AgentCode"
            return $false
        }
        $config.agentBindings.$AgentCode.model = $null
        $config.agentBindings.$AgentCode.provider = $null
        $config.agentBindings.$AgentCode.temperature = $null
        Write-AuditEntry -Action 'binding.reset' -Detail "Agent=$AgentCode reset to defaults"
    } else {
        foreach ($agent in $script:ALL_AGENTS) {
            $config.agentBindings.$agent.model = $null
            $config.agentBindings.$agent.provider = $null
            $config.agentBindings.$agent.temperature = $null
        }
        Write-AuditEntry -Action 'binding.reset-all' -Detail 'All agents reset to defaults'
    }
    $config.lastModified = (Get-Date -Format 'o')
    Save-ModelRouterConfig -Config $config -Path $ConfigPath
    return $true
}

function Set-ModelRouterDefaults {
    param(
        [string]$Model = '',
        [string]$Provider = '',
        [string]$Temperature = '',
        [string]$ConfigPath = $ConfigPath,
        [switch]$Init
    )
    if ($Init) {
        if (-not (Test-Path $ConfigPath)) {
            $template = @"
{
  "version": "2.1.0",
  "enabled": true,
  "description": "Model Router: per-agent model/temperature binding with opencode Go tier models and big-pickle fallback",
  "lastModified": "$(Get-Date -Format 'o')",
  "modifiedBy": "init",
  "defaults": {
    "model": "gpt-5.4-mini",
    "provider": "opencode",
    "temperature": 0.3,
    "hallucinationGuard": "medium",
    "notes": "Base model for agents without specific override"
  },
  "fallback": {
    "model": "opencode/big-pickle",
    "description": "Free-tier opencode model when Go subscription quota exhausted",
    "quotaExhaustedBehavior": "auto-switch",
    "notifyOnSwitch": true,
    "notificationMessage": "[QUOTA] Monthly Go subscription quota exhausted. Switched to opencode/big-pickle (free tier).",
    "resetOnRenewal": true
  },
  "agentBindings": {
    "BA":  { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "SAD": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "DEV": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "QA":  { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "OPS": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GOV": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "DOC": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "SESSION": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "MKT": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "SALES": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "FINANCE": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "HR": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "LEGAL": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "BUS-TELE": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "PREMORTEM": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "SCRIPT-GOV": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GITFLOW-BRANCH": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GITFLOW-PR": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GITFLOW-HOOKS": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GITFLOW-MERGE": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GITFLOW-WORKFLOW": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GITFLOW-COMMIT": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "GITFLOW-CONFLICT": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "REPORT": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "PR-REVIEW": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "RELEASE": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "SESSION-CLOSE": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "DAILY": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null },
    "ORCHESTRATOR": { "model": null, "provider": null, "temperature": null, "hallucinationGuard": null, "subagent": null, "rationale": null }
  },
  "temperaturePolicy": {
    "description": "Temperature can ONLY be modified from the model assignment flow. Standalone temperature commands are blocked.",
    "allowCommandOverride": false,
    "allowTUIModification": true,
    "allowScriptModification": false,
    "lockedByDefault": true,
    "unlockRequiresAdmin": true,
    "auditChanges": true,
    "validationRange": { "min": 0.0, "max": 2.0 }
  },
  "admin": {
    "enabled": true,
    "credentialSource": "keys/master.key",
    "passwordHash": null,
    "pcIdentitySource": ["machineGuid", "macAddress", "hostname"],
    "currentPcFingerprint": null,
    "trustedPcs": [],
    "authMode": "auto",
    "sessionTimeoutMinutes": 60,
    "auditLog": ".logs/model-router-audit.jsonl",
    "maxAuthAttempts": 3,
    "lockoutDurationMinutes": 15
  },
  "providerPriority": {
    "order": ["anthropic", "openai", "bedrock", "gemini", "azure", "ollama", "dify", "custom"]
  },
  "audit": {
    "enabled": true,
    "logRetentionDays": 90,
    "logToJson": true
  }
}
"@
            Set-Content $ConfigPath -Value $template -Encoding UTF8
            Write-AuditEntry -Action 'config.init' -Detail 'Config initialized from template'
            Write-Success "Model router config initialized at $ConfigPath"
        }
        return Initialize-AdminSetup -ConfigPath $ConfigPath
    }
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config) { return $false }
    if ($Model) { $config.defaults.model = $Model }
    if ($Provider) { $config.defaults.provider = $Provider }
    if ($Temperature -ne '') {
        $tempVal = [double]$Temperature
        $range = $config.temperaturePolicy.validationRange
        if ($tempVal -lt $range.min -or $tempVal -gt $range.max) {
            Write-Error "Temperature $tempVal out of range [$($range.min)..$($range.max)]"
            return $false
        }
        $config.defaults.temperature = $tempVal
    }
    $config.lastModified = (Get-Date -Format 'o')
    Save-ModelRouterConfig -Config $config -Path $ConfigPath
    Write-AuditEntry -Action 'defaults.set' -Detail "Model=$Model Provider=$Provider Temperature=$Temperature"
    return $true
}

# ============================================================================
# ADMIN AUTHENTICATION
# ============================================================================

function Get-PcFingerprint {
    $source = @()
    try {
        $guid = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' -ErrorAction Stop).MachineGuid
        $source += $guid
    } catch { $source += 'no-guid' }

    try {
        $mac = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1 -ErrorAction SilentlyContinue).MacAddress
        if (-not $mac) { $mac = 'no-mac' }
        $source += $mac
    } catch { $source += 'no-mac' }

    $source += $env:COMPUTERNAME
    $combined = $source -join '|'
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combined))
    return ($hashBytes | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Get-AdminPasswordHash {
    $config = Get-ModelRouterConfig
    if (-not $config -or -not $config.admin.passwordHash) { return $null }
    return $config.admin.passwordHash
}

function Initialize-AdminSetup {
    param([string]$ConfigPath = $ConfigPath)
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config) { return $false }

    $fingerprint = Get-PcFingerprint
    $config.admin.currentPcFingerprint = $fingerprint

    if (Test-Path $keyFilePath) {
        $keyBytes = [System.IO.File]::ReadAllBytes($keyFilePath)
        $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($keyBytes)
        $config.admin.passwordHash = ($hashBytes | ForEach-Object { $_.ToString('x2') }) -join ''
    }

    $existing = $config.admin.trustedPcs | Where-Object { $_.fingerprint -eq $fingerprint }
    if (-not $existing) {
        $entry = [PSCustomObject]@{
            fingerprint = $fingerprint
            label       = $env:COMPUTERNAME
            autoGrant   = $true
            grantedAt   = (Get-Date -Format 'o')
        }
        $config.admin.trustedPcs = @($config.admin.trustedPcs + $entry)
    }

    $config.lastModified = (Get-Date -Format 'o')
    Save-ModelRouterConfig -Config $config -Path $ConfigPath
    Write-AuditEntry -Action 'admin.initialized' -Detail "PC registered as trusted: $fingerprint"
    return $true
}

function Test-AdminAuthorized {
    param(
        [string]$ConfigPath = $ConfigPath,
        [string]$ProvidedPassword = ''
    )
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config -or -not $config.admin.enabled) { return $true }

    $fingerprint = Get-PcFingerprint
    $trusted = $config.admin.trustedPcs | Where-Object { $_.fingerprint -eq $fingerprint -and $_.autoGrant }

    if ($trusted) { return $true }

    if ($ProvidedPassword) {
        $inputHashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($ProvidedPassword))
        $inputHash = ($inputHashBytes | ForEach-Object { $_.ToString('x2') }) -join ''
        $storedHash = $config.admin.passwordHash
        if ($inputHash -eq $storedHash) {
            New-AdminSession -Fingerprint $fingerprint -ConfigPath $ConfigPath
            return $true
        }
        return $false
    }

    return (Test-AdminSession -Fingerprint $fingerprint)
}

function New-AdminSession {
    param(
        [string]$Fingerprint,
        [string]$ConfigPath = $ConfigPath
    )
    $config = Get-ModelRouterConfig -Path $ConfigPath
    $expiry = (Get-Date).AddMinutes([int]$config.admin.sessionTimeoutMinutes)
    $session = @{
        fingerprint = $Fingerprint
        createdAt   = (Get-Date -Format 'o')
        expiresAt   = $expiry.ToString('o')
    }
    if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }
    $session | ConvertTo-Json | Set-Content $sessionFile -Encoding UTF8
    Write-AuditEntry -Action 'admin.session-created' -Detail "Session created for $Fingerprint, expires $($session.expiresAt)"
}

function Test-AdminSession {
    param([string]$Fingerprint)
    if (-not (Test-Path $sessionFile)) { return $false }
    try {
        $session = Get-Content $sessionFile -Raw | ConvertFrom-Json
        $expiry = [DateTime]::Parse($session.expiresAt)
        return ($session.fingerprint -eq $Fingerprint -and $expiry -gt [DateTime]::UtcNow)
    } catch { return $false }
}

function Register-TrustedPc {
    param(
        [string]$Label = $env:COMPUTERNAME,
        [string]$ConfigPath = $ConfigPath
    )
    $config = Get-ModelRouterConfig -Path $ConfigPath
    if (-not $config) { return $false }
    $fingerprint = Get-PcFingerprint
    $existing = $config.admin.trustedPcs | Where-Object { $_.fingerprint -eq $fingerprint }
    if (-not $existing) {
        $entry = [PSCustomObject]@{
            fingerprint = $fingerprint
            label       = $Label
            autoGrant   = $true
            grantedAt   = (Get-Date -Format 'o')
        }
        $config.admin.trustedPcs = @($config.admin.trustedPcs + $entry)
        $config.lastModified = (Get-Date -Format 'o')
        Save-ModelRouterConfig -Config $config -Path $ConfigPath
        Write-AuditEntry -Action 'admin.register-pc' -Detail "PC registered: $fingerprint ($Label)"
    }
    return $true
}

# ============================================================================
# AUDIT
# ============================================================================

function Write-AuditEntry {
    param(
        [string]$Action,
        [string]$Detail = '',
        [string]$Status = 'success'
    )
    if (-not (Test-Path $auditLogDir)) { New-Item -ItemType Directory -Path $auditLogDir -Force | Out-Null }
    $entry = @{
        timestamp   = (Get-Date -Format 'o')
        action      = $Action
        detail      = $Detail
        status      = $Status
        fingerprint = Get-PcFingerprint
        hostname    = $env:COMPUTERNAME
        user        = $env:USERNAME
    }
    $line = ($entry | ConvertTo-Json -Compress)
    Add-Content $auditLogFile -Value $line -Encoding UTF8
}

function Get-AuditLog {
    param(
        [int]$Last = 50,
        [string]$FilterAction = ''
    )
    if (-not (Test-Path $auditLogFile)) { return @() }
    $entries = Get-Content $auditLogFile -Raw | Where-Object { $_ -ne '' } | ForEach-Object { $_ | ConvertFrom-Json }
    if ($FilterAction) { $entries = $entries | Where-Object { $_.action -like "*$FilterAction*" } }
    return $entries | Select-Object -Last $Last
}

# ============================================================================
# DISPLAY HELPERS
# ============================================================================

function Format-RouteTable {
    param(
        [PSObject[]]$Bindings,
        [switch]$ShowConfig
    )
    $rows = $Bindings | ForEach-Object {
        $src = if ($_.source -eq 'agent-override') { 'CUSTOM' } else { 'default' }
        [PSCustomObject]@{
            Agent       = $_.agent
            Model       = $_.effectiveModel
            Provider    = $_.effectiveProvider
            Temperature = "{0:N2}" -f $_.effectiveTemperature
            Source      = $src
        }
    }
    $rows | Format-Table -AutoSize
}

function Show-AdminStatus {
    $config = Get-ModelRouterConfig
    if (-not $config) { return }
    $fingerprint = Get-PcFingerprint
    $trusted = $config.admin.trustedPcs | Where-Object { $_.fingerprint -eq $fingerprint }
    $authed = Test-AdminAuthorized
    Write-Host "`nAdmin Status" -ForegroundColor Cyan
    Write-Host "  PC Fingerprint..: $fingerprint" -ForegroundColor Gray
    if ($trusted) {
        Write-Host "  Trusted PC......: YES ($($trusted.label))" -ForegroundColor Green
    } else {
        Write-Host "  Trusted PC......: NO" -ForegroundColor Yellow
    }
    Write-Host "  Authorized......: $(if ($authed) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($authed) { 'Green' } else { 'Red' })
    Write-Host "  Auth Mode.......: $($config.admin.authMode)" -ForegroundColor Gray
    Write-Host "  Session Timeout.: $($config.admin.sessionTimeoutMinutes) min" -ForegroundColor Gray
    Write-Host "  Trusted PCs.....: $($config.admin.trustedPcs.Count)" -ForegroundColor Gray
    Write-Host "  Audit Log.......: $auditLogFile" -ForegroundColor Gray
}

# ============================================================================
# COMMAND HANDLER
# ============================================================================

function Invoke-RouteCommand {
    param(
        [string]$Action,
        [string]$Agent,
        [string]$Model,
        [string]$Provider,
        [string]$Temperature,
        [string]$AdminPassword,
        [string]$AdminKeyFile,
        [switch]$JSON
    )

    switch ($Action) {
        'list' {
            $bindings = Get-AgentBinding -ConfigPath $ConfigPath
            if (-not $bindings) {
                Write-Host "No bindings configured. Run 'route defaults --init' first." -ForegroundColor Yellow
                return
            }
            if ($JSON) {
                $bindings | ConvertTo-Json -Depth 3
            } else {
                Write-Host "`nModel Router — Agent Bindings" -ForegroundColor Cyan
                Write-Host "  (null = inherits from defaults)" -ForegroundColor Gray
                Format-RouteTable -Bindings $bindings
            }
        }

        'show' {
            if (-not $Agent) { Write-Error "Usage: route show --agent <CODE>"; return }
            $binding = Get-AgentBinding -AgentCode $Agent -ConfigPath $ConfigPath
            if (-not $binding) { return }
            if ($JSON) {
                $binding | ConvertTo-Json -Depth 3
            } else {
                Write-Host "`nAgent: $Agent" -ForegroundColor Cyan
                Write-Host "  Effective Model......: $($binding.effectiveModel)" -ForegroundColor White
                Write-Host "  Effective Provider...: $($binding.effectiveProvider)" -ForegroundColor White
                Write-Host "  Effective Temp.......: $($binding.effectiveTemperature)" -ForegroundColor White
                Write-Host "  Override Model.......: $(if ($binding.overrideModel) { $binding.overrideModel } else { 'defaults' })" -ForegroundColor Gray
                Write-Host "  Override Provider....: $(if ($binding.overrideProvider) { $binding.overrideProvider } else { 'defaults' })" -ForegroundColor Gray
                Write-Host "  Override Temp........: $(if ($binding.overrideTemperature -ne $null -and $binding.overrideTemperature -ne '') { '{0:N2}' -f [double]$binding.overrideTemperature } else { 'defaults' })" -ForegroundColor Gray
                Write-Host "  Source...............: $($binding.source)" -ForegroundColor Yellow
            }
        }

        'set' {
            if (-not $Agent) { Write-Error "Usage: route set --agent <CODE> [--model <M>] [--provider <P>] [--temperature <T>]"; return }
            $authed = Test-AdminAuthorized -ProvidedPassword $AdminPassword
            if (-not $authed) {
                Write-Error "Admin authorization required. Run 'route admin-auth' first or provide --AdminPassword."
                return
            }
            Set-AgentBinding -AgentCode $Agent -Model $Model -Provider $Provider -Temperature $Temperature
            $binding = Get-AgentBinding -AgentCode $Agent
            Write-Success "Agent $Agent updated"
            if (-not $JSON) {
                Write-Host "  Model: $($binding.effectiveModel) ($($binding.effectiveProvider))" -ForegroundColor Gray
                Write-Host "  Temp:  $($binding.effectiveTemperature)" -ForegroundColor Gray
            }
        }

        'reset' {
            $authed = Test-AdminAuthorized -ProvidedPassword $AdminPassword
            if (-not $authed) { Write-Error "Admin authorization required."; return }
            Reset-AgentBinding -AgentCode $Agent
            Write-Success "Agent $(if ($Agent) { $Agent } else { 'ALL' }) reset to defaults"
        }

        'defaults' {
            if ($Agent -eq 'init') {
                Set-ModelRouterDefaults -Init
                return
            }
            $authed = Test-AdminAuthorized -ProvidedPassword $AdminPassword
            if (-not $authed) { Write-Error "Admin authorization required."; return }
            Set-ModelRouterDefaults -Model $Model -Provider $Provider -Temperature $Temperature
            Write-Success "Defaults updated"
        }

        'admin-status' {
            Show-AdminStatus
        }

        'admin-auth' {
            $fingerprint = Get-PcFingerprint
            $config = Get-ModelRouterConfig
            if (-not $config) { Write-Error "Config not initialized. Run 'route defaults --init' first."; return }
            $trusted = $config.admin.trustedPcs | Where-Object { $_.fingerprint -eq $fingerprint }
            if ($trusted) {
                Write-Success "Auto-authorized (trusted PC: $($trusted.label))"
                return
            }
            if ($AdminKeyFile -and (Test-Path $AdminKeyFile)) {
                $keyBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $AdminKeyFile))
                $pwd = [System.Convert]::ToBase64String($keyBytes)
                $authed = Test-AdminAuthorized -ProvidedPassword $pwd
                if ($authed) {
                    Write-Success "Admin authenticated via key file"
                    return
                }
            }
            if ($AdminPassword) {
                $authed = Test-AdminAuthorized -ProvidedPassword $AdminPassword
                if ($authed) { Write-Success "Admin authenticated"; return }
                Write-Error "Invalid admin password"
                return
            }
            Write-Host "Non-trusted PC. Authentication required." -ForegroundColor Yellow
            Write-Host "Options:" -ForegroundColor Cyan
            Write-Host "  1. Provide --AdminPassword <password>" -ForegroundColor White
            Write-Host "  2. Provide --AdminKeyFile <path-to-master.key>" -ForegroundColor White
        }

        'admin-register-pc' {
            $authed = Test-AdminAuthorized -ProvidedPassword $AdminPassword
            if (-not $authed) { Write-Error "Admin authorization required."; return }
            Register-TrustedPc -Label "$env:COMPUTERNAME (registered)"
            Write-Success "This PC registered as trusted"
        }

        'tui' {
            $tuiPath = Join-Path $PSScriptRoot '..\model-router-tui\model-router-tui.exe'
            $altPath = Join-Path $repoRootGlobal 'build\public\model-router-tui.exe'
            if (Test-Path $tuiPath) {
                & $tuiPath "--config=$ConfigPath"
            } elseif (Test-Path $altPath) {
                & $altPath "--config=$ConfigPath"
            } else {
                Write-Error "TUI binary not found. Build with: go build -o model-router-tui.exe ./scripts/utilities/model-router-tui/"
            }
        }

        default {
            Write-Host "`nModel Router v2.0" -ForegroundColor Cyan
            Write-Host "Usage: wf.ps1 route <action> [options]" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Actions:" -ForegroundColor White
            Write-Host "  list                              Show all agent bindings" -ForegroundColor Gray
            Write-Host "  show --agent <CODE>               Show single agent binding" -ForegroundColor Gray
            Write-Host "  set --agent <CODE> [options]      Set binding (requires admin)" -ForegroundColor Gray
            Write-Host "  reset [--agent <CODE>]            Reset to defaults (requires admin)" -ForegroundColor Gray
            Write-Host "  defaults [options]                Set global defaults (requires admin)" -ForegroundColor Gray
            Write-Host "  defaults --init                   Initialize config + register this PC" -ForegroundColor Gray
            Write-Host "  tui                               Launch interactive TUI" -ForegroundColor Gray
            Write-Host "  admin-status                      Show admin auth status" -ForegroundColor Gray
            Write-Host "  admin-auth [options]               Authenticate as admin" -ForegroundColor Gray
            Write-Host "  admin-register-pc                  Register this PC as trusted (requires admin)" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Options:" -ForegroundColor White
            Write-Host "  --agent <CODE>        $($script:ALL_AGENTS -join ' | ')" -ForegroundColor Gray
            Write-Host "  --model <NAME>        Model identifier" -ForegroundColor Gray
            Write-Host "  --provider <CODE>     Provider from cloud-agents.json" -ForegroundColor Gray
            Write-Host "  --temperature <0-2>   Override temperature" -ForegroundColor Gray
            Write-Host "  --AdminPassword <pwd> Admin password (for non-trusted PCs)" -ForegroundColor Gray
            Write-Host "  --AdminKeyFile <path> Path to master.key" -ForegroundColor Gray
            Write-Host "  -Json                 Output as JSON" -ForegroundColor Gray
        }
    }
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if ($Help) {
    Invoke-RouteCommand -Action ''
    return
}

if ($Action) {
    Invoke-RouteCommand -Action $Action -Agent $Agent -Model $Model -Provider $Provider -Temperature $Temperature -AdminPassword $AdminPassword -AdminKeyFile $AdminKeyFile -JSON:$JSON
}
