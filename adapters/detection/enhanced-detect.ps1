<#
.SYNOPSIS
    Enhanced IDE/Tool detection for Foundation adapters.

.DESCRIPTION
    Extends detect-ide-session.ps1 with:
    - MCP-compatible tool detection (Windsurf, Codex, Antigravity)
    - Adapter recommendation
    - Format capability reporting

.PARAMETER AsJson
    Output as JSON.

.PARAMETER Quiet
    Suppress console output.

.PARAMETER DetectAdapters
    Detect available adapters in adapters/ directory.

.EXAMPLE
    .\enhanced-detect.ps1
    .\enhanced-detect.ps1 -AsJson
    .\enhanced-detect.ps1 -DetectAdapters
#>

param(
    [switch]$AsJson,
    [switch]$Quiet,
    [switch]$DetectAdapters
)

$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$adaptersDir = Join-Path $repoRoot 'adapters'

function Get-ParentProcessNames {
    $names = @()
    try {
        $pidCursor = $PID
        for ($i = 0; $i -lt 5; $i++) {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$pidCursor"
            if (-not $proc) { break }
            $parentId = $proc.ParentProcessId
            if (-not $parentId) { break }
            $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$parentId"
            if (-not $parent) { break }
            $names += $parent.Name
            $pidCursor = $parentId
        }
    } catch {
        Write-Verbose "Unable to resolve full parent process tree"
    }
    return $names
}

function Get-EnvVars {
    param($prefix)
    $vars = @{}
    Get-ChildItem env: | Where-Object { $_.Name -like "$prefix*" } | ForEach-Object {
        $vars[$_.Name] = $_.Value
    }
    return $vars
}

function Get-ToolCapability {
    param($toolName)
    
    $capabilities = @{
        'vscode' = @('file_ops', 'terminal', 'git', 'debugging')
        'opencode' = @('mcp', 'subagents', 'token_management', 'skills')
        'cursor' = @('parallel_execution', 'mcp', 'skills', 'code_completion')
        'windsurf' = @('ai_chat', 'code_generation')  # Limited - needs MCP Bridge
        'codex' = @('function_calling', 'code_completion')  # Needs format adapter
        'antigravity' = @('mission_control')  # Needs format adapter
        'jetbrains' = @('file_ops', 'terminal', 'git', 'debugging')
        'terminal' = @('basic_commands')
    }
    
    return $capabilities[$toolName] || @('unknown')
}

function Get-AdapterPath {
    param($toolName)
    
    $adapterMap = @{
        'windsurf' = Join-Path $adaptersDir 'format-adapters\windsurf-adapter'
        'codex' = Join-Path $adaptersDir 'format-adapters\codex-adapter'
        'antigravity' = Join-Path $adaptersDir 'format-adapters\antigravity-adapter'
    }
    
    return $adapterMap[$toolName]
}

function Get-Recommendation {
    param($toolName, $capabilities)
    
    if ($capabilities -contains 'mcp') {
        return "Use MCP Bridge at adapters/mcp-bridge"
    }
    
    $adapterPath = Get-AdapterPath $toolName
    if ($adapterPath -and (Test-Path $adapterPath)) {
        return "Use format adapter at $adapterPath"
    }
    
    return "Implement adapter for $toolName (see adapters/README.md)"
}

# Main detection logic
$parentNames = Get-ParentProcessNames
$termProgram = $env:TERM_PROGRAM
$processName = $env:PROCESSNAME

$toolName = 'unknown'
$source = 'none'
$confidence = 'low'
$detectionMethod = 'none'

# Check for specific tools (order matters - most specific first)
if ($env:WINDSURF_ -or $parentNames -match 'windsurf|Windsurf') {
    $toolName = 'windsurf'
    $source = 'env/process'
    $confidence = 'medium'
    $detectionMethod = 'WINDSURF_ env or process name'
} elseif ($env:CODEX_ -or $termProgram -match 'codex') {
    $toolName = 'codex'
    $source = 'env/process'
    $confidence = 'medium'
    $detectionMethod = 'CODEX_ env or TERM_PROGRAM'
} elseif ($env:ANTIGRAVITY_ -or $parentNames -match 'antigravity') {
    $toolName = 'antigravity'
    $source = 'env/process'
    $confidence = 'low'
    $detectionMethod = 'ANTIGRAVITY_ env or process name'
} elseif ($env:OPENCODE_ -or $parentNames -match 'opencode|OpenCode') {
    $toolName = 'opencode'
    $source = 'env/process'
    $confidence = 'high'
    $detectionMethod = 'OPENCODE_ env or process name'
} elseif ($env:CURSOR_ -or $parentNames -match 'cursor|Cursor') {
    $toolName = 'cursor'
    $source = 'env/process'
    $confidence = 'high'
    $detectionMethod = 'CURSOR_ env or process name'
} elseif ($env:VSCODE_GIT_IPC_HANDLE -or $termProgram -eq 'vscode' -or ($parentNames -match 'Code.exe|Code - Insiders.exe')) {
    $toolName = 'vscode'
    $source = 'env/process'
    $confidence = 'high'
    $detectionMethod = 'VSCODE env or process name'
} elseif ($env:JETBRAINS_IDE -or $env:IDEA_INITIAL_DIRECTORY -or ($parentNames -match 'idea64.exe|pycharm64.exe|webstorm64.exe|rider64.exe')) {
    $toolName = 'jetbrains'
    $source = 'env/process'
    $confidence = 'medium'
    $detectionMethod = 'JetBrains env or process name'
} elseif ($parentNames -match 'devenv.exe') {
    $toolName = 'visual-studio'
    $source = 'process'
    $confidence = 'medium'
    $detectionMethod = 'devenv.exe process'
} elseif ($termProgram) {
    $toolName = "terminal-$termProgram"
    $source = 'env'
    $confidence = 'low'
    $detectionMethod = 'TERM_PROGRAM env'
} else {
    $toolName = 'terminal'
    $source = 'fallback'
    $confidence = 'low'
    $detectionMethod = 'fallback'
}

# Get capabilities and recommendation
$capabilities = Get-ToolCapability $toolName
$adapterPath = Get-AdapterPath $toolName
$recommendation = Get-Recommendation $toolName $capabilities

# Check adapter availability
$hasMcpBridge = Test-Path (Join-Path $adaptersDir 'mcp-bridge\package.json')
$hasFormatAdapter = $adapterPath -and (Test-Path $adapterPath)

# Build result
$result = [pscustomobject]@{
    toolName = $toolName
    displayName = $toolName.ToUpper()[0] + $toolName.Substring(1)
    isIdeSession = @('vscode', 'cursor', 'windsurf', 'codex', 'antigravity', 'jetbrains', 'visual-studio') -contains $toolName
    source = $source
    confidence = $confidence
    detectionMethod = $detectionMethod
    parentProcesses = $parentNames
    capabilities = $capabilities
    supportsMcp = $capabilities -contains 'mcp'
    supportsSkills = $capabilities -contains 'skills'
    supportsSubagents = $capabilities -contains 'subagents'
    recommendation = $recommendation
    adapterStatus = @{
        mcpBridge = @{
            available = $hasMcpBridge
            path = Join-Path $adaptersDir 'mcp-bridge'
        }
        formatAdapter = @{
            available = $hasFormatAdapter
            path = $adapterPath
        }
    }
    nextSteps = @(
        "1. Check if tool supports MCP (supportsMcp field)",
        "2. If yes: Configure MCP Bridge (adapters/mcp-bridge/)",
        "3. If no: Use format adapter (adapters/format-adapters/)",
        "4. Run: node adapters/mcp-bridge/dist/server.js"
    )
}

# Detect available adapters if requested
if ($DetectAdapters) {
    $adapters = @()
    if (Test-Path $adaptersDir) {
        Get-ChildItem $adaptersDir -Directory | ForEach-Object {
            $adapters += @{ name = $_.Name; path = $_.FullName }
        }
    }
    $result | Add-Member -NotePropertyName 'availableAdapters' -NotePropertyValue $adapters
}

# Output
if ($AsJson) {
    $result | ConvertTo-Json -Depth 10
    exit 0
}

if (-not $Quiet) {
    Write-Host "=== Foundation Enhanced Detection ===" -ForegroundColor Cyan
    Write-Host "Tool: $($result.toolName) ($($result.displayName))" -ForegroundColor White
    Write-Host "Confidence: $($result.confidence) (source: $($result.source))" -ForegroundColor $(if ($result.confidence -eq 'high') { 'Green' } elseif ($result.confidence -eq 'medium') { 'Yellow' } else { 'Red' })
    Write-Host "Detection: $($result.detectionMethod)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Capabilities: $(($result.capabilities) -join ', ')" -ForegroundColor Cyan
    Write-Host "Supports MCP: $($result.supportsMcp)" -ForegroundColor $(if ($result.supportsMcp) { 'Green' } else { 'Red' })
    Write-Host "Supports Skills: $($result.supportsSkills)" -ForegroundColor $(if ($result.supportsSkills) { 'Green' } else { 'Yellow' })
    Write-Host ""
    Write-Host "=== Adapter Status ===" -ForegroundColor Cyan
    Write-Host "MCP Bridge: $($result.adapterStatus.mcpBridge.available)" -ForegroundColor $(if ($result.adapterStatus.mcpBridge.available) { 'Green' } else { 'Red' })
    Write-Host "Format Adapter: $($result.adapterStatus.formatAdapter.available)" -ForegroundColor $(if ($result.adapterStatus.formatAdapter.available) { 'Green' } else { 'Red' })
    Write-Host ""
    Write-Host "=== Recommendation ===" -ForegroundColor Yellow
    Write-Host $result.recommendation -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Green
    $result.nextSteps | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
}

$result
