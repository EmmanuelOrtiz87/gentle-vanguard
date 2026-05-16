# detect-tool.ps1
# Detects which AI tool/agent is running and returns standardized config

param(
    [string]$ConfigPath = "",
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'

function Get-DetectedTool {
    $tool = @{
        name          = "unknown"
        source        = "unknown"
        configFile    = ""
        promptFile    = ""
        isClaude      = $false
        isOpenCode    = $false
        isCline       = $false
        isCursor      = $false
        isWindsurf    = $false
        isContinueDev = $false
        isCopilot     = $false
        isAntigravity = $false
        confidence    = 0
        os            = @{
            platform      = "unknown"
            shell         = "unknown"
            pathSeparator = [System.IO.Path]::DirectorySeparatorChar.ToString()
            isWindows     = $false
            isLinux       = $false
            isMacOS       = $false
        }
    }

    # Detect OS (compatible with PS 5.1 and PS 7+)
    $osPlatform = [Environment]::OSVersion.Platform
    if ($osPlatform -eq 'Win32NT') {
        $tool.os.isWindows  = $true
        $tool.os.platform   = "windows"
        $tool.os.shell      = "powershell"
    } elseif ($osPlatform -eq 'Unix') {
        $uname = (uname -s)
        if ($uname -eq 'Darwin') {
            $tool.os.isMacOS = $true
            $tool.os.platform = "macos"
            $tool.os.shell    = "zsh"
        } else {
            $tool.os.isLinux  = $true
            $tool.os.platform = "linux"
            $tool.os.shell    = "bash"
        }
    }

    # 1. Check OPENCODE env vars (most reliable for opencode)
    if ($env:OPENCODE_SERVER_USERNAME) {
        $tool.name = "opencode"
        $tool.source = "env:OPENCODE_SERVER_USERNAME"
        $tool.isOpenCode = $true
        $tool.confidence = 100
        $tool.configFile = "opencode.json"
        $tool.promptFile = "CLAUDE.md"
        return $tool
    }

    # 1b. Check for .opencode/ directory (fallback for OpenCode without env var)
    $repoRoot = if ($env:GV_BASE_DIR) { $env:GV_BASE_DIR } else { (Get-Location).Path }
    if (Test-Path (Join-Path $repoRoot ".opencode")) {
        $tool.name = "opencode"
        $tool.source = "dir:.opencode"
        $tool.isOpenCode = $true
        $tool.confidence = 85
        $tool.configFile = "opencode.json"
        $tool.promptFile = "CLAUDE.md"
        return $tool
    }

    # 2. Check CLAUDE_VSCODE_VERSION (Claude Code extension)
    if ($env:CLAUDE_VSCODE_VERSION) {
        $tool.name = "claude-code"
        $tool.source = "env:CLAUDE_VSCODE_VERSION"
        $tool.isClaude = $true
        $tool.confidence = 90
        $tool.configFile = ".claude/settings.json"
        $tool.promptFile = "CLAUDE.md"
        return $tool
    }

    # 3. Platform-default policy: OpenCode baseline for this workspace.
    # If no explicit runtime marker exists, default to OpenCode and let routing/skills decide behavior.
    if (Test-Path (Join-Path $repoRoot "opencode.json")) {
        $tool.name = "opencode"
        $tool.source = "policy-default:opencode"
        $tool.isOpenCode = $true
        $tool.confidence = 75
        $tool.configFile = "opencode.json"
        $tool.promptFile = "CLAUDE.md"
        return $tool
    }

    # 4. Check for .clinerules file (Cline)
    $repoRoot = if ($env:GV_BASE_DIR) { $env:GV_BASE_DIR } else { (Get-Location).Path }
    if (Test-Path (Join-Path $repoRoot ".clinerules")) {
        $tool.name = "cline"
        $tool.source = "file:.clinerules"
        $tool.isCline = $true
        $tool.confidence = 85
        $tool.configFile = ".clinerules"
        $tool.promptFile = ".clinerules"
        return $tool
    }

    # 5. Check for .cursorrules file (Cursor)
    if (Test-Path (Join-Path $repoRoot ".cursorrules")) {
        $tool.name = "cursor"
        $tool.source = "file:.cursorrules"
        $tool.isCursor = $true
        $tool.confidence = 85
        $tool.configFile = ".cursorrules"
        $tool.promptFile = ".cursorrules"
        return $tool
    }

    # 6. Check for .windsurf directory (Windsurf)
    if (Test-Path (Join-Path $repoRoot ".windsurf")) {
        $tool.name = "windsurf"
        $tool.source = "dir:.windsurf"
        $tool.isWindsurf = $true
        $tool.confidence = 80
        $tool.configFile = ".windsurf/config.json"
        $tool.promptFile = "CLAUDE.md"
        return $tool
    }

    # 7. Check for Continue config
    $homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    $continueConfig = Join-Path $homePath ".continue/config.json"
    if (Test-Path $continueConfig -PathType Leaf) {
        $tool.name = "continue-dev"
        $tool.source = "file:$continueConfig"
        $tool.isContinueDev = $true
        $tool.confidence = 70
        $tool.configFile = ".continue/config.json"
        $tool.promptFile = "CLAUDE.md"
        return $tool
    }

    # 8. Fallback: detect by prompt instruction file presence
    $candidates = @(
        @{file="CLAUDE.md"; name="claude-generic"; promptFile="CLAUDE.md"}
        @{file=".clinerules"; name="cline"; promptFile=".clinerules"}
        @{file=".cursorrules"; name="cursor"; promptFile=".cursorrules"}
    )
    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $repoRoot $c.file)) {
            $tool.name = $c.name
            $tool.source = "file:$($c.file)"
            $tool.confidence = 50
            $tool.promptFile = $c.promptFile
            if ($c.name -eq "cline") { $tool.isCline = $true }
            if ($c.name -eq "cursor") { $tool.isCursor = $true }
            return $tool
        }
    }

    # 9. Final fallback: enforce OpenCode default baseline.
    $tool.name = "opencode"
    $tool.source = "fallback-default:opencode"
    $tool.isOpenCode = $true
    $tool.confidence = 40
    $tool.configFile = "opencode.json"
    $tool.promptFile = "CLAUDE.md"
    return $tool
}

function Get-ToolConfig {
    param(
        [hashtable]$DetectedTool,
        [string]$ConfigPath
    )
    $result = $DetectedTool
    $sessionStartCmd = if ($DetectedTool.os.isWindows) {
        "scripts/utilities/session-autostart.cmd"
    } elseif ($DetectedTool.os.isLinux -or $DetectedTool.os.isMacOS) {
        "bash ./scripts/utilities/session-autostart.sh"
    } else {
        "scripts/utilities/session-autostart.cmd"
    }

    $result.instructions = @{
        primaryEntryPoint  = "docs/AGENTS.md"
        primaryConfig      = "config/orchestrator.json"
        workspaceConfig    = "config/workspace.config.json"
        routingConfig      = "config/auto-delegation.json"
        normatives         = "rules/AI-NORMATIVES.md"
        sessionLifecycle   = "rules/NORMATIVAS-SESSION.md"
        developmentStandards = "rules/DEVELOPMENT-STANDARDS.md"
        sessionAutostart   = $sessionStartCmd
        preProcessHook     = "scripts/utilities/pre-process-input.ps1"
        responseProfile    = "ultra"
        communicationLang  = "es"
    }

    if (-not $ConfigPath) { return $result }
    if (-not (Test-Path $ConfigPath)) { return $result }

    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $toolName = $DetectedTool.name
        if ($config.psObject.Properties.Name -contains "toolProfiles" -and
            $config.toolProfiles.psObject.Properties.Name -contains $toolName) {
            $profile = $config.toolProfiles.$toolName
            foreach ($prop in $profile.PSObject.Properties) {
                $result.instructions[$prop.Name] = $prop.Value
            }
        }
    }
    catch {
        Write-Warning "Could not load tool config from $ConfigPath"
    }

    return $result
}

$detected = Get-DetectedTool
$configPath = if ($ConfigPath) { $ConfigPath } else { Join-Path (Split-Path -Parent $PSScriptRoot) "config\orchestrator.json" }
$fullConfig = Get-ToolConfig -DetectedTool $detected -ConfigPath $configPath

if ($AsJson) {
    return ($fullConfig | ConvertTo-Json -Depth 4)
}
return $fullConfig

