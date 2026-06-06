#!/usr/bin/env pwsh
param(
    [ValidateSet('init','status','enforce','report','sanitize','scan')]
    [string]$Action = 'status',
    [string]$InputText = '',
    [string]$Path = '',
    [switch]$AsJson,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptDir

$configPaths = @{
    privacy   = Join-Path $repoRoot 'config\security-privacy.json'
    policy    = Join-Path $repoRoot 'config\security-policy.json'
    hardening = Join-Path $repoRoot 'config\security-hardening.json'
}

function Read-Config($Path) {
    if (-not (Test-Path $Path)) { return $null }
    try { return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { Write-Warning "Failed to parse: $Path"; return $null }
}

$configs = @{}; foreach ($n in $configPaths.Keys) { $configs[$n] = Read-Config $configPaths[$n] }

$auditDir = Join-Path $repoRoot '.runtime'
$auditPath = Join-Path $auditDir 'security-audit.log'
if (-not (Test-Path $auditDir)) { New-Item -ItemType Directory -Path $auditDir -Force | Out-Null }

function Write-Audit($Event, $Severity='INFO', $Details=@{}) {
    $e = @{ timestamp=(Get-Date -Format 'o'); event=$Event; severity=$Severity; details=$Details }
    ($e | ConvertTo-Json -Compress) | Add-Content -Path $auditPath -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Invoke-PrivacySanitization($Text) {
    if ([string]::IsNullOrWhiteSpace($Text) -or -not $configs.privacy) { return @{text=$Text;replacements=@()} }
    $sanitized = $Text; $replacements = @()
    foreach ($p in $configs.privacy.privacy.prohibited) {
        foreach ($r in $p.patterns) {
            $m = [regex]::Matches($sanitized, $r, 'IgnoreCase')
            foreach ($match in $m) { $replacements += @{original=$match.Value;replacement=$p.replacement;category=$p.category;severity=$p.severity} }
            $sanitized = [regex]::Replace($sanitized, $r, $p.replacement, 'IgnoreCase')
        }
    }
    return @{text=$sanitized;replacements=$replacements}
}

function Test-CriticalPatterns($Text) {
    if ([string]::IsNullOrWhiteSpace($Text) -or -not $configs.privacy) { return @() }
    $v = @(); foreach ($p in $configs.privacy.privacy.criticalBlock) {
        $m = [regex]::Matches($Text, $p.pattern, 'IgnoreCase')
        foreach ($match in $m) { $v += @{id=$p.id;matched=$match.Value;action=$p.action} }
    }
    return $v
}

function Test-InjectionPatterns($Text) {
    if ([string]::IsNullOrWhiteSpace($Text) -or -not $configs.privacy) { return @() }
    $v = @(); foreach ($p in $configs.privacy.privacy.injectionBlock) {
        $m = [regex]::Matches($Text, $p.pattern, 'IgnoreCase')
        foreach ($match in $m) { $v += @{id=$p.id;category=$p.category;severity=$p.severity;matched=$match.Value;action=$p.action} }
    }
    return $v
}

function Invoke-SecurityScan($ScanPath) {
    if (-not (Test-Path $ScanPath)) { return @{error="Path not found: $ScanPath"} }
    $results = @{filesScanned=0;violations=@();sanitized=@()}
    $files = Get-ChildItem -Path $ScanPath -Recurse -File -Include '*.ps1','*.json','*.md','*.yml','*.yaml','*.ts','*.js' -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $results.filesScanned++
        $c = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        $critical = Test-CriticalPatterns $c
        if ($critical.Count -gt 0) { $results.violations += @{file=$f.FullName;type='critical';violations=$critical} }
        $inj = Test-InjectionPatterns $c
        if ($inj.Count -gt 0) { $results.violations += @{file=$f.FullName;type='injection';violations=$inj} }
        $san = Invoke-PrivacySanitization $c
        if ($san.replacements.Count -gt 0) { $results.sanitized += @{file=$f.FullName;replacements=$san.replacements.Count} }
    }
    return $results
}

function Get-ComplianceReport() {
    if (-not $configs.hardening) { return @{error="Hardening config not loaded"} }
    $h = $configs.hardening
    $r = @{framework=$h.framework;version=$h.version;generatedAt=(Get-Date -Format 'o');controls=@{};riskMatrix=$h.compliance.risk_matrix;overallScore=0}
    $controls = @('prompt_injection','excessive_agency','sensitive_information_disclosure','system_prompt_leakage','supply_chain','data_poisoning','tool_misuse','inter_agent_communication','observability')
    $enabledCount = 0
    foreach ($c in $controls) {
        $cfg = $h.$c
        if ($cfg) { $e = ($cfg.PSObject.Properties | Where-Object { $_.Value -eq $true }).Count; $t = $cfg.PSObject.Properties.Count; $r.controls[$c] = @{enabled=$e;total=$t;score=if($t-gt0){[math]::Round(($e/$t)*100,1)}else{0}}; $enabledCount += $e }
    }
    $r.overallScore = [math]::Round(($enabledCount / ($controls.Count * 5)) * 100, 1)
    return $r
}

$results = @{action=$Action;timestamp=(Get-Date -Format 'o');status='unknown'}

switch ($Action) {
    'init' {
        Write-Host "`n=== Security Orchestrator Initialization ===" -ForegroundColor Cyan
        $loaded = 0; foreach ($n in $configPaths.Keys) { $e = Test-Path $configPaths[$n]; $s = if($e){'OK'}else{'MISSING'}; $c = if($e){'Green'}else{'Yellow'}; Write-Host "  [$s] $n`: $($configPaths[$n])" -ForegroundColor $c; if($e){$loaded++} }
        $results.status = if($loaded -ge 2){'initialized'}else{'degraded'}; $results.configsLoaded = $loaded
        Write-Host "`n[$(if($results.status -eq 'initialized'){'OK'}else{'WARN'})] Status: $($results.status)" -ForegroundColor $(if($results.status -eq 'initialized'){'Green'}else{'Yellow'})
        Write-Audit 'INIT' $(if($loaded -ge 2){'INFO'}else{'WARNING'}) @{configsLoaded=$loaded}
    }
    'status' {
        Write-Host "`n=== Security Posture ===" -ForegroundColor Cyan
        $privacyEnabled = $configs.privacy -and $configs.privacy.security.enabled
        $policyEnforced = $configs.policy -and $configs.policy.accessControl.mode -eq 'enforced'
        $hardeningLoaded = $null -ne $configs.hardening
        Write-Host "  Privacy Gateway: $(if($privacyEnabled){'ENABLED'}else{'DISABLED'})" -ForegroundColor $(if($privacyEnabled){'Green'}else{'Red'})
        Write-Host "  Policy Enforcement: $(if($policyEnforced){'ENFORCED'}else{'PERMISSIVE'})" -ForegroundColor $(if($policyEnforced){'Green'}else{'Yellow'})
        Write-Host "  Hardening Config: $(if($hardeningLoaded){'LOADED'}else{'MISSING'})" -ForegroundColor $(if($hardeningLoaded){'Green'}else{'Red'})
        if ($configs.privacy) { $prohibited = $configs.privacy.privacy.prohibited.Count; $critical = $configs.privacy.privacy.criticalBlock.Count; $injection = $configs.privacy.privacy.injectionBlock.Count; Write-Host "`n  Patterns: $prohibited privacy, $critical critical, $injection injection" -ForegroundColor Gray }
        $results.status = if($privacyEnabled -and $policyEnforced -and $hardeningLoaded){'secure'}else{'at-risk'}
        $results.privacyEnabled = $privacyEnabled; $results.policyEnforced = $policyEnforced; $results.hardeningLoaded = $hardeningLoaded
        Write-Host "`n[$(if($results.status -eq 'secure'){'OK'}else{'WARN'})] Overall: $($results.status.ToUpper())" -ForegroundColor $(if($results.status -eq 'secure'){'Green'}else{'Yellow'})
        Write-Audit 'STATUS' $(if($results.status -eq 'secure'){'INFO'}else{'WARNING'}) $results
    }
    'enforce' {
        Write-Host "`n=== Active Enforcement Scan ===" -ForegroundColor Cyan
        $sessionDir = Join-Path $repoRoot '.session'
        if (Test-Path $sessionDir) {
            $scan = Invoke-SecurityScan $sessionDir
            Write-Host "  Files: $($scan.filesScanned), Violations: $($scan.violations.Count), Sanitizable: $($scan.sanitized.Count)" -ForegroundColor Gray
            if ($scan.violations.Count -gt 0 -and $Strict) { Write-Error "Violations detected in strict mode"; exit 1 }
            $results.scan = $scan
        } else { Write-Host "  No session directory" -ForegroundColor Gray }
        $results.status = 'enforced'
        Write-Audit 'ENFORCE' 'INFO' @{violations=$scan.violations.Count}
    }
    'report' {
        Write-Host "`n=== Compliance Report ===" -ForegroundColor Cyan
        $report = Get-ComplianceReport; $results.report = $report
        Write-Host "  Framework: $($report.framework)" -ForegroundColor Gray
        Write-Host "`n  Control Scores:" -ForegroundColor White
        foreach ($c in $report.controls.Keys) { $s = $report.controls[$c].score; $col = if($s -ge 80){'Green'}elseif($s -ge 50){'Yellow'}else{'Red'}; Write-Host "    - ${c}: $s%" -ForegroundColor $col }
        Write-Host "`n  Overall Score: $($report.overallScore)%" -ForegroundColor $(if($report.overallScore -ge 80){'Green'}elseif($report.overallScore -ge 50){'Yellow'}else{'Red'})
        $results.status = 'reported'
        Write-Audit 'REPORT' 'INFO' @{overallScore=$report.overallScore}
    }
    'sanitize' {
        if ([string]::IsNullOrWhiteSpace($InputText)) { Write-Error "-InputText required"; exit 1 }
        $sanitized = Invoke-PrivacySanitization $InputText
        $results.original = $InputText; $results.sanitized = $sanitized.text; $results.replacements = $sanitized.replacements.Count; $results.status = 'sanitized'
        if (-not $AsJson) { Write-Host "`n=== Sanitization ===" -ForegroundColor Cyan; Write-Host "Replacements: $($sanitized.replacements.Count)" -ForegroundColor Gray; foreach ($r in $sanitized.replacements) { Write-Host "  [$($r.category)] '$($r.original)' -> '$($r.replacement)'" -ForegroundColor Yellow }; Write-Host "`nOutput:" -ForegroundColor Green; Write-Host $sanitized.text }
        Write-Audit 'SANITIZE' 'INFO' @{replacements=$sanitized.replacements.Count}
    }
    'scan' {
        if ([string]::IsNullOrWhiteSpace($Path)) { Write-Error "-Path required"; exit 1 }
        $scanPath = Join-Path $repoRoot $Path
        Write-Host "`n=== Security Scan: $Path ===" -ForegroundColor Cyan
        $scan = Invoke-SecurityScan $scanPath; $results.scan = $scan; $results.status = 'scanned'
        Write-Host "Files: $($scan.filesScanned)" -ForegroundColor Gray
        if ($scan.violations.Count -gt 0) { Write-Host "`nVIOLATIONS: $($scan.violations.Count)" -ForegroundColor Red; foreach ($v in $scan.violations) { Write-Host "  [$($v.type)] $($v.file)" -ForegroundColor Red; foreach ($d in $v.violations) { Write-Host "    - $($d.id): $($d.matched.Substring(0,[Math]::Min(30,$d.matched.Length)))..." -ForegroundColor Yellow } }; if ($Strict) { exit 1 } }
        else { Write-Host "No violations" -ForegroundColor Green }
        if ($scan.sanitized.Count -gt 0) { Write-Host "`nSanitizable: $($scan.sanitized.Count)" -ForegroundColor Yellow }
        Write-Audit 'SCAN' 'INFO' @{files=$scan.filesScanned;violations=$scan.violations.Count}
    }
}

if ($AsJson) { $results | ConvertTo-Json -Depth 10 }
exit 0
