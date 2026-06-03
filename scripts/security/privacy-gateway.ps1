# Privacy Gateway - Gentle-Vanguard
# Intermediario para sanitizacion automatica de prompts

param(
    [Parameter(Mandatory)]
    [string]$Text,
    
    [ValidateSet('ai-api', 'mcp', 'log', 'error', 'prompt')]
    [string]$Target = 'prompt',
    
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$scriptPath = $PSCommandPath
$scriptDir = Split-Path -Parent $scriptPath
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

# Prompt injection detection patterns
$INJECTION_PATTERNS = @(
    @{ Pattern = '(?i)(?:\bignore\s+(?:all\s+)?(?:previous\s+)?(?:instructions|commands|directions|rules|prompts?|constraints?|guidelines?|orders?))\b'; Category = 'instruction-override'; Severity = 'CRITICAL' },
    @{ Pattern = '(?i)(?:\b(?:repeat|output|print|show|display|reveal|leak|dump|copy)\s+(?:your\s+)?(?:system\s+)?(?:prompt|instructions|rules|directions|commands|guidelines|initial\s+prompt|system\s+message))\b'; Category = 'prompt-leakage'; Severity = 'CRITICAL' },
    @{ Pattern = '(?i)(?:\byou\s+(?:are\s+)?(?:now|must\s+act\s+as|will\s+pretend|have\s+to\s+roleplay|shall\s+behave))\b'; Category = 'role-takeover'; Severity = 'HIGH' },
    @{ Pattern = '(?i)(?:DAN|do\s+anything\s+now|jailbreak|jail\s*broken|unrestricted\s+mode|god\s+mode|developer\s+mode|debug\s+mode|super\s+mode|free\s+mode|no\s+(?:limits|restrictions|filter|boundaries))\b'; Category = 'jailbreak'; Severity = 'CRITICAL' },
    @{ Pattern = '(?i)(?:\$?(?:exec|run|eval|system|shell|cmd|powershell|bash|sh|zsh|os\.system|subprocess|child_process|execSync|spawn)\s*[\(])'; Category = 'code-execution'; Severity = 'CRITICAL' },
    @{ Pattern = '(?i)(?:\b(?:new\s+)?system\s+prompt\s*[:=]|重置|新\s*的\s*提\s*示|system\s+message\s*[:=]|##?\s*system\s*(?:prompt|instructions))\b'; Category = 'prompt-override'; Severity = 'HIGH' },
    @{ Pattern = '(?i)(?:base64\s*(?:decode|encode|64)|rot[0-9]+|hex\s*(?:decode|encode)|unicode\s*escape|reverse\s*(?:string|text))\s*(?:the\s+)?(?:following|above|below|this)\s*(?:text|message|prompt|string|instructions)'; Category = 'encoding-obfuscation'; Severity = 'HIGH' },
    @{ Pattern = '(?i)(?:respond\s+(?:with|in\s+a\s+way\s+that\s+doesnt\s+reflect|without\s+(?:the\s+)?(?:usual|typical|standard|normal))|dont\s+(?:adhere|follow|abide|comply|stick)\s+to)'; Category = 'constraint-bypass'; Severity = 'HIGH' },
    @{ Pattern = '(?i)(?:pretend|imagine|simulate|hypothetically)\s+(?:you\s+are|youve\s+been\s+replaced|you\s+have\s+no\s+(?:rules|restrictions|limits|boundaries|filters))'; Category = 'simulation-attack'; Severity = 'HIGH' },
    @{ Pattern = '(?i)(?:forget|ignore|disregard|skip|omit|override|bypass|circumvent)\s+(?:all\s+)?(?:previous\s+)?(?:instructions|commands|rules|directions|prompts|constraints|guidelines|policies|safeguards|protocols)\b'; Category = 'instruction-override'; Severity = 'CRITICAL' }
)

# Fallback sanitization (built-in, no dependency on external scripts)
function Test-InjectionAttempt {
    param([string]$Text)
    
    foreach ($p in $INJECTION_PATTERNS) {
        if ($Text -match $p.Pattern) {
            return @{
                detected = $true
                category = $p.Category
                severity = $p.Severity
                matched = $matches[0]
            }
        }
    }
    return @{ detected = $false }
}

function FallbackSanitize {
    param([string]$Input)
    
    $machineName = [System.Environment]::MachineName
    $userName = [System.Environment]::UserName
    $homePath = [System.Environment]::GetFolderPath('UserProfile')
    
    $result = $Input
    if ($machineName) { $result = $result -replace [regex]::Escape($machineName), '<MACHINE>' }
    if ($userName) { $result = $result -replace [regex]::Escape($userName), '<USER>' }
    if ($homePath) { $result = $result -replace [regex]::Escape($homePath), '<HOME>' }
    $result = $result -replace 'C:\\Users\\[^\\]+', '<HOME>'
    $result = $result -replace '/home/[^/]+', '<HOME>'
    
    return $result
}

# Check for prompt injection / jailbreak / leakage attempts
$injectionCheck = Test-InjectionAttempt -Text $Text

if ($injectionCheck.detected) {
    $blocked = @{
        status = 'BLOCKED'
        category = $injectionCheck.category
        severity = $injectionCheck.severity
        matched = $injectionCheck.matched
        message = "Prompt security violation detected: $($injectionCheck.category) [severity: $($injectionCheck.severity)]"
    }
    if ($AsJson) { return $blocked | ConvertTo-Json -Depth 3 }
    Write-Host "[BLOCKED] $($blocked.message)" -ForegroundColor Red
    exit 1
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
        injectionChecked = $true
    } | ConvertTo-Json -Depth 3
}
else {
    Write-Output $sanitized
}
