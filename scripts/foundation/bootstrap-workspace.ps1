param(
    [string]$ConfigPath = $(Join-Path $PSScriptRoot '..\..\config\workspace.config.json'),
    [string]$TemplatePath = $(Join-Path $PSScriptRoot '..\..\templates\project-root'),
    [string]$TemplateKindsRoot = $(Join-Path $PSScriptRoot '..\..\templates\project-types'),
    [string]$WorkspaceRoot = $(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$ProjectName = '',
    [string]$ProjectKind = '',
    [string]$ProjectPreset = '',
    [string]$ProjectArchitecture = '',
    [string]$ProjectProfile = '',
    [string]$ProjectAiModelMode = '',
    [string]$ProjectAiModelProvider = '',
    [string]$ProjectAiModelName = '',
    [string]$ProjectAiModelEndpoint = '',
    [string]$ProjectAiModelNotes = '',
    [string]$RepoUrl = '',
    [string]$ProjectRoot = '',
    [switch]$CreateProject,
    [switch]$RunToolInstallers
)

$ErrorActionPreference = 'Stop'

function Get-PlatformKey {
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) { return 'windows' }
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) { return 'macos' }
    return 'linux'
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Resolve-ConfigText {
    param(
        [string]$Text,
        [hashtable]$Context
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    $resolved = $Text
    foreach ($key in $Context.Keys) {
        $resolved = $resolved.Replace("{$key}", [string]$Context[$key])
    }

    return $resolved
}

function Test-ToolInstalled {
    param(
        [pscustomobject]$Tool,
        [hashtable]$Context
    )

    if ($Tool.checkPath) {
        $resolvedPath = Resolve-ConfigText -Text $Tool.checkPath -Context $Context
        return Test-Path $resolvedPath
    }

    if ($Tool.checkCommand) {
        return [bool](Get-Command $Tool.checkCommand -ErrorAction SilentlyContinue)
    }

    return $false
}

function Read-WorkspaceConfig {
    param([string]$Path)

    if (Test-Path $Path) {
        return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    }

    return [pscustomobject]@{
        dataRoot = $(Join-Path $WorkspaceRoot '.engram-data')
        toolsRoot = $(Join-Path $WorkspaceRoot 'tools')
        projectsRoot = $(Join-Path $WorkspaceRoot 'projects')
        projectTemplate = $TemplatePath
        projectDefaults = [pscustomobject]@{
            repositoryMode = 'template'
            kind = 'service'
            preset = 'default'
            architecture = 'layered'
            profile = 'general'
            aiModelMode = 'none'
            aiModelProvider = ''
            aiModelName = ''
            aiModelEndpoint = ''
            aiModelNotes = ''
            repoUrl = ''
            cloneDir = ''
            buildCommand = ''
            testCommand = 'go test ./...'
            postInstallCommand = ''
        }
        projectKinds = @('service', 'cli', 'library')
        tools = @()
    }
}

function Copy-TemplateProject {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Name
    )

    if (-not (Test-Path $Source)) {
        throw "Template path not found: $Source"
    }

    if (Test-Path $Destination) {
        throw "Destination already exists: $Destination"
    }

    # Create the destination directory explicitly so template copies work reliably.
    Ensure-Directory -Path (Split-Path -Parent $Destination)
    Ensure-Directory -Path $Destination
    Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force

    $readme = Join-Path $Destination 'README.md'
    if (Test-Path $readme) {
        (Get-Content -Path $readme -Raw -Encoding UTF8) `
            -replace 'Project Name', $Name `
            -replace 'cmd/project-name', "cmd/$Name" |
            Set-Content -Path $readme -Encoding UTF8
    }
}

function Write-ProjectContext {
    param(
        [string]$Destination,
        [hashtable]$Context,
        [string]$TemplateSource
    )

    $docsDir = Join-Path $Destination 'docs'
    Ensure-Directory -Path $docsDir

    $contextPath = Join-Path $docsDir 'project-context.md'
    $templateContextPath = if ([string]::IsNullOrWhiteSpace($TemplateSource)) {
        $null
    } else {
        Join-Path $TemplateSource 'docs\project-context.md'
    }

    if (Test-Path -LiteralPath $contextPath) {
        $existingText = Get-Content -Path $contextPath -Raw -Encoding UTF8
        if ($existingText -notmatch '\{\{') {
            return
        }
        $templateText = $existingText
    } elseif ($templateContextPath -and (Test-Path -LiteralPath $templateContextPath)) {
        $templateText = Get-Content -Path $templateContextPath -Raw -Encoding UTF8
    } else {
        $templateText = @"
# Project Context

This file captures the selected defaults for the project and the first decisions that affect structure, AI usage, and delivery.

## Selected Defaults

- Project name: {{projectName}}
- Workspace name: {{workspaceName}}
- Kind: {{kind}}
- Preset: {{preset}}
- Architecture: {{architecture}}
- Profile: {{profile}}
- Repository mode: {{repositoryMode}}
- Source repo: {{repoUrl}}

## AI Model Decision

- Mode: {{ai-model-mode}}
- Provider: {{ai-model-provider}}
- Model name: {{ai-model-name}}
- Endpoint: {{ai-model-endpoint}}
- Notes: {{ai-model-notes}}

## Notes

- Keep these defaults if the project is still being discovered.
- Ask the project owner before changing architecture, repository strategy, or model provider.
- Use the project documentation or Engram to capture later decisions.
- Leave this file as the first place to record scope changes.

## Follow-Up Items

1. Confirm the project scope with the owner.
2. Confirm whether the AI setup is local, cloud-based, or not needed.
3. Review the README and ARCHITECTURE files.
4. Record any operational constraints or deployment assumptions.
5. Update this file when a decision changes.
"@
    }

    $rendered = $templateText
    foreach ($key in $Context.Keys) {
        $rendered = $rendered.Replace("{{${key}}}", [string]$Context[$key])
    }

    $rendered | Set-Content -Path $contextPath -Encoding UTF8
}

function Apply-TemplateOverlay {
    param(
        [string]$Source,
        [string]$Destination
    )

    if ([string]::IsNullOrWhiteSpace($Source) -or -not (Test-Path $Source)) {
        return
    }

    Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
}

function Remove-LegacyTemplateFiles {
    param([string]$Destination)

    $legacySetupDoc = Join-Path $Destination 'docs\setup\prerequisitos.md'
    if (Test-Path -LiteralPath $legacySetupDoc) {
        Remove-Item -LiteralPath $legacySetupDoc -Force
    }
}

function Install-SecuritySkill {
    param(
        [string]$ProjectPath,
        [string]$WorkspaceSkillsPath,
        [string]$SkillName = 'security-expert-skill'
    )

    $skillSource = Join-Path $WorkspaceSkillsPath $SkillName
    $skillDest = Join-Path $ProjectPath '.workspace-foundation\skills\$SkillName'
    
    $skillDest = Join-Path $ProjectPath ".workspace-foundation\skills\$SkillName"
    
    if (Test-Path $skillSource) {
        Write-Host "Installing $SkillName..."
        Ensure-Directory -Path (Split-Path -Parent $skillDest)
        Copy-Item -Path $skillSource -Destination $skillDest -Recurse -Force
        
        Install-SecurityHook -ProjectPath $ProjectPath
        
        Write-Success "Security Expert skill installed"
        return $true
    } else {
        Write-Warning "$SkillName not found in workspace skills"
        return $false
    }
}

function Install-SecurityHook {
    param([string]$ProjectPath)

    $hooksDir = Join-Path $ProjectPath '.git\hooks'
    Ensure-Directory -Path $hooksDir
    
    $isWindowsHost = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
    
    $hookScript = if ($isWindowsHost) {
        'pre-commit-security.ps1'
    } else {
        'pre-commit-security.sh'
    }
    
    $hookSource = Join-Path $WorkspaceRoot "skills\security-expert-skill\hooks\$hookScript"
    $hookDest = Join-Path $hooksDir 'pre-commit'
    
    if (Test-Path $hookSource) {
        Copy-Item -Path $hookSource -Destination $hookDest -Force
        
        if (-not $isWindowsHost) {
            & chmod +x $hookDest 2>$null
        }
        
        Write-Success "Security pre-commit hook installed"
    }
}

function Install-ProjectSkills {
    param(
        [string]$ProjectPath,
        [string]$WorkspaceSkillsPath,
        [string[]]$SkillNames
    )

    $hooksInstalled = $false

    foreach ($skillName in $SkillNames) {
        $skillSource = Join-Path $WorkspaceSkillsPath $skillName
        
        if (-not (Test-Path $skillSource)) {
            Write-Warning "Skill not found: $skillName"
            continue
        }
        
        $skillDest = Join-Path $ProjectPath ".workspace-foundation\skills\$skillName"
        Ensure-Directory -Path (Split-Path -Parent $skillDest)
        
        Copy-Item -Path $skillSource -Destination $skillDest -Recurse -Force
        Write-Host "  Installed skill: $skillName"
        
        if (-not $hooksInstalled) {
            $hooksSource = Join-Path $skillSource "hooks"
            if (Test-Path $hooksSource) {
                Install-ReviewHook -ProjectPath $ProjectPath -HooksSource $hooksSource
                $hooksInstalled = $true
            }
        }
    }
}

function Create-OrchestratorActivation {
    param([string]$ProjectPath)

    $activation = @{
        activated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        skill = "project-orchestrator"
        version = "1.0"
        project = Split-Path $ProjectPath -Leaf
        auto_active = $true
    }

    $activationFile = Join-Path $ProjectPath '.orchestrator-active'
    $activation | ConvertTo-Json | Set-Content -Path $activationFile -Encoding UTF8

    $configDir = Join-Path $ProjectPath 'config'
    Ensure-Directory -Path $configDir

    $config = @{
        active = $true
        skill_path = ".workspace-foundation/skills/project-orchestrator-skill"
        auto_detect = $true
        workflow_mode = "coordinated"
        communication_response_mode = "simple"
        allowed_response_modes = @("simple", "executive", "standard", "deep")
        memory_integration = $true
        quality_gates = $true
        session_tracking = $true
        git_integration = $true
        activated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $configFile = Join-Path $configDir 'orchestrator.json'
    $config | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8
    Write-Host "Orchestrator activation created at: $activationFile" -ForegroundColor Green
}

function Install-ReviewHook {
    param(
        [string]$ProjectPath,
        [string]$HooksSource
    )

    $hooksDir = Join-Path $ProjectPath '.git\hooks'
    Ensure-Directory -Path $hooksDir
    
    $isWindowsHost = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
    
    $hookScript = if ($isWindowsHost) {
        'pre-commit-review.ps1'
    } else {
        'pre-commit-review.sh'
    }
    
    $hookSource = Join-Path $HooksSource $hookScript
    $hookDest = Join-Path $hooksDir 'pre-commit'
    
    if (Test-Path $hookSource) {
        Copy-Item -Path $hookSource -Destination $hookDest -Force
        
        if (-not $isWindowsHost) {
            & chmod +x $hookDest 2>$null
        }
        
        Write-Success "Code Review hook installed"
    }
}

# ============================================================================
# Native Integration
# ============================================================================

# All functionality is native to the workspace.
# No external dependencies required - all features are built-in.

# ============================================================================
# Skills Integration
# ============================================================================

function Install-Skills {
    param()

    $skillsDir = Join-Path $config.toolsRoot "skills"

    if (-not (Test-Path $skillsDir)) {
        Write-Host "[Skills] Creating skills directory..." -ForegroundColor Blue
        New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    }

    Write-Host "[Skills] Skills directory available at: $skillsDir" -ForegroundColor Green
    Write-Host "[Skills] Native workspace skills are automatically available." -ForegroundColor Cyan

    return $true
}

function Install-SkillsToAgent {
    param(
        [string]$Agent = "claude"
    )

    $skillsRepo = Join-Path $config.toolsRoot "workspace-skills"

    if (-not (Test-Path $skillsRepo)) {
        Write-Host "[Workspace-Skills] Repository not found. Skipping skill installation." -ForegroundColor Yellow
        return $false
    }

    $skillsDir = switch ($Agent.ToLower()) {
        "claude" { "$env:USERPROFILE\.claude\skills" }
        "opencode" { "$env:USERPROFILE\.config\opencode\skills" }
        "gemini" { "$env:USERPROFILE\.gemini\skills" }
        "cursor" { "$env:USERPROFILE\.cursor\skills" }
        default {
            Write-Host "[Workspace-Skills] Unknown agent: $Agent" -ForegroundColor Yellow
            return $false
        }
    }

    try {
        Ensure-Directory -Path $skillsDir

        $curatedPath = Join-Path $skillsRepo "curated"
        if (Test-Path $curatedPath) {
            Copy-Item -Path (Join-Path $curatedPath "*") -Destination $skillsDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "[Workspace-Skills] Installed curated skills for $Agent" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "[Workspace-Skills] Failed to install skills: $_" -ForegroundColor Red
    }

    return $false
}

function Initialize-Project {
    param(
        [string]$Name,
        [string]$Destination,
        [string]$RepositoryUrl,
        [string]$TemplateSource
    )

    if (-not [string]::IsNullOrWhiteSpace($RepositoryUrl)) {
        # Clone mode: the workspace can bootstrap from an existing repository without using the template.
        Ensure-Directory -Path (Split-Path -Parent $Destination)
        if (Test-Path $Destination) {
            throw "Destination already exists: $Destination"
        }

        Write-Host "Cloning repository into $Destination"
        & git clone $RepositoryUrl $Destination
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed for $RepositoryUrl"
        }
        return
    }

    Copy-TemplateProject -Source $TemplateSource -Destination $Destination -Name $Name
}

$config = Read-WorkspaceConfig -Path $ConfigPath

# Resolve relative paths based on WorkspaceRoot
if ($config.dataRoot -and -not [System.IO.Path]::IsPathRooted($config.dataRoot)) {
    $config.dataRoot = Join-Path $WorkspaceRoot $config.dataRoot
}
if ($config.toolsRoot -and -not [System.IO.Path]::IsPathRooted($config.toolsRoot)) {
    $config.toolsRoot = Join-Path $WorkspaceRoot $config.toolsRoot
}
if ($config.projectsRoot -and -not [System.IO.Path]::IsPathRooted($config.projectsRoot)) {
    $config.projectsRoot = Join-Path $WorkspaceRoot $config.projectsRoot
}
if ($config.projectTemplate -and -not [System.IO.Path]::IsPathRooted($config.projectTemplate)) {
    $config.projectTemplate = Join-Path $WorkspaceRoot $config.projectTemplate
}

if (-not $config.dataRoot) { $config | Add-Member -NotePropertyName dataRoot -NotePropertyValue $(Join-Path $WorkspaceRoot '.engram-data') }
if (-not $config.toolsRoot) { $config | Add-Member -NotePropertyName toolsRoot -NotePropertyValue $(Join-Path $WorkspaceRoot 'tools') }
if (-not $config.projectsRoot) { $config | Add-Member -NotePropertyName projectsRoot -NotePropertyValue $(Join-Path $WorkspaceRoot 'projects') }
if (-not $config.projectTemplate) { $config | Add-Member -NotePropertyName projectTemplate -NotePropertyValue $TemplatePath }
if (-not $config.projectDefaults) {
    $config | Add-Member -NotePropertyName projectDefaults -NotePropertyValue ([pscustomobject]@{
        repositoryMode = 'template'
        kind = 'service'
        preset = 'default'
        architecture = 'layered'
        profile = 'general'
        aiModelMode = 'none'
        aiModelProvider = ''
        aiModelName = ''
        aiModelEndpoint = ''
        aiModelNotes = ''
        repoUrl = ''
        cloneDir = ''
        buildCommand = ''
        testCommand = 'go test ./...'
        postInstallCommand = ''
    })
}
if (-not $config.projectKinds) { $config | Add-Member -NotePropertyName projectKinds -NotePropertyValue @('service', 'cli', 'library') }
    if (-not $config.tools) { $config | Add-Member -NotePropertyName tools -NotePropertyValue @() }
if (-not $config.skills) {
    $config | Add-Member -NotePropertyName skills -NotePropertyValue @(
        'project-orchestrator-skill',
        'project-scaffolding-skill',
        'code-review-orchestrator-skill',
        'golang-api-skill',
        'angular-spa-skill',
        'react-19-skill',
        'nextjs-15-skill',
        'typescript-skill',
        'testing-strategy-skill',
        'docker-devops-skill',
        'ai-sdk-5-skill',
        'mcp-skill'
    )
}

Ensure-Directory -Path $WorkspaceRoot
Ensure-Directory -Path $config.dataRoot
Ensure-Directory -Path $config.toolsRoot
Ensure-Directory -Path $config.projectsRoot

Write-Host "Workspace root: $WorkspaceRoot"
Write-Host "Data root: $($config.dataRoot)"
Write-Host "Tools root: $($config.toolsRoot)"
Write-Host "Projects root: $($config.projectsRoot)"

$configContext = @{
    workspaceRoot = $WorkspaceRoot
    dataRoot = $config.dataRoot
    toolsRoot = $config.toolsRoot
    projectsRoot = $config.projectsRoot
}

$requiredCommands = @('git', 'pwsh')
foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Warning "$cmd was not found in PATH."
    } else {
        Write-Host "$cmd OK"
    }
}

if ($CreateProject) {
    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        throw "ProjectName is required when CreateProject is set."
    }

    $destination = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        Join-Path $config.projectsRoot $ProjectName
    } else {
        $ProjectRoot
    }

    $selectedKind = if (-not [string]::IsNullOrWhiteSpace($ProjectKind)) {
        $ProjectKind
    } elseif ($config.projectDefaults.kind) {
        $config.projectDefaults.kind
    } else {
        'service'
    }

    if ($config.projectKinds -and ($config.projectKinds -notcontains $selectedKind)) {
        Write-Warning "Project kind '$selectedKind' is not listed in config.projectKinds; using base template and continuing."
    }

    $repoToClone = if (-not [string]::IsNullOrWhiteSpace($RepoUrl)) {
        $RepoUrl
    } elseif ($config.projectDefaults.repoUrl) {
        $config.projectDefaults.repoUrl
    } else {
        ''
    }

    $selectedRepositoryMode = if (-not [string]::IsNullOrWhiteSpace($repoToClone)) {
        'clone'
    } elseif ($config.projectDefaults.repositoryMode) {
        $config.projectDefaults.repositoryMode
    } else {
        'template'
    }

    $selectedPreset = if (-not [string]::IsNullOrWhiteSpace($ProjectPreset)) {
        $ProjectPreset
    } elseif ($config.projectDefaults.preset) {
        $config.projectDefaults.preset
    } else {
        'default'
    }

    $selectedArchitecture = if (-not [string]::IsNullOrWhiteSpace($ProjectArchitecture)) {
        $ProjectArchitecture
    } elseif ($config.projectDefaults.architecture) {
        $config.projectDefaults.architecture
    } else {
        'layered'
    }

    $selectedProfile = if (-not [string]::IsNullOrWhiteSpace($ProjectProfile)) {
        $ProjectProfile
    } elseif ($config.projectDefaults.profile) {
        $config.projectDefaults.profile
    } else {
        'general'
    }

    $selectedAiModelMode = if (-not [string]::IsNullOrWhiteSpace($ProjectAiModelMode)) {
        $ProjectAiModelMode
    } elseif ($config.projectDefaults.aiModelMode) {
        $config.projectDefaults.aiModelMode
    } else {
        'none'
    }

    $selectedAiModelProvider = if (-not [string]::IsNullOrWhiteSpace($ProjectAiModelProvider)) {
        $ProjectAiModelProvider
    } elseif ($config.projectDefaults.aiModelProvider) {
        $config.projectDefaults.aiModelProvider
    } else {
        ''
    }

    $selectedAiModelName = if (-not [string]::IsNullOrWhiteSpace($ProjectAiModelName)) {
        $ProjectAiModelName
    } elseif ($config.projectDefaults.aiModelName) {
        $config.projectDefaults.aiModelName
    } else {
        ''
    }

    $selectedAiModelEndpoint = if (-not [string]::IsNullOrWhiteSpace($ProjectAiModelEndpoint)) {
        $ProjectAiModelEndpoint
    } elseif ($config.projectDefaults.aiModelEndpoint) {
        $config.projectDefaults.aiModelEndpoint
    } else {
        ''
    }

    $selectedAiModelNotes = if (-not [string]::IsNullOrWhiteSpace($ProjectAiModelNotes)) {
        $ProjectAiModelNotes
    } elseif ($config.projectDefaults.aiModelNotes) {
        $config.projectDefaults.aiModelNotes
    } else {
        ''
    }

    Initialize-Project -Name $ProjectName -Destination $destination -RepositoryUrl $repoToClone -TemplateSource $config.projectTemplate

    $kindOverlay = Join-Path $TemplateKindsRoot $selectedKind
    if (Test-Path $kindOverlay) {
        Write-Host "Applying project kind overlay: $selectedKind"
        Apply-TemplateOverlay -Source $kindOverlay -Destination $destination
    } else {
        Write-Host "Project kind overlay not found for '$selectedKind'; using base template only."
    }

    Remove-LegacyTemplateFiles -Destination $destination

    Create-OrchestratorActivation -ProjectPath $destination

    Write-ProjectContext -Destination $destination -TemplateSource $config.projectTemplate -Context @{
        workspaceName = $config.workspaceName
        projectName = $ProjectName
        kind = $selectedKind
        preset = $selectedPreset
        architecture = $selectedArchitecture
        profile = $selectedProfile
        repositoryMode = $selectedRepositoryMode
        repoUrl = $repoToClone
        'ai-model-mode' = $selectedAiModelMode
        'ai-model-provider' = $selectedAiModelProvider
        'ai-model-name' = $selectedAiModelName
        'ai-model-endpoint' = $selectedAiModelEndpoint
        'ai-model-notes' = $selectedAiModelNotes
    }

    Write-Host "Installing project skills..."
    $projectSkills = if ($config.skills) { $config.skills } else {
        @('project-scaffolding-skill', 'code-review-orchestrator-skill')
    }
    Install-ProjectSkills -ProjectPath $destination -WorkspaceSkillsPath $config.toolsRoot -SkillNames $projectSkills

    # Install native workspace skills
    Install-Skills

    # Try to auto-detect and install skills for available AI agent
    $detectedAgent = $null
    if (Get-Command claude -ErrorAction SilentlyContinue) { $detectedAgent = "claude" }
    elseif (Get-Command opencode -ErrorAction SilentlyContinue) { $detectedAgent = "opencode" }
    elseif (Get-Command gemini -ErrorAction SilentlyContinue) { $detectedAgent = "gemini" }
    elseif (Get-Command cursor -ErrorAction SilentlyContinue) { $detectedAgent = "cursor" }

    if ($detectedAgent) {
        Install-SkillsToAgent -Agent $detectedAgent
    }

    # Install CI/CD templates
    Write-Host "Installing CI/CD templates..."
    $ciCdTemplateScript = Join-Path (Join-Path $PSScriptRoot '..\utilities') 'install-ci-cd-template.ps1'
    & $ciCdTemplateScript -ProjectPath $destination

    Write-Host "Project scaffold created at $destination"

    if ($config.projectDefaults.testCommand) {
        Write-Host "Suggested test command: $($config.projectDefaults.testCommand)"
    }
    if ($config.projectDefaults.buildCommand) {
        Write-Host "Suggested build command: $($config.projectDefaults.buildCommand)"
    }
    if ($config.projectDefaults.postInstallCommand) {
        Write-Host "Suggested post-install command: $($config.projectDefaults.postInstallCommand)"
    }
    Write-Host "Project kind: $selectedKind"
    Write-Host "Project preset: $selectedPreset"
    Write-Host "Project architecture: $selectedArchitecture"
    Write-Host "Project profile: $selectedProfile"
    Write-Host "Repository mode: $selectedRepositoryMode"
    Write-Host "AI model mode: $selectedAiModelMode"
    if (-not [string]::IsNullOrWhiteSpace($selectedAiModelProvider)) {
        Write-Host "AI model provider: $selectedAiModelProvider"
    }
    if (-not [string]::IsNullOrWhiteSpace($selectedAiModelName)) {
        Write-Host "AI model name: $selectedAiModelName"
    }
}
}

$platformKey = Get-PlatformKey
foreach ($tool in $config.tools) {
    $toolName = $tool.name
    if ([string]::IsNullOrWhiteSpace($toolName)) {
        continue
    }

    if (Test-ToolInstalled -Tool $tool -Context $configContext) {
        $installedLabel = if ($tool.checkPath) {
            Resolve-ConfigText -Text $tool.checkPath -Context $configContext
        } else {
            $tool.checkCommand
        }
        Write-Host "$toolName OK ($installedLabel)"
        continue
    }

    $installCommand = $null
    if ($tool.install) {
        if ($tool.install.$platformKey) {
            $installCommand = $tool.install.$platformKey
        } elseif ($tool.install.windows -and $IsWindows) {
            $installCommand = $tool.install.windows
        }
    }

    if ([string]::IsNullOrWhiteSpace($installCommand)) {
        Write-Warning "No installer command configured for $toolName on $platformKey."
        continue
    }

    $installCommand = Resolve-ConfigText -Text $installCommand -Context $configContext

    # Installation commands stay in config so external tools can evolve independently.
    Write-Host "Installer available for $toolName on ${platformKey}:"
    Write-Host $installCommand

    if ($RunToolInstallers) {
        $requiredCommands = @()
        if ($tool.requires) {
            $requiredCommands = @($tool.requires)
        }

        $missingRequired = $false
        foreach ($required in $requiredCommands) {
            if (-not (Get-Command $required -ErrorAction SilentlyContinue)) {
                Write-Warning "Skipping $toolName installer because required command '$required' is not available."
                $missingRequired = $true
                break
            }
        }

        if ($missingRequired) {
            continue
        }

        Write-Host "Running installer for $toolName..."
        $shellRunner = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($shellRunner) {
            & pwsh -NoProfile -Command $installCommand
        } elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
            & powershell -NoProfile -Command $installCommand
        } else {
            throw "No PowerShell runner found for $toolName installer."
        }
    }
}

Write-Host "Workspace bootstrap complete."
