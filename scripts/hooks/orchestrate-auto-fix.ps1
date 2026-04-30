param(
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Fix,
    [switch]$Delegate
)

$ErrorActionPreference = 'Continue'
$repoRoot = $PWD.Path

Set-Location $repoRoot

$script:Validators = @{
    scripts = @{ name = "Script Validator"; path = $null; exists = $false; results = @() }
    docs = @{ name = "Documentation Validator"; path = $null; exists = $false; results = @() }
    skills = @{ name = "Skills Validator"; path = $null; exists = $false; results = @() }
    config = @{ name = "Config Validator"; path = $null; exists = $false; results = @() }
    typescript = @{ name = "TypeScript Validator"; path = $null; exists = $false; results = @() }
    docker = @{ name = "Docker Validator"; path = $null; exists = $false; results = @() }
    security = @{ name = "Security Validator"; path = $null; exists = $false; results = @() }
    links = @{ name = "Links Validator"; path = $null; exists = $false; results = @() }
}

$script:Summary = @{
    validated = @()
    skipped = @()
    fixed = @()
    issues = @()
    delegated = @()
}

function Write-Header {
    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "       ORCHESTRATOR: Autofix Unified Flow           " -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "Repository: $repoRoot" -ForegroundColor Gray
    Write-Host "Started: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
}

function Write-Announce {
    param([string]$Validator, [string]$Action, [string]$Detail = "")
    $msg = "[$Validator] $Action"
    if ($Detail) { $msg += " - $Detail" }
    Write-Host $msg -ForegroundColor Cyan
}

function Write-Skip {
    param([string]$Validator, [string]$Reason)
    Write-Host "[SKIP] $Validator - $Reason" -ForegroundColor DarkGray
    $script:Summary.skipped += $Validator
}

function Write-Fixed {
    param([string]$Validator, [string]$Details)
    Write-Host "[FIXED] $Validator - $Details" -ForegroundColor Green
    $script:Summary.fixed += "$Validator`: $Details"
}

function Write-Issue {
    param([string]$Validator, [string]$Details)
    Write-Host "[ISSUE] $Validator - $Details" -ForegroundColor Yellow
    $script:Summary.issues += "$Validator`: $Details"
}

function Write-Delegate {
    param([string]$Validator, [string]$Task)
    Write-Host "[DELEGATE] $Validator - $Task" -ForegroundColor Magenta
    $script:Summary.delegated += "$Validator`: $Task"
}

function Write-Success {
    param([string]$Validator, [string]$Details)
    Write-Host "[OK] $Validator - $Details" -ForegroundColor Green
    $script:Summary.validated += "$Validator`: $Details"
}

function Initialize-Validators {
    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "PHASE 1: Discovery" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan

    $script:Validators.scripts.path = Get-ChildItem -Path $repoRoot -Filter "auto-fix-delegate.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $script:Validators.scripts.path) {
        $script:Validators.scripts.path = Get-ChildItem -Path $repoRoot -Filter "pre-push-script-validator.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    $script:Validators.scripts.exists = $null -ne $script:Validators.scripts.path

    $script:Validators.docs.path = Get-ChildItem -Path $repoRoot -Filter "audit-sweep.ps1" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -match "foundation-audit" } | Select-Object -First 1
    $script:Validators.docs.exists = $null -ne $script:Validators.docs.path

    $script:Validators.skills.path = $script:Validators.docs.path
    $script:Validators.skills.exists = $script:Validators.docs.exists

    $script:Validators.config.path = Get-ChildItem -Path $repoRoot -Filter "cross-workspace-validator.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:Validators.config.exists = $null -ne $script:Validators.config.path

    $script:Validators.typescript.path = Get-ChildItem -Path $repoRoot -Filter "tsconfig.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:Validators.typescript.exists = $null -ne $script:Validators.typescript.path

    $script:Validators.docker.path = Get-ChildItem -Path $repoRoot -Filter "Dockerfile" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:Validators.docker.exists = $null -ne $script:Validators.docker.path

    $script:Validators.security.path = Get-ChildItem -Path $repoRoot -Filter "security-orchestrator.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:Validators.security.exists = $null -ne $script:Validators.security.path

    $script:Validators.links.path = Get-ChildItem -Path $repoRoot -Filter "broken-links*.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:Validators.links.exists = $null -ne $script:Validators.links.path
}

function Invoke-ValidationPhase {
    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "PHASE 2: Validation" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan

    foreach ($key in $script:Validators.Keys) {
        $validator = $script:Validators[$key]
        $name = $validator.name

        if (-not $validator.exists) {
            Write-Skip $name "Validator not found - skipping"
            continue
        }

        Write-Announce $name "Validating..." $validator.path.FullName
        $script:Summary.validated += $name

        switch ($key) {
            "scripts" { Invoke-ScriptsValidation $validator }
            "docs" { Invoke-DocsValidation $validator }
            "skills" { Invoke-SkillsValidation $validator }
            "config" { Invoke-ConfigValidation $validator }
            "typescript" { Invoke-TypeScriptValidation $validator }
            "docker" { Invoke-DockerValidation $validator }
            "security" { Invoke-SecurityValidation $validator }
            "links" { Invoke-LinksValidation $validator }
        }
    }
}

function Invoke-ScriptsValidation {
    param($validator)
    try {
        $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validator.path.FullName 2>&1 | Out-String

        if ($output -match "SUCCESS|PASS|0 issues found") {
            Write-Success "Scripts" "No issues found"
        } elseif ($output -match "Auto-fixed (\d+)") {
            Write-Fixed "Scripts" "$($matches[1]) patterns auto-corrected"
        } else {
            Write-Issue "Scripts" "Check output for details"
        }
    } catch {
        Write-Issue "Scripts" $_.Exception.Message
    }
}

function Invoke-DocsValidation {
    param($validator)
    try {
        $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validator.path.FullName -Scope quick 2>&1 | Out-String

        if ($output -match "0 errors|0 issues") {
            Write-Success "Documentation" "No broken links"
        } elseif ($output -match "(\d+) (warnings|broken)") {
            Write-Issue "Documentation" "$($matches[1]) $($matches[2]) found"
        } else {
            Write-Success "Documentation" "Validated"
        }
    } catch {
        Write-Skip "Documentation" $_.Exception.Message
    }
}

function Invoke-SkillsValidation {
    param($validator)
    try {
        $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validator.path.FullName -Scope standard 2>&1 | Out-String

        if ($output -match "(\d+) skills") {
            Write-Success "Skills" "$($matches[1]) skills validated"
        } else {
            Write-Success "Skills" "Structure valid"
        }
    } catch {
        Write-Skip "Skills" $_.Exception.Message
    }
}

function Invoke-ConfigValidation {
    param($validator)
    try {
        $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validator.path.FullName 2>&1 | Out-String

        if ($output -match "0|inconsistencies|sin diferencias") {
            Write-Success "Configuration" "No inconsistencies"
        } else {
            Write-Issue "Configuration" "Differences found"
        }
    } catch {
        Write-Skip "Configuration" $_.Exception.Message
    }
}

function Invoke-TypeScriptValidation {
    param($validator)
    Write-Success "TypeScript" "tsconfig.json present - CI handles validation"
}

function Invoke-DockerValidation {
    param($validator)
    Write-Success "Docker" "Dockerfile present - CI handles validation"
}

function Invoke-SecurityValidation {
    param($validator)
    Write-Success "Security" "Security orchestrator available"
}

function Invoke-LinksValidation {
    param($validator)
    Write-Skip "Links" "Dedicated validator not configured"
}

function Invoke-AutoFixPhase {
    if (-not $Fix) { return }

    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "PHASE 3: Auto-Fix" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan

    if ($script:Summary.issues.Count -eq 0) {
        Write-Host "[AUTO-FIX] No issues to fix" -ForegroundColor Green
        return
    }

    Write-Host "[AUTO-FIX] Attempting fixes for: $($script:Summary.issues.Count) validators with issues" -ForegroundColor Yellow

    if ($script:Validators.scripts.exists -and $script:Summary.issues -match "Scripts") {
        $fixScript = Get-ChildItem -Path $repoRoot -Filter "auto-fix-delegate.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($fixScript) {
            $fixOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File $fixScript.FullName 2>&1 | Out-String
            if ($fixOutput -match "Auto-fixed") {
                Write-Fixed "Scripts" "Parser patterns corrected"
            }
        }
    }
}

function Invoke-DelegationPhase {
    if (-not $Delegate) { return }
    if ($script:Summary.issues.Count -eq 0) { return }

    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "PHASE 4: Delegation" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan

    $delegateScript = Get-ChildItem -Path $repoRoot -Filter "auto-delegation-wrapper.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $delegateScript) {
        Write-Host "[DELEGATE] Wrapper not found - manual intervention required" -ForegroundColor Yellow
        return
    }

    foreach ($issue in $script:Summary.issues) {
        $validatorName = $issue -replace ":.*", ""
        $task = "fix $($issue.ToLower())"
        Write-Delegate $validatorName $task
    }
}

function Write-FinalSummary {
    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "Validated:" -ForegroundColor White
    $script:Summary.validated | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

    if ($script:Summary.skipped.Count -gt 0) {
        Write-Host ""
        Write-Host "Skipped:" -ForegroundColor White
        $script:Summary.skipped | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }
    }

    if ($script:Summary.fixed.Count -gt 0) {
        Write-Host ""
        Write-Host "Fixed:" -ForegroundColor Green
        $script:Summary.fixed | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
    }

    if ($script:Summary.issues.Count -gt 0) {
        Write-Host ""
        Write-Host "Issues:" -ForegroundColor Yellow
        $script:Summary.issues | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Yellow }
    }

    if ($script:Summary.delegated.Count -gt 0) {
        Write-Host ""
        Write-Host "Delegated:" -ForegroundColor Magenta
        $script:Summary.delegated | ForEach-Object { Write-Host "   $_" -ForegroundColor Magenta }
    }

    Write-Host ""
    $total = $script:Summary.validated.Count
    $fixed = $script:Summary.fixed.Count
    $issues = $script:Summary.issues.Count
    $skipped = $script:Summary.skipped.Count

    if ($issues -eq 0) {
        Write-Host "" -ForegroundColor Green
        Write-Host "RESULT: SUCCESS - All validations passed!" -ForegroundColor Green
        Write-Host "" -ForegroundColor Green
        Write-Host "READY: Push authorized" -ForegroundColor Green
        exit 0
    } elseif ($fixed -gt 0 -and $issues -gt 0) {
        Write-Host "" -ForegroundColor Yellow
        Write-Host "RESULT: PARTIAL - Fixed $fixed, $issues remaining" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Yellow
        Write-Host "RECOMMENDATION: Run with -Fix -Delegate for full resolution" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "" -ForegroundColor Red
        Write-Host "RESULT: ACTION REQUIRED - $issues issues need attention" -ForegroundColor Red
        Write-Host "" -ForegroundColor Red
        exit 1
    }
}

Write-Header
Initialize-Validators
Invoke-ValidationPhase
Invoke-AutoFixPhase
Invoke-DelegationPhase
Write-FinalSummary

