# Privacy Gateway - Foundation
# Intermediario para sanitizacion automatica de prompts

param(
    [Parameter(Mandatory)]
    [string]$Text,
    
    [ValidateSet('ai-api', 'mcp', 'log', 'error', 'prompt')]
    [string]$Target = 'prompt',
    
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'
$scriptPath = $PSCommandPath
$scriptDir = Split-Path -Parent $scriptPath
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

# Fallback sanitization (built-in, no dependency on external scripts)
function FallbackSanitize {
    param([string]$Input)
    
    $machineName = [System.Environment]::MachineName
    $userName = [System.Environment]::UserName
    $homePath = [System.Environment]::GetFolderPath('UserProfile')
    
    $result = $Input
    $result = $result -replace [regex]::Escape($machineName), '<MACHINE>'
    $result = $result -replace [regex]::Escape($userName), '<USER>'
    $result = $result -replace [regex]::Escape($homePath), '<HOME>'
    $result = $result -replace 'C:\\Users\\[^\\]+', '<HOME>'
    $result = $result -replace '/home/[^/]+', '<HOME>'
    
    return $result
}

# Try security orchestrator first
$securityScript = Join-Path $repoRoot 'scripts\security\security-orchestrator.ps1'
$sanitized = $null
$method = 'fallback'

if (Test-Path $securityScript) {
    try {
        $sanitized = & $securityScript -Action "sanitize" -Content $Text -Mode "prompt" 2>$null
        if ($sanitized) {
            $method = 'orchestrator'
        }
    }
    catch {
        Write-Host "[DEBUG] Orchestrator error: $_" -ForegroundColor Gray
    }
}

if (-not $sanitized) {
    $sanitized = FallbackSanitize -Input $Text
}

# Output
if ($AsJson) {
    @{
        status = 'OK'
        method = $method
        original = $Text
        sanitized = $sanitized
        target = $Target
    } | ConvertTo-Json -Depth 3
}
else {
    Write-Output $sanitized
}