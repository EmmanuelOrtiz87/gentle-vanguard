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

# Prohibited: secrets/passwords in plain text
if ($UserInput -match '(?i)\b(?:password|secret|api.?key|token|credential|auth.?token)\s*[:=]\s*\S{8,}') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'SEC-001'; Severity = 'block'; Message = 'Plain-text secrets detected in input' })
}

# Prohibited: dangerous destructive commands
if ($UserInput -match '(?i)\b(?:rm\s+-rf\s+[/\\]|format\s+|fdisk|dd\s+if=|shutdown\s+/s|rd\s+[/\\].+[/\\]/s)') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'OPS-001'; Severity = 'warn'; Message = 'Destructive command pattern detected' })
}

# Prohibited: git force push without explicit approval
if ($UserInput -match '(?i)git\s+push\s+.*--force') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'GIT-001'; Severity = 'warn'; Message = 'Force push requires explicit approval' })
}

# Length guard: >5000 chars without clear purpose
if ($UserInput.Length -gt 5000 -and $UserInput -notmatch '(?i)(test|pr|pull.request|review|document)') {
    [void]$violations.Add([PSCustomObject]@{ Rule = 'PERF-001'; Severity = 'info'; Message = "Input exceeds 5000 chars ($($UserInput.Length)) — consider delegating to subagent" })
}

# Log violations
if ($violations.Count -gt 0) {
    $violationLog = Join-Path $sessionDir "input-violations.jsonl"
    foreach ($v in $violations) {
        $entry = @{ Timestamp = (Get-Date -Format 'o'); Rule = $v.Rule; Severity = $v.Severity; Message = $v.Message; InputPreview = $UserInput.Substring(0, [Math]::Min(80, $UserInput.Length)) }
        Add-Content -Path $violationLog -Value (ConvertTo-Json $entry -Compress)
        Write-Output "[VALIDATION] $($v.Severity.ToUpper()): $($v.Rule) — $($v.Message)"
    }
}

# ========== TOKEN TRACKING ==========
# Report previous turn metrics
$tokenUsageFile = Join-Path $sessionDir "token-usage.json"
if (Test-Path $tokenUsageFile) {
    try {
        $tu = Get-Content $tokenUsageFile -Raw | ConvertFrom-Json
        $tc = $tu.totalTokens
        $cc = $tu.totalContextChars
        Write-Output "[TOKENS] sesion: $($tu.sessionId) | total: $tc | chars: $cc | msgs: $($tu.messageCount)"
    } catch {}
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

# ========== PRE-COMPACT HOOK (trigger if context > 15K tokens) ==========
$tokenFile = Join-Path $sessionDir "token-usage.json"
if (Test-Path $tokenFile) {
    try {
        $tu = Get-Content $tokenFile -Raw | ConvertFrom-Json
        $ctxTokens = [Math]::Floor([int]$tu.totalContextChars / 4) + [int]$tu.totalTokens
        if ($ctxTokens -gt 15000) {
            $hook = Join-Path $repoRoot "scripts\utilities\PERFORMANCE-OPTIMIZATION\pre-compact-hook.ps1"
            if (Test-Path $hook) { & $hook -TriggerThreshold 15000 2>&1 | Out-Null }
        }
    } catch {}
}

# ========== KEYWORD ROUTING (logic intact) ==========
Write-Output "[pre-process-input] Processing: $UserInput"

$rules = @(
    @{ Keywords = @('abrir un pr', 'abrir un pull request', 'crear pr', 'open a pr', 'create pr', 'necesito abrir un pr'); Skill = 'branch-pr'; AgentCode = 'QA'; PlanMode = $false },
    @{ Keywords = @('iniciar sessao', 'iniciar sessão', 'iniciar sesion', 'iniciar sesión', 'start session'); Skill = 'session-workflow-skill'; AgentCode = 'SESSION'; PlanMode = $false },
    @{ Keywords = @('deploy', 'kubernetes', 'docker', 'helm', 'terraform', 'ci/cd'); Skill = 'docker-devops-skill'; AgentCode = 'OPS'; PlanMode = $false },
    @{ Keywords = @('dashboard', 'reporte', 'metrics', 'metricas', 'report', 'resumen ejecutivo'); Skill = 'reporting-skill'; AgentCode = 'DOC'; PlanMode = $false },
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
try { $cache | ConvertTo-Json -Depth 5 -Compress | Set-Content $cacheFile } catch {}
Write-Output "[CACHE] SAVED for input hash $cacheKey"

Write-Output $summary
exit 0
