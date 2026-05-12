# pre-process-input.ps1
# MANDATORY pre-processing hook - runs BEFORE any AI response

param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$SkillsPath = "skills",
    [string]$WorkspaceRoot = ".",
    [switch]$DisableSkillFileFallback,
    [switch]$FromAgent
)

$ErrorActionPreference = 'Continue'

# ============================================================================
# SECURITY: Sanitize ALL input before processing (prevents prompt injection
# and cross-agent data poisoning). When data comes FROM another agent,
# apply strict mode with full sanitization + critical pattern blocking.
# ============================================================================
if (-not $FromAgent) {
    # User input: sanitize for PII, secrets, and prompt injection patterns
    $securityScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\security\security-orchestrator.ps1'
    if (Test-Path $securityScript) {
        try {
            $sanitized = & $securityScript -Action sanitize -Content $UserInput -Mode prompt -AsJson 2>$null | ConvertFrom-Json
            if ($sanitized -and $sanitized.status -eq 'OK' -and $sanitized.sanitized) {
                $UserInput = $sanitized.sanitized
            }
        } catch { }
    }
} else {
    # Inter-agent data: full sanitize + critical pattern blocking
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
        } catch { }
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

function Add-TriggersFromSkillFiles {
    param(
        [hashtable]$Map,
        [string]$SkillsPathFull
    )

    $skillFiles = Get-ChildItem -Path $SkillsPathFull -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $skillFiles) {
        $content = Get-Content $file.FullName -Raw
        $skillName = $file.Directory.Name

        # Extract frontmatter (between --- markers)
        $startMarker = $content.IndexOf("---")
        if ($startMarker -ge 0) {
            $secondMarker = $content.IndexOf("---", $startMarker + 3)
            if ($secondMarker -ge 0) {
                $frontMatter = $content.Substring($startMarker + 3, $secondMarker - $startMarker - 3)

                # Find trigger line (allowing leading whitespace)
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

# Source 2: auto-delegation.json - single config load, all mappings driven by config
$autoDelegationConfig = Join-Path $workspaceRoot "config/auto-delegation.json"
$delegationConfig = $null
if (Test-Path $autoDelegationConfig) {
    $delegationConfig = Get-Content $autoDelegationConfig -Raw | ConvertFrom-Json
}

if ($delegationConfig -and $delegationConfig.keywordMappings) {
    # agentCodeToSkill: loaded from config - no hardcoding in script
    $skillMapping = @{}
    if ($delegationConfig.agentCodeToSkill) {
        foreach ($prop in $delegationConfig.agentCodeToSkill.PSObject.Properties) {
            $skillMapping[$prop.Name] = $prop.Value
        }
    }

    # skillToAgentProfile overrides: loaded from config
    $skillToAgent = @{}
    if ($delegationConfig.skillToAgentProfile) {
        foreach ($prop in $delegationConfig.skillToAgentProfile.PSObject.Properties) {
            $skillToAgent[$prop.Name] = $prop.Value
        }
    }
    # Fallback reverse map for any skills not in override
    foreach ($kv in $skillMapping.GetEnumerator()) {
        if (-not $skillToAgent.ContainsKey($kv.Value)) {
            $skillToAgent[$kv.Value] = $kv.Key
        }
    }

    foreach ($agent in $delegationConfig.keywordMappings.PSObject.Properties.Name) {
        $keywords = $delegationConfig.keywordMappings.$agent
        $skillName = if ($skillMapping.ContainsKey($agent)) { $skillMapping[$agent] } else { $agent.ToLower() }

        foreach ($keyword in $keywords) {
            if ($keyword -and -not $triggerMap.ContainsKey($keyword)) {
                $triggerMap[$keyword] = $skillName
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
    # Exact match: input is exactly the trigger
    if ($InputText -eq $Trigger) { return 100 }
    # Word boundary match: trigger appears as whole word
    $pattern = '\b' + [regex]::Escape($Trigger) + '\b'
    if ($InputText -match $pattern) { return 95 }
    # Word-start match: trigger matches start of a word
    $wordStartPattern = '\b' + [regex]::Escape($Trigger)
    if ($InputText -match $wordStartPattern) { return 90 }
    # Substring match: trigger is contained within input
    if ($InputText.Contains($Trigger)) { return 85 }
    # Word-fragment match: trigger words partially present
    $triggerWords = $Trigger -split '\s+'
    $matchedWords = 0
    foreach ($w in $triggerWords) {
        if ($w.Length -gt 2 -and $InputText.Contains($w)) { $matchedWords++ }
    }
    if ($matchedWords -gt 0 -and $triggerWords.Count -gt 0) {
        $ratio = $matchedWords / $triggerWords.Count
        return [math]::Max(40, [math]::Min(79, [int]($ratio * 70 + 10)))
    }
    return 0
}

function Compute-ConfidenceBonus {
    param(
        [string]$InputText,
        [hashtable]$Map,
        [ref]$MatchesRef
    )
    $bonus = 0
    $foundMatches = @($MatchesRef.Value)
    foreach ($kv in $Map.GetEnumerator()) {
        $trigger = $kv.Key
        if ($trigger -and $InputText.Contains($trigger)) {
            $alreadyMatched = $foundMatches | Where-Object { $_ -eq $trigger }
            if (-not $alreadyMatched) {
                $bonus += 5
                $foundMatches += $trigger
            }
        }
    }
    $MatchesRef.Value = $foundMatches
    return [math]::Min(15, $bonus)
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

    # Bonus for multiple matches on same skill
    $skillMatches = $allMatches | Where-Object { $_['Skill'] -eq $bestSkill } | ForEach-Object { $_['Trigger'] }
    $uniqueForSkill = $skillMatches | Select-Object -Unique
    if ($uniqueForSkill.Count -gt 1) {
        $bonus = [math]::Min(10, ($uniqueForSkill.Count - 1) * 5)
        $bestConfidence = [math]::Min(100, $bestConfidence + $bonus)
    }

    return @($bestSkill, $bestTrigger, $bestConfidence)
}

# Check user input against triggers
$inputLower = $UserInput.ToLower()
$matchingSkill = $null
$matchingTrigger = $null
$confidenceScore = 0

$firstPass = Find-Match -InputText $inputLower -Map $triggerMap -Sorted $sortedTriggers
$matchingSkill = $firstPass[0]
$matchingTrigger = $firstPass[1]
$confidenceScore = $firstPass[2]

# Fallback: parse SKILL.md only when config-based routing did not match.
if (-not $matchingSkill -and -not $DisableSkillFileFallback) {
    Add-TriggersFromSkillFiles -Map $triggerMap -SkillsPathFull $skillsFullPath
    $sortedTriggers = $triggerMap.Keys | Sort-Object Length -Descending
    $secondPass = Find-Match -InputText $inputLower -Map $triggerMap -Sorted $sortedTriggers
    $matchingSkill = $secondPass[0]
    $matchingTrigger = $secondPass[1]
    $confidenceScore = $secondPass[2]
}

# Final boost: if user input word count matches trigger ratio well
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

# Read strategy and profiles from already-loaded config
$fallbackStrategy  = if ($delegationConfig -and $delegationConfig.fallbackStrategy) { $delegationConfig.fallbackStrategy } else { "manual" }
$clarifyBaStrategy = if ($delegationConfig) { $delegationConfig.clarifyBaStrategy } else { $null }
$agentProfiles     = if ($delegationConfig) { $delegationConfig.agentProfiles } else { $null }
$unmappedFlows     = if ($delegationConfig) { $delegationConfig.unmappedFlows } else { $null }

$lowConfidenceThreshold = if ($clarifyBaStrategy -and $clarifyBaStrategy.triggerThreshold) { $clarifyBaStrategy.triggerThreshold } else { 40 }

# Resolve agent profile for matched skill
# For GITFLOW-* aliases and SCRIPT aliases, resolve to the parent profile
function Resolve-AgentProfile {
    param($AgentCode, $Profiles)
    if (-not $AgentCode -or -not $Profiles) { return $null }
    if ($Profiles.PSObject.Properties[$AgentCode]) {
        return $Profiles.PSObject.Properties[$AgentCode].Value
    }
    # Check aliases in profiles
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

if ($matchingSkill) {
    Write-Output "SOURCE: $sourceTag"
    Write-Output "TRIGGER_MATCH_FOUND"
    Write-Output "SKILL: $matchingSkill"
    Write-Output "TRIGGER_MATCHED: $matchingTrigger"
    Write-Output "CONFIDENCE: $confidenceScore"
    Write-Output "ACTION: Load skill '$matchingSkill' using skill tool"
    Write-AgentProfile -Profile $activeProfile -AgentCode $resolvedAgent
    Write-FlowGate -Flows $unmappedFlows -Skill $matchingSkill
} elseif ($fallbackStrategy -eq "clarify-ba" -and $confidenceScore -lt $lowConfidenceThreshold) {
    $baProfile = Resolve-AgentProfile -AgentCode "BA" -Profiles $agentProfiles
    Write-Output "SOURCE: $sourceTag"
    Write-Output "PLAN_MODE_REQUIRED"
    Write-Output "CONFIDENCE: $confidenceScore"
    Write-Output "AGENT: BA"
    Write-Output "SKILL: sdd-lifecycle"
    Write-Output "PHASE: EXPLORE"
    Write-Output "ACTION: $($clarifyBaStrategy.instructions)"
    Write-AgentProfile -Profile $baProfile -AgentCode "BA"
    if ($clarifyBaStrategy.questions) {
        Write-Output "CLARIFICATION_QUESTIONS:"
        foreach ($q in $clarifyBaStrategy.questions) { Write-Output "  - $q" }
    }
} else {
    Write-Output "SOURCE: $sourceTag"
    Write-Output "NO_TRIGGER_MATCH"
    Write-Output "CONFIDENCE: $confidenceScore"
    Write-Output "ACTION: Continue with normal behavior"
}

return @{
    HasMatch       = ($null -ne $matchingSkill)
    Skill          = $matchingSkill
    Trigger        = $matchingTrigger
    Confidence     = $confidenceScore
    PlanMode       = ($fallbackStrategy -eq "clarify-ba" -and $confidenceScore -lt $lowConfidenceThreshold)
    AgentCode      = $resolvedAgent
    AgentProfile   = $activeProfile
}
