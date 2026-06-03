param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [string]$ConfigPath = $(Join-Path $PSScriptRoot '..\config\workspace.config.json'),
    [string]$Kind = '',
    [string]$Preset = '',
    [string]$Architecture = '',
    [string]$ProjectProfile = '',
    [string]$AiModelMode = '',
    [string]$AiModelProvider = '',
    [string]$AiModelName = '',
    [string]$AiModelEndpoint = '',
    [string]$AiModelNotes = '',
    [string]$RepoUrl = '',
    [string]$ProjectRoot = '',
    [string]$GgaProvider = 'opencode'
)

$bootstrap = Join-Path (Join-Path $PSScriptRoot '..\gentle-vanguard') 'bootstrap-workspace.ps1'

$bootstrapArgs = @(
    '-ConfigPath', $ConfigPath,
    '-CreateProject',
    '-ProjectName', $Name
)

if (-not [string]::IsNullOrWhiteSpace($Kind)) { $bootstrapArgs += @('-ProjectKind', $Kind) }
if (-not [string]::IsNullOrWhiteSpace($Preset)) { $bootstrapArgs += @('-ProjectPreset', $Preset) }
if (-not [string]::IsNullOrWhiteSpace($Architecture)) { $bootstrapArgs += @('-ProjectArchitecture', $Architecture) }
if (-not [string]::IsNullOrWhiteSpace($ProjectProfile)) { $bootstrapArgs += @('-ProjectProfile', $ProjectProfile) }
if (-not [string]::IsNullOrWhiteSpace($AiModelMode)) { $bootstrapArgs += @('-ProjectAiModelMode', $AiModelMode) }
if (-not [string]::IsNullOrWhiteSpace($AiModelProvider)) { $bootstrapArgs += @('-ProjectAiModelProvider', $AiModelProvider) }
if (-not [string]::IsNullOrWhiteSpace($AiModelName)) { $bootstrapArgs += @('-ProjectAiModelName', $AiModelName) }
if (-not [string]::IsNullOrWhiteSpace($AiModelEndpoint)) { $bootstrapArgs += @('-ProjectAiModelEndpoint', $AiModelEndpoint) }
if (-not [string]::IsNullOrWhiteSpace($AiModelNotes)) { $bootstrapArgs += @('-ProjectAiModelNotes', $AiModelNotes) }
if (-not [string]::IsNullOrWhiteSpace($RepoUrl)) { $bootstrapArgs += @('-RepoUrl', $RepoUrl) }
if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) { $bootstrapArgs += @('-ProjectRoot', $ProjectRoot) }
if (-not [string]::IsNullOrWhiteSpace($GgaProvider)) { $bootstrapArgs += @('-GgaProvider', $GgaProvider) }

$runner = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $runner) {
    $runner = Get-Command powershell -ErrorAction SilentlyContinue
}

if ($runner) {
    & $runner.Source -NoProfile -ExecutionPolicy Bypass -File $bootstrap @bootstrapArgs
} else {
    & $bootstrap @bootstrapArgs
}

