<#
.SYNOPSIS
    Stack Health Check — valida que el stack Gentle-Vanguard esté 100% funcional
.DESCRIPTION
    Smoke test integral que verifica: scripts, configs, hooks, auth, session, tools,
    dependencias, permisos. Exit code 0 = todo OK, 1+ = errores.
#>

param(
    [switch]$Quiet,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$results = [System.Collections.ArrayList]@()
$start = Get-Date

function Add-Check {
    param([string]$Name, [scriptblock]$Script)
    try {
        $ok = & $Script
        $status = if ($ok) { "PASS" } else { "FAIL" }
        $null = $results.Add([PSCustomObject]@{ check = $Name; status = $status; message = "" })
        if (-not $Quiet) {
            $clr = if ($status -eq "PASS") { "Green" } else { "Red" }
            Write-Host "  [$status] $Name" -ForegroundColor $clr
        }
    } catch {
        $err = $_.Exception.Message
        $null = $results.Add([PSCustomObject]@{ check = $Name; status = "FAIL"; message = $err })
        if (-not $Quiet) { Write-Host "  [FAIL] $Name :: $err" -ForegroundColor Red }
    }
}

Write-Host "=== Gentle-Vanguard Stack Health Check ===" -ForegroundColor Cyan
Write-Host ""

# --- PHASE 1: Core scripts exist ---
Write-Host "[Phase 1/6] Core Scripts" -ForegroundColor Yellow
Add-Check "detect-tool.ps1" { Test-Path "scripts/utilities/detect-tool.ps1" }
Add-Check "pre-process-input.ps1" { Test-Path "scripts/utilities/pre-process-input.ps1" }
Add-Check "session-start-optimized.ps1" { Test-Path "scripts/utilities/session-start-optimized.ps1" }
Add-Check "session-autostart.ps1" { Test-Path "scripts/utilities/session-autostart.ps1" }
Add-Check "session-manager.ps1" { Test-Path "scripts/utilities/session-manager.ps1" }
Add-Check "gv.ps1" { Test-Path "scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1" }
Add-Check "trusted-user-check.ps1" { Test-Path "scripts/utilities/trusted-user-check.ps1" }

# --- PHASE 2: Config files valid ---
Write-Host "[Phase 2/6] Config Files" -ForegroundColor Yellow
$configs = @("config/orchestrator.json","config/auto-delegation.json","config/session-autostart.config.json",
             "config/security-policy.json","config/trusted-users-policy.json",
             "config/security-privacy.json","config/sre-error-budgets.json")
foreach ($cfg in $configs) {
    Add-Check "$cfg" { try { $null = Get-Content $cfg -Raw | ConvertFrom-Json; return $true } catch { return $false } }.GetNewClosure()
}

# --- PHASE 3: Hooks ---
Write-Host "[Phase 3/6] Git Hooks" -ForegroundColor Yellow
Add-Check ".lefthook.yml" { Test-Path ".lefthook.yml" }
Add-Check "lefthook validate" { try { $r = lefthook validate 2>&1; $? } catch { $false } }

# --- PHASE 4: Tool-specific configs ---
Write-Host "[Phase 4/6] Cross-Tool Configs" -ForegroundColor Yellow
Add-Check "CLAUDE.md" { Test-Path "CLAUDE.md" }
Add-Check "AGENTS.md" { Test-Path "docs/AGENTS.md" }
Add-Check "opencode.json" { try { $null = Get-Content "opencode.json" -Raw | ConvertFrom-Json; $true } catch { $false } }
Add-Check ".clinerules" { Test-Path ".clinerules" }
Add-Check ".cursorrules" { Test-Path ".cursorrules" }
Add-Check ".windsurf/config.json" { try { $null = Get-Content ".windsurf/config.json" -Raw | ConvertFrom-Json; $true } catch { $false } }

# --- PHASE 5: Security ---
Write-Host "[Phase 5/6] Security" -ForegroundColor Yellow
Add-Check "owner-auth.json.integrity" { Test-Path "config/owner-auth.json.integrity" }
Add-Check "owner-auth.json.enc" { Test-Path "config/owner-auth.json.enc" }
Add-Check "SECURITY.md" { Test-Path "SECURITY.md" }
Add-Check "privacy-gateway.ps1" { Test-Path "scripts/security/privacy-gateway.ps1" }

# --- PHASE 6: Governance ---
Write-Host "[Phase 6/6] Governance" -ForegroundColor Yellow
Add-Check "openspec/config.yaml" { Test-Path "openspec/config.yaml" }
Add-Check "renovate.json" { try { $null = Get-Content "renovate.json" -Raw | ConvertFrom-Json; $true } catch { $false } }
Add-Check "dependabot.yml" { Test-Path ".github/dependabot.yml" }
Add-Check "CODEOWNERS" { Test-Path ".github/CODEOWNERS" }
Add-Check "rules/NORMATIVAS-PERFORMANCE.md" { Test-Path "rules/NORMATIVAS-PERFORMANCE.md" }
Add-Check "rules/SDD-STRICT-TDD.md" { Test-Path "rules/SDD-STRICT-TDD.md" }
Add-Check "rules/PER-PHASE-MODEL-ROUTING.md" { Test-Path "rules/PER-PHASE-MODEL-ROUTING.md" }
Add-Check "pester-minimum-version" {
    $pv = (Get-Module -ListAvailable Pester | Where-Object { $_.Version -ge [version]'5.0.0' }).Version
    $pv -ne $null -and $pv -ge [version]'5.0.0'
}
Add-Check "config/clinerules" { Test-Path "config/clinerules" }
Add-Check ".nvmrc" { Test-Path ".nvmrc" }
Add-Check ".node-version" { Test-Path ".node-version" }

# --- Summary ---
$duration = (Get-Date) - $start
$passed = @($results | Where-Object { $_.status -eq "PASS" }).Count
$failed = @($results | Where-Object { $_.status -eq "FAIL" }).Count
$total = $results.Count

Write-Host ""
Write-Host "=== Health Check Complete ===" -ForegroundColor Cyan
Write-Host "Duration: $($duration.TotalSeconds.ToString('0.0'))s" -ForegroundColor Gray
Write-Host "Passed: $passed/$total" -ForegroundColor $(if($failed -eq 0){'Green'}else{'Yellow'})
Write-Host "Failed: $failed" -ForegroundColor $(if($failed -eq 0){'Green'}else{'Red'})

if ($Json) {
    $results | ConvertTo-Json
}

exit $failed
