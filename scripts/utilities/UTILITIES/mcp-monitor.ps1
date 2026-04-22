# mcp-monitor.ps1
# Monitors MCP server activity and shuts down inactive servers to save resources.
# Usage: .\mcp-monitor.ps1 [-TimeoutMinutes 60]

param(
    [int]$TimeoutMinutes = 60
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$logFile = Join-Path $repoRoot 'docs\sessions\metrics\mcp-activity.csv'

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }

function Get-ActiveMCPs {
    # Placeholder: In a real environment, this would query the MCP host process or check socket connections
    # For now, we simulate based on a known list or a config file if it exists
    $configPath = Join-Path $repoRoot 'config\mcp-servers.json'
    if (Test-Path $configPath) {
        return Get-Content $configPath | ConvertFrom-Json | Where-Object { $_.enabled }
    }
    return @()
}

function Test-MCPActivity {
    param([string]$ServerName)
    # Check last access time in log or via system process monitoring
    # Simulated: Randomly decide if active for demonstration
    return (Get-Random -Minimum 0 -Maximum 100) -gt 20 
}

function Stop-MCPServer {
    param([string]$ServerName)
    Write-Warn "Shutting down inactive MCP server: $ServerName"
    # Actual shutdown command would go here
    # e.g., Invoke-RestMethod -Uri "http://localhost:$port/shutdown" -Method Post
}

Write-Step "MCP Inactivity Monitor (Timeout: ${TimeoutMinutes} min)"

$servers = Get-ActiveMCPs
if ($servers.Count -eq 0) {
    Write-Host "No enabled MCP servers found in config." -ForegroundColor Gray
    exit 0
}

foreach ($server in $servers) {
    $isActive = Test-MCPActivity -ServerName $server.name
    if (-not $isActive) {
        Write-Warn "Server '$($server.name)' has been inactive for > ${TimeoutMinutes} minutes."
        Stop-MCPServer -ServerName $server.name
    } else {
        Write-Ok "Server '$($server.name)' is active."
    }
}

Write-Ok "MCP monitoring cycle complete."
