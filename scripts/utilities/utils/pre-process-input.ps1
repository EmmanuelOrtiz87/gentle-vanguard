param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

$ErrorActionPreference = 'Continue'
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else { (Get-Location).Path }
$sessionDir = Join-Path $repoRoot ".session"
if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }

# ========== INPUT VALIDATION ==========
$violations = [System.Collections.ArrayList]::new()
$inputLower = $UserInput.ToLower()

if ($UserInput -match '(?i)\b(?:password|secret|api.?key|token|credential|auth.?token)\s*[:=]\s*\S{8,}') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'SEC-001'; Severity = 'block'; Message = 'Plain-text secrets detected in input' })
}

if ($UserInput -match '(?i)\b(?:rm\s+-rf\s+[/\\]|format\s+|fdisk|dd\s+if=|shutdown\s+/s|rd\s+[/\\].+[/\\]/s)') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'OPS-001'; Severity = 'warn'; Message = 'Destructive command pattern detected' })
}

if ($UserInput -match '(?i)git\s+push\s+.*--force') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'GIT-001'; Severity = 'warn'; Message = 'Force push requires explicit approval' })
}

if ($UserInput.Length -gt 5000 -and $UserInput -notmatch '(?i)(test|pr|pull.request|review|document)') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'PERF-001'; Severity = 'info'; Message = "Input exceeds 5000 chars ($($UserInput.Length)) — consider delegating to subagent" })
}

if ($violations.Count -gt 0) {
    $violationLog = Join-Path $sessionDir "input-violations.jsonl"
    foreach ($v in $violations) {
        $entry = @{ Timestamp = (Get-Date -Format 'o'); Rule = $v.Rule; Severity = $v.Severity; Message = $v.Message; InputPreview = $UserInput.Substring(0, [Math]::Min(80, $UserInput.Length)) }
        Add-Content -Path $violationLog -Value (ConvertTo-Json $entry -Compress)
        Write-Output "[VALIDATION] $($v.Severity.ToUpper()): $($v.Rule) — $($v.Message)"
    }
}

# ========== TOKEN TRACKING ==========
$tokenUsageFile = Join-Path $sessionDir "token-usage.json"
if (Test-Path $tokenUsageFile) {
    try {
        $tu = Get-Content $tokenUsageFile -Raw | ConvertFrom-Json
        $tc = $tu.totalTokens
        $cc = $tu.totalContextChars
        Write-Output "[TOKENS] sesion: $($tu.sessionId) | total: $tc | chars: $cc | msgs: $($tu.messageCount)"
    } catch { Write-Output "[TOKENS] No token usage data available" }
}

# ========== RESPONSE CACHE ==========
$cacheFile = Join-Path $sessionDir "preprocess-response-cache.json"
$cache = @{}
if (Test-Path $cacheFile) {
    try { $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json -AsHashtable } catch { $cache = @{} }
}
$inputHash = -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($UserInput)) | ForEach-Object { $_.ToString("x2") })
$cacheKey = $inputHash.Substring(0, 16)
$cacheTTL = 1800
$now = Get-Date

if ($cache.ContainsKey($cacheKey)) {
    $entry = $cache[$cacheKey]
    $entryTime = try { [DateTime]::Parse($entry.timestamp, [cultureinfo]::InvariantCulture) } catch { $null }
    if ($entryTime -and ($now - $entryTime).TotalSeconds -lt $cacheTTL) {
        Write-Output "[CACHE] HIT for input hash $cacheKey (TTL: $cacheTTL`s)"
        Write-Output $entry.result
        exit 0
    }
    Write-Output "[CACHE] EXPIRED for input hash $cacheKey"
}

# ========== CORRECTION DETECTION (FASE 3: Feedback Loop) ==========
$correctionCapture = Join-Path $repoRoot "scripts\adaptive\correction-capture.ps1"
if (Test-Path $correctionCapture) {
    $correctionResult = & $correctionCapture -UserInput $UserInput -VerboseOutput:$false 2>&1 | Out-String
    if ($correctionResult -match 'CORRECTION_CAPTURED') {
        Write-Output "[FEEDBACK] Correction pattern detected — logged and will trigger learning"
    }
}

# ========== PATTERN DETECTION (FASE 4: Proactive Intelligence) ==========
$patternDetector = Join-Path $repoRoot "scripts\adaptive\pattern-detector.ps1"
if (Test-Path $patternDetector) {
    & $patternDetector -Action detect -UserInput $UserInput *>&1 | Out-Null
    $suggestResult = & $patternDetector -Action suggest -UserInput $UserInput *>&1 | Out-String
    if ($suggestResult -match '\[PROACTIVE\]') {
        $suggestResult -split "`n" | Where-Object { $_ -match '\[PROACTIVE\]' } | ForEach-Object {
            Write-Output $_
        }
    }
}

# ========== PRE-COMPACT HOOK ==========
$tokenFile = Join-Path $sessionDir "token-usage.json"
if (Test-Path $tokenFile) {
    try {
        $tu = Get-Content $tokenFile -Raw | ConvertFrom-Json
        $ctxTokens = [Math]::Floor([int]$tu.totalContextChars / 4) + [int]$tu.totalTokens
        if ($ctxTokens -gt 15000) {
            $hook = Join-Path $repoRoot "scripts\utilities\PERFORMANCE-OPTIMIZATION\pre-compact-hook.ps1"
            if (Test-Path $hook) { & $hook -TriggerThreshold 15000 2>&1 | Out-Null }
        }
    } catch { Write-Output "[HOOK] Pre-compact failed, continuing" }
}

# ========== KEYWORD ROUTING ==========
Write-Output "[pre-process-input] Processing: $UserInput"

$rules = @(
    @{ Keywords = @('abrir un pr', 'abrir un pull request', 'crear pr', 'open a pr', 'create pr', 'necesito abrir un pr'); Skill = 'branch-pr'; AgentCode = 'QA'; PlanMode = $false },
    @{ Keywords = @('inicia sesion', 'inicia sesión', 'iniciar sesion', 'iniciar sesión', 'start session', 'iniciar sessao', 'iniciar sessão', 'iniciar sessao de trabalho', 'iniciar sessão de trabalho', 'guardar sesión', 'guardar sesion', 'guarda sesion', 'guarda sesión', 'continuar', 'continue', 'continuar sessao', 'continuar sessão', 'estado', 'status', 'status da sessao', 'status da sessão', 'cerrar sesion', 'cerrar sesión', 'close session', 'session end', 'encerrar sessao', 'encerrar sessão', 'fechar sessao', 'fechar sessão', 'fin de sesion', 'fin de sesión', 'finalizar sesion', 'finalizar sesión'); Skill = 'session-workflow-skill'; AgentCode = 'SESSION'; PlanMode = $false },
    @{ Keywords = @('deploy', 'kubernetes', 'docker', 'helm', 'terraform', 'ci/cd'); Skill = 'docker-devops-skill'; AgentCode = 'OPS'; PlanMode = $false },
    @{ Keywords = @('dashboard', 'reporte', 'metrics', 'metricas', 'report', 'resumen ejecutivo', 'informe', 'tokens', 'costos', 'telemetry', 'stats', 'telemetria', 'estadisticas'); Skill = 'reporting-skill'; AgentCode = 'DOC'; PlanMode = $false },
    @{ Keywords = @('fix bug', 'bug fix', 'error 401', 'bug'); Skill = 'sdd-lifecycle'; AgentCode = 'DEV'; PlanMode = $false },
    @{ Keywords = @('nuevo proyecto', 'novo projeto', 'criar projeto', 'create project', 'new project', 'crear proyecto', 'empezar proyecto', 'iniciar proyecto', 'bootstrap project', 'scaffold project'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },
    @{ Keywords = @('crear componente', 'new component', 'nuevo componente', 'novo componente', 'criar componente', 'create component'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },
    @{ Keywords = @('nueva funcionalidad', 'nuevo modulo', 'nuevo módulo', 'new feature', 'new module', 'nueva feature', 'nova feature', 'novo recurso'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },
    @{ Keywords = @('feature request', 'add feature', 'add module', 'add component'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },
    @{ Keywords = @('implementar', 'desarrollar', 'construir', 'implement ', 'develop '); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true },
    @{ Keywords = @('quero criar um novo projeto', 'criar um novo projeto', 'quero criar'); Skill = 'sdd-lifecycle'; AgentCode = 'BA'; PlanMode = $true }
)

$matched = $false; $matchedSkill = $null; $matchedAgent = $null; $matchedPlanMode = $false; $bestScore = 0
foreach ($rule in $rules) {
    foreach ($kw in $rule.Keywords) {
        if ($inputLower -match [regex]::Escape($kw.ToLower())) {
            $score = $kw.Length
            if ($score -gt $bestScore) { $bestScore = $score; $matched = $true; $matchedSkill = $rule.Skill; $matchedAgent = $rule.AgentCode; $matchedPlanMode = $rule.PlanMode }
        }
    }
}
if (-not $matched) { $matchedSkill = 'sdd-lifecycle'; $matchedAgent = 'BA'; $matchedPlanMode = $true }

$summary = @{ HasMatch = $matched; Skill = $matchedSkill; AgentCode = $matchedAgent; PlanMode = $matchedPlanMode; Confidence = $bestScore; Input = $UserInput }

# ========== PERIODIC ENFORCEMENT (every 5 turns) ==========
$turnCounterFile = Join-Path $sessionDir "enforcement-turn-counter.txt"
$turnCount = 0
if (Test-Path $turnCounterFile) { $turnCount = [int](Get-Content $turnCounterFile -Raw).Trim() }
$turnCount++
Set-Content $turnCounterFile -Value $turnCount

if ($turnCount % 5 -eq 0) {
    $enforcer = Join-Path $repoRoot "scripts\adaptive\auto-norm-enforcer.ps1"
    if (Test-Path $enforcer) {
        Write-Output "[ENFORCER] Turn $turnCount — running auto-norm-enforcer"
        & $enforcer -Trigger orchestrator -VerboseOutput:$false 2>&1 | Out-Null
    }
}
if ($turnCount -ge 20) {
    Set-Content $turnCounterFile -Value "0"
}

# ========== WRITE TO CACHE ==========
$cache[$cacheKey] = @{ timestamp = $now.ToString("o"); result = $summary }
try { $cache | ConvertTo-Json -Depth 5 -Compress | Set-Content $cacheFile } catch { Write-Output "[CACHE] Failed to write cache" }
Write-Output "[CACHE] SAVED for input hash $cacheKey"

Write-Output $summary
exit 0
