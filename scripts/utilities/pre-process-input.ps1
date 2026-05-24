# pre-process-input.ps1
# MANDATORY pre-processing hook - runs BEFORE any AI response

param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$SkillsPath = "skills",
    [string]$WorkspaceRoot = ".",
    [switch]$DisableSkillFileFallback,
    [switch]$FromAgent,
    [switch]$DisableCache
)

$ErrorActionPreference = 'Continue'

# ============================================================================
# RESPONSE CACHE: Return cached output for repeated inputs (saves ~2.5s each)
if (-not $DisableCache -and -not $FromAgent) {
    $cacheDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) ".session"
    $responseCacheFile = Join-Path $cacheDir "preprocess-response-cache.json"
    if (Test-Path $cacheDir) {
        try {
            $inputHash = [Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($UserInput)))
            $responseCache = @{}
            if (Test-Path $responseCacheFile) {
                $responseCache = Get-Content $responseCacheFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($responseCache -and $responseCache.cache) { $responseCache = $responseCache.cache } else { $responseCache = @{} }
            }
            if ($responseCache.ContainsKey($inputHash)) {
                $entry = $responseCache[$inputHash]
                $age = [datetime]::UtcNow - [datetime]::Parse($entry.timestamp)
                if ($age.TotalMinutes -le 30) {
                    Write-Output $entry.output
                    return
                }
            }
        } catch { }
    }
}

# ============================================================================
# SECURITY: Sanitize ALL input before processing
# ============================================================================
if (-not $FromAgent) {
    $securityScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\security\security-orchestrator.ps1'
    if (Test-Path $securityScript) {
        try {
            $sanitized = & $securityScript -Action sanitize -Content $UserInput -Mode prompt -AsJson 2>$null | ConvertFrom-Json
            if ($sanitized -and $sanitized.status -eq 'OK' -and $sanitized.sanitized) {
                $UserInput = $sanitized.sanitized
            }
        } catch { Write-Warning "Security sanitize (first path) failed: $_" }
    }
} else {
    $securityScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\security\security-orchestrator.ps1'
    if (Test-Path $securityScript) {
        try {
            $sanitized = & $securityScript -Action sanitize -Content $UserInput -Mode prompt -AsJson 2>$null | ConvertFrom-Json
            if ($sanitized -and $sanitized.status -eq 'OK' -and $sanitized.sanitized) {
                $UserInput = $sanitized.sanitized
            } elseif ($sanitized -and $sanitized.status -eq 'BLOCKED') {
                Write-Output "TRIGGER_MATCH_FOUND"
                Write-Output "SKILL: governance"
                Write-Output "ACTION: Blocked by security - critical pattern in inter-agent data"
                return @{ HasMatch = $true; Skill = 'governance'; Blocked = $true; Message = $sanitized.message }
            }
        } catch { Write-Warning "Security sanitize (second path) failed: $_" }
    }
}

$triggerMap = @{}
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = if ($PSBoundParameters.ContainsKey("WorkspaceRoot") -and $WorkspaceRoot -ne ".") {
    try { (Resolve-Path -Path $WorkspaceRoot -ErrorAction Stop).Path } catch { (Split-Path -Parent (Split-Path -Parent $scriptDir)) }
} else {
    (Split-Path -Parent (Split-Path -Parent $scriptDir))
}
$skillsFullPath = Join-Path $workspaceRoot $SkillsPath
$sessionDir = Join-Path $workspaceRoot ".session"
$cacheFile = Join-Path $sessionDir "preprocess-trigger-cache.json"

# ============================================================================
# CACHE: Skip expensive re-scanning of skills/config when nothing changed
# ============================================================================
function Get-CacheHash {
    param([string]$SkillsPathFull)
    $hashInput = ""
    $skillFiles = Get-ChildItem -Path $SkillsPathFull -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue
    foreach ($f in $skillFiles) { $hashInput += "$($f.FullName):$($f.LastWriteTimeUtc.Ticks);" }
    $configPath = Join-Path (Split-Path -Parent $SkillsPathFull) "config/auto-delegation.json"
    if (Test-Path $configPath) { $hashInput += "cfg:" + (Get-Item $configPath).LastWriteTimeUtc.Ticks }
    if ([string]::IsNullOrEmpty($hashInput)) { return "" }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($hashInput)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    return [Convert]::ToBase64String($sha256.ComputeHash($bytes))
}

function Load-CachedData {
    param([string]$CachePath, [string]$CurrentHash)
    if (-not (Test-Path $CachePath)) { return $null }
    try {
        $cached = Get-Content $CachePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($cached.cacheHash -eq $CurrentHash) { return $cached }
    } catch {}
    return $null
}

$currentHash = Get-CacheHash -SkillsPathFull $skillsFullPath
$cachedData = Load-CachedData -CachePath $cacheFile -CurrentHash $currentHash

if ($cachedData) {
    $cachedTriggers = @{}
    foreach ($item in $cachedData.triggers) { $cachedTriggers[$item.key] = $item.skill }
    $triggerMap = $cachedTriggers
} else {
    Write-Debug "Pre-process cache miss — reindexing skills/config"
}

function Add-TriggersFromSkillFiles {
    param(
        [hashtable]$Map,
        [string]$SkillsPathFull
    )

    $skillFiles = Get-ChildItem -Path $SkillsPathFull -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $skillFiles) {
        $content = Get-Content $file.FullName -Raw
        $skillName = $file.Directory.Name

        $startMarker = $content.IndexOf("---")
        if ($startMarker -ge 0) {
            $secondMarker = $content.IndexOf("---", $startMarker + 3)
            if ($secondMarker -ge 0) {
                $frontMatter = $content.Substring($startMarker + 3, $secondMarker - $startMarker - 3)

                $lines = $frontMatter -split "`n"
                foreach ($line in $lines) {
                    if ($line -match '\s*[Tt]rigger:\s*') {
                        $allMatches = [regex]::Matches($line, '"([^"]+)"')
                        foreach ($match in $allMatches) {
                            $trigger = $match.Groups[1].Value.Trim()
                            if ($trigger -and -not $Map.ContainsKey($trigger)) {
                                $Map[$trigger] = $skillName
                            }
                        }
                    }
                }
            }
        }
    }
}

$autoDelegationConfig = Join-Path $workspaceRoot "config/auto-delegation.json"
$delegationConfig = $null
$skillMapping = @{}
$skillToAgent = @{}

function Normalize-Trigger {
    param([string]$RawTrigger)
    if (-not $RawTrigger) { return $null }
    $normalized = $RawTrigger.ToLower().Trim()
    $normalized = $normalized.Trim('"')
    $normalized = $normalized.TrimEnd('.', ',', ';', ':')
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $null }
    return $normalized
}

# If cache was valid and has delegationData, skip the 1.8K-line JSON load
if ($cachedData -and $cachedData.delegationData) {
    $dd = $cachedData.delegationData
    $fallbackStrategy  = $dd.fallbackStrategy
    $clarifyBaStrategy = $dd.clarifyBaStrategy
    $agentProfiles     = $dd.agentProfiles
    $unmappedFlows     = $dd.unmappedFlows
    $skillMapping      = @{}
    if ($dd.skillMapping) { foreach ($kv in $dd.skillMapping.PSObject.Properties) { $skillMapping[$kv.Name] = $kv.Value } }
    $skillToAgent      = @{}
    if ($dd.skillToAgent) { foreach ($kv in $dd.skillToAgent.PSObject.Properties) { $skillToAgent[$kv.Name] = $kv.Value } }
} else {
    if (Test-Path $autoDelegationConfig) {
        $delegationConfig = Get-Content $autoDelegationConfig -Raw | ConvertFrom-Json
    }

    if ($delegationConfig -and $delegationConfig.keywordMappings) {
        if ($delegationConfig.agentCodeToSkill) {
            foreach ($prop in $delegationConfig.agentCodeToSkill.PSObject.Properties) {
                $skillMapping[$prop.Name] = $prop.Value
            }
        }
        if ($delegationConfig.skillToAgentProfile) {
            foreach ($prop in $delegationConfig.skillToAgentProfile.PSObject.Properties) {
                $skillToAgent[$prop.Name] = $prop.Value
            }
        }
        foreach ($kv in $skillMapping.GetEnumerator()) {
            if (-not $skillToAgent.ContainsKey($kv.Value)) {
                $skillToAgent[$kv.Value] = $kv.Key
            }
        }
        foreach ($agent in $delegationConfig.keywordMappings.PSObject.Properties.Name) {
            $keywords = $delegationConfig.keywordMappings.$agent
            $skillName = if ($skillMapping.ContainsKey($agent)) { $skillMapping[$agent] } else { $agent.ToLower() }
            foreach ($keyword in $keywords) {
                $normalizedKeyword = Normalize-Trigger -RawTrigger $keyword
                if ($normalizedKeyword -and -not $triggerMap.ContainsKey($normalizedKeyword)) {
                    $triggerMap[$normalizedKeyword] = $skillName
                }
            }
        }
    }
}

$sortedTriggers = $triggerMap.Keys | Sort-Object Length -Descending

function Compute-MatchQuality {
    param(
        [string]$InputText,
        [string]$Trigger,
        [int]$InputWordCount
    )
    if ($InputText -eq $Trigger) { return 100 }
    $pattern = '\b' + [regex]::Escape($Trigger) + '\b'
    if ($InputText -match $pattern) { return 95 }
    if ($Trigger.Length -le 2) { return 0 }
    $wordStartPattern = '\b' + [regex]::Escape($Trigger)
    if ($InputText -match $wordStartPattern) { return 90 }
    if ($InputText.Contains($Trigger)) {
        if ($Trigger.Contains(' ') -or $Trigger.Length -ge 5) {
            return 85
        }
    }
    $triggerWords = $Trigger -split '\s+'
    $matchedWords = 0
    foreach ($w in $triggerWords) {
        if ($w.Length -gt 2) {
            $wordPattern = '\b' + [regex]::Escape($w) + '\b'
            if ($InputText -match $wordPattern) { $matchedWords++ }
        }
    }
    if ($matchedWords -gt 0 -and $triggerWords.Count -gt 0) {
        $ratio = $matchedWords / $triggerWords.Count
        return [math]::Max(40, [math]::Min(79, [int]($ratio * 70 + 10)))
    }
    return 0
}

function Find-Match {
    param(
        [string]$InputText,
        [hashtable]$Map,
        [array]$Sorted
    )
    $bestSkill = $null
    $bestTrigger = $null
    $bestConfidence = 0
    $allMatches = @()

    foreach ($trigger in $Sorted) {
        $quality = Compute-MatchQuality -InputText $InputText -Trigger $trigger
        if ($quality -ge 40) {
            $allMatches += @{Trigger = $trigger; Skill = $Map[$trigger]; Quality = $quality }
            if ($quality -gt $bestConfidence) {
                $bestConfidence = $quality
                $bestSkill = $Map[$trigger]
                $bestTrigger = $trigger
            }
        }
    }

    if (-not $bestSkill) { return @($null, $null, 0) }

    $skillMatches = $allMatches | Where-Object { $_['Skill'] -eq $bestSkill } | ForEach-Object { $_['Trigger'] }
    $uniqueForSkill = $skillMatches | Select-Object -Unique
    if ($uniqueForSkill.Count -gt 1) {
        $bonus = [math]::Min(10, ($uniqueForSkill.Count - 1) * 5)
        $bestConfidence = [math]::Min(100, $bestConfidence + $bonus)
    }

    return @($bestSkill, $bestTrigger, $bestConfidence)
}

$inputLower = $UserInput.ToLower()
$matchingSkill = $null
$matchingTrigger = $null
$confidenceScore = 0
$planMode = $false

$firstPass = Find-Match -InputText $inputLower -Map $triggerMap -Sorted $sortedTriggers
$matchingSkill = $firstPass[0]
$matchingTrigger = $firstPass[1]
$confidenceScore = $firstPass[2]

if (-not $matchingSkill -and -not $DisableSkillFileFallback) {
    Add-TriggersFromSkillFiles -Map $triggerMap -SkillsPathFull $skillsFullPath
    $sortedTriggers = $triggerMap.Keys | Sort-Object Length -Descending
    $secondPass = Find-Match -InputText $inputLower -Map $triggerMap -Sorted $sortedTriggers
    $matchingSkill = $secondPass[0]
    $matchingTrigger = $secondPass[1]
    $confidenceScore = $secondPass[2]
}

$inputWords = $inputLower -split '\s+' | Where-Object { $_ -and $_.Length -gt 2 }
if ($matchingTrigger -and $inputWords.Count -gt 0) {
    $triggerWords = $matchingTrigger -split '\s+' | Where-Object { $_ -and $_.Length -gt 2 }
    if ($triggerWords.Count -gt 0) {
        $wordRatio = [math]::Min(1.0, $inputWords.Count / $triggerWords.Count)
        if ($wordRatio -gt 0.3 -and $wordRatio -lt 0.8) {
            $confidenceScore = [math]::Min(100, $confidenceScore + 3)
        }
    }
}

$fallbackStrategy  = if ($null -ne $fallbackStrategy) { $fallbackStrategy } elseif ($delegationConfig -and $delegationConfig.fallbackStrategy) { $delegationConfig.fallbackStrategy } else { "manual" }
$clarifyBaStrategy = if ($null -ne $clarifyBaStrategy) { $clarifyBaStrategy } elseif ($delegationConfig) { $delegationConfig.clarifyBaStrategy } else { $null }
$agentProfiles     = if ($null -ne $agentProfiles) { $agentProfiles } elseif ($delegationConfig) { $delegationConfig.agentProfiles } else { $null }
$unmappedFlows     = if ($null -ne $unmappedFlows) { $unmappedFlows } elseif ($delegationConfig) { $delegationConfig.unmappedFlows } else { $null }

$lowConfidenceThreshold = if ($clarifyBaStrategy -and $clarifyBaStrategy.triggerThreshold) { $clarifyBaStrategy.triggerThreshold } else { 40 }

# ============================================================================
# CACHE SAVE: Persist parsed data when cache was invalid
# ============================================================================
if (-not $cachedData -and $currentHash) {
    try {
        $cachedTriggers = @()
        foreach ($kv in $triggerMap.GetEnumerator()) {
            $cachedTriggers += @{key = $kv.Name; skill = $kv.Value}
        }
        $cachePayload = @{
            cacheHash    = $currentHash
            cachedAt     = (Get-Date -Format 'o')
            triggers     = $cachedTriggers
            delegationData = @{}
        }
        $dd = $cachePayload.delegationData
        $dd.fallbackStrategy  = $fallbackStrategy
        $dd.clarifyBaStrategy = if ($clarifyBaStrategy) { $clarifyBaStrategy } else { $null }
        $dd.agentProfiles     = if ($agentProfiles) { $agentProfiles } else { $null }
        $dd.unmappedFlows     = if ($unmappedFlows) { $unmappedFlows } else { $null }
        $skillMappingCache = @{}
        if ($skillMapping) { foreach ($kv in $skillMapping.GetEnumerator()) { $skillMappingCache[$kv.Name] = $kv.Value } }
        $skillToAgentCache = @{}
        if ($skillToAgent) { foreach ($kv in $skillToAgent.GetEnumerator()) { $skillToAgentCache[$kv.Name] = $kv.Value } }
        $dd.skillMapping = $skillMappingCache
        $dd.skillToAgent = $skillToAgentCache
        if (-not (Test-Path $sessionDir)) { $null = New-Item -ItemType Directory -Path $sessionDir -Force }
        $cachePayload | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile -Force
    } catch { Write-Debug "Cache save failed: $_" }
}

function Resolve-AgentProfile {
    param($AgentCode, $Profiles)
    if (-not $AgentCode -or -not $Profiles) { return $null }
    if ($Profiles.PSObject.Properties[$AgentCode]) {
        return $Profiles.PSObject.Properties[$AgentCode].Value
    }
    foreach ($prof in $Profiles.PSObject.Properties) {
        if ($prof.Value -and $prof.Value.aliases -and $AgentCode -in $prof.Value.aliases) {
            return $prof.Value
        }
    }
    return $null
}

$resolvedAgent  = if ($matchingSkill -and $skillToAgent.ContainsKey($matchingSkill)) { $skillToAgent[$matchingSkill] } else { $null }
$activeProfile  = Resolve-AgentProfile -AgentCode $resolvedAgent -Profiles $agentProfiles

function Write-AgentProfile {
    param($Profile, $AgentCode)
    if (-not $Profile) { return }
    Write-Output "AGENT_PROFILE: $AgentCode"
    Write-Output "  temperature: $($Profile.temperature)"
    Write-Output "  hallucinationGuard: $($Profile.hallucinationGuard)"
    Write-Output "  hedgingBlocked: $($Profile.hedgingBlocked)"
    Write-Output "  maxRetries: $($Profile.maxRetries)"
    Write-Output "  escalateOnFailure: $($Profile.escalateOnFailure)"
    if ($Profile.requiredEvidence) {
        Write-Output "  requiredEvidence:"
        foreach ($e in $Profile.requiredEvidence) { Write-Output "    - $e" }
    }
}

function Write-FlowGate {
    param($Flows, $Skill)
    if (-not $Flows) { return }
    foreach ($flow in $Flows.PSObject.Properties) {
        if ($flow.Value -and $flow.Value.skill -eq $Skill) {
            $gate = $flow.Value.gate
            if (-not $gate) { return }
            Write-Output "FLOW_GATE: $($flow.Name)"
            $reqKey   = $gate.PSObject.Properties.Name | Where-Object { $_ -like "required*" } | Select-Object -First 1
            $blockKey = $gate.PSObject.Properties.Name | Where-Object { $_ -like "block*"    } | Select-Object -First 1
            if ($reqKey)   { Write-Output "REQUIRED_BEFORE_PROCEED:"; foreach ($i in $gate.$reqKey)   { Write-Output "  - $i" } }
            if ($blockKey) { Write-Output "BLOCKS_IF:";               foreach ($i in $gate.$blockKey) { Write-Output "  - $i" } }
            return
        }
    }
}

$sourceTag = if ($FromAgent) { 'AGENT' } else { 'USER' }

$codegraphContextTriggers = @(
    'implement', 'develop', 'refactor', 'modify', 'change', 'fix', 'update',
    'rename', 'move', 'delete', 'restructure', 'migrate', 'port', 'rewrite',
    'callers of', 'callees of', 'who calls', 'where is', 'find references',
    'impact of', 'affected by', 'depends on', 'dependency', 'dependencies',
    'implementar', 'desarrollar', 'refactorizar', 'modificar', 'cambiar',
    'arreglar', 'actualizar', 'renombrar', 'mover', 'eliminar', 'reestructurar',
    'migrar', 'reescribir', 'llamadores de', 'impacto de', 'afectado por',
    'depende de', 'dependencias', 'buscar referencia', 'donde se usa',
    'codegraph', 'code graph', 'symbol search', 'call graph', 'impact analysis'
)
$isCodegraphRecommended = $false
foreach ($trigger in $codegraphContextTriggers) {
    if ($inputLower -match [regex]::Escape($trigger)) {
        $isCodegraphRecommended = $true
        break
    }
}

$devIntentTriggersEN = @('implement', 'develop', 'build', 'create', 'make', 'code')
$featureIntentPatternsML = @(
    'implementar', 'desarrollar', 'construir',
    'implementa', 'desarrolla', 'construye',
    'nueva funcionalidad', 'nuevo modulo', 'nuevo modulo',
    'nuevo componente', 'nueva feature', 'nuevo endpoint',
    'nueva api', 'nueva API',
    'implementar', 'desenvolver', 'construir',
    'novo componente', 'novo modulo', 'novo modulo',
    'novo projeto', 'criar projeto', 'criar componente',
    'nova funcionalidade', 'nova feature', 'novo endpoint',
    'nova api', 'nova API',
    'feature request',
    'new feature', 'new module', 'new component',
    'new endpoint', 'new api', 'new API',
    'add feature', 'add module', 'add component'
)
$isFeatureIntent = $false
if ($matchingSkill -eq 'sdd-lifecycle') {
    if ($matchingTrigger -in $devIntentTriggersEN -and $inputLower -notmatch '\bsdd\b') {
        $isFeatureIntent = $true
    }
    if (-not $isFeatureIntent) {
        foreach ($pattern in $featureIntentPatternsML) {
            if ($inputLower -match [regex]::Escape($pattern)) {
                $isFeatureIntent = $true
                break
            }
        }
    }
}

# Capture output lines for caching
$outLines = [System.Collections.ArrayList]@()

if ($isFeatureIntent) {
    $sddOrch = Join-Path (Split-Path -Parent $PSCommandPath) 'sdd-orchestrator.ps1'
    $wsRoot = if ($PSBoundParameters.ContainsKey("WorkspaceRoot") -and $WorkspaceRoot -ne ".") { $WorkspaceRoot } else { (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))) }
    if (Test-Path $sddOrch) {
        $featureTag = "auto-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
        $null = & $sddOrch -Action register-feature -FeatureName $featureTag -WorkspaceRoot $wsRoot 2>&1
        $null = & $sddOrch -Action update-phase -FeatureName $featureTag -Phase explore -WorkspaceRoot $wsRoot 2>&1
    }

    $baProfile = Resolve-AgentProfile -AgentCode "BA" -Profiles $agentProfiles
    $outLines.Add("SOURCE: $sourceTag") | Out-Null
    $outLines.Add("PLAN_MODE_REQUIRED") | Out-Null
    $outLines.Add("CONFIDENCE: $confidenceScore") | Out-Null
    $outLines.Add("AGENT: BA") | Out-Null
    $outLines.Add("SKILL: sdd-lifecycle") | Out-Null
    $outLines.Add("PHASE: EXPLORE") | Out-Null
    $outLines.Add("ACTION: SDD flow enforced - all feature/development requests route through BA/EXPLORE first") | Out-Null
    foreach ($line in (Write-AgentProfile -Profile $baProfile -AgentCode "BA" 2>&1)) { $outLines.Add($line) | Out-Null }
    if ($clarifyBaStrategy -and $clarifyBaStrategy.questions) {
        $outLines.Add("CLARIFICATION_QUESTIONS:") | Out-Null
        foreach ($q in $clarifyBaStrategy.questions) { $outLines.Add("  - $q") | Out-Null }
    }
    $matchingSkill = "sdd-lifecycle"
    $resolvedAgent = "BA"
    $activeProfile = $baProfile
    $planMode = $true
} elseif ($matchingSkill) {
    $outLines.Add("SOURCE: $sourceTag") | Out-Null
    $outLines.Add("TRIGGER_MATCH_FOUND") | Out-Null
    $outLines.Add("SKILL: $matchingSkill") | Out-Null
    $outLines.Add("TRIGGER_MATCHED: $matchingTrigger") | Out-Null
    $outLines.Add("CONFIDENCE: $confidenceScore") | Out-Null
    $outLines.Add("ACTION: Load skill '$matchingSkill' using skill tool") | Out-Null
    foreach ($line in (Write-AgentProfile -Profile $activeProfile -AgentCode $resolvedAgent 2>&1)) { $outLines.Add($line) | Out-Null }
    foreach ($line in (Write-FlowGate -Flows $unmappedFlows -Skill $matchingSkill 2>&1)) { $outLines.Add($line) | Out-Null }
    if ($isCodegraphRecommended -and $matchingSkill -ne 'codegraph-skill') {
        $outLines.Add("CODEGRAPH_CONTEXT_RECOMMENDED: true") | Out-Null
        $outLines.Add("CODEGRAPH_REASON: Modification/dependency task detected — use codegraph_context before proceeding") | Out-Null
    }
} elseif ($fallbackStrategy -eq "clarify-ba" -and $confidenceScore -lt $lowConfidenceThreshold) {
    $baProfile = Resolve-AgentProfile -AgentCode "BA" -Profiles $agentProfiles
    $outLines.Add("SOURCE: $sourceTag") | Out-Null
    $outLines.Add("PLAN_MODE_REQUIRED") | Out-Null
    $outLines.Add("CONFIDENCE: $confidenceScore") | Out-Null
    $outLines.Add("AGENT: BA") | Out-Null
    $outLines.Add("SKILL: sdd-lifecycle") | Out-Null
    $outLines.Add("PHASE: EXPLORE") | Out-Null
    $outLines.Add("ACTION: $($clarifyBaStrategy.instructions)") | Out-Null
    foreach ($line in (Write-AgentProfile -Profile $baProfile -AgentCode "BA" 2>&1)) { $outLines.Add($line) | Out-Null }
    if ($clarifyBaStrategy.questions) {
        $outLines.Add("CLARIFICATION_QUESTIONS:") | Out-Null
        foreach ($q in $clarifyBaStrategy.questions) { $outLines.Add("  - $q") | Out-Null }
    }
    $planMode = $true
} else {
    $outLines.Add("SOURCE: $sourceTag") | Out-Null
    $outLines.Add("NO_TRIGGER_MATCH") | Out-Null
    $outLines.Add("CONFIDENCE: $confidenceScore") | Out-Null
    $outLines.Add("ACTION: Continue with normal behavior") | Out-Null
}

# Emit output
foreach ($line in $outLines) { Write-Output $line }

# Cache result for identical future calls (TTL: 30min)
if (-not $DisableCache -and -not $FromAgent -and $outLines.Count -gt 0) {
    try {
        $cacheDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) ".session"
        $responseCacheFile = Join-Path $cacheDir "preprocess-response-cache.json"
        $responseCache = @{}
        if (Test-Path $responseCacheFile) {
            $cached = Get-Content $responseCacheFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($cached -and $cached.cache) { $responseCache = $cached.cache }
        }
        $inputHash = [Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($UserInput)))
        $responseCache[$inputHash] = @{ output = ($outLines -join "`n"); timestamp = ([datetime]::UtcNow.ToString("O")) }
        # Prune entries >1hr
        $pruned = @{}; $now = [datetime]::UtcNow
        foreach ($kv in $responseCache.GetEnumerator()) {
            try { if (($now - [datetime]::Parse($kv.Value.timestamp)).TotalHours -le 1) { $pruned[$kv.Key] = $kv.Value } } catch { }
        }
        @{ cache = $pruned } | ConvertTo-Json -Depth 5 -Compress | Set-Content $responseCacheFile -Force
    } catch { }
}

return @{
    HasMatch       = ($null -ne $matchingSkill)
    Skill          = $matchingSkill
    Trigger        = $matchingTrigger
    Confidence     = $confidenceScore
    PlanMode       = ($planMode -eq $true)
    AgentCode      = $resolvedAgent
    AgentProfile   = $activeProfile
}