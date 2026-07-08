param(
  [ValidateSet('register', 'unregister', 'list', 'start', 'stop', 'restart', 'health', 'reload', 'quickstart', 'list-templates', 'create')]
  [string]$Action = 'list',
  [string]$Name,
  [string]$Command,
  [string[]]$Args = @(),
  [string]$Description = '',
  [string]$Transport = 'stdio',
  [string]$Template,
  [string]$Path,
  [ValidateSet('ts', 'js', 'py', 'go', 'rs')]
  [string]$Lang = 'ts',
  [switch]$AutoStart,
  [switch]$Start,
  [switch]$Build,
  [switch]$Register,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$REGISTRY_PATH = Join-Path $ROOT 'config' 'mcp-registry.json'

# ─── helpers ─────────────────────────────────────────────────────────

function Read-Registry {
  if (-not (Test-Path $REGISTRY_PATH)) { return @{ version = '2.0.0'; description = 'MCP Native registry'; servers = @() } }
  return Get-Content $REGISTRY_PATH -Raw | ConvertFrom-Json
}

function Write-Registry($reg) {
  $reg | ConvertTo-Json -Depth 10 | Set-Content $REGISTRY_PATH -Encoding UTF8
}

function Get-ProcPath($name) {
  $lock = Join-Path $ROOT '.runtime' 'mcp' "$Name.pid"
  if (-not (Test-Path $lock)) { return $null }
  $pid = Get-Content $lock -Raw -ErrorAction SilentlyContinue
  if (-not $pid -or -not ($pid -match '^\d+$')) { return $null }
  $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
  if (-not $proc) { Remove-Item $lock -Force -ErrorAction SilentlyContinue; return $null }
  return $proc
}

# ─── actions ─────────────────────────────────────────────────────────

switch ($Action) {
  'register' {
    if (-not $Name) { Write-Host 'ERROR: -Name is required' -ForegroundColor Red; exit 1 }
    if (-not $Command) { Write-Host 'ERROR: -Command is required' -ForegroundColor Red; exit 1 }
    $reg = Read-Registry
    $existing = $reg.servers | Where-Object { $_.name -eq $Name }
    if ($existing) { Write-Host "ERROR: server '$Name' already registered" -ForegroundColor Red; exit 1 }
    $entry = @{
      name = $Name
      type = 'user'
      transport = $Transport
      command = $Command
      args = @($Args)
      enabled = $true
      autoStart = $AutoStart.IsPresent
      description = $Description
    }
    $reg.servers += $entry
    Write-Registry $reg
    if (-not $Quiet) { Write-Host "Registered MCP server: $Name" -ForegroundColor Green }
  }

  'unregister' {
    if (-not $Name) { Write-Host 'ERROR: -Name is required' -ForegroundColor Red; exit 1 }
    $reg = Read-Registry
    $before = $reg.servers.Count
    $reg.servers = $reg.servers | Where-Object { $_.name -ne $Name }
    if ($reg.servers.Count -eq $before) { Write-Host "ERROR: server '$Name' not found" -ForegroundColor Red; exit 1 }
    Write-Registry $reg
    if (-not $Quiet) { Write-Host "Unregistered MCP server: $Name" -ForegroundColor Green }
  }

  'list' {
    $reg = Read-Registry
    if ($reg.servers.Count -eq 0) { Write-Host 'No MCP servers registered.'; return }
    Write-Host "MCP Servers ($($reg.servers.Count) registered):" -ForegroundColor Cyan
    foreach ($s in $reg.servers) {
      $proc = Get-ProcPath $s.name
      $status = if ($proc) { 'RUNNING' } else { 'stopped' }
      $icon = if ($s.enabled) { '✅' } else { '⏸' }
      $type = if ($s.type -eq 'builtin') { '🔧' } else { '🧩' }
      Write-Host "  $icon $type $($s.name) [$status]" -ForegroundColor White
      Write-Host "       cmd: $($s.command) $($s.args -join ' ')" -ForegroundColor Gray
      Write-Host "       $($s.description)" -ForegroundColor Gray
    }
  }

  'health' {
    $reg = Read-Registry
    $allOk = $true
    foreach ($s in $reg.servers) {
      $proc = Get-ProcPath $s.name
      if ($proc) {
        Write-Host "  ✅ $($s.name) — PID $($proc.Id), running" -ForegroundColor Green
      } else {
        if ($s.autoStart) { Write-Host "  ❌ $($s.name) — NOT running (autoStart)" -ForegroundColor Red; $allOk = $false }
        else { Write-Host "  ⏸  $($s.name) — stopped (manual)" -ForegroundColor Yellow }
      }
    }
    if ($allOk) { if (-not $Quiet) { Write-Host 'All MCP servers healthy.' -ForegroundColor Green } }
    else { if (-not $Quiet) { Write-Host 'Some MCP servers need attention.' -ForegroundColor Yellow } }
  }

  'start' {
    if (-not $Name) { Write-Host 'ERROR: -Name is required' -ForegroundColor Red; exit 1 }
    $reg = Read-Registry
    $server = $reg.servers | Where-Object { $_.name -eq $Name }
    if (-not $server) { Write-Host "ERROR: server '$Name' not found" -ForegroundColor Red; exit 1 }
    $existing = Get-ProcPath $Name
    if ($existing) { Write-Host "Server '$Name' already running (PID $($existing.Id))" -ForegroundColor Yellow; return }
    $lockDir = Join-Path $ROOT '.runtime' 'mcp'
    if (-not (Test-Path $lockDir)) { New-Item -ItemType Directory -Path $lockDir -Force | Out-Null }
    $proc = Start-Process -FilePath $server.command -ArgumentList $server.args -WindowStyle Hidden -PassThru -NoNewWindow
    $proc | Select-Object -ExpandProperty Id | Set-Content (Join-Path $lockDir "$Name.pid") -Encoding UTF8
    if (-not $Quiet) { Write-Host "Started MCP server: $Name (PID $($proc.Id))" -ForegroundColor Green }
  }

  'stop' {
    if (-not $Name) { Write-Host 'ERROR: -Name is required' -ForegroundColor Red; exit 1 }
    $proc = Get-ProcPath $Name
    if (-not $proc) { Write-Host "Server '$Name' not running" -ForegroundColor Yellow; return }
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    $lock = Join-Path $ROOT '.runtime' 'mcp' "$Name.pid"
    Remove-Item $lock -Force -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host "Stopped MCP server: $Name" -ForegroundColor Green }
  }

  'restart' {
    if (-not $Name) { Write-Host 'ERROR: -Name is required' -ForegroundColor Red; exit 1 }
    & $PSCommandPath -Action stop -Name $Name -Quiet:$Quiet
    Start-Sleep -Milliseconds 500
    & $PSCommandPath -Action start -Name $Name -Quiet:$Quiet
  }

  'list-templates' {
    $templatesPath = Join-Path $ROOT 'config' 'mcp-templates.json'
    if (-not (Test-Path $templatesPath)) { Write-Host 'No templates found (config/mcp-templates.json missing).' -ForegroundColor Yellow; return }
    $tpl = Get-Content $templatesPath -Raw | ConvertFrom-Json
    Write-Host "MCP Templates ($($tpl.templates.Count) available):" -ForegroundColor Cyan
    foreach ($t in $tpl.templates) {
      Write-Host "  📦 $($t.name)" -ForegroundColor White
      Write-Host "       $($t.description)" -ForegroundColor Gray
      Write-Host "       cmd: $($t.command) $($t.args -join ' ')" -ForegroundColor Gray
    }
  }

  'quickstart' {
    if (-not $Template) { Write-Host 'ERROR: -Template is required. Use list-templates to see available.' -ForegroundColor Red; exit 1 }
    $templatesPath = Join-Path $ROOT 'config' 'mcp-templates.json'
    if (-not (Test-Path $templatesPath)) { Write-Host 'ERROR: config/mcp-templates.json not found' -ForegroundColor Red; exit 1 }
    $tpl = Get-Content $templatesPath -Raw | ConvertFrom-Json
    $tmpl = $tpl.templates | Where-Object { $_.name -eq $Template }
    if (-not $tmpl) { Write-Host "ERROR: template '$Template' not found" -ForegroundColor Red; exit 1 }
    $resolvedPath = if ($Path) { $Path } elseif ($tmpl.defaultPath) { $tmpl.defaultPath }
    $resolvedArgs = @($tmpl.args | ForEach-Object { $_ -replace '{path}', $resolvedPath })
    if ($resolvedPath -and $resolvedPath -ne '.') {
      $absPath = Join-Path $ROOT $resolvedPath
      $parent = Split-Path -Parent $absPath
      if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    }
    & $PSCommandPath -Action register -Name $tmpl.name -Command $tmpl.command -Args $resolvedArgs -Description $tmpl.description -Transport $tmpl.transport -AutoStart:$tmpl.autoStart -Quiet:$Quiet
    if ($Start -or $tmpl.autoStart) { & $PSCommandPath -Action start -Name $tmpl.name -Quiet:$Quiet }
    if (-not $Quiet) { Write-Host "Quickstart complete: $Template — registered and ready." -ForegroundColor Green }
  }

  'create' {
    if (-not $Name) { Write-Host 'ERROR: -Name is required' -ForegroundColor Red; exit 1 }
    $serverDir = Join-Path $ROOT 'mcp-servers' $Name
    if (Test-Path $serverDir) { Write-Host "ERROR: directory '$serverDir' already exists" -ForegroundColor Red; exit 1 }
    New-Item -ItemType Directory -Path $serverDir -Force | Out-Null
    $serverName = $Name

    switch ($Lang) {
      'ts' {
        @"
{
  "name": "$serverName",
  "version": "1.0.0",
  "description": "MCP server: $serverName",
  "main": "dist/index.js",
  "scripts": { "build": "tsc", "start": "node dist/index.js" },
  "dependencies": { "@modelcontextprotocol/sdk": "^1.0.0" },
  "devDependencies": { "typescript": "^5.5.0", "@types/node": "^20.0.0" }
}
"@ | Set-Content (Join-Path $serverDir 'package.json') -Encoding UTF8
        @"
{ "compilerOptions": { "target": "ES2022", "module": "NodeNext", "moduleResolution": "NodeNext", "outDir": "dist", "rootDir": "src", "strict": true, "declaration": true }, "include": ["src"] }
"@ | Set-Content (Join-Path $serverDir 'tsconfig.json') -Encoding UTF8
        $srcDir = Join-Path $serverDir 'src'
        New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
        @"
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

const server = new Server({ name: '$serverName', version: '1.0.0' }, { capabilities: { tools: {} } });

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [{ name: 'hello', description: 'A simple hello world tool', inputSchema: { type: 'object', properties: { name: { type: 'string' } }, required: ['name'] } }]
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  if (req.params.name === 'hello') {
    return { content: [{ type: 'text', text: `Hello, ${req.params.arguments?.name || 'world'}!` }] };
  }
  throw new Error('Tool not found');
});

const transport = new StdioServerTransport();
await server.connect(transport);
"@ | Set-Content (Join-Path $srcDir 'index.ts') -Encoding UTF8
        $buildCmd = 'npm install && npx tsc'
        $runCmd = "node dist/index.js"
        $entryPoint = "dist/index.js"
      }

      'js' {
        @"
{
  "name": "$serverName",
  "version": "1.0.0",
  "description": "MCP server: $serverName",
  "main": "index.js",
  "scripts": { "start": "node index.js" },
  "dependencies": { "@modelcontextprotocol/sdk": "^1.0.0" }
}
"@ | Set-Content (Join-Path $serverDir 'package.json') -Encoding UTF8
        @"
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

const server = new Server({ name: '$serverName', version: '1.0.0' }, { capabilities: { tools: {} } });

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [{ name: 'hello', description: 'A simple hello world tool', inputSchema: { type: 'object', properties: { name: { type: 'string' } }, required: ['name'] } }]
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  if (req.params.name === 'hello') {
    return { content: [{ type: 'text', text: 'Hello, ' + (req.params.arguments?.name || 'world') + '!' }] };
  }
  throw new Error('Tool not found');
});

const transport = new StdioServerTransport();
await server.connect(transport);
"@ | Set-Content (Join-Path $serverDir 'index.js') -Encoding UTF8
        $buildCmd = 'npm install'
        $runCmd = "node index.js"
        $entryPoint = "index.js"
      }

      'py' {
        @"
[build-system]
requires = ["setuptools>=68.0"]
build-backend = "setuptools.backends._legacy:_Backend"

[project]
name = "$serverName"
version = "1.0.0"
description = "MCP server: $serverName"
requires-python = ">=3.10"
dependencies = ["mcp>=1.0.0"]
"@ | Set-Content (Join-Path $serverDir 'pyproject.toml') -Encoding UTF8
        @"
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types

server = Server("$serverName")

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    return [types.Tool(name="hello", description="A simple hello world tool", inputSchema={"type": "object", "properties": {"name": {"type": "string"}}, "required": ["name"]})]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    if name == "hello":
        return [types.TextContent(type="text", text=f"Hello, {arguments.get('name', 'world')}!")]
    raise ValueError(f"Unknown tool: {name}")

async def main():
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, InitializationOptions(server_name="$serverName", server_version="1.0.0"))

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
"@ | Set-Content (Join-Path $serverDir 'server.py') -Encoding UTF8
        $buildCmd = 'pip install -e . 2>$null'
        $runCmd = "python server.py"
        $entryPoint = "server.py"
      }

      'go' {
        @"
module $serverName

go 1.21

require github.com/mark3labs/mcp-go v1.0.0
"@ | Set-Content (Join-Path $serverDir 'go.mod') -Encoding UTF8
        @"
package main

import (
	"context"
	"fmt"
	mcp "github.com/mark3labs/mcp-go/server"
)

func main() {
	s := mcp.NewServer(mcp.WithServerInfo("$serverName", "1.0.0"))

	s.AddTool(mcp.NewTool("hello",
		mcp.WithDescription("A simple hello world tool"),
		mcp.WithString("name", mcp.Required(), mcp.Description("Your name")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		name, _ := req.Params.Arguments["name"].(string)
		if name == "" { name = "world" }
		return mcp.NewTextResult(fmt.Sprintf("Hello, %s!", name)), nil
	})

	if err := mcp.ServeStdio(s); err != nil {
		panic(err)
	}
}
"@ | Set-Content (Join-Path $serverDir 'main.go') -Encoding UTF8
        $buildCmd = 'go mod tidy && go build -o bin/server .'
        $runCmd = "./bin/server"
        $entryPoint = "bin/server"
      }

      'rs' {
        @"
[package]
name = "$serverName"
version = "1.0.0"
edition = "2021"

[dependencies]
rmcp = "0.1"
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
"@ | Set-Content (Join-Path $serverDir 'Cargo.toml') -Encoding UTF8
        $rsSrcDir = Join-Path $serverDir 'src'
        New-Item -ItemType Directory -Path $rsSrcDir -Force | Out-Null
        @"
use rmcp::{ServiceExt, model::*, service::Service};
use serde_json::json;
use tokio::io::{stdin, stdout};

#[derive(Debug, serde::Deserialize)]
struct HelloArgs { name: Option<String> }

#[derive(Debug)]
struct MyServer;

impl Service for MyServer {
    fn list_tools(&self) -> Vec<Tool> {
        vec![Tool {
            name: "hello".into(),
            description: Some("A simple hello world tool".into()),
            input_schema: Some(json!({
                "type": "object",
                "properties": { "name": { "type": "string" } },
                "required": ["name"]
            })),
        }]
    }

    fn call_tool(&self, tool_name: &str, args: serde_json::Value) -> Result<CallToolResult, CallToolError> {
        if tool_name == "hello" {
            let name = serde_json::from_value::<HelloArgs>(args)
                .ok()
                .and_then(|a| a.name)
                .unwrap_or_else(|| "world".into());
            return Ok(CallToolResult { content: vec![Content::Text(TextContent { text: format!("Hello, {name}!") })], is_error: false });
        }
        Err(CallToolError::unknown_tool(tool_name))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let service = MyServer;
    service.serve(StdioTransport::new(stdin(), stdout())).await?;
    Ok(())
}
"@ | Set-Content (Join-Path $rsSrcDir 'main.rs') -Encoding UTF8
        $buildCmd = 'cargo build'
        $runCmd = "./target/debug/$serverName"
        $entryPoint = "target/debug/$serverName"
      }
    }

    Write-Host "MCP server scaffolded at: mcp-servers/$Name ($Lang)" -ForegroundColor Cyan

    if ($Build) {
      Write-Host "  Building ($Lang)..." -ForegroundColor Yellow
      Push-Location $serverDir
      Invoke-Expression $buildCmd
      Pop-Location
      if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: build failed for $Name" -ForegroundColor Red; exit 1 }
      Write-Host "  Build complete." -ForegroundColor Green
    }

    if ($Register -or $Build.IsPresent -or $Start) {
      $regCmd = "node"
      $regArgs = @("mcp-servers/$Name/$entryPoint")
      if ($Lang -eq 'py') { $regCmd = "python"; $regArgs = @("mcp-servers/$Name/$entryPoint") }
      if ($Lang -eq 'go' -or $Lang -eq 'rs') { $regCmd = "mcp-servers/$Name/$entryPoint"; $regArgs = @() }
      & $PSCommandPath -Action register -Name $Name -Command $regCmd -Args $regArgs -Description "MCP server: $Name" -Transport stdio -AutoStart:$Start.IsPresent -Quiet:$Quiet
      if ($Start) { & $PSCommandPath -Action start -Name $Name -Quiet:$Quiet }
    }

    Write-Host "  cd mcp-servers/$Name" -ForegroundColor Gray
    Write-Host "  Build: $buildCmd" -ForegroundColor Gray
    Write-Host "  Run:   $runCmd" -ForegroundColor Gray
    if (-not $Quiet) { Write-Host "MCP server created: $Name ($Lang)" -ForegroundColor Green }
  }

  'reload' {
    if (-not $Quiet) { Write-Host 'Reloading MCP registry from disk...' -ForegroundColor Cyan }
    $reg = Read-Registry
    foreach ($s in $reg.servers) {
      $proc = Get-ProcPath $s.name
      if ($s.enabled -and $s.autoStart -and -not $proc) {
        & $PSCommandPath -Action start -Name $s.name -Quiet
      } elseif (-not $s.enabled -and $proc) {
        & $PSCommandPath -Action stop -Name $s.name -Quiet
      }
    }
    if (-not $Quiet) { Write-Host 'MCP registry reloaded.' -ForegroundColor Green }
  }
}
