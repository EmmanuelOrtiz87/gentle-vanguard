param(
    [ValidateSet('status', 'list', 'set', 'set-language', 'set-detail', 'export')]
    [string]$Mode = 'status',
    [ValidateSet('lite', 'lleno', 'ultra')]
    [string]$Profile,
    [ValidateSet('es', 'pt-BR', 'en')]
    [string]$Language,
    [ValidateSet('simple', 'executive', 'expanded')]
    [string]$Detail,
    [switch]$AsJson,
    [switch]$PassThru,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$configPath = Join-Path $repoRoot 'config\orchestrator.json'

function Get-DefaultProfiles {
    return [ordered]@{
        communication_language = 'es'
        allowed_languages = @('es', 'pt-BR', 'en')
        communication_response_mode = 'executive'
        allowed_response_modes = @('simple', 'executive', 'expanded')
        response_profiles = [ordered]@{
            active = 'lite'
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
    }
}

function Ensure-ConfigDefaults {
    param([pscustomobject]$Config)

    $defaults = Get-DefaultProfiles

    if (-not $Config.PSObject.Properties['communication_language']) {
        Add-Member -InputObject $Config -MemberType NoteProperty -Name 'communication_language' -Value $defaults.communication_language
    }
    if (-not $Config.PSObject.Properties['allowed_languages']) {
        Add-Member -InputObject $Config -MemberType NoteProperty -Name 'allowed_languages' -Value @($defaults.allowed_languages)
    }
    if (-not $Config.PSObject.Properties['communication_response_mode']) {
        Add-Member -InputObject $Config -MemberType NoteProperty -Name 'communication_response_mode' -Value $defaults.communication_response_mode
    }
    if (-not $Config.PSObject.Properties['allowed_response_modes']) {
        Add-Member -InputObject $Config -MemberType NoteProperty -Name 'allowed_response_modes' -Value @($defaults.allowed_response_modes)
    }
    if (-not $Config.PSObject.Properties['response_profiles']) {
        Add-Member -InputObject $Config -MemberType NoteProperty -Name 'response_profiles' -Value ([pscustomobject]$defaults.response_profiles)
    }

    if (-not $Config.response_profiles.PSObject.Properties['active']) {
        $Config.response_profiles | Add-Member -MemberType NoteProperty -Name 'active' -Value $defaults.response_profiles.active -Force
    }
    if (-not $Config.response_profiles.PSObject.Properties['allow']) {
        $Config.response_profiles | Add-Member -MemberType NoteProperty -Name 'allow' -Value @($defaults.response_profiles.allow) -Force
    }
    if (-not $Config.response_profiles.PSObject.Properties['profiles']) {
        $Config.response_profiles | Add-Member -MemberType NoteProperty -Name 'profiles' -Value ([pscustomobject]$defaults.response_profiles.profiles) -Force
    }

    foreach ($name in $defaults.response_profiles.allow) {
        if (-not $Config.response_profiles.profiles.PSObject.Properties[$name]) {
            $Config.response_profiles.profiles | Add-Member -MemberType NoteProperty -Name $name -Value ([pscustomobject]$defaults.response_profiles.profiles[$name])
        }
    }

    # Remove deprecated Chinese profiles if present.
    foreach ($deprecated in @('wenyan-lite', 'wenyan-full', 'wenyan-ultra')) {
        if ($Config.response_profiles.profiles.PSObject.Properties[$deprecated]) {
            $Config.response_profiles.profiles.PSObject.Properties.Remove($deprecated)
        }
    }

    $Config.response_profiles.allow = @($Config.response_profiles.allow | ForEach-Object { [string]$_ } | Where-Object { $_ -in @('lite', 'lleno', 'ultra') })
    if ($Config.response_profiles.allow.Count -eq 0) {
        $Config.response_profiles.allow = @('lite', 'lleno', 'ultra')
    }

    if ($Config.response_profiles.active -notin $Config.response_profiles.allow) {
        $Config.response_profiles.active = 'lite'
    }

    $Config.allowed_languages = @($Config.allowed_languages | ForEach-Object { [string]$_ } | Where-Object { $_ -in @('es', 'pt-BR', 'en') })
    if ($Config.allowed_languages.Count -eq 0) {
        $Config.allowed_languages = @('es', 'pt-BR', 'en')
    }

    if ($Config.communication_language -notin $Config.allowed_languages) {
        $Config.communication_language = 'es'
    }

    $Config.allowed_response_modes = @($Config.allowed_response_modes | ForEach-Object { [string]$_ } | Where-Object { $_ -in @('simple', 'executive', 'expanded') })
    if ($Config.allowed_response_modes.Count -eq 0) {
        $Config.allowed_response_modes = @('simple', 'executive', 'expanded')
    }

    if ($Config.communication_response_mode -notin $Config.allowed_response_modes) {
        $Config.communication_response_mode = 'executive'
    }

    return $Config
}

function Get-Config {
    $defaults = Get-DefaultProfiles
    if (-not (Test-Path $configPath)) {
        return [pscustomobject]$defaults
    }

    try {
        $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]$defaults
    }

    return Ensure-ConfigDefaults -Config $config
}

function Save-Config {
    param([pscustomobject]$Config)

    $json = $Config | ConvertTo-Json -Depth 30
    Set-Content -Path $configPath -Value $json -Encoding UTF8
}

function Emit-Output {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [switch]$AsPassThru
    )

    if ($AsPassThru) {
        Write-Output $Text
    }
    elseif (-not $Quiet) {
        Write-Host $Text
    }
}

$config = Get-Config

if ($Mode -eq 'set') {
    if ([string]::IsNullOrWhiteSpace($Profile)) {
        throw 'Profile is required when Mode=set.'
    }

    if ($config.response_profiles.allow -notcontains $Profile) {
        throw "Unsupported profile '$Profile'. Allowed: $($config.response_profiles.allow -join ', ')"
    }

    $config.response_profiles.active = $Profile
    Save-Config -Config $config
    Emit-Output -Text "[OK] Active response profile set to: $Profile" -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'set-language') {
    if ([string]::IsNullOrWhiteSpace($Language)) {
        throw 'Language is required when Mode=set-language.'
    }

    if ($config.allowed_languages -notcontains $Language) {
        throw "Unsupported language '$Language'. Allowed: $($config.allowed_languages -join ', ')"
    }

    $config.communication_language = $Language
    Save-Config -Config $config
    Emit-Output -Text "[OK] Communication language set to: $Language" -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'set-detail') {
    if ([string]::IsNullOrWhiteSpace($Detail)) {
        throw 'Detail is required when Mode=set-detail.'
    }

    if ($config.allowed_response_modes -notcontains $Detail) {
        throw "Unsupported detail level '$Detail'. Allowed: $($config.allowed_response_modes -join ', ')"
    }

    $config.communication_response_mode = $Detail
    Save-Config -Config $config
    Emit-Output -Text "[OK] Response detail level set to: $Detail" -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'list') {
    if ($AsJson) {
        $payload = [pscustomobject]@{
            language = $config.communication_language
            allowedLanguages = @($config.allowed_languages)
            detail = $config.communication_response_mode
            allowedDetailLevels = @($config.allowed_response_modes)
            profile = $config.response_profiles.active
            allowedProfiles = @($config.response_profiles.allow)
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
    $lines += ''
    $lines += "Allowed languages: $($config.allowed_languages -join ', ')"
    $lines += "Allowed detail levels: $($config.allowed_response_modes -join ', ')"
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
    $lines += 'Guidelines:'

    foreach ($rule in $config.response_profiles.profiles.$($config.response_profiles.active).guidelines) {
        $lines += "- $rule"
    }

    Emit-Output -Text ($lines -join [Environment]::NewLine) -AsPassThru:$PassThru
    exit 0
}

if ($AsJson) {
    $status = [pscustomobject]@{
        language = $config.communication_language
        allowedLanguages = @($config.allowed_languages)
        detail = $config.communication_response_mode
        allowedDetailLevels = @($config.allowed_response_modes)
        active = $config.response_profiles.active
        description = $config.response_profiles.profiles.$($config.response_profiles.active).description
        guidelines = @($config.response_profiles.profiles.$($config.response_profiles.active).guidelines)
        allowed = @($config.response_profiles.allow)
    } | ConvertTo-Json -Depth 20

    Emit-Output -Text $status -AsPassThru:$PassThru
    exit 0
}

$statusLines = @(
    'Response Profile Status',
    "Language: $($config.communication_language)",
    "Detail level: $($config.communication_response_mode)",
    "Active compression profile: $($config.response_profiles.active)",
    "Description: $($config.response_profiles.profiles.$($config.response_profiles.active).description)",
    'Guidelines:'
)

foreach ($rule in $config.response_profiles.profiles.$($config.response_profiles.active).guidelines) {
    $statusLines += "- $rule"
}

Emit-Output -Text ($statusLines -join [Environment]::NewLine) -AsPassThru:$PassThru
exit 0
