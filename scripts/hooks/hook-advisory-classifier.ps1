# hook-advisory-classifier.ps1
# FF-003: Advisory vs Blocking classification for git hook checks.
# Dot-source this module in any hook script to get structured finding tracking.
#
# Usage:
#   . $PSScriptRoot\hook-advisory-classifier.ps1
#   Add-BlockingFinding "ESLint error in src/app.ts"
#   Add-AdvisoryFinding  "Prettier format mismatch in README.md"
#   Exit-HookCheck "quality"        # exits 1 only if blocking findings exist

$script:_blockingFindings = [System.Collections.Generic.List[string]]::new()
$script:_advisoryFindings = [System.Collections.Generic.List[string]]::new()

function Add-BlockingFinding {
    param([string]$Message)
    $script:_blockingFindings.Add($Message)
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) {
        Write-SafeHook "[BLOCK] $Message" -Color Red
    } else {
        Write-Host "[BLOCK] $Message" -ForegroundColor Red
    }
}

function Add-AdvisoryFinding {
    param([string]$Message)
    $script:_advisoryFindings.Add($Message)
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) {
        Write-SafeHook "[ADVISORY] $Message" -Color Yellow
    } else {
        Write-Host "[ADVISORY] $Message" -ForegroundColor Yellow
    }
}

function Get-HookFindings {
    return @{
        blocking = $script:_blockingFindings.ToArray()
        advisory = $script:_advisoryFindings.ToArray()
        has_blocking = ($script:_blockingFindings.Count -gt 0)
        has_advisory = ($script:_advisoryFindings.Count -gt 0)
    }
}

function Reset-HookFindings {
    $script:_blockingFindings.Clear()
    $script:_advisoryFindings.Clear()
}

function Exit-HookCheck {
    param([string]$CheckName = 'hook')
    $findings = Get-HookFindings

    if ($findings.has_advisory) {
        $aCount = $findings.advisory.Count
        if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) {
            Write-SafeHook "[$($CheckName.ToUpper())] $aCount advisory finding(s) — not blocking." -Color Yellow
        } else {
            Write-Host "[$($CheckName.ToUpper())] $aCount advisory finding(s) — not blocking." -ForegroundColor Yellow
        }
    }

    if ($findings.has_blocking) {
        $bCount = $findings.blocking.Count
        if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) {
            Write-SafeHook "[$($CheckName.ToUpper())] $bCount blocking finding(s) — commit rejected." -Color Red
        } else {
            Write-Host "[$($CheckName.ToUpper())] $bCount blocking finding(s) — commit rejected." -ForegroundColor Red
        }
        exit 1
    }

    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) {
        Write-SafeHook "[$($CheckName.ToUpper())] All checks passed." -Color Green
    } else {
        Write-Host "[$($CheckName.ToUpper())] All checks passed." -ForegroundColor Green
    }
    exit 0
}
