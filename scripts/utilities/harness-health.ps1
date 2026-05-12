# harness-health.ps1
# Cross-layer harness health check for agent stack integrity

param(
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'

function Write-Health {
    param([string]$Layer, [string]$Status, [string]$Message)
    $icon = switch ($Status) { 'PASS' { '[OK]' } 'WARN' { '[~]' } 'FAIL' { '[X]' } default { '[?]' } }
    Write-Output "$icon LAYER[$Layer] $Message"
    return @{ Layer = $Layer; Status = $Status; Message = $Message }
}

$results = @()
$repoRoot = if ($env:FOUNDATION_BASE_DIR) { $env:FOUNDATION_BASE_DIR } else { (Get-Location).Path }

Write-Output "=== HARNESS HEALTH CHECK ==="
Write-Output ""

# L0: Tool Detection
$toolScript = Join-Path $repoRoot "scripts/utilities/detect-tool.ps1"
if (Test-Path $toolScript) {
    $toolResult = & $toolScript -AsJson 2>$null
    if ($toolResult) {
        $results += Write-Health -Layer 0 -Status 'PASS' -Message "detect-tool.ps1 ejecutable"
    } else {
        $results += Write-Health -Layer 0 -Status 'WARN' -Message "detect-tool.ps1 no retorna datos"
    }
} else {
    $results += Write-Health -Layer 0 -Status 'FAIL' -Message "detect-tool.ps1 no encontrado"
}

# L1: Pre-Processing
$preScript = Join-Path $repoRoot "scripts/utilities/pre-process-input.ps1"
if (Test-Path $preScript) {
    $testResult = & $preScript -UserInput "test harness" -WorkspaceRoot $repoRoot 2>&1 | Out-String
    if ($testResult -match 'TRIGGER_MATCH_FOUND|NO_TRIGGER_MATCH|PLAN_MODE_REQUIRED') {
        $results += Write-Health -Layer 1 -Status 'PASS' -Message "pre-process-input.ps1 responde correctamente"
    } else {
        $results += Write-Health -Layer 1 -Status 'WARN' -Message "pre-process-input.ps1 respuesta inesperada"
    }
} else {
    $results += Write-Health -Layer 1 -Status 'FAIL' -Message "pre-process-input.ps1 no encontrado"
}

# L2: Routing Config
$routingConfig = Join-Path $repoRoot "config/auto-delegation.json"
if (Test-Path $routingConfig) {
    $routing = Get-Content $routingConfig -Raw | ConvertFrom-Json
    $hasMappings = $routing.keywordMappings -and $routing.agentCodeToSkill -and $routing.agentProfiles
    if ($hasMappings) {
        $results += Write-Health -Layer 2 -Status 'PASS' -Message "auto-delegation.json: keywordMappings + agentCodeToSkill + agentProfiles OK"
    } else {
        $results += Write-Health -Layer 2 -Status 'WARN' -Message "auto-delegation.json: faltan secciones requeridas"
    }
} else {
    $results += Write-Health -Layer 2 -Status 'FAIL' -Message "auto-delegation.json no encontrado"
}

# L3: Orchestration
$orchConfig = Join-Path $repoRoot "config/orchestrator.json"
if (Test-Path $orchConfig) {
    $orch = Get-Content $orchConfig -Raw | ConvertFrom-Json
    $hasOrch = $orch.orchestrator -and $orch.orchestrator.sessionStartup -and $orch.orchestrator.preProcessing
    if ($hasOrch) {
        $results += Write-Health -Layer 3 -Status 'PASS' -Message "orchestrator.json: sessionStartup + preProcessing OK"
    } else {
        $results += Write-Health -Layer 3 -Status 'WARN' -Message "orchestrator.json: faltan secciones"
    }
} else {
    $results += Write-Health -Layer 3 -Status 'FAIL' -Message "orchestrator.json no encontrado"
}

# L4: Agent Profiles
if ($routing.agentProfiles) {
    $agentCount = ($routing.agentProfiles.PSObject.Properties | Measure-Object).Count
    $hasTemps = ($routing.agentProfiles.PSObject.Properties | Where-Object { $_.Value.temperature -ne $null } | Measure-Object).Count
    if ($agentCount -ge 10 -and $hasTemps -ge 10) {
        $results += Write-Health -Layer 4 -Status 'PASS' -Message "$agentCount agent profiles con temperature config"
    } else {
        $results += Write-Health -Layer 4 -Status 'WARN' -Message "Solo $agentCount agent profiles"
    }
}

# L5: Skills
$skillsDir = Join-Path $repoRoot "skills"
if (Test-Path $skillsDir) {
    $skillDirs = Get-ChildItem -Path $skillsDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }
    $skillCount = ($skillDirs | Measure-Object).Count
    if ($skillCount -gt 0) {
        $results += Write-Health -Layer 5 -Status 'PASS' -Message "$skillCount skills con SKILL.md"
    } else {
        $results += Write-Health -Layer 5 -Status 'WARN' -Message "skills dir sin SKILL.md"
    }
} else {
    $results += Write-Health -Layer 5 -Status 'FAIL' -Message "skills/ directorio no encontrado"
}

# L6: Circuit Breaker
$cbConfig = Join-Path $repoRoot "config/circuit-breaker.json"
if (Test-Path $cbConfig) {
    $results += Write-Health -Layer 6 -Status 'PASS' -Message "circuit-breaker.json presente"
} else {
    $results += Write-Health -Layer 6 -Status 'WARN' -Message "circuit-breaker.json NO presente"
}

# L7: Tools (Engram, wf.ps1, session-autostart)
$wf = Join-Path $repoRoot "scripts/utilities/wf.ps1"
$autostart = Join-Path $repoRoot "scripts/utilities/session-autostart.cmd"
$engramPresent = (Get-Command "engram.exe" -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $env:USERPROFILE "bin/engram.exe"))
$toolsOK = $true
if (-not (Test-Path $wf)) { $toolsOK = $false; $results += Write-Health -Layer 7 -Status 'FAIL' -Message "wf.ps1 no encontrado" }
if (-not (Test-Path $autostart)) { $toolsOK = $false; $results += Write-Health -Layer 7 -Status 'FAIL' -Message "session-autostart.cmd no encontrado" }
if (-not $engramPresent) { $toolsOK = $false; $results += Write-Health -Layer 7 -Status 'FAIL' -Message "engram.exe no disponible" }
if ($toolsOK) { $results += Write-Health -Layer 7 -Status 'PASS' -Message "Tools: wf.ps1 + session-autostart + engram OK" }

# L8: Governance
$normFiles = @(
    "rules/AI-NORMATIVES.md",
    "rules/NORMATIVAS-CODIGO.md",
    "rules/NORMATIVAS-ERROR-HANDLING.md",
    "rules/NORMATIVAS-PERFORMANCE.md",
    "rules/NORMATIVAS-SESSION.md",
    "rules/DEVELOPMENT-STANDARDS.md"
)
$missingNorms = @()
foreach ($nf in $normFiles) {
    if (-not (Test-Path (Join-Path $repoRoot $nf))) { $missingNorms += $nf }
}
if ($missingNorms.Count -eq 0) {
    $results += Write-Health -Layer 8 -Status 'PASS' -Message "Todas las normativas presentes ($($normFiles.Count))"
} else {
    $results += Write-Health -Layer 8 -Status 'WARN' -Message "Faltan normativas: $($missingNorms -join ', ')"
}

Write-Output ""
$passCount = ($results | Where-Object { $_.Status -eq 'PASS' } | Measure-Object).Count
$warnCount = ($results | Where-Object { $_.Status -eq 'WARN' } | Measure-Object).Count
$failCount = ($results | Where-Object { $_.Status -eq 'FAIL' } | Measure-Object).Count
Write-Output "=== HARNESS HEALTH: $passCount PASS | $warnCount WARN | $failCount FAIL ==="
Write-Output ""

if ($AsJson) {
    return @{
        timestamp = (Get-Date -Format "o")
        layers = $results
        summary = @{ pass = $passCount; warn = $warnCount; fail = $failCount; total = $results.Count }
    } | ConvertTo-Json -Depth 3
}
