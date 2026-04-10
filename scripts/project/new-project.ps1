param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [string]$ConfigPath = $(Join-Path $PSScriptRoot '..\config\workspace.config.json'),
    [string]$Kind = '',
    [string]$Preset = '',
    [string]$Architecture = '',
    [string]$Profile = '',
    [string]$AiModelMode = '',
    [string]$AiModelProvider = '',
    [string]$AiModelName = '',
    [string]$AiModelEndpoint = '',
    [string]$AiModelNotes = '',
    [string]$RepoUrl = '',
    [string]$ProjectRoot = '',
    [string]$GgaProvider = 'opencode'
)

$bootstrap = Join-Path $PSScriptRoot 'bootstrap-workspace.ps1'

$runner = Get-Command pwsh -ErrorAction SilentlyContinue
if ($runner) {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $bootstrap -ConfigPath $ConfigPath -CreateProject -ProjectName $Name -ProjectKind $Kind -ProjectPreset $Preset -ProjectArchitecture $Architecture -ProjectProfile $Profile -ProjectAiModelMode $AiModelMode -ProjectAiModelProvider $AiModelProvider -ProjectAiModelName $AiModelName -ProjectAiModelEndpoint $AiModelEndpoint -ProjectAiModelNotes $AiModelNotes -RepoUrl $RepoUrl -ProjectRoot $ProjectRoot -GgaProvider $GgaProvider
} else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap -ConfigPath $ConfigPath -CreateProject -ProjectName $Name -ProjectKind $Kind -ProjectPreset $Preset -ProjectArchitecture $Architecture -ProjectProfile $Profile -ProjectAiModelMode $AiModelMode -ProjectAiModelProvider $AiModelProvider -ProjectAiModelName $AiModelName -ProjectAiModelEndpoint $AiModelEndpoint -ProjectAiModelNotes $AiModelNotes -RepoUrl $RepoUrl -ProjectRoot $ProjectRoot -GgaProvider $GgaProvider
}
