#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Input Validator - Sanitization and Validation
    
.DESCRIPTION
    Validates and sanitizes input to prevent injection attacks
    
.PARAMETER Input
    Input to validate
    
.PARAMETER Type
    Type of validation: string, integer, path, command
    
.EXAMPLE
    .\input-validator.ps1 -Input "test-data" -Type string
#>

param(
    [string]$InputText,
    [ValidateSet('string', 'integer', 'path', 'command', 'email')]
    [string]$Type = 'string',
    [string]$LogLevel = 'info'
)

$ValidatorVersion = "1.0.0"

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Validate-String {
    param([string]$Value)
    
    Write-Log "Validating string input..." "info"
    
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Log "Input is null or whitespace" "error"
        return $false
    }
    
    if ($Value.Length -gt 10000) {
        Write-Log "Input exceeds maximum length (10000)" "error"
        return $false
    }
    
    $dangerousChars = @(';', '|', '&', '$', '`', '>', '<', '(', ')', '{', '}', '[', ']')
    foreach ($char in $dangerousChars) {
        if ($Value.Contains($char)) {
            Write-Log "Input contains dangerous character: $char" "error"
            return $false
        }
    }
    
    Write-Log "String validation passed" "info"
    return $true
}

function Validate-Integer {
    param([string]$Value)
    
    Write-Log "Validating integer input..." "info"
    
    if ($Value -match '^\d+$') {
        $intValue = [int]$Value
        if ($intValue -lt 0 -or $intValue -gt 10000) {
            Write-Log "Integer out of valid range (0-10000)" "error"
            return $false
        }
        Write-Log "Integer validation passed" "info"
        return $true
    }
    
    Write-Log "Input is not a valid integer" "error"
    return $false
}

function Validate-Path {
    param([string]$Value)
    
    Write-Log "Validating path input..." "info"
    
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Log "Path is null or whitespace" "error"
        return $false
    }
    
    if ($Value -match "\.\.") {
        Write-Log "Path contains traversal attempt" "error"
        return $false
    }
    
    if ([System.IO.Path]::IsPathRooted($Value)) {
        Write-Log "Absolute paths not allowed" "error"
        return $false
    }
    
    Write-Log "Path validation passed" "info"
    return $true
}

function Validate-Command {
    param([string]$Value)
    
    Write-Log "Validating command input..." "info"
    
    $dangerousPatterns = @(
        '&&',
        '||',
        ';',
        '|',
        '`',
        '$(',
        '$()',
        'rm ',
        'del ',
        'format ',
        'shutdown'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Value -match [regex]::Escape($pattern)) {
            Write-Log "Command contains dangerous pattern: $pattern" "error"
            return $false
        }
    }
    
    Write-Log "Command validation passed" "info"
    return $true
}

function Validate-Email {
    param([string]$Value)
    
    Write-Log "Validating email input..." "info"
    
    $emailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    
    if ($Value -notmatch $emailPattern) {
        Write-Log "Invalid email format" "error"
        return $false
    }
    
    Write-Log "Email validation passed" "info"
    return $true
}

function Main {
    Write-Log "Input Validator v$ValidatorVersion" "info"
    Write-Log "Validating input as type: $Type" "info"
    
    $result = switch ($Type) {
        'string' { Validate-String -Value $InputText }
        'integer' { Validate-Integer -Value $InputText }
        'path' { Validate-Path -Value $InputText }
        'command' { Validate-Command -Value $InputText }
        'email' { Validate-Email -Value $InputText }
        default { $false }
    }
    
    if ($result) {
        Write-Log "Validation successful" "info"
        return 0
    }
    else {
        Write-Log "Validation failed" "error"
        return 1
    }
}

exit (Main)