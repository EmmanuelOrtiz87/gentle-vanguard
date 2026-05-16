param(
    [string]$ConfigPath = "",
    [string]$Owner = "",
    [string]$Repo = "",
    [string]$RepositoryUrl = "",
    [string]$RunnerRoot = "",
    [string]$RunnerName = "",
    [string[]]$Labels = @(),
    [string]$RunnerGroup = "",
    [string]$WorkFolder = "",
    [string]$RunnerVersion = "",
    [string]$RegistrationToken = "",
    [switch]$InstallService,
    [switch]$ReplaceExisting,
    [switch]$DownloadOnly,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Gray
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Resolve-TemplateValue {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    $resolved = $Value
    if ($env:USERPROFILE) {
        $resolved = $resolved.Replace('{userProfile}', $env:USERPROFILE)
    }
    if ($HOME) {
        $resolved = $resolved.Replace('{home}', $HOME)
    }
    if ($env:COMPUTERNAME) {
        $resolved = $resolved.Replace('{machineName}', $env:COMPUTERNAME)
    }
    return ($resolved -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Get-PlatformPackage {
    $os = if ($IsWindows) {
        'win'
    } elseif ($IsLinux) {
        'linux'
    } elseif ($IsMacOS) {
        'osx'
    } else {
        throw 'Unsupported operating system for GitHub runner setup.'
    }

    $archMap = @{
        'X64' = 'x64'
        'Arm64' = 'arm64'
        'X86' = 'x86'
    }

    $arch = $archMap[[System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()]
    if (-not $arch) {
        throw 'Unsupported CPU architecture for GitHub runner setup.'
    }

    $extension = if ($os -eq 'win') { 'zip' } else { 'tar.gz' }
    [pscustomobject]@{
        Os = $os
        Arch = $arch
        Extension = $extension
        FileName = "actions-runner-$os-$arch-$RunnerVersion.$extension"
    }
}

function Get-RegistrationTokenFromGh {
    param(
        [string]$TokenOwner,
        [string]$TokenRepo
    )

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'gh CLI is not installed. Pass -RegistrationToken or install/authenticate gh.'
    }

    $token = gh api --method POST "repos/$TokenOwner/$TokenRepo/actions/runners/registration-token" --jq .token
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
        throw 'Could not obtain a registration token via gh. Check gh auth and repository admin permissions.'
    }

    $token.Trim()
}

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    if ($env:GENTLE_VANGUARD_BASE_DIR) {
        $repoRoot = $env:GENTLE_VANGUARD_BASE_DIR
    } else {
        $searchDir = $PSScriptRoot
        while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
            $searchDir = Split-Path -Parent $searchDir
        }
        $repoRoot = $searchDir
    }
    $ConfigPath = Join-Path $repoRoot 'config\github-runner.local.json'
}

$config = $null
if (Test-Path $ConfigPath) {
    $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Info "Loaded config: $ConfigPath"
}

if (-not $Owner -and $config -and $config.repository.owner) { $Owner = [string]$config.repository.owner }
if (-not $Repo -and $config -and $config.repository.name) { $Repo = [string]$config.repository.name }
if (-not $RepositoryUrl -and $config -and $config.repository.url) { $RepositoryUrl = [string]$config.repository.url }
if (-not $RunnerRoot -and $config -and $config.runner.root) { $RunnerRoot = Resolve-TemplateValue ([string]$config.runner.root) }
if (-not $RunnerName -and $config -and $config.runner.name) { $RunnerName = Resolve-TemplateValue ([string]$config.runner.name) }
if (($Labels.Count -eq 0) -and $config -and $config.runner.labels) { $Labels = @($config.runner.labels | ForEach-Object { [string]$_ }) }
if (-not $RunnerGroup -and $config -and $config.runner.group) { $RunnerGroup = [string]$config.runner.group }
if (-not $WorkFolder -and $config -and $config.runner.workFolder) { $WorkFolder = [string]$config.runner.workFolder }
if (-not $RunnerVersion -and $config -and $config.runner.version) { $RunnerVersion = [string]$config.runner.version }
if (-not $InstallService.IsPresent -and $config -and $null -ne $config.runner.installService) { $InstallService = [bool]$config.runner.installService }
if (-not $ReplaceExisting.IsPresent -and $config -and $null -ne $config.runner.replaceExisting) { $ReplaceExisting = [bool]$config.runner.replaceExisting }

if ([string]::IsNullOrWhiteSpace($Owner) -or [string]::IsNullOrWhiteSpace($Repo)) {
    throw 'Owner and repo are required. Use -Owner/-Repo or config/github-runner.local.json.'
}

if ([string]::IsNullOrWhiteSpace($RepositoryUrl)) {
    $RepositoryUrl = "https://github.com/$Owner/$Repo"
}

if ([string]::IsNullOrWhiteSpace($RunnerVersion)) {
    $RunnerVersion = '2.329.0'
}

if ([string]::IsNullOrWhiteSpace($RunnerRoot)) {
    $RunnerRoot = Join-Path $HOME "actions-runner\$Repo"
}

if ([string]::IsNullOrWhiteSpace($RunnerName)) {
    $machineName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { 'gentle-vanguard-runner' }
    $RunnerName = "$machineName-$Repo"
}

if ([string]::IsNullOrWhiteSpace($RunnerGroup)) {
    $RunnerGroup = 'Default'
}

if ([string]::IsNullOrWhiteSpace($WorkFolder)) {
    $WorkFolder = '_work'
}

if ($Labels.Count -eq 0) {
    $platformLabel = if ($IsWindows) { 'windows' } elseif ($IsLinux) { 'linux' } else { 'macos' }
    $Labels = @('self-hosted', $platformLabel, 'gentle-vanguard')
}

$package = Get-PlatformPackage
$archivePath = Join-Path $RunnerRoot $package.FileName
$downloadUrl = "https://github.com/actions/runner/releases/download/v$RunnerVersion/$($package.FileName)"

Write-Step 'GitHub Runner Configuration'
Write-Host "Repository:   $RepositoryUrl"
Write-Host "Runner root:  $RunnerRoot"
Write-Host "Runner name:  $RunnerName"
Write-Host "Runner group: $RunnerGroup"
Write-Host "Labels:       $($Labels -join ',')"
Write-Host "Version:      $RunnerVersion"

if ($DryRun) {
    Write-Info 'Dry run enabled. No files or runner configuration will be changed.'
    exit 0
}

if (-not (Test-Path $RunnerRoot)) {
    New-Item -ItemType Directory -Path $RunnerRoot -Force | Out-Null
}

Write-Step 'Download runner package'
if (-not (Test-Path $archivePath)) {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath
    Write-Success "Downloaded $($package.FileName)"
} else {
    Write-Info "Package already present: $archivePath"
}

Write-Step 'Extract runner package'
if ($package.Extension -eq 'zip') {
    Expand-Archive -Path $archivePath -DestinationPath $RunnerRoot -Force
} else {
    tar -xzf $archivePath -C $RunnerRoot
}
Write-Success 'Runner package extracted'

if ($DownloadOnly) {
    Write-Info 'DownloadOnly enabled. Skipping registration and service setup.'
    exit 0
}

Write-Step 'Resolve registration token'
if ([string]::IsNullOrWhiteSpace($RegistrationToken)) {
    $RegistrationToken = Get-RegistrationTokenFromGh -TokenOwner $Owner -TokenRepo $Repo
    Write-Success 'Registration token acquired via gh'
} else {
    Write-Success 'Using registration token passed by parameter'
}

Push-Location $RunnerRoot
try {
    Write-Step 'Configure runner'
    $labelText = $Labels -join ','
    $configCommand = if ($IsWindows) { '.\config.cmd' } else { './config.sh' }
    $configArgs = @(
        '--url', $RepositoryUrl,
        '--token', $RegistrationToken,
        '--name', $RunnerName,
        '--runnergroup', $RunnerGroup,
        '--labels', $labelText,
        '--work', $WorkFolder,
        '--unattended'
    )

    if ($ReplaceExisting) {
        $configArgs += '--replace'
    }

    & $configCommand @configArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'Runner configuration failed.'
    }
    Write-Success 'Runner configured'

    if ($InstallService) {
        Write-Step 'Install runner service'
        if ($IsWindows) {
            & .\svc.cmd install
            & .\svc.cmd start
        } else {
            & ./svc.sh install
            & ./svc.sh start
        }

        if ($LASTEXITCODE -ne 0) {
            throw 'Runner service installation failed.'
        }
        Write-Success 'Runner service installed and started'
    } else {
        Write-Info 'Service installation skipped. Start the runner manually with run.cmd or run.sh.'
    }
}
finally {
    Pop-Location
}

Write-Step 'Next Steps'
Write-Host '1. Keep config/github-runner.local.json local only.'
Write-Host '2. If you later remove this runner, unregister it from GitHub first.'
Write-Host '3. For public repos, keep untrusted PR workflows on GitHub-hosted runners.'
