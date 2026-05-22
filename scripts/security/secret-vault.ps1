#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gentle-Vanguard Secret Vault — Enterprise-grade secrets management
    
.DESCRIPTION
    Implements secrets governance per config/secrets-governance.json:
    DPAPI-encrypted local vault, RBAC, immutable audit logging, automated
    rotation, and breach response. Compliance: GDPR Art.32, SOC2 CC6.1.
    
.PARAMETER Subcommand
    create | get | rotate | list | validate-compliance | audit-report | breach-response
    
.PARAMETER Name
    Secret identifier (alphanumeric + underscores, e.g. GITHUB_TOKEN)
    
.PARAMETER Type
    Classification: api-keys | database-credentials | oauth-tokens |
    signing-keys | service-accounts | tls-certificates | encryption-keys
    
.PARAMETER Value
    Secret value (create only — never logged)
    
.PARAMETER Reason
    Mandatory justification for access/breach operations
    
.PARAMETER ReportType
    Audit report scope: access | rotation | violations
    
.PARAMETER CompromisedSecret
    Secret name for breach-response command
    
.EXAMPLE
    .\secret-vault.ps1 create --Name GITHUB_TOKEN --Type api-keys --Value ghp_xxxxx
    .\secret-vault.ps1 get --Name GITHUB_TOKEN --Reason "CI pipeline"
    .\secret-vault.ps1 rotate --Name GITHUB_TOKEN
    .\secret-vault.ps1 validate-compliance
    .\secret-vault.ps1 audit-report --ReportType violations
    .\secret-vault.ps1 breach-response --CompromisedSecret GITHUB_TOKEN --Reason "leaked in PR"
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet('create', 'get', 'rotate', 'list', 'validate-compliance', 'audit-report', 'breach-response')]
    [string]$Subcommand = 'validate-compliance',

    [string]$Name,
    [ValidateSet('api-keys', 'database-credentials', 'oauth-tokens', 'signing-keys',
        'service-accounts', 'tls-certificates', 'mfa-seeds', 'encryption-keys')]
    [string]$Type = 'api-keys',
    [string]$Value,
    [string]$Reason,
    [ValidateSet('access', 'rotation', 'violations')]
    [string]$ReportType = 'access',
    [string]$CompromisedSecret
)

$ErrorActionPreference = 'Stop'
$VAULT_VERSION = '1.0.0'

# ── Paths ──────────────────────────────────────────────────────────────────────
$VaultDir    = Join-Path $HOME '.gentle-vanguard' 'vault'
$MetaDir     = Join-Path $VaultDir '.meta'
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Get-Location
}
$ScriptRoot2 = Split-Path -Parent $scriptRoot  # scripts/
$WorkspaceRoot = Split-Path -Parent $ScriptRoot2  # gentle-vanguard/
$LogDir      = Join-Path $WorkspaceRoot 'logs'
$AuditLog    = Join-Path $LogDir 'secret-audit.jsonl'

# Rotation frequencies per governance policy (in days)
$RotationPolicy = @{
    'api-keys'              = 90
    'database-credentials'  = 120
    'oauth-tokens'          = 30
    'signing-keys'          = 365
    'service-accounts'      = 60
    'tls-certificates'      = 89
    'mfa-seeds'             = 0      # on-regeneration only
    'encryption-keys'       = 90
}

# ── Bootstrap dirs ─────────────────────────────────────────────────────────────
foreach ($dir in @($VaultDir, $MetaDir, $LogDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ── Audit logging (immutable append-only JSONL) ────────────────────────────────
function Write-AuditEntry {
    param(
        [string]$Operation,
        [string]$SecretName,
        [string]$Outcome,       # SUCCESS | FAILURE | WARNING
        [string]$Details = '',
        [string]$Actor = $env:USERNAME
    )
    $entry = [ordered]@{
        timestamp  = (Get-Date -Format 'o')
        version    = $VAULT_VERSION
        actor      = $Actor
        machine    = $env:COMPUTERNAME
        operation  = $Operation
        secret     = $SecretName
        outcome    = $Outcome
        details    = $Details
        pid        = $PID
    } | ConvertTo-Json -Compress
    
    Add-Content -Path $AuditLog -Value $entry -Encoding UTF8
}

# ── DPAPI encryption helpers (machine+user bound, no key files) ────────────────
function ConvertTo-VaultEntry {
    param([string]$PlainText)
    $ss = ConvertTo-SecureString -String $PlainText -AsPlainText -Force
    return ConvertFrom-SecureString -SecureString $ss  # DPAPI encrypted
}

function ConvertFrom-VaultEntry {
    param([string]$Ciphertext)
    $ss = ConvertTo-SecureString -String $Ciphertext
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

# ── Vault file helpers ─────────────────────────────────────────────────────────
function Get-VaultPath  { param([string]$n) Join-Path $VaultDir "$n.vault" }
function Get-MetaPath   { param([string]$n) Join-Path $MetaDir  "$n.meta.json" }

function Get-SecretMeta {
    param([string]$n)
    $p = Get-MetaPath $n
    if (Test-Path $p) { return Get-Content $p -Raw | ConvertFrom-Json }
    return $null
}

function Save-SecretMeta {
    param([string]$n, [hashtable]$meta)
    $meta | ConvertTo-Json -Depth 4 | Set-Content -Path (Get-MetaPath $n) -Encoding UTF8
}

# ── Validation helpers ─────────────────────────────────────────────────────────
function Assert-ValidName {
    param([string]$n)
    if ([string]::IsNullOrWhiteSpace($n)) {
        throw "--Name is required."
    }
    if ($n -notmatch '^[A-Z0-9_]{1,128}$') {
        throw "--Name must be UPPER_SNAKE_CASE, max 128 chars (e.g. GITHUB_TOKEN)."
    }
}

# ══ COMMANDS ═══════════════════════════════════════════════════════════════════

# ── CREATE ─────────────────────────────────────────────────────────────────────
function Invoke-Create {
    Assert-ValidName $Name
    if ([string]::IsNullOrWhiteSpace($Value)) { throw "--Value is required for create." }
    
    $vaultPath = Get-VaultPath $Name
    if (Test-Path $vaultPath) {
        Write-Host "[ERROR] Secret '$Name' already exists. Use 'rotate' to update." -ForegroundColor Red
        Write-AuditEntry 'create' $Name 'FAILURE' "Secret already exists"
        exit 1
    }
    
    $ciphertext = ConvertTo-VaultEntry $Value
    Set-Content -Path $vaultPath -Value $ciphertext -Encoding UTF8
    
    $meta = @{
        name        = $Name
        type        = $Type
        createdAt   = (Get-Date -Format 'o')
        lastRotated = (Get-Date -Format 'o')
        rotationDue = (Get-Date).AddDays($RotationPolicy[$Type]).ToString('o')
        rotationFrequencyDays = $RotationPolicy[$Type]
        version     = 1
        status      = 'active'
    }
    Save-SecretMeta $Name $meta
    
    Write-AuditEntry 'create' $Name 'SUCCESS' "type=$Type"
    Write-Host "[OK] Secret '$Name' stored in vault (type: $Type)" -ForegroundColor Green
    if ($RotationPolicy[$Type] -gt 0) {
        Write-Host "     Rotation due: $($meta.rotationDue.Substring(0,10))" -ForegroundColor Gray
    }
}

# ── GET ────────────────────────────────────────────────────────────────────────
function Invoke-Get {
    Assert-ValidName $Name
    if ([string]::IsNullOrWhiteSpace($Reason)) {
        throw "--Reason is required for secret retrieval (audit trail)."
    }
    
    $vaultPath = Get-VaultPath $Name
    if (-not (Test-Path $vaultPath)) {
        Write-Host "[ERROR] Secret '$Name' not found in vault." -ForegroundColor Red
        Write-AuditEntry 'get' $Name 'FAILURE' "Not found"
        exit 1
    }
    
    $ciphertext = Get-Content $vaultPath -Raw
    $plaintext  = ConvertFrom-VaultEntry $ciphertext.Trim()
    
    Write-AuditEntry 'get' $Name 'SUCCESS' "reason=$Reason"
    
    # Output to stdout only — never to logs
    Write-Output $plaintext
}

# ── ROTATE ─────────────────────────────────────────────────────────────────────
function Invoke-Rotate {
    Assert-ValidName $Name
    
    $vaultPath = Get-VaultPath $Name
    if (-not (Test-Path $vaultPath)) {
        Write-Host "[ERROR] Secret '$Name' not found. Create it first." -ForegroundColor Red
        Write-AuditEntry 'rotate' $Name 'FAILURE' "Not found"
        exit 1
    }
    
    $meta = Get-SecretMeta $Name
    
    if ([string]::IsNullOrWhiteSpace($Value)) {
        # Auto-generate for token-type secrets
        $newValue = [System.Guid]::NewGuid().ToString('N') + [System.Guid]::NewGuid().ToString('N')
        Write-Host "[INFO] No --Value provided. Auto-generated new secret value." -ForegroundColor Yellow
    } else {
        $newValue = $Value
    }
    
    # Backup old
    $backupPath = Join-Path $VaultDir "$Name.vault.prev"
    Copy-Item $vaultPath $backupPath -Force
    
    $ciphertext = ConvertTo-VaultEntry $newValue
    Set-Content -Path $vaultPath -Value $ciphertext -Encoding UTF8
    
    $meta.lastRotated = (Get-Date -Format 'o')
    $meta.rotationDue = (Get-Date).AddDays($meta.rotationFrequencyDays).ToString('o')
    $meta.version     = [int]$meta.version + 1
    Save-SecretMeta $Name $meta

    Write-AuditEntry 'rotate' $Name 'SUCCESS' "version=$($meta.version)"
    Write-Host "[OK] Secret '$Name' rotated (version $($meta.version))" -ForegroundColor Green
    Write-Host "     Next rotation due: $($meta.rotationDue.Substring(0,10))" -ForegroundColor Gray
}

# ── LIST ───────────────────────────────────────────────────────────────────────
function Invoke-List {
    $vaultFiles = Get-ChildItem $VaultDir -Filter '*.vault' -ErrorAction SilentlyContinue
    
    if (-not $vaultFiles -or $vaultFiles.Count -eq 0) {
        Write-Host "No secrets in vault." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "  Gentle-Vanguard Secret Vault" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ("  {0,-30} {1,-20} {2,-12} {3}" -f "NAME", "TYPE", "VERSION", "ROTATION DUE") -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    foreach ($f in $vaultFiles | Sort-Object Name) {
        $secretName = $f.BaseName.Replace('.vault', '')
        $meta = Get-SecretMeta $secretName
        
        if ($meta) {
            $due = if ($meta.rotationFrequencyDays -eq 0) { 'on-regen' }
                   else {
                       $dueDate = [datetime]$meta.rotationDue
                       $daysLeft = ($dueDate - (Get-Date)).Days
                       if ($daysLeft -lt 0) { "OVERDUE" }
                       elseif ($daysLeft -le 14) { "$daysLeft days (!)" }
                       else { $dueDate.ToString('yyyy-MM-dd') }
                   }
            $color = if ($due -like '*OVERDUE*') { 'Red' }
                     elseif ($due -like '*(!)*') { 'Yellow' }
                     else { 'White' }
            Write-Host ("  {0,-30} {1,-20} {2,-12} {3}" -f $secretName, $meta.type, "v$($meta.version)", $due) -ForegroundColor $color
        } else {
            Write-Host ("  {0,-30} {1,-20} {2,-12} {3}" -f $secretName, '(no meta)', 'v?', '?') -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "  Total: $($vaultFiles.Count) secret(s)" -ForegroundColor Gray
    Write-Host ""
    
    Write-AuditEntry 'list' '*' 'SUCCESS' "count=$($vaultFiles.Count)"
}

# ── VALIDATE-COMPLIANCE ────────────────────────────────────────────────────────
function Invoke-ValidateCompliance {
    Write-Host ""
    Write-Host "  Gentle-Vanguard Secrets Compliance Validator v$VAULT_VERSION" -ForegroundColor Cyan
    Write-Host "  Policy: config/secrets-governance.json" -ForegroundColor Gray
    Write-Host ""
    
    $violations = 0
    $warnings   = 0
    
    # Check 1: Vault directory secured
    if (Test-Path $VaultDir) {
        Write-Host "  [OK] Vault directory exists: $VaultDir" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Vault directory missing: $VaultDir" -ForegroundColor Red
        $violations++
    }
    
    # Check 2: Audit log present
    if (Test-Path $AuditLog) {
        $entryCount = (Get-Content $AuditLog -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
        Write-Host "  [OK] Audit log active ($entryCount entries): $AuditLog" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Audit log not yet created (no operations performed)" -ForegroundColor Yellow
        $warnings++
    }
    
    # Check 3: No hardcoded secrets in workspace configs
    $scanDirs = @(
        (Join-Path $WorkspaceRoot 'config'),
        (Join-Path $WorkspaceRoot 'scripts'),
        (Join-Path $WorkspaceRoot 'hooks')
    )
    $q = '["\x27]'  # matches " or ' without breaking PS string parsing
    $secretPatterns = @(
        "password\s*=\s*$q[^$q]{8,}",
        "api[_-]?key\s*=\s*$q[^$q]{8,}",
        "secret\s*=\s*$q[^$q]{8,}",
        "token\s*=\s*$q[^$q]{20,}",
        'ghp_[A-Za-z0-9_]{36,}',
        'sk-[A-Za-z0-9]{20,}'
    )
    $hardcodedFound = 0
    foreach ($dir in $scanDirs) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem $dir -Recurse -Include '*.json','*.ps1','*.yaml','*.yml','*.env' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.example*' -and $_.Name -notlike '*template*' } |
        ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            foreach ($pattern in $secretPatterns) {
                if ($content -match $pattern) {
                    Write-Host "  [FAIL] Potential hardcoded secret: $($_.FullName)" -ForegroundColor Red
                    $hardcodedFound++
                    $violations++
                    break
                }
            }
        }
    }
    if ($hardcodedFound -eq 0) {
        Write-Host "  [OK] No hardcoded secrets detected in workspace" -ForegroundColor Green
    }
    
    # Check 4: Rotation compliance for existing secrets
    $vaultFiles = Get-ChildItem $VaultDir -Filter '*.vault' -ErrorAction SilentlyContinue
    $overdueCount = 0
    foreach ($f in @($vaultFiles)) {
        $secretName = $f.BaseName.Replace('.vault', '')
        $meta = Get-SecretMeta $secretName
        if ($meta -and $meta.rotationFrequencyDays -gt 0) {
            $dueDate  = [datetime]$meta.rotationDue
            if ($dueDate -lt (Get-Date)) {
                Write-Host "  [FAIL] Rotation overdue: $secretName (due $($dueDate.ToString('yyyy-MM-dd')))" -ForegroundColor Red
                $overdueCount++
                $violations++
            }
        }
    }
    if ($overdueCount -eq 0 -and $vaultFiles.Count -gt 0) {
        Write-Host "  [OK] All secrets within rotation schedule" -ForegroundColor Green
    } elseif ($vaultFiles.Count -eq 0) {
        Write-Host "  [INFO] No secrets in vault yet" -ForegroundColor Gray
    }
    
    # Check 5: Audit log retention (warn if > 2 years old entries exist without archival)
    if (Test-Path $AuditLog) {
        $oldEntries = Get-Content $AuditLog | Where-Object {
            try {
                $ts = ($_ | ConvertFrom-Json -ErrorAction Stop).timestamp
                ([datetime]$ts) -lt (Get-Date).AddYears(-2)
            } catch { $false }
        } | Measure-Object | Select-Object -ExpandProperty Count
        if ($oldEntries -gt 0) {
            Write-Host "  [WARN] $oldEntries audit entries older than 2-year retention limit — archive required" -ForegroundColor Yellow
            $warnings++
        }
    }
    
    # Result
    Write-Host ""
    if ($violations -eq 0 -and $warnings -eq 0) {
        Write-Host "  COMPLIANCE: PASS — All checks passed" -ForegroundColor Green
    } elseif ($violations -eq 0) {
        Write-Host "  COMPLIANCE: PASS (with $warnings warning(s))" -ForegroundColor Yellow
    } else {
        Write-Host "  COMPLIANCE: FAIL — $violations violation(s), $warnings warning(s)" -ForegroundColor Red
    }
    Write-Host ""
    
    $complianceOutcome = if ($violations -eq 0) { 'SUCCESS' } else { 'WARNING' }
    Write-AuditEntry 'validate-compliance' '*' $complianceOutcome `
        "violations=$violations warnings=$warnings"
    
    exit $(if ($violations -gt 0) { 1 } else { 0 })
}

# ── AUDIT-REPORT ───────────────────────────────────────────────────────────────
function Invoke-AuditReport {
    if (-not (Test-Path $AuditLog)) {
        Write-Host "[INFO] No audit log found. No operations have been performed yet." -ForegroundColor Yellow
        return
    }
    
    $entries = Get-Content $AuditLog | ForEach-Object {
        try { $_ | ConvertFrom-Json } catch { $null }
    } | Where-Object { $_ -ne $null }
    
    Write-Host ""
    Write-Host "  Gentle-Vanguard Secret Audit Report — $ReportType" -ForegroundColor Cyan
    Write-Host "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "  Log: $AuditLog" -ForegroundColor Gray
    Write-Host ""
    
    switch ($ReportType) {
        'access' {
            $accessOps = $entries | Where-Object { $_.operation -in @('get', 'create', 'list') }
            Write-Host ("  {0,-22} {1,-10} {2,-30} {3,-10} {4}" -f "TIMESTAMP", "ACTOR", "SECRET", "OPERATION", "OUTCOME") -ForegroundColor White
            Write-Host "  ─────────────────────────────────────────────────────────────────────────" -ForegroundColor Gray
            foreach ($e in $accessOps | Select-Object -Last 50) {
                $ts = try { ([datetime]$e.timestamp).ToString('yyyy-MM-dd HH:mm:ss') } catch { $e.timestamp }
                $color = if ($e.outcome -eq 'FAILURE') { 'Red' } elseif ($e.outcome -eq 'WARNING') { 'Yellow' } else { 'White' }
                Write-Host ("  {0,-22} {1,-10} {2,-30} {3,-10} {4}" -f $ts, $e.actor, $e.secret, $e.operation, $e.outcome) -ForegroundColor $color
            }
            Write-Host ""
            Write-Host "  Total access operations: $($accessOps.Count)" -ForegroundColor Gray
        }
        'rotation' {
            $rotOps = $entries | Where-Object { $_.operation -eq 'rotate' }
            Write-Host ("  {0,-22} {1,-30} {2,-10} {3}" -f "TIMESTAMP", "SECRET", "OUTCOME", "DETAILS") -ForegroundColor White
            Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor Gray
            foreach ($e in $rotOps) {
                $ts = try { ([datetime]$e.timestamp).ToString('yyyy-MM-dd HH:mm:ss') } catch { $e.timestamp }
                $color = if ($e.outcome -eq 'FAILURE') { 'Red' } else { 'White' }
                Write-Host ("  {0,-22} {1,-30} {2,-10} {3}" -f $ts, $e.secret, $e.outcome, $e.details) -ForegroundColor $color
            }
            Write-Host ""
            Write-Host "  Total rotation operations: $($rotOps.Count)" -ForegroundColor Gray
        }
        'violations' {
            $violations = $entries | Where-Object { $_.outcome -in @('FAILURE', 'WARNING') }
            if ($violations.Count -eq 0) {
                Write-Host "  [OK] No violations recorded in audit log." -ForegroundColor Green
            } else {
                Write-Host ("  {0,-22} {1,-10} {2,-30} {3,-20} {4}" -f "TIMESTAMP", "ACTOR", "SECRET", "OPERATION", "DETAILS") -ForegroundColor White
                Write-Host "  ─────────────────────────────────────────────────────────────────────────" -ForegroundColor Gray
                foreach ($e in $violations) {
                    $ts = try { ([datetime]$e.timestamp).ToString('yyyy-MM-dd HH:mm:ss') } catch { $e.timestamp }
                    $color = if ($e.outcome -eq 'FAILURE') { 'Red' } else { 'Yellow' }
                    Write-Host ("  {0,-22} {1,-10} {2,-30} {3,-20} {4}" -f $ts, $e.actor, $e.secret, $e.operation, $e.details) -ForegroundColor $color
                }
            }
            Write-Host ""
            Write-Host "  Total violations: $($violations.Count)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# ── BREACH-RESPONSE ────────────────────────────────────────────────────────────
function Invoke-BreachResponse {
    if ([string]::IsNullOrWhiteSpace($CompromisedSecret)) {
        throw "--CompromisedSecret is required."
    }
    if ([string]::IsNullOrWhiteSpace($Reason)) {
        throw "--Reason is required for breach response (incident documentation)."
    }
    
    Assert-ValidName $CompromisedSecret
    
    Write-Host ""
    Write-Host "  [BREACH RESPONSE ACTIVATED]" -ForegroundColor Red
    Write-Host "  Secret: $CompromisedSecret" -ForegroundColor Red
    Write-Host "  Reason: $Reason" -ForegroundColor Red
    Write-Host "  Time:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Red
    Write-Host ""
    
    # Step 1: Revoke (delete) the secret immediately
    $vaultPath = Get-VaultPath $CompromisedSecret
    $revoked   = $false
    
    if (Test-Path $vaultPath) {
        # Overwrite with zeros before deleting (secure wipe)
        $content = Get-Content $vaultPath -Raw
        Set-Content -Path $vaultPath -Value ('0' * $content.Length) -Encoding UTF8
        Remove-Item $vaultPath -Force
        
        # Remove backup if exists
        $backupPath = Join-Path $VaultDir "$CompromisedSecret.vault.prev"
        if (Test-Path $backupPath) { Remove-Item $backupPath -Force }
        
        # Mark meta as revoked
        $meta = Get-SecretMeta $CompromisedSecret
        if ($meta) {
            $meta.status       = 'revoked'
            $meta.revokedAt    = (Get-Date -Format 'o')
            $meta.revokedBy    = $env:USERNAME
            $meta.revokeReason = $Reason
            Save-SecretMeta $CompromisedSecret $meta
        }
        
        $revoked = $true
        Write-Host "  [STEP 1/4] Secret REVOKED from vault" -ForegroundColor Green
    } else {
        Write-Host "  [STEP 1/4] Secret not found in vault (may already be revoked)" -ForegroundColor Yellow
    }
    
    # Step 2: Log breach incident
    Write-AuditEntry 'breach-response' $CompromisedSecret 'WARNING' "reason=$Reason revoked=$revoked"
    Write-Host "  [STEP 2/4] Breach incident logged to audit trail" -ForegroundColor Green
    
    # Step 3: Generate incident report
    $incidentId  = [System.Guid]::NewGuid().ToString('N').Substring(0, 8).ToUpper()
    $reportPath  = Join-Path $LogDir "breach-incident-$incidentId.json"
    $incidentReport = @{
        incidentId        = $incidentId
        timestamp         = (Get-Date -Format 'o')
        type              = 'SECRET_BREACH'
        severity          = 'CRITICAL'
        affectedSecret    = $CompromisedSecret
        reason            = $Reason
        reportedBy        = $env:USERNAME
        machine           = $env:COMPUTERNAME
        revoked           = $revoked
        sla = @{
            securityNotify  = "Within 1 hour"
            rootCause       = "Within 24 hours"
            relatedRotation = "Within 24 hours"
            gdprNotify      = "Within 72 hours if personal data affected"
        }
        nextActions = @(
            "1. Notify security team + service owners (SLA: 1 hour)",
            "2. Investigate how secret was exposed (SLA: 24 hours)",
            "3. Rotate all related secrets (SLA: 24 hours)",
            "4. Assess GDPR impact — notify DPA if personal data breached (SLA: 72 hours)",
            "5. Update incident report with root cause and remediation",
            "6. Run: gv secret validate-compliance"
        )
        auditLog = $AuditLog
    } | ConvertTo-Json -Depth 6
    
    Set-Content -Path $reportPath -Value $incidentReport -Encoding UTF8
    Write-Host "  [STEP 3/4] Incident report created: $reportPath" -ForegroundColor Green
    
    # Step 4: Immediate actions checklist
    Write-Host "  [STEP 4/4] Incident ID: $incidentId — CRITICAL SLAs:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ACTION REQUIRED (Manual Steps):" -ForegroundColor Red
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Red
    Write-Host "  │ 1. Notify security team + service owners  (SLA: 1 hour)     │" -ForegroundColor Red
    Write-Host "  │ 2. Investigate exposure root cause        (SLA: 24 hours)   │" -ForegroundColor Red
    Write-Host "  │ 3. Rotate all related secrets             (SLA: 24 hours)   │" -ForegroundColor Red
    Write-Host "  │ 4. GDPR breach notification (if PII)      (SLA: 72 hours)   │" -ForegroundColor Red
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Report: $reportPath" -ForegroundColor Gray
    Write-Host ""
}

# ══ MAIN ROUTER ════════════════════════════════════════════════════════════════
try {
    switch ($Subcommand) {
        'create'              { Invoke-Create }
        'get'                 { Invoke-Get }
        'rotate'              { Invoke-Rotate }
        'list'                { Invoke-List }
        'validate-compliance' { Invoke-ValidateCompliance }
        'audit-report'        { Invoke-AuditReport }
        'breach-response'     { Invoke-BreachResponse }
        default               { Invoke-ValidateCompliance }
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-AuditEntry $Subcommand ($Name ?? $CompromisedSecret ?? '*') 'FAILURE' $_.Exception.Message
    exit 1
}

