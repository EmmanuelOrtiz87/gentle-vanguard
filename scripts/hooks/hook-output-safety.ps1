# hook-output-safety.ps1
# FF-015 - Centralized hook output safety filter.
# Prevents accidental leakage of environment variables and sensitive path info in hook stdout.
# Usage: dot-source this file at the top of any hook:
#   . (Join-Path $PSScriptRoot 'hook-output-safety.ps1')
# Then replace Write-Host with Write-SafeHook for lines that may contain variable expansions.

$homePath = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { '/home/' }
$winDirPath = if ($env:SystemRoot) { $env:SystemRoot } else { Join-Path 'C:' 'Windows' }

$script:_SENSITIVE_PATTERNS = @(
    # Raw env var values injected into strings
    @{ Name = 'API_KEY';         Pattern = '(?i)(api[_-]?key|apikey)[^\s]*\s*[:=]\s*\S{8,}' },
    @{ Name = 'SECRET';          Pattern = '(?i)(secret|password|passwd|token|bearer)[^\s]*\s*[:=]\s*\S{8,}' },
    @{ Name = 'AWS_KEY';         Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Name = 'PRIVATE_KEY';     Pattern = '-----BEGIN.*PRIVATE KEY-----' },
    @{ Name = 'GITHUB_TOKEN';    Pattern = 'ghp_[A-Za-z0-9]{36}' },
    @{ Name = 'STRIPE_KEY';      Pattern = 'sk_live_[0-9a-zA-Z]{24,}' },
    # Full absolute paths that reveal home dir or infra layout
    @{ Name = 'ABS_PATH_HOME';   Pattern = [regex]::Escape($homePath) + '[^\s]+' },
    @{ Name = 'ABS_PATH_WINDIR'; Pattern = [regex]::Escape($winDirPath) + '[^\s]+' }
)

<#
.SYNOPSIS
    Write hook output safely, redacting known-sensitive patterns.
.PARAMETER Message
    Message string to output.
.PARAMETER Color
    Optional ForegroundColor for Write-Host.
.PARAMETER Redact
    If set, replace sensitive matches with [REDACTED] instead of skipping the line.
    Default: redact in place (safer than dropping the whole line).
#>
function Write-SafeHook {
    param(
        [string]$Message,
        [string]$Color = 'White',
        [switch]$Redact
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        Write-Host '' -ForegroundColor $Color
        return
    }

    $safe = $Message
    foreach ($p in $script:_SENSITIVE_PATTERNS) {
        if ($safe -match $p.Pattern) {
            $safe = [regex]::Replace($safe, $p.Pattern, "[REDACTED:$($p.Name)]")
        }
    }

    Write-Host $safe -ForegroundColor $Color
}

<#
.SYNOPSIS
    Validate that a string is safe to output (no sensitive patterns).
    Returns $true if safe, $false if it contains sensitive data.
#>
function Test-HookOutputSafe {
    param([string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) { return $true }

    foreach ($p in $script:_SENSITIVE_PATTERNS) {
        if ($Message -match $p.Pattern) { return $false }
    }
    return $true
}

<#
.SYNOPSIS
    Filter a collection of output lines, redacting sensitive content.
    Useful for piped output from git or external tools.
#>
function Protect-HookOutput {
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Line
    )
    process {
        if ([string]::IsNullOrWhiteSpace($Line)) {
            $Line
            return
        }
        $safe = $Line
        foreach ($p in $script:_SENSITIVE_PATTERNS) {
            if ($safe -match $p.Pattern) {
                $safe = [regex]::Replace($safe, $p.Pattern, "[REDACTED:$($p.Name)]")
            }
        }
        $safe
    }
}
