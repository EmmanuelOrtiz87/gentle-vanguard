# check-security.ps1
# Valida secretos y dependencias vulnerables

$ErrorActionPreference = 'Continue'

$StagedFiles = git diff --cached --name-only --diff-filter=ACM 2>$null
$SecretFound = $false
$CriticalPatterns = @(
    @{ Name = "AWS Access Key"; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = "GitHub Token"; Pattern = 'ghp_[A-Za-z0-9]{36}' },
    @{ Name = "Private Key"; Pattern = '-----BEGIN.*PRIVATE KEY-----' },
    @{ Name = "Generic API Key"; Pattern = '(?i)(api[_-]?key|apikey)["\s]*[=:]["\s]*["''][A-Za-z0-9]{20,}["'']' },
    @{ Name = "Database URL"; Pattern = '(?i)(mysql|postgres|mongodb)://[^:]+:[^@]+@' },
    @{ Name = "Stripe Key"; Pattern = 'sk_live_[0-9a-zA-Z]{24,}' },
    @{ Name = "JWT Token"; Pattern = 'eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+' }
)

foreach ($file in $StagedFiles.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    # Skip known documentation/example files that intentionally contain example patterns
    $ExcludedPaths = @(
        'docs/reference/ARCHITECTURE.md',
        'hooks/pre-commit.ps1',
        'hooks/pre-commit-privacy.ps1',
        'scripts/hooks/check-security.ps1',
        'scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1',
        'skills/docker-devops-skill/SKILL.md',
        'skills/security-expert-skill/references/security-patterns.md',
        'config/security-privacy.json',
        'config/security-policy.json',
        'scripts/hooks/hook-output-safety.ps1'
    )
    if ($ExcludedPaths -contains $file) { continue }
    $content = git show ":0:$file" 2>$null
    if (-not $content) { continue }
    foreach ($pattern in $CriticalPatterns) {
        if ($content -match $pattern.Pattern) {
            Write-Host "[CRITICAL] $($pattern.Name) detected in: $file" -ForegroundColor Red
            $SecretFound = $true
        }
    }
}

# Dependencias (ejemplo para Node.js)
if (Test-Path "package.json") {
    $audit = npm audit --json 2>$null | ConvertFrom-Json
    if ($audit.metadata.vulnerabilities.critical -gt 0) {
        Write-Host "[CRITICAL] Vulnerabilidades crticas detectadas en dependencias (npm audit)" -ForegroundColor Red
        $SecretFound = $true
    }
}

if ($SecretFound) { exit 1 } else { exit 0 }
