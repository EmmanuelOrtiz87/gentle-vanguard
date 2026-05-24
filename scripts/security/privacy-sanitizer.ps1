# Privacy Sanitizer - Gentle-Vanguard
# Sanitiza outputs automaticos para evitar data leakage

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Content,
    
    [ValidateSet('prompt', 'log', 'error', 'all')]
    [string]$Mode = 'prompt'
)

$ErrorActionPreference = 'Stop'
$scriptPath = $PSCommandPath
$scriptDir = Split-Path -Parent $scriptPath
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

# =============================================================================
# PATRONES PROHIBIDOS
# =============================================================================

$BLOCKED_PATTERNS = @{
    machineId = @(
        [System.Environment]::MachineName,
        'COMPUTERNAME',
        $env:COMPUTERNAME
    )
    userId = @(
        $env:USERNAME,
        'USERNAME',
        [System.Environment]::UserName
    )
    homePath = @(
        [System.Environment]::GetFolderPath('UserProfile'),
        [System.Environment]::GetFolderPath('ApplicationData'),
        $env:USERPROFILE,
        $env:HOME,
        $env:APPDATA
    )
    envVars = @(
        'API_KEY',
        'SECRET',
        'PASSWORD',
        'TOKEN',
        'CREDENTIAL',
        'AUTH'
    )
    ipAddress = @(
        '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
    )
    awsKeys = @(
        'AKIA[0-9A-Z]{16}',
        'aws_secret_access_key'
    )
    apiKeys = @(
        'sk_live_[0-9a-zA-Z]{24,}',
        'ghp_[A-Za-z0-9]{36}'
    )
}

# =============================================================================
# FUNCIONES DE SANITIZACION
# =============================================================================

function Sanitize-MachineId {
    param([string]$Text)
    $BLOCKED_PATTERNS.machineId | Where-Object { $_ } | ForEach-Object {
        $Text = $Text -replace [regex]::Escape($_), '<MACHINE>'
    }
    return $Text
}

function Sanitize-UserId {
    param([string]$Text)
    $BLOCKED_PATTERNS.userId | Where-Object { $_ } | ForEach-Object {
        $Text = $Text -replace [regex]::Escape($_), '<USER>'
    }
    return $Text
}

function Sanitize-HomePath {
    param([string]$Text)
    $BLOCKED_PATTERNS.homePath | ForEach-Object {
        if ($_) {
            $Text = $Text -replace [regex]::Escape($_), '<HOME>'
            $Text = $Text -replace [regex]::Escape($_.Replace('\', '\\')), '<HOME>'
        }
    }
    return $Text
}

function Sanitize-Credentials {
    param([string]$Text)
    foreach ($key in $BLOCKED_PATTERNS.envVars) {
        $envPattern = '(?i)(\$env:' + $key + '|[A-Z_]+_KEY)\s*=\s*["\x27]?[^"\x27\s]+["\x27]?'
        $Text = $Text -replace $envPattern, '$<KEY>=[REDACTED]'
    }
    $BLOCKED_PATTERNS.apiKeys | ForEach-Object {
        $Text = $Text -replace $_, '<API_KEY>'
    }
    $BLOCKED_PATTERNS.awsKeys | ForEach-Object {
        $Text = $Text -replace $_, '<AWS_KEY>'
    }
    return $Text
}

function Sanitize-IPAddress {
    param([string]$Text)
    $Text = $Text -replace $BLOCKED_PATTERNS.ipAddress[0], '<IP>'
    return $Text
}

function Sanitize-FilePaths {
    param([string]$Text)
    # Windows paths: C:\Users\...\ -> <PATH>
    $Text = $Text -replace 'C:\\Users\\[^\\]+', '<HOME>'
    $Text = $Text -replace '/home/[^/]+', '<HOME>'
    # UNC paths
    $Text = $Text -replace '\\\\[A-Za-z0-9_-]+\\[^\\]+', '<UNC>'
    return $Text
}

function Sanitize-Timestamps {
    param([string]$Text)
    # Generic ISO timestamps allowed
    # But redact specific user timestamps if combined with user data
    return $Text
}

# =============================================================================
# MODO DE OPERACION
# =============================================================================

function Invoke-Sanitization {
    param([string]$Text, [string]$Mode)
    
    $result = $Text
    
    switch ($Mode) {
        'prompt' {
            # Max sanitization for prompts to AI APIs
            $result = Sanitize-MachineId -Text $result
            $result = Sanitize-UserId -Text $result
            $result = Sanitize-HomePath -Text $result
            $result = Sanitize-Credentials -Text $result
            $result = Sanitize-IPAddress -Text $result
            $result = Sanitize-FilePaths -Text $result
        }
        'log' {
            # Moderate for logs (keep some context)
            $result = Sanitize-MachineId -Text $result
            $result = Sanitize-UserId -Text $result
            $result = Sanitize-HomePath -Text $result
            $result = Sanitize-Credentials -Text $result
            $result = Sanitize-FilePaths -Text $result
        }
        'error' {
            # Minimal for errors (for debugging)
            $result = Sanitize-MachineId -Text $result
            $result = Sanitize-UserId -Text $result
            $result = Sanitize-Credentials -Text $result
            $result = Sanitize-FilePaths -Text $result
        }
    }
    
    return $result
}

# =============================================================================
# EJECUCION
# =============================================================================

try {
    $sanitized = Invoke-Sanitization -Text $Content -Mode $Mode
    
    if ($PSBoundParameters.ContainsKey('Verbose')) {
        Write-Host "=== PRIVACY SANITIZER ===" -ForegroundColor Cyan
        Write-Host "Mode: $Mode" -ForegroundColor Yellow
        Write-Host "Original length: $($Content.Length)" -ForegroundColor Gray
        Write-Host "Sanitized length: $($sanitized.Length)" -ForegroundColor Gray
        Write-Host "---" -ForegroundColor Gray
    }
    
    Write-Output $sanitized
    exit 0
}
catch {
    Write-Error "Privacy Sanitizer failed: $_"
    Write-Output $Content  # Return original on failure
    exit 1
}
