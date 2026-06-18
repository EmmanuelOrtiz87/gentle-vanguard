param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

$ErrorActionPreference = 'Continue'
$start = Get-Date
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else { (Get-Location).Path }
$sessionDir = Join-Path $repoRoot ".session"
$traceDir = Join-Path $sessionDir "traces"
$traceFile = Join-Path $traceDir "preprocess.jsonl"

function Write-Trace {
    param([string]$Phase, [int]$ElapsedMs, [string]$Status = 'ok', [string]$Detail = '')
    try {
        if (-not (Test-Path $traceDir)) { New-Item -ItemType Directory -Path $traceDir -Force | Out-Null }
        $entry = @{ Timestamp = (Get-Date -Format 'o'); Phase = $Phase; ElapsedMs = $ElapsedMs; Status = $Status }
        if ($Detail) { $entry.Detail = $Detail }
        Add-Content -Path $traceFile -Value (ConvertTo-Json $entry -Compress)
    } catch {}
}

function Safe-Invoke {
    param([scriptblock]$Block, [string]$Name, [int]$TimeoutSec = 15, [object[]]$ArgumentList)
    $s = Get-Date
    try {
        if ($ArgumentList) {
            $job = Start-Job -ScriptBlock $Block -ArgumentList $ArgumentList
        } else {
            $job = Start-Job -ScriptBlock $Block
        }
        $wait = $job | Wait-Job -Timeout $TimeoutSec
        if (-not $wait) {
            Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force -ErrorAction SilentlyContinue
            Write-Trace -Phase $Name -ElapsedMs ([math]::Round(((Get-Date) - $s).TotalMilliseconds)) -Status 'timeout'
            return $null
        }
        $result = $job | Receive-Job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        $elapsed = [math]::Round(((Get-Date) - $s).TotalMilliseconds)
        Write-Trace -Phase $Name -ElapsedMs $elapsed -Status 'ok'
        return $result
    } catch {
        $elapsed = [math]::Round(((Get-Date) - $s).TotalMilliseconds)
        Write-Trace -Phase $Name -ElapsedMs $elapsed -Status 'error' -Detail $_.ToString()
        return $null
    }
}

# Ensure session dir exists
if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }

$phases = @{}
$phaseStart = Get-Date

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

$violationLog = Join-Path $sessionDir "input-violations.jsonl"
foreach ($v in $violations) {
    $entry = @{ Timestamp = (Get-Date -Format 'o'); Rule = $v.Rule; Severity = $v.Severity; Message = $v.Message; InputPreview = $UserInput.Substring(0, [Math]::Min(80, $UserInput.Length)) }
    try { Add-Content -Path $violationLog -Value (ConvertTo-Json $entry -Compress) } catch {}
    Write-Output "[VALIDATION] $($v.Severity.ToUpper()): $($v.Rule) — $($v.Message)"
}

# ========== TOKEN TRACKING (lightweight) ==========
$tokenUsageFile = Join-Path $sessionDir "token-usage.json"
if (Test-Path $tokenUsageFile) {
    $tu = Safe-Invoke -Block { param($f) Get-Content $f -Raw | ConvertFrom-Json } -Name 'token-read' -TimeoutSec 5 -ArgumentList @($tokenUsageFile)
    if ($tu) {
        Write-Output "[TOKENS] sesion: $($tu.sessionId) | total: $($tu.totalTokens) | chars: $($tu.totalContextChars) | msgs: $($tu.messageCount)"
    }
}

# ========== RESPONSE CACHE (fast hash: .NET string hash, no crypto) ==========
$cacheFile = Join-Path $sessionDir "preprocess-response-cache.json"
$cache = @{}
if (Test-Path $cacheFile) {
    try { $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json -AsHashtable } catch { $cache = @{} }
}
$cacheBytes = [System.Text.Encoding]::UTF8.GetBytes($UserInput)
$md5 = [System.Security.Cryptography.MD5]::Create()
$cacheKey = ([System.BitConverter]::ToString($md5.ComputeHash($cacheBytes)) + [System.BitConverter]::ToString($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($UserInput.Length.ToString())))).Replace("-","").ToLower().Substring(0, 16)
$cacheTTL = 1800
$now = Get-Date

if ($cache.ContainsKey($cacheKey)) {
    $entry = $cache[$cacheKey]
    $entryTime = try { [DateTime]::Parse($entry.timestamp, [cultureinfo]::InvariantCulture) } catch { $null }
    if ($entryTime -and ($now - $entryTime).TotalSeconds -lt $cacheTTL) {
        Write-Output "[CACHE] HIT for input $cacheKey"
        Write-Output $entry.result
        Write-Trace -Phase 'total' -ElapsedMs ([math]::Round(($now - $start).TotalMilliseconds)) -Status 'cached'
        exit 0
    }
}

# ========== CORRECTION DETECTION ==========
Safe-Invoke -Block { param($u, $rr) & "$rr\scripts\adaptive\correction-capture.ps1" -UserInput $u -VerboseOutput:$false 2>&1 | Out-String } -Name 'correction-detect' -TimeoutSec 10 -ArgumentList @($UserInput, $repoRoot)

# ========== PATTERN DETECTION ==========
Safe-Invoke -Block { param($u, $rr) & "$rr\scripts\adaptive\pattern-detector.ps1" -Action detect -UserInput $u *>&1 | Out-Null } -Name 'pattern-detect' -TimeoutSec 10 -ArgumentList @($UserInput, $repoRoot)

# ========== KEYWORD ROUTING (lightweight) ==========
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
    Safe-Invoke -Block { param($rr) & "$rr\scripts\adaptive\auto-norm-enforcer.ps1" -Trigger orchestrator -VerboseOutput:$false 2>&1 | Out-Null } -Name 'norm-enforce' -TimeoutSec 30 -ArgumentList @($repoRoot)
}
if ($turnCount -ge 20) { Set-Content $turnCounterFile -Value "0" }

# ========== WRITE CACHE + TRACE ==========
try { $cache[$cacheKey] = @{ timestamp = $now.ToString("o"); result = $summary }; $cache | ConvertTo-Json -Depth 5 -Compress | Set-Content $cacheFile } catch {}
$elapsed = [math]::Round(((Get-Date) - $start).TotalMilliseconds)
Write-Trace -Phase 'total' -ElapsedMs $elapsed -Status 'ok' -Detail ($matchedAgent + '|' + $matchedSkill)

Write-Output "[CACHE] SAVED for input $cacheKey"
Write-Output $summary
exit 0
