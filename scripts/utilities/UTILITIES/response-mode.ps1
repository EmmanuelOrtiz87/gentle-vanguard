param(
    [ValidateSet('status', 'list', 'set', 'set-language', 'set-detail', 'set-preset', 'set-chat-level', 'enforce-baseline', 'recommend', 'export')]
    [string]$Mode = 'status',
    [ValidateSet('lite', 'lleno', 'ultra')]
    [string]$Profile,
    [ValidateSet('es', 'pt-BR', 'en')]
    [string]$Language,
    [ValidateSet('simple', 'executive', 'expanded')]
    [string]$Detail,
    [ValidateSet('bugfix', 'refactor', 'docs', 'audit-review', 'executive-demo')]
    [string]$Preset,
    [ValidateSet('low', 'medium', 'high')]
    [string]$Risk = 'medium',
    [ValidateSet('chat-compact', 'chat-balanced', 'chat-detailed')]
    [string]$ChatLevel,
    [switch]$AsJson,
    [switch]$PassThru,
    [switch]$SkipEngramLog,
    [switch]$AllowPolicyOverride,
    [string]$OverrideReason = '',
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
if ($env:FOUNDATION_BASE_DIR) {
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
$configPath = Join-Path $repoRoot 'config\orchestrator.json'

function Get-DefaultConfig {
    return [ordered]@{
        communication_language = 'es'
        allowed_languages = @('es', 'pt-BR', 'en')
        communication_response_mode = 'simple'
        allowed_response_modes = @('simple', 'executive', 'expanded')
        chat_response = [ordered]@{
            default_level = 'chat-compact'
            enforce_on_session_start = $true
            allow = @('chat-compact', 'chat-balanced', 'chat-detailed')
            decision = [ordered]@{
                kind = 'architecture'
                title = 'startup-chat-baseline'
                rationale = 'Initialize sessions with minimal chat verbosity for token efficiency and closure-first operation.'
            }
        }
        communication_presets = [ordered]@{
            default = 'bugfix'
            allow = @('bugfix', 'refactor', 'docs', 'audit-review', 'executive-demo')
            profiles = [ordered]@{
                'bugfix' = [ordered]@{ language = 'es'; detail = 'simple'; compression = 'ultra' }
                'refactor' = [ordered]@{ language = 'es'; detail = 'simple'; compression = 'ultra' }
                'docs' = [ordered]@{ language = 'es'; detail = 'simple'; compression = 'ultra' }
                'audit-review' = [ordered]@{ language = 'es'; detail = 'simple'; compression = 'ultra' }
                'executive-demo' = [ordered]@{ language = 'es'; detail = 'simple'; compression = 'ultra' }
            }
        }
        response_profiles = [ordered]@{
            active = 'ultra'
            allow = @('lite', 'lleno', 'ultra')
            profiles = [ordered]@{
                'lite' = [ordered]@{
                    description = 'Professional concise language with complete sentences; no filler.'
                    guidelines = @(
                        'No digressions.',
                        'Keep complete sentences.',
                        'Focus on actionable output.'
                    )
                }
                'lleno' = [ordered]@{
                    description = 'Compressed language with short fragments accepted.'
                    guidelines = @(
                        'Prefer short clauses.',
                        'Drop non-essential connectors.',
                        'Keep meaning explicit.'
                    )
                }
                'ultra' = [ordered]@{
                    description = 'Aggressive compression with abbreviations and causal arrows.'
                    guidelines = @(
                        'Use compact abbreviations (db/auth/config/req/res/fn/impl).',
                        'Prefer X -> Y causal notation.',
                        'One-word answers when enough.'
                    )
                }
            }
        }
        response_policy = [ordered]@{
            strict_mode = $true
            enforce_baseline = $true
            baseline_detail = 'simple'
            baseline_profile = 'ultra'
            baseline_chat_level = 'chat-compact'
            allow_overrides = $false
            require_override_reason = $true
        }
    }
}

function Ensure-ConfigDefaults {
    param([pscustomobject]$Config)

    $defaults = Get-DefaultConfig

    foreach ($key in @('communication_language', 'allowed_languages', 'communication_response_mode', 'allowed_response_modes', 'chat_response', 'communication_presets', 'response_profiles', 'response_policy')) {
        if (-not $Config.PSObject.Properties[$key]) {
            Add-Member -InputObject $Config -MemberType NoteProperty -Name $key -Value $defaults[$key]
        }
    }

    foreach ($deprecated in @('wenyan-lite', 'wenyan-full', 'wenyan-ultra')) {
        if ($Config.response_profiles.profiles.PSObject.Properties[$deprecated]) {
            $Config.response_profiles.profiles.PSObject.Properties.Remove($deprecated)
        }
    }

    $Config.allowed_languages = @($Config.allowed_languages | ForEach-Object { [string]$_ } | Where-Object { $_ -in @('es', 'pt-BR', 'en') })
    if ($Config.allowed_languages.Count -eq 0) { $Config.allowed_languages = @('es', 'pt-BR', 'en') }
    if ($Config.communication_language -notin $Config.allowed_languages) { $Config.communication_language = 'es' }

    $Config.allowed_response_modes = @($Config.allowed_response_modes | ForEach-Object { [string]$_ } | Where-Object { $_ -in @('simple', 'executive', 'expanded') })
    if ($Config.allowed_response_modes.Count -eq 0) { $Config.allowed_response_modes = @('simple', 'executive', 'expanded') }
    if ($Config.communication_response_mode -notin $Config.allowed_response_modes) { $Config.communication_response_mode = 'simple' }

    $Config.response_profiles.allow = @($Config.response_profiles.allow | ForEach-Object { [string]$_ } | Where-Object { $_ -in @('lite', 'lleno', 'ultra') })
    if ($Config.response_profiles.allow.Count -eq 0) { $Config.response_profiles.allow = @('lite', 'lleno', 'ultra') }
    if ($Config.response_profiles.active -notin $Config.response_profiles.allow) { $Config.response_profiles.active = 'ultra' }

    $chatLevelMap = Get-ChatLevelMap
    if (-not $Config.chat_response.PSObject.Properties['allow']) {
        $Config.chat_response | Add-Member -MemberType NoteProperty -Name 'allow' -Value @($chatLevelMap.Keys)
    }
    if (-not $Config.chat_response.PSObject.Properties['default_level']) {
        $Config.chat_response | Add-Member -MemberType NoteProperty -Name 'default_level' -Value 'chat-compact'
    }
    if (-not $Config.chat_response.PSObject.Properties['enforce_on_session_start']) {
        $Config.chat_response | Add-Member -MemberType NoteProperty -Name 'enforce_on_session_start' -Value $true
    }
    if (-not $Config.chat_response.PSObject.Properties['decision']) {
        $Config.chat_response | Add-Member -MemberType NoteProperty -Name 'decision' -Value ([pscustomobject](Get-DefaultConfig).chat_response.decision)
    }

    $Config.chat_response.allow = @($Config.chat_response.allow | ForEach-Object { [string]$_ } | Where-Object { $_ -in @($chatLevelMap.Keys) })
    if ($Config.chat_response.allow.Count -eq 0) { $Config.chat_response.allow = @($chatLevelMap.Keys) }
    if ($Config.chat_response.default_level -notin $Config.chat_response.allow) { $Config.chat_response.default_level = 'chat-compact' }

    if (-not $Config.communication_presets.PSObject.Properties['allow']) {
        $Config.communication_presets | Add-Member -MemberType NoteProperty -Name 'allow' -Value @('bugfix', 'refactor', 'docs', 'audit-review', 'executive-demo')
    }
    if (-not $Config.communication_presets.PSObject.Properties['profiles']) {
        $Config.communication_presets | Add-Member -MemberType NoteProperty -Name 'profiles' -Value ([pscustomobject](Get-DefaultConfig).communication_presets.profiles)
    }

    $Config.communication_presets.allow = @($Config.communication_presets.allow | ForEach-Object { [string]$_ } | Where-Object { $_ -in @('bugfix', 'refactor', 'docs', 'audit-review', 'executive-demo') })
    if ($Config.communication_presets.allow.Count -eq 0) { $Config.communication_presets.allow = @('bugfix', 'refactor', 'docs', 'audit-review', 'executive-demo') }

    if (-not $Config.communication_presets.PSObject.Properties['default'] -or $Config.communication_presets.default -notin $Config.communication_presets.allow) {
        $Config.communication_presets.default = 'bugfix'
    }

    if (-not $Config.response_policy.PSObject.Properties['strict_mode']) {
        $Config.response_policy | Add-Member -MemberType NoteProperty -Name 'strict_mode' -Value $true
    }
    if (-not $Config.response_policy.PSObject.Properties['enforce_baseline']) {
        $Config.response_policy | Add-Member -MemberType NoteProperty -Name 'enforce_baseline' -Value $true
    }
    if (-not $Config.response_policy.PSObject.Properties['baseline_detail']) {
        $Config.response_policy | Add-Member -MemberType NoteProperty -Name 'baseline_detail' -Value 'simple'
    }
    if (-not $Config.response_policy.PSObject.Properties['baseline_profile']) {
        $Config.response_policy | Add-Member -MemberType NoteProperty -Name 'baseline_profile' -Value 'ultra'
    }
    if (-not $Config.response_policy.PSObject.Properties['baseline_chat_level']) {
        $Config.response_policy | Add-Member -MemberType NoteProperty -Name 'baseline_chat_level' -Value 'chat-compact'
    }
    if (-not $Config.response_policy.PSObject.Properties['allow_overrides']) {
        $Config.response_policy | Add-Member -MemberType NoteProperty -Name 'allow_overrides' -Value $false
    }
    if (-not $Config.response_policy.PSObject.Properties['require_override_reason']) {
        $Config.response_policy | Add-Member -MemberType NoteProperty -Name 'require_override_reason' -Value $true
    }

    return $Config
}

function Get-Config {
    $defaults = [pscustomobject](Get-DefaultConfig)
    if (-not (Test-Path $configPath)) { return $defaults }
    try { $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return $defaults }
    return Ensure-ConfigDefaults -Config $config
}

function Save-Config {
    param([pscustomobject]$Config)
    $json = $Config | ConvertTo-Json -Depth 30
    Set-Content -Path $configPath -Value $json -Encoding UTF8
}

function Emit-Output {
    param([string]$Text, [switch]$AsPassThru)
    if ($AsPassThru) { Write-Output $Text }
    elseif (-not $Quiet) { Write-Host $Text }
}

function Get-ChatLevelMap {
    return [ordered]@{
        'chat-compact' = [ordered]@{
            detail = 'simple'
            profile = 'ultra'
            description = 'Minimo para cierre rapido: simple + ultra.'
        }
        'chat-balanced' = [ordered]@{
            detail = 'executive'
            profile = 'lleno'
            description = 'Balance entre claridad y tokens: executive + lleno.'
        }
        'chat-detailed' = [ordered]@{
            detail = 'expanded'
            profile = 'lite'
            description = 'Mayor explicacion con mas contexto: expanded + lite.'
        }
    }
}

function Resolve-ActiveChatLevel {
    param([pscustomobject]$Config)

    $map = Get-ChatLevelMap
    foreach ($levelName in $map.Keys) {
        $level = $map[$levelName]
        if ($Config.communication_response_mode -eq $level.detail -and $Config.response_profiles.active -eq $level.profile) {
            return $levelName
        }
    }

    return 'custom'
}

function Save-ResponseModeObservation {
    param(
        [pscustomobject]$Config,
        [string]$Reason
    )

    if ($SkipEngramLog) {
        return
    }

    $runEngramScript = Join-Path $PSScriptRoot 'run-engram.ps1'
    if (-not (Test-Path $runEngramScript)) {
        return
    }

    $projectName = Split-Path $repoRoot -Leaf
    $message = "language=$($Config.communication_language); detail=$($Config.communication_response_mode); profile=$($Config.response_profiles.active); preset=$($Config.communication_presets.default); reason=$Reason"

    try {
        & $runEngramScript 'save' 'communication-response-mode' $message '--project' $projectName | Out-Null
    }
    catch {
        if (-not $Quiet) {
            Write-Warning "Engram logging failed for response-mode change: $($_.Exception.Message)"
        }
    }
}

function Test-PolicyOverride {
    param([pscustomobject]$Config)

    if (-not $Config.PSObject.Properties['response_policy']) { return $AllowPolicyOverride }

    if ($Config.response_policy.allow_overrides) {
        return $true
    }

    if (-not $AllowPolicyOverride) {
        return $false
    }

    if ($Config.response_policy.require_override_reason -and [string]::IsNullOrWhiteSpace($OverrideReason)) {
        throw "Policy override requires -OverrideReason when require_override_reason=true."
    }

    return $true
}

function Assert-ResponsePolicy {
    param(
        [pscustomobject]$Config,
        [string]$TargetDetail,
        [string]$TargetProfile,
        [string]$TargetChatLevel,
        [string]$Operation
    )

    if (-not $Config.PSObject.Properties['response_policy']) { return }
    if (-not $Config.response_policy.strict_mode -or -not $Config.response_policy.enforce_baseline) { return }

    $baselineDetail = [string]$Config.response_policy.baseline_detail
    $baselineProfile = [string]$Config.response_policy.baseline_profile
    $baselineChat = [string]$Config.response_policy.baseline_chat_level

    $detailViolation = (-not [string]::IsNullOrWhiteSpace($TargetDetail)) -and ($TargetDetail -ne $baselineDetail)
    $profileViolation = (-not [string]::IsNullOrWhiteSpace($TargetProfile)) -and ($TargetProfile -ne $baselineProfile)
    $chatViolation = (-not [string]::IsNullOrWhiteSpace($TargetChatLevel)) -and ($TargetChatLevel -ne $baselineChat)

    if (-not ($detailViolation -or $profileViolation -or $chatViolation)) {
        return
    }

    if (-not (Test-PolicyOverride -Config $Config)) {
        throw ("Policy blocked operation '{0}'. Baseline is detail={1}, profile={2}, chat={3}. Use -AllowPolicyOverride -OverrideReason '<why>' or change response_policy config explicitly." -f $Operation, $baselineDetail, $baselineProfile, $baselineChat)
    }
}

function Apply-Preset {
    param([pscustomobject]$Config, [string]$PresetName)

    if ($Config.communication_presets.allow -notcontains $PresetName) {
        throw ("Unsupported preset '{0}'. Allowed: {1}" -f $PresetName, ($Config.communication_presets.allow -join ', '))
    }

    $presetData = $Config.communication_presets.profiles.$PresetName
    if (-not $presetData) {
        throw "Preset '$PresetName' has no profile data configured."
    }

    if ($presetData.language -in $Config.allowed_languages) {
        $Config.communication_language = [string]$presetData.language
    }
    if ($presetData.detail -in $Config.allowed_response_modes) {
        $Config.communication_response_mode = [string]$presetData.detail
    }
    if ($presetData.compression -in $Config.response_profiles.allow) {
        $Config.response_profiles.active = [string]$presetData.compression
    }

    return $Config
}

function Get-Recommendation {
    param(
        [pscustomobject]$Config,
        [string]$PresetName,
        [string]$RiskLevel
    )

    $selectedPreset = if ([string]::IsNullOrWhiteSpace($PresetName)) { [string]$Config.communication_presets.default } else { $PresetName }
    $effective = Apply-Preset -Config $Config -PresetName $selectedPreset

    if ($RiskLevel -eq 'high') {
        $effective.communication_response_mode = 'expanded'
        if ($effective.response_profiles.active -eq 'ultra') {
            $effective.response_profiles.active = 'lleno'
        }
    }
    elseif ($RiskLevel -eq 'low') {
        if ($effective.communication_response_mode -eq 'expanded') {
            $effective.communication_response_mode = 'executive'
        }
    }

    return [pscustomobject]@{
        preset = $selectedPreset
        risk = $RiskLevel
        language = [string]$effective.communication_language
        detail = [string]$effective.communication_response_mode
        compression = [string]$effective.response_profiles.active
    }
}

$config = Get-Config

if ($Mode -eq 'set') {
    if ([string]::IsNullOrWhiteSpace($Profile)) { throw 'Profile is required when Mode=set.' }
    if ($config.response_profiles.allow -notcontains $Profile) { throw "Unsupported profile '$Profile'. Allowed: $($config.response_profiles.allow -join ', ')" }
    Assert-ResponsePolicy -Config $config -TargetDetail $config.communication_response_mode -TargetProfile $Profile -TargetChatLevel (Resolve-ActiveChatLevel -Config $config) -Operation 'set-profile'
    $config.response_profiles.active = $Profile
    Save-Config -Config $config
    $reasonTag = if ($AllowPolicyOverride) { "override:$OverrideReason" } else { "set-profile:$Profile" }
    Save-ResponseModeObservation -Config $config -Reason $reasonTag
    Emit-Output -Text "[OK] Active response profile set to: $Profile" -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'set-language') {
    if ([string]::IsNullOrWhiteSpace($Language)) { throw 'Language is required when Mode=set-language.' }
    if ($config.allowed_languages -notcontains $Language) { throw "Unsupported language '$Language'. Allowed: $($config.allowed_languages -join ', ')" }
    $config.communication_language = $Language
    Save-Config -Config $config
    Save-ResponseModeObservation -Config $config -Reason "set-language:$Language"
    Emit-Output -Text "[OK] Communication language set to: $Language" -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'set-detail') {
    if ([string]::IsNullOrWhiteSpace($Detail)) { throw 'Detail is required when Mode=set-detail.' }
    if ($config.allowed_response_modes -notcontains $Detail) { throw "Unsupported detail level '$Detail'. Allowed: $($config.allowed_response_modes -join ', ')" }
    Assert-ResponsePolicy -Config $config -TargetDetail $Detail -TargetProfile $config.response_profiles.active -TargetChatLevel (Resolve-ActiveChatLevel -Config $config) -Operation 'set-detail'
    $config.communication_response_mode = $Detail
    Save-Config -Config $config
    $reasonTag = if ($AllowPolicyOverride) { "override:$OverrideReason" } else { "set-detail:$Detail" }
    Save-ResponseModeObservation -Config $config -Reason $reasonTag
    Emit-Output -Text "[OK] Response detail level set to: $Detail" -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'set-preset') {
    if ([string]::IsNullOrWhiteSpace($Preset)) { throw 'Preset is required when Mode=set-preset.' }
    $presetData = $config.communication_presets.profiles.$Preset
    Assert-ResponsePolicy -Config $config -TargetDetail ([string]$presetData.detail) -TargetProfile ([string]$presetData.compression) -TargetChatLevel '' -Operation 'set-preset'
    $config = Apply-Preset -Config $config -PresetName $Preset
    Save-Config -Config $config
    $reasonTag = if ($AllowPolicyOverride) { "override:$OverrideReason" } else { "set-preset:$Preset" }
    Save-ResponseModeObservation -Config $config -Reason $reasonTag
    Emit-Output -Text ("[OK] Preset applied: {0} (language={1}, detail={2}, profile={3})" -f $Preset, $config.communication_language, $config.communication_response_mode, $config.response_profiles.active) -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'set-chat-level') {
    if ([string]::IsNullOrWhiteSpace($ChatLevel)) { throw 'ChatLevel is required when Mode=set-chat-level.' }
    $chatLevels = Get-ChatLevelMap
    if (-not $chatLevels.Contains($ChatLevel)) {
        throw "Unsupported chat level '$ChatLevel'. Allowed: $($chatLevels.Keys -join ', ')"
    }

    $selected = $chatLevels[$ChatLevel]
    Assert-ResponsePolicy -Config $config -TargetDetail ([string]$selected.detail) -TargetProfile ([string]$selected.profile) -TargetChatLevel $ChatLevel -Operation 'set-chat-level'
    $config.communication_response_mode = [string]$selected.detail
    $config.response_profiles.active = [string]$selected.profile
    if ($config.PSObject.Properties['chat_response']) {
        $config.chat_response.default_level = [string]$ChatLevel
    }
    Save-Config -Config $config
    $reasonTag = if ($AllowPolicyOverride) { "override:$OverrideReason" } else { ("set-chat-level:{0}" -f $ChatLevel) }
    Save-ResponseModeObservation -Config $config -Reason $reasonTag
    Emit-Output -Text ("[OK] Chat level applied: {0} (detail={1}, profile={2})" -f $ChatLevel, $config.communication_response_mode, $config.response_profiles.active) -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'enforce-baseline') {
    $baselineDetail = [string]$config.response_policy.baseline_detail
    $baselineProfile = [string]$config.response_policy.baseline_profile
    $baselineChat = [string]$config.response_policy.baseline_chat_level

    $config.communication_response_mode = $baselineDetail
    $config.response_profiles.active = $baselineProfile
    if ($config.PSObject.Properties['chat_response']) {
        $config.chat_response.default_level = $baselineChat
        $config.chat_response.enforce_on_session_start = $true
    }

    Save-Config -Config $config
    Save-ResponseModeObservation -Config $config -Reason 'enforce-baseline'
    Emit-Output -Text ("[OK] Baseline enforced: detail={0}, profile={1}, chat={2}" -f $baselineDetail, $baselineProfile, $baselineChat) -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'recommend') {
    $rec = Get-Recommendation -Config $config -PresetName $Preset -RiskLevel $Risk
    if ($AsJson) {
        Emit-Output -Text ($rec | ConvertTo-Json -Depth 6) -AsPassThru:$PassThru
    } else {
        $lines = @(
            'Response Recommendation',
            ("Preset: {0}" -f $rec.preset),
            ("Risk: {0}" -f $rec.risk),
            ("Language: {0}" -f $rec.language),
            ("Detail: {0}" -f $rec.detail),
            ("Compression: {0}" -f $rec.compression)
        )
        Emit-Output -Text ($lines -join [Environment]::NewLine) -AsPassThru:$PassThru
    }
    exit 0
}

if ($Mode -eq 'list') {
    $chatLevelMap = Get-ChatLevelMap
    $activeChatLevel = Resolve-ActiveChatLevel -Config $config
    if ($AsJson) {
        $payload = [pscustomobject]@{
            language = $config.communication_language
            allowedLanguages = @($config.allowed_languages)
            detail = $config.communication_response_mode
            allowedDetailLevels = @($config.allowed_response_modes)
            profile = $config.response_profiles.active
            allowedProfiles = @($config.response_profiles.allow)
            chatLevel = $activeChatLevel
            defaultChatLevel = if ($config.PSObject.Properties['chat_response']) { [string]$config.chat_response.default_level } else { 'chat-compact' }
            enforceChatLevelOnSessionStart = if ($config.PSObject.Properties['chat_response']) { [bool]$config.chat_response.enforce_on_session_start } else { $true }
            allowedChatLevels = @($chatLevelMap.Keys)
            chatLevels = $chatLevelMap
            responsePolicy = $config.response_policy
            preset = $config.communication_presets.default
            allowedPresets = @($config.communication_presets.allow)
            presets = $config.communication_presets.profiles
            profiles = $config.response_profiles.profiles
        } | ConvertTo-Json -Depth 20
        Emit-Output -Text $payload -AsPassThru:$PassThru
        exit 0
    }

    $lines = @()
    $lines += 'Communication Modes'
    $lines += "Language: $($config.communication_language)"
    $lines += "Detail: $($config.communication_response_mode)"
    $lines += "Compression Profile: $($config.response_profiles.active)"
    $lines += "Chat level: $activeChatLevel"
    if ($config.PSObject.Properties['chat_response']) {
        $lines += "Default chat level: $($config.chat_response.default_level)"
        $lines += "Enforce chat level on session start: $($config.chat_response.enforce_on_session_start)"
    }
        if ($config.PSObject.Properties['response_policy']) {
            $lines += "Policy strict_mode: $($config.response_policy.strict_mode)"
            $lines += "Policy enforce_baseline: $($config.response_policy.enforce_baseline)"
            $lines += "Policy allow_overrides: $($config.response_policy.allow_overrides)"
        }
    $lines += "Default Preset: $($config.communication_presets.default)"
    $lines += ''
    $lines += "Allowed languages: $($config.allowed_languages -join ', ')"
    $lines += "Allowed detail levels: $($config.allowed_response_modes -join ', ')"
    $lines += "Allowed chat levels: $($chatLevelMap.Keys -join ', ')"
    $lines += "Allowed presets: $($config.communication_presets.allow -join ', ')"
    $lines += ''
    $lines += 'Chat level map:'
    foreach ($levelName in $chatLevelMap.Keys) {
        $level = $chatLevelMap[$levelName]
        $marker = if ($levelName -eq $activeChatLevel) { '*' } else { '-' }
        $lines += ('{0} {1}: detail={2}, profile={3}' -f $marker, $levelName, $level.detail, $level.profile)
    }
    $lines += ''
    $lines += 'Compression profiles:'
    foreach ($name in $config.response_profiles.allow) {
        $marker = if ($name -eq $config.response_profiles.active) { '*' } else { '-' }
        $lines += ('{0} {1}: {2}' -f $marker, $name, $config.response_profiles.profiles.$name.description)
    }

    Emit-Output -Text ($lines -join [Environment]::NewLine) -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'export') {
    $lines = @()
    $lines += "Language: $($config.communication_language)"
    $lines += "Detail level: $($config.communication_response_mode)"
    $lines += "Compression profile: $($config.response_profiles.active)"
    $lines += "Profile description: $($config.response_profiles.profiles.$($config.response_profiles.active).description)"
    $lines += "Default preset: $($config.communication_presets.default)"
    $lines += 'Guidelines:'
    foreach ($rule in $config.response_profiles.profiles.$($config.response_profiles.active).guidelines) { $lines += "- $rule" }
    Emit-Output -Text ($lines -join [Environment]::NewLine) -AsPassThru:$PassThru
    exit 0
}

if ($AsJson) {
    $chatLevelMap = Get-ChatLevelMap
    $activeChatLevel = Resolve-ActiveChatLevel -Config $config
    $status = [pscustomobject]@{
        language = $config.communication_language
        allowedLanguages = @($config.allowed_languages)
        detail = $config.communication_response_mode
        allowedDetailLevels = @($config.allowed_response_modes)
        active = $config.response_profiles.active
        chatLevel = $activeChatLevel
        defaultChatLevel = if ($config.PSObject.Properties['chat_response']) { [string]$config.chat_response.default_level } else { 'chat-compact' }
        enforceChatLevelOnSessionStart = if ($config.PSObject.Properties['chat_response']) { [bool]$config.chat_response.enforce_on_session_start } else { $true }
        allowedChatLevels = @($chatLevelMap.Keys)
        chatLevels = $chatLevelMap
        responsePolicy = $config.response_policy
        description = $config.response_profiles.profiles.$($config.response_profiles.active).description
        guidelines = @($config.response_profiles.profiles.$($config.response_profiles.active).guidelines)
        preset = $config.communication_presets.default
        allowedPresets = @($config.communication_presets.allow)
    } | ConvertTo-Json -Depth 20
    Emit-Output -Text $status -AsPassThru:$PassThru
    exit 0
}

$statusLines = @(
    'Response Profile Status',
    "Language: $($config.communication_language)",
    "Detail level: $($config.communication_response_mode)",
    "Active compression profile: $($config.response_profiles.active)",
    "Active chat level: $(Resolve-ActiveChatLevel -Config $config)",
    "Default chat level: $(if ($config.PSObject.Properties['chat_response']) { $config.chat_response.default_level } else { 'chat-compact' })",
    "Default preset: $($config.communication_presets.default)",
    "Description: $($config.response_profiles.profiles.$($config.response_profiles.active).description)",
    'Guidelines:'
)
foreach ($rule in $config.response_profiles.profiles.$($config.response_profiles.active).guidelines) { $statusLines += "- $rule" }
Emit-Output -Text ($statusLines -join [Environment]::NewLine) -AsPassThru:$PassThru
exit 0
