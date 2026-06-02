param(
  [ValidateSet("status","setup","verify","launch")]
  [string]$Action = "status",
  [string]$Tool = "",
  [switch]$AllTools
)

$ROOT = Resolve-Path "$PSScriptRoot/../.."
$CONFIG = "$ROOT/config/orchestrator.json"

function Get-DetectedTool {
  $result = & "$ROOT/scripts/utilities/detect-tool.ps1" -AsJson | ConvertFrom-Json
  return $result.name
}

function Get-ToolMCPConfigPath {
  param([string]$tool)
  switch ($tool) {
    "cursor"    { return "$ROOT/.cursor/config.json" }
    "windsurf"  { return "$ROOT/.windsurf/config.json" }
    "cline"     { return "$ROOT/.cline/config.json" }
    "opencode"  { return "$ROOT/opencode.json" }
    default     { return $null }
  }
}

function Test-MCPIntegration {
  param([string]$tool)
  $path = Get-ToolMCPConfigPath $tool
  if (-not $path -or -not (Test-Path $path)) { return $false }
  $content = Get-Content $path -Raw | ConvertFrom-Json
  $hasMCP = $content.PSObject.Properties.Name -contains "mcpServers"
  $hasSkills = $hasMCP -and ($content.mcpServers.PSObject.Properties.Name -contains "gentle-vanguard-skills")
  return @{ configured = $hasMCP; skillServer = $hasSkills; path = $path }
}

function Invoke-MCPSetup {
  param([string]$tool)
  $path = Get-ToolMCPConfigPath $tool
  if (-not $path) { Write-Warning "Unknown tool: $tool"; return }
  if (-not (Test-Path $path)) { Write-Warning "Config not found: $path"; return }

  $existing = Get-Content $path -Raw | ConvertFrom-Json
  $hasMCP = $existing.PSObject.Properties.Name -contains "mcpServers"

  if ($hasMCP) { Write-Host "[$tool] MCP ya configurado en $path" -ForegroundColor Green; return }

  $mcpBlock = @"
  "mcpServers": {
    "gentle-vanguard-skills": {
      "command": "node",
      "args": ["dist/scripts/mcp/skill-server.js"],
      "description": "143+ skills vía MCP: list_skills, get_skill, search_skills"
    },
    "engram": {
      "command": "engram",
      "args": ["mcp", "--tools=agent"],
      "description": "Memoria persistente Engram vía MCP"
    },
    "codegraph": {
      "command": "codegraph",
      "args": ["serve", "--mcp"],
      "description": "CodeGraph: análisis de código indexado"
    }
  }
"@
  $json = Get-Content $path -Raw
  $json = $json.TrimEnd() -replace "}$",",`n$mcpBlock`n}"
  Set-Content -Path $path -Value $json -NoNewline
  Write-Host "[$tool] MCP bridge configurado en $path" -ForegroundColor Green
}

function Test-SkillServer {
  $serverPath = "$ROOT/dist/scripts/mcp/skill-server.js"
  if (Test-Path $serverPath) {
    Write-Host "  skill-server.js: OK" -ForegroundColor Green
    return $true
  } else {
    Write-Host "  skill-server.js: NO COMPILADO (ejecute: pnpm build:mcp)" -ForegroundColor Yellow
    return $false
  }
}

switch ($Action) {
  "status" {
    $detected = Get-DetectedTool
    Write-Host "Tool detectado: $detected" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Estado MCP Bridge:" -ForegroundColor Cyan
    foreach ($t in @("cursor","windsurf","cline")) {
      $s = Test-MCPIntegration $t
      $icon = if ($s.skillServer) { "✅" } elseif ($s.configured) { "⚠️" } else { "❌" }
      Write-Host "  $icon $t — skills:$($s.skillServer) | config:$($s.configured)"
    }
    Write-Host "  ℹ️  opencode — skills nativas (no MCP)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Skill server:" -ForegroundColor Cyan
    Test-SkillServer
  }

  "setup" {
    $targets = if ($AllTools) { @("cursor","windsurf","cline") } elseif ($Tool) { @($Tool) } else { @((Get-DetectedTool)) }
    foreach ($t in $targets) { Invoke-MCPSetup $t }

    $orchestrator = Get-Content "$ROOT/config/orchestrator.json" -Raw | ConvertFrom-Json
    $profiles = $orchestrator.toolProfiles
    foreach ($t in $targets) {
      if ($profiles.$t) {
        $profiles.$t | Add-Member -NotePropertyName "mcpBridge" -NotePropertyValue "scripts/mcp-bridge/mcp-bridge.ps1" -Force
      }
    }
    $orchestrator | ConvertTo-Json -Depth 10 | Set-Content "$ROOT/config/orchestrator.json"
    Write-Host "orchestrator.json actualizado con mcpBridge" -ForegroundColor Green
  }

  "verify" {
    $allOk = $true
    $mcpTools = @("cursor","windsurf","cline")
    foreach ($t in $mcpTools) {
      $s = Test-MCPIntegration $t
      if (-not $s.skillServer) { $allOk = $false; Write-Host "  ❌ $t — MCP no configurado" -ForegroundColor Red }
      else { Write-Host "  ✅ $t — MCP configurado" -ForegroundColor Green }
    }
    # opencode uses native skill tools, not MCP — skip MCP check
    Write-Host "  ℹ️  opencode — usa skills nativas (no MCP)" -ForegroundColor Cyan
    if (-not (Test-SkillServer)) { $allOk = $false }
    if ($allOk) { Write-Host "Bridge status: OK" -ForegroundColor Green } else { Write-Host "Bridge status: INCOMPLETO" -ForegroundColor Yellow }
    return $allOk
  }

  "launch" {
    $serverPath = "$ROOT/dist/scripts/mcp/skill-server.js"
    if (-not (Test-Path $serverPath)) {
      Write-Host "Compilando skill server..." -ForegroundColor Yellow
      Push-Location $ROOT
      pnpm build:mcp 2>&1 | Out-Null
      Pop-Location
    }
    Write-Host "Lanzando MCP skill server..." -ForegroundColor Cyan
    & node $serverPath
  }
}
