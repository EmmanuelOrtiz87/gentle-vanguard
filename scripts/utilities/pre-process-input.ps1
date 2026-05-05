# pre-process-input.ps1
# MANDATORY pre-processing hook - runs BEFORE any AI response

param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$SkillsPath = "skills",
    [string]$WorkspaceRoot = ".",
    [switch]$DisableSkillFileFallback
)

$triggerMap = @{}
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = if ($PSBoundParameters.ContainsKey("WorkspaceRoot") -and $WorkspaceRoot -ne ".") {
    try { (Resolve-Path -Path $WorkspaceRoot -ErrorAction Stop).Path } catch { Split-Path -Parent (Split-Path -Parent $scriptDir) }
} else {
    Split-Path -Parent (Split-Path -Parent $scriptDir)
}
$skillsFullPath = Join-Path $workspaceRoot $SkillsPath

# Detect which AI tool is calling this script
$detectScript = Join-Path $workspaceRoot "adapters/detection/enhanced-detect.ps1"
$detectedTool = $null
$toolCapabilities = @()
if (Test-Path $detectScript) {
    $detectionResult = & $detectScript -AsJson | ConvertFrom-Json
    $detectedTool = $detectionResult.toolName
    $toolCapabilities = $detectionResult.capabilities
    Write-Output "DETECTED_TOOL: $detectedTool"
    Write-Output "DETECTION_CONFIDENCE: $($detectionResult.confidence)"
    Write-Output "DETECTION_METHOD: $($detectionResult.detectionMethod)"
    Write-Output "TOOL_CAPABILITIES: $($toolCapabilities -join ', ')"
} else {
    Write-Output "DETECTED_TOOL: unknown"
    Write-Output "DETECTION_CONFIDENCE: low"
    Write-Output "DETECTION_METHOD: fallback"
}

# Load tool-specific configuration if available
$toolConfigPath = Join-Path $workspaceRoot "config/tool-$detectedTool.json"
if (Test-Path $toolConfigPath) {
    $toolConfig = Get-Content $toolConfigPath -Raw | ConvertFrom-Json
    Write-Output "TOOL_CONFIG_LOADED: $detectedTool"
    if ($toolConfig.preProcess) {
        Write-Output "TOOL_PREPROCESS: $($toolConfig.preProcess)"
    }
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

        # Extract frontmatter (between --- markers)
        $startMarker = $content.IndexOf("---")
        if ($startMarker -ge 0) {
            $secondMarker = $content.IndexOf("---", $startMarker + 3)
            if ($secondMarker -ge 0) {
                $frontMatter = $content.Substring($startMarker + 3, $secondMarker - $startMarker - 3)

                # Find trigger line (allowing leading whitespace)
                $lines = $frontMatter -split "`n"
                foreach ($line in $lines) {
                    if ($line -match '\s*[Tt]rigger:\s*"([^"]+)"') {
                        $triggerText = $matches[1]
                        $triggers = $triggerText -split ',' | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_.Length -gt 0 }

                        foreach ($trigger in $triggers) {
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

# Source 2: auto-delegation.json — single config load, all mappings driven by config
$autoDelegationConfig = Join-Path $workspaceRoot "config/auto-delegation.json"
$delegationConfig = $null
if (Test-Path $autoDelegationConfig) {
    $delegationConfig = Get-Content $autoDelegationConfig -Raw | ConvertFrom-Json
}

if ($delegationConfig -and $delegationConfig.keywordMappings) {
    # agentCodeToSkill: loaded from config — no hardcoding in script
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

function Find-Match {
    param(
        [string]$InputText,
        [hashtable]$Map,
        [array]$Sorted
    )
    foreach ($trigger in $Sorted) {
        if ($InputText.Contains($trigger.ToLower())) {
            return @($Map[$trigger], $trigger)
        }
    }
    return @($null, $null)
}

# Check user input against triggers
$inputLower = $UserInput.ToLower()
$matchingSkill = $null
$matchingTrigger = $null

$firstPass = Find-Match -InputText $inputLower -Map $triggerMap -Sorted $sortedTriggers
$matchingSkill = $firstPass[0]
$matchingTrigger = $firstPass[1]

# Fallback: parse SKILL.md only when config-based routing did not match.
if (-not $matchingSkill -and -not $DisableSkillFileFallback) {
    Add-TriggersFromSkillFiles -Map $triggerMap -SkillsPathFull $skillsFullPath
    $sortedTriggers = $triggerMap.Keys | Sort-Object Length -Descending
    $secondPass = Find-Match -InputText $inputLower -Map $triggerMap -Sorted $sortedTriggers
    $matchingSkill = $secondPass[0]
    $matchingTrigger = $secondPass[1]
}

# Compute confidence score
$confidenceScore = if ($matchingSkill) { 80 } else { 0 }

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

if ($matchingSkill) {
    Write-Output "TRIGGER_MATCH_FOUND"
    Write-Output "SKILL: $matchingSkill"
    Write-Output "TRIGGER_MATCHED: $matchingTrigger"
    Write-Output "CONFIDENCE: $confidenceScore"
    Write-Output "ACTION: Load skill '$matchingSkill' using skill tool"
    Write-Output "TOOL_DETECTED: $detectedTool"
    if ($toolCapabilities -contains 'skills') {
        Write-Output "TOOL_SUPPORTS_SKILLS: true"
    } else {
        Write-Output "TOOL_SUPPORTS_SKILLS: false"
        Write-Output "FALLBACK: Load skill manually for $detectedTool"
    }
    Write-AgentProfile -Profile $activeProfile -AgentCode $resolvedAgent
    Write-FlowGate -Flows $unmappedFlows -Skill $matchingSkill
} elseif ($fallbackStrategy -eq "clarify-ba" -and $confidenceScore -lt $lowConfidenceThreshold) {
    $baProfile = Resolve-AgentProfile -AgentCode "BA" -Profiles $agentProfiles
    Write-Output "PLAN_MODE_REQUIRED"
    Write-Output "CONFIDENCE: $confidenceScore"
    Write-Output "AGENT: BA"
    Write-Output "SKILL: sdd-lifecycle"
    Write-Output "PHASE: EXPLORE"
    Write-Output "ACTION: $($clarifyBaStrategy.instructions)"
    Write-Output "TOOL_DETECTED: $detectedTool"
    Write-AgentProfile -Profile $baProfile -AgentCode "BA"
    if ($clarifyBaStrategy.questions) {
        Write-Output "CLARIFICATION_QUESTIONS:"
        foreach ($q in $clarifyBaStrategy.questions) { Write-Output "  - $q" }
    }
} else {
    Write-Output "NO_TRIGGER_MATCH"
    Write-Output "CONFIDENCE: $confidenceScore"
    Write-Output "ACTION: Continue with normal behavior"
    Write-Output "TOOL_DETECTED: $detectedTool"
}

return @{
    HasMatch       = ($null -ne $matchingSkill)
    Skill          = $matchingSkill
    Trigger        = $matchingTrigger
    Confidence     = $confidenceScore
    PlanMode       = ($fallbackStrategy -eq "clarify-ba" -and $confidenceScore -lt $lowConfidenceThreshold)
    AgentCode      = $resolvedAgent
    AgentProfile   = $activeProfile
    DetectedTool   = $detectedTool
    ToolCapabilities = $toolCapabilities
}
