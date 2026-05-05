# check-quality.ps1
# Ejecuta linters y formatters

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M,[string]$C='White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C } else { Write-Host $M -ForegroundColor $C } }

# FF-003: advisory vs blocking classifier
$_classifier = Join-Path $PSScriptRoot 'hook-advisory-classifier.ps1'
if (Test-Path $_classifier) { . $_classifier }

# Node.js/TypeScript
if (Test-Path "package.json") {
    _Wh "[QUALITY] Ejecutando ESLint..." Cyan
    npx eslint .
    if ($LASTEXITCODE -ne 0) {
        if (Get-Command 'Add-BlockingFinding' -EA SilentlyContinue) {
            Add-BlockingFinding "ESLint reported errors. Fix before committing."
        } else { exit 1 }
    }

    _Wh "[QUALITY] Ejecutando Prettier (advisory)..." Cyan
    npx prettier --check .
    if ($LASTEXITCODE -ne 0) {
        if (Get-Command 'Add-AdvisoryFinding' -EA SilentlyContinue) {
            Add-AdvisoryFinding "Prettier format issues found. Run 'npx prettier --write .' to auto-fix."
        } else {
            _Wh "[QUALITY] Prettier advisory: run 'npx prettier --write .' to auto-fix." Yellow
        }
    }
}

# Go
if (Test-Path "go.mod") {
    _Wh "[QUALITY] Ejecutando golint (advisory)..." Cyan
    $golintOut = golint ./... 2>&1
    if ($golintOut) {
        if (Get-Command 'Add-AdvisoryFinding' -EA SilentlyContinue) {
            Add-AdvisoryFinding "golint suggestions: $($golintOut -join '; ')"
        } else {
            _Wh "[QUALITY] golint advisory: $golintOut" Yellow
        }
    }

    _Wh "[QUALITY] Ejecutando gofmt..." Cyan
    $gofmtFiles = gofmt -l . 2>&1
    if ($gofmtFiles) {
        if (Get-Command 'Add-BlockingFinding' -EA SilentlyContinue) {
            Add-BlockingFinding "gofmt: files need formatting: $($gofmtFiles -join ', ')"
        } else { exit 1 }
    }
}

if (Get-Command 'Exit-HookCheck' -EA SilentlyContinue) {
    Exit-HookCheck "quality"
} else {
    _Wh "[QUALITY] Chequeos de calidad completados." Green
    exit 0
}
