param(
    [ValidateSet('status', 'list', 'set', 'export')]
    [string]$Mode = 'status',
    [ValidateSet('lite', 'lleno', 'ultra', 'wenyan-lite', 'wenyan-full', 'wenyan-ultra')]
    [string]$Profile,
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
        active = 'lite'
        allow = @('lite', 'lleno', 'ultra', 'wenyan-lite', 'wenyan-full', 'wenyan-ultra')
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
            'wenyan-lite' = [ordered]@{
                description = 'Semi-classical Chinese style preserving sentence structure.'
                guidelines = @(
                    'Remove hedging and filler.',
                    'Keep grammatical structure.',
                    'Use only for Chinese-language audiences.'
                )
            }
            'wenyan-full' = [ordered]@{
                description = 'Maximum classical Chinese concision.'
                guidelines = @(
                    'Strong character compression.',
                    'Frequent subject omission.',
                    'Use only for Chinese-language audiences.'
                )
            }
            'wenyan-ultra' = [ordered]@{
                description = 'Extreme classical Chinese abbreviation while preserving core meaning.'
                guidelines = @(
                    'Maximum compression.',
                    'Keep only essential semantics.',
                    'Use only for Chinese-language audiences.'
                )
            }
        }
    }
}

function Get-ResponseProfilesConfig {
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

    if (-not $config.PSObject.Properties['response_profiles']) {
        return [pscustomobject]$defaults
    }

    $raw = $config.response_profiles
    $active = if ($raw.PSObject.Properties['active'] -and -not [string]::IsNullOrWhiteSpace([string]$raw.active)) {
        [string]$raw.active
    } else {
        [string]$defaults.active
    }

    $allow = if ($raw.PSObject.Properties['allow'] -and $raw.allow) {
        @($raw.allow | ForEach-Object { [string]$_ })
    } else {
        @($defaults.allow)
    }

    $profiles = [ordered]@{}
    foreach ($name in $defaults.allow) {
        if ($raw.PSObject.Properties['profiles'] -and $raw.profiles.PSObject.Properties[$name]) {
            $candidate = $raw.profiles.$name
            $profiles[$name] = [ordered]@{
                description = if ($candidate.PSObject.Properties['description']) { [string]$candidate.description } else { [string]$defaults.profiles[$name].description }
                guidelines = if ($candidate.PSObject.Properties['guidelines'] -and $candidate.guidelines) {
                    @($candidate.guidelines | ForEach-Object { [string]$_ })
                } else {
                    @($defaults.profiles[$name].guidelines)
                }
            }
        }
        else {
            $profiles[$name] = [ordered]@{
                description = [string]$defaults.profiles[$name].description
                guidelines = @($defaults.profiles[$name].guidelines)
            }
        }
    }

    return [pscustomobject]@{
        active = $active
        allow = $allow
        profiles = [pscustomobject]$profiles
    }
}

function Set-ResponseProfile {
    param([string]$Name)

    if (-not (Test-Path $configPath)) {
        throw 'config/orchestrator.json not found.'
    }

    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

    if (-not $config.PSObject.Properties['response_profiles']) {
        $defaultConfig = Get-DefaultProfiles
        Add-Member -InputObject $config -MemberType NoteProperty -Name 'response_profiles' -Value ([pscustomobject]$defaultConfig)
    }

    $allow = @($config.response_profiles.allow | ForEach-Object { [string]$_ })
    if ($allow.Count -eq 0) {
        $allow = @('lite', 'lleno', 'ultra', 'wenyan-lite', 'wenyan-full', 'wenyan-ultra')
        $config.response_profiles | Add-Member -MemberType NoteProperty -Name 'allow' -Value $allow -Force
    }

    if ($allow -notcontains $Name) {
        throw "Unsupported profile '$Name'. Allowed: $($allow -join ', ')"
    }

    $config.response_profiles.active = $Name
    $json = $config | ConvertTo-Json -Depth 20
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

$profiles = Get-ResponseProfilesConfig
$active = [string]$profiles.active

if ($Mode -eq 'set') {
    if ([string]::IsNullOrWhiteSpace($Profile)) {
        throw 'Profile is required when Mode=set.'
    }

    Set-ResponseProfile -Name $Profile
    $profiles = Get-ResponseProfilesConfig
    $active = [string]$profiles.active

    Emit-Output -Text "[OK] Active response profile set to: $active" -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'list') {
    if ($AsJson) {
        $payload = [pscustomobject]@{
            active = $active
            allow = @($profiles.allow)
            profiles = $profiles.profiles
        } | ConvertTo-Json -Depth 10
        Emit-Output -Text $payload -AsPassThru:$PassThru
        exit 0
    }

    $lines = @()
    $lines += 'Response Profiles'
    $lines += "Active: $active"

    foreach ($name in $profiles.allow) {
        $marker = if ($name -eq $active) { '*' } else { '-' }
        $lines += ('{0} {1}: {2}' -f $marker, $name, $profiles.profiles.$name.description)
    }

    Emit-Output -Text ($lines -join [Environment]::NewLine) -AsPassThru:$PassThru
    exit 0
}

if ($Mode -eq 'export') {
    $lines = @()
    $lines += "Active response profile: $active"
    $lines += "Description: $($profiles.profiles.$active.description)"
    $lines += 'Guidelines:'

    foreach ($rule in $profiles.profiles.$active.guidelines) {
        $lines += "- $rule"
    }

    Emit-Output -Text ($lines -join [Environment]::NewLine) -AsPassThru:$PassThru
    exit 0
}

if ($AsJson) {
    $status = [pscustomobject]@{
        active = $active
        description = $profiles.profiles.$active.description
        guidelines = @($profiles.profiles.$active.guidelines)
        allowed = @($profiles.allow)
    } | ConvertTo-Json -Depth 8
    Emit-Output -Text $status -AsPassThru:$PassThru
    exit 0
}

$statusLines = @(
    'Response Profile Status',
    "Active: $active",
    "Description: $($profiles.profiles.$active.description)",
    'Guidelines:'
)

foreach ($rule in $profiles.profiles.$active.guidelines) {
    $statusLines += "- $rule"
}

Emit-Output -Text ($statusLines -join [Environment]::NewLine) -AsPassThru:$PassThru
exit 0
