param(
    [ValidateSet('start', 'stop', 'list', 'status', 'register', 'deregister')]
    [string]$Action = 'status',
    [string]$SkillName = '',
    [string]$McpName = '',
    [string]$Command = '',
    [string[]]$Args = @(),
    [string]$ConfigFile = '',
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$mcpConfigFile = Join-Path $repoRoot 'config\mcp-servers.json'
$skillMcpDir = Join-Path $repoRoot '.runtime' 'skill-mcps'
$activeMcpsFile = Join-Path $skillMcpDir 'active-skill-mcps.json'

if (-not (Test-Path $skillMcpDir)) { New-Item -ItemType Directory -Path $skillMcpDir -Force | Out-Null }

function Write-SkillMCP {
    param([string]$M, [string]$C = 'White')
    if (-not $Quiet) { Write-Host $M -ForegroundColor $C }
}

function Read-McpConfig {
    if (Test-Path $mcpConfigFile) {
        try {
            $raw = Get-Content $mcpConfigFile -Raw -Encoding UTF8
            $parsed = $raw | ConvertFrom-Json
            $mcpServers = @{}
            foreach ($prop in $parsed.mcpServers.PSObject.Properties) {
                $mcpServers[$prop.Name] = $prop.Value
            }
            return @{ mcpServers = $mcpServers; version = $parsed.version; autoStart = $parsed.autoStart }
        } catch { }
    }
    return @{ mcpServers = @{}; version = '1.0.0'; autoStart = $false }
}

function Write-McpConfig {
    param([object]$Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigFile -Encoding UTF8 -Force
}

function Read-ActiveMcps {
    if (Test-Path $activeMcpsFile) {
        try {
            $raw = Get-Content $activeMcpsFile -Raw -Encoding UTF8
            $parsed = $raw | ConvertFrom-Json
            $skillMcps = @{}
            foreach ($prop in $parsed.skill_mcps.PSObject.Properties) {
                $skillMcps[$prop.Name] = $prop.Value
            }
            return @{ skill_mcps = $skillMcps }
        } catch { }
    }
    return @{ skill_mcps = @{} }
}

function Write-ActiveMcps {
    param([object]$Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content $activeMcpsFile -Encoding UTF8 -Force
}

function Get-SkillMcpDefinitions {
    param([string]$Name)
    $skillDir = Join-Path $repoRoot 'skills' $Name
    $skillFile = Join-Path $skillDir 'SKILL.md'
    if (-not (Test-Path $skillFile)) { return @() }

    try {
        $content = Get-Content $skillFile -Raw -Encoding UTF8
        $frontmatter = @{}
        if ($content -match '(?s)^---\s*\n(.*?)\n---') {
            $yamlBlock = $matches[1]
            $currentKey = ''
            $currentValue = @()
            $inArray = $false
            foreach ($line in $yamlBlock -split '\r?\n') {
                if ($line -match '^(\w[\w_-]*):\s*(.*)') {
                    if ($inArray -and $currentKey) {
                        $frontmatter[$currentKey] = $currentValue -join "`n"
                        $currentValue = @()
                        $inArray = $false
                    }
                    $currentKey = $matches[1]
                    $val = $matches[2].Trim()
                    if ($val -eq '') {
                        $inArray = $true
                        $currentValue = @()
                    } elseif ($val -match '^\[.*\]$') {
                        $frontmatter[$currentKey] = $val -replace '^\[|\]$', '' -split ',\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }
                    } else {
                        $frontmatter[$currentKey] = $val
                    }
                } elseif ($inArray -and $line -match '^\s+-\s+(.*)') {
                    $currentValue += $matches[1].Trim().Trim('"').Trim("'")
                }
            }
            if ($inArray -and $currentKey -and $currentValue) {
                $frontmatter[$currentKey] = $currentValue
            }

            if ($frontmatter['mcp_servers']) {
                $servers = @()
                $raw = $frontmatter['mcp_servers']
                $entries = if ($raw -is [array]) { $raw } else { @($raw -split '\r?\n') }
                foreach ($entry in $entries) {
                    $entry = $entry.Trim()
                    if ($entry -match '^(\w[\w_-]+):\s*(\S+)') {
                        $servers += @{ name = $matches[1]; command = $matches[2]; args = @() }
                    }
                }
                return $servers
            }
        }
    } catch {
        Write-SkillMCP "[WARN] Could not parse SKILL.md for $Name" 'Yellow'
    }
    return @()
}

switch ($Action) {
    'start' {
        if (-not $SkillName) { Write-SkillMCP "[ERROR] -SkillName required" 'Red'; exit 1 }
        $mcps = @(Get-SkillMcpDefinitions -Name $SkillName)
        if ($mcps.Count -eq 0) {
            Write-SkillMCP "[SKILL-MCP] No MCP definitions in skill: $SkillName" 'Yellow'
            if ($AsJson) { return (@{ status = 'no-definitions'; skill = $SkillName } | ConvertTo-Json) }
            exit 0
        }

        $mcpConfig = Read-McpConfig
        $active = Read-ActiveMcps

        $started = @()
        foreach ($mcp in $mcps) {
            $mcpName = $mcp['name']
            $mcpCmd = $mcp['command']
            $mcpArgs = $mcp['args']
            $mcpKey = "$SkillName-$mcpName"
            if ($active.skill_mcps.$mcpKey) {
                Write-SkillMCP "[SKILL-MCP] Already active: $mcpKey" 'Yellow'
                continue
            }

            $mcpConfig.mcpServers[$mcpKey] = @{
                command = $mcpCmd
                args = $mcpArgs
                description = "Skill-embedded MCP: $SkillName/$mcpName"
                skill = $SkillName
                autoStart = $true
                security = @{
                    hardened = $true
                    mode = 'skill-scoped'
                }
            }

            $active.skill_mcps[$mcpKey] = @{
                skill = $SkillName
                mcp_name = $mcpName
                command = $mcpCmd
                started_at = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
                status = 'active'
            }
            $started += $mcpKey
            Write-SkillMCP "[SKILL-MCP] Started: $mcpKey ($mcpCmd)" 'Green'
        }

        Write-McpConfig $mcpConfig
        Write-ActiveMcps $active

        Write-SkillMCP "[SKILL-MCP] Started $($started.Count) MCP(s) for skill: $SkillName" 'Green'
        if ($AsJson) { return (@{ status = 'started'; skill = $SkillName; mcps_started = $started } | ConvertTo-Json) }
    }

    'stop' {
        if (-not $SkillName) {
            Write-SkillMCP "[ERROR] -SkillName required" 'Red'; exit 1
        }
        $mcpConfig = Read-McpConfig
        $active = Read-ActiveMcps
        $stopped = @()
        $toRemove = @()

        foreach ($key in $active.skill_mcps.Keys) {
            $entry = $active.skill_mcps[$key]
            $entrySkill = if ($entry -is [hashtable]) { $entry['skill'] } else { $entry.skill }
            if ($entrySkill -eq $SkillName) {
                $toRemove += $key
            }
        }

        if ($toRemove.Count -eq 0) {
            Write-SkillMCP "[SKILL-MCP] No active MCPs for skill: $SkillName" 'Yellow'
            if ($AsJson) { return (@{ status = 'none'; skill = $SkillName } | ConvertTo-Json) }
            exit 0
        }

        foreach ($key in $toRemove) {
            $mcpConfig.mcpServers.Remove($key)
            $active.skill_mcps.Remove($key)
            $stopped += $key
            Write-SkillMCP "[SKILL-MCP] Stopped: $key" 'Yellow'
        }

        Write-McpConfig $mcpConfig
        Write-ActiveMcps $active
        Write-SkillMCP "[SKILL-MCP] Stopped $($stopped.Count) MCP(s) for skill: $SkillName" 'Green'
        if ($AsJson) { return (@{ status = 'stopped'; skill = $SkillName; mcps_stopped = $stopped } | ConvertTo-Json) }
    }

    'list' {
        Write-SkillMCP "=== SKILL MCP DEFINITIONS ===" 'Cyan'
        $skillDirs = Get-ChildItem (Join-Path $repoRoot 'skills') -Directory
        $found = 0
        foreach ($dir in $skillDirs) {
            $mcps = Get-SkillMcpDefinitions -Name $dir.Name
            if ($mcps.Count -gt 0) {
                Write-Host "  $($dir.Name):" -ForegroundColor White
                foreach ($mcp in $mcps) {
                    Write-Host "    - $($mcp.name): $($mcp.command)" -ForegroundColor Gray
                }
                $found++
            }
        }
        if ($found -eq 0) {
            Write-Host "  (no skills with MCP definitions found)" -ForegroundColor Gray
        }
        if ($AsJson) {
            $allDefs = @{}
            foreach ($dir in $skillDirs) {
                $mcps = Get-SkillMcpDefinitions -Name $dir.Name
                if ($mcps.Count -gt 0) { $allDefs[$dir.Name] = $mcps }
            }
            return (@{ skills_with_mcps = $allDefs; count = $found } | ConvertTo-Json -Depth 5)
        }
    }

    'status' {
        $active = Read-ActiveMcps
        $count = @($active.skill_mcps.Keys).Count
        Write-SkillMCP "=== ACTIVE SKILL MCPs ($count) ===" 'Cyan'
        foreach ($key in $active.skill_mcps.Keys) {
            $mcp = $active.skill_mcps[$key]
            $mcpStatus = if ($mcp -is [hashtable]) { $mcp['status'] } else { $mcp.status }
            $mcpSkill = if ($mcp -is [hashtable]) { $mcp['skill'] } else { $mcp.skill }
            $mcpCmd = if ($mcp -is [hashtable]) { $mcp['command'] } else { $mcp.command }
            $color = if ($mcpStatus -eq 'active') { 'Green' } else { 'Gray' }
            Write-Host "  ${key}: skill=$mcpSkill cmd=$mcpCmd status=$mcpStatus" -ForegroundColor $color
        }
        if ($count -eq 0) { Write-Host "  (none active)" -ForegroundColor Gray }
        if ($AsJson) { return ($active | ConvertTo-Json -Depth 5) }
    }

    'register' {
        if (-not $SkillName -or -not $McpName -or -not $Command) {
            Write-SkillMCP "[ERROR] -SkillName, -McpName, -Command required" 'Red'; exit 1
        }
        $skillDir = Join-Path $repoRoot 'skills' $SkillName
        $skillFile = Join-Path $skillDir 'SKILL.md'
        if (-not (Test-Path $skillFile)) {
            Write-SkillMCP "[ERROR] Skill not found: $SkillName" 'Red'; exit 1
        }

        $content = Get-Content $skillFile -Raw -Encoding UTF8
        $mcpEntry = "  - $McpName`: $Command"
        if ($Args.Count -gt 0) {
            $mcpEntry = "  - $McpName`: $Command ($($Args -join ' '))"
        }

        if ($content -match '(?s)^---\s*\n(.*?)\n---') {
            $yamlBlock = $matches[0]
            if ($yamlBlock -match 'mcp_servers:') {
                $newYaml = $yamlBlock -replace 'mcp_servers:\s*\[.*?\]', "mcp_servers:`n$mcpEntry"
                $newContent = $content -replace [regex]::Escape($yamlBlock), $newYaml
            } elseif ($yamlBlock -match 'license:\s*\S+') {
                $newYaml = $yamlBlock -replace 'license:\s*\S+', "license: Apache-2.0`nmcp_servers:`n$mcpEntry"
                $newContent = $content -replace [regex]::Escape($yamlBlock), $newYaml
            } else {
                $newYaml = $yamlBlock -replace '(?=---\s*$)', "mcp_servers:`n$mcpEntry`n"
                $newContent = $content -replace [regex]::Escape($yamlBlock), $newYaml
            }
            $newContent | Set-Content $skillFile -Encoding UTF8 -Force
            Write-SkillMCP "[SKILL-MCP] Registered $McpName in skill $SkillName" 'Green'
        } else {
            Write-SkillMCP "[ERROR] No YAML frontmatter in $skillFile" 'Red'
            exit 1
        }
        if ($AsJson) { return (@{ status = 'registered'; skill = $SkillName; mcp = $McpName } | ConvertTo-Json) }
    }

    'deregister' {
        if (-not $SkillName -or -not $McpName) {
            Write-SkillMCP "[ERROR] -SkillName, -McpName required" 'Red'; exit 1
        }

        & $MyInvocation.MyCommand.Path -Action stop -SkillName $SkillName -Quiet

        $skillFile = Join-Path $repoRoot 'skills' $SkillName 'SKILL.md'
        if (Test-Path $skillFile) {
            $content = Get-Content $skillFile -Raw -Encoding UTF8
            $pattern = "(?m)^  - $([regex]::Escape($McpName)):.*`n?"
            $newContent = $content -replace $pattern, ''
            if ($newContent -ne $content) {
                $newContent | Set-Content $skillFile -Encoding UTF8 -Force
                Write-SkillMCP "[SKILL-MCP] Removed $McpName from skill $SkillName" 'Yellow'
            }
        }
        if ($AsJson) { return (@{ status = 'deregistered'; skill = $SkillName; mcp = $McpName } | ConvertTo-Json) }
    }
}
