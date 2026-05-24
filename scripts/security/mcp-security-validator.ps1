<#
.SYNOPSIS
    MCP Security Validator — pre-MCP hook for input validation and injection detection
.DESCRIPTION
    Validates MCP tool calls against prompt injection, jailbreak, and path traversal.
    Delegates to privacy-gateway.ps1 for injection detection and sanitization.
    Hook reference: config/security-privacy.json#hooks.preMcp
.PARAMETER Input
    MCP tool call input text to validate
.PARAMETER ToolName
    Name of the MCP tool being called (optional, for audit)
.PARAMETER AllowedPaths
    Comma-separated list of allowed directory paths
.EXAMPLE
    .\mcp-security-validator.ps1 -Input "read file /etc/passwd" -ToolName "read_file"
#>
param(
    [Parameter(Mandatory)]
    [string]$Input,
    [string]$ToolName,
    [string]$AllowedPaths = "$PWD/**"
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $PSCommandPath
$gateway = Join-Path $scriptDir "privacy-gateway.ps1"

# Check injection via privacy-gateway
if (Test-Path $gateway) {
    $result = & $gateway -Text $Input -AsJson 2>&1
    $parsed = if ($result -is [string]) { $result | ConvertFrom-Json } else { $result }
    if ($parsed.status -eq 'BLOCKED') {
        Write-Host "[MCP-SECURITY] BLOCKED: $($parsed.category) - $($parsed.message)" -ForegroundColor Red
        exit 1
    }
}

# Path traversal check for file tools
if ($ToolName -match 'read|write|delete|exec|run|file|path') {
    foreach ($part in $Input.Split(" \t\n")) {
        if ($part -match '\.\.\\\\|\.\./|~|/etc/|/var/|/root/|C:\\Windows|\\\\') {
            Write-Host "[MCP-SECURITY] BLOCKED: Path traversal detected in input: $part" -ForegroundColor Red
            exit 1
        }
    }
}

exit 0
