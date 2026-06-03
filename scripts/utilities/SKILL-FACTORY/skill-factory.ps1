#!/usr/bin/env pwsh
# skill-factory.ps1
# Skill Factory runtime — scaffolding automatizado de nuevos skills
# Version: 1.0.0
<#
.SYNOPSIS
  Crea un nuevo skill con estructura completa, frontmatter YAML, y registro opcional.

.DESCRIPTION
  Scaffolding completo para nuevos skills:
  1. Crea skills/<name>/ con SKILL.md y referencias
  2. Registra en config/auto-delegation.json
  3. Actualiza .atl/skill-registry.md
  4. Compila el MCP server para exponerlo

.PARAMETER Name
  Nombre del skill (e.g., "my-awesome-skill")
.PARAMETER Description
  Descripción corta para el frontmatter y triggers
.PARAMETER Agent
  Agente destino (DEV, QA, GOV, DOC, OPS, etc). Default: DEV
.PARAMETER Triggers
  Palabras clave separadas por coma para activación
.PARAMETER Register
  Registra en auto-delegation.json y skill-registry
.PARAMETER DryRun
  Muestra lo que haría sin ejecutar
.EXAMPLE
  ./skill-factory.ps1 -Name "rust-backend-skill" -Description "Rust backend with Axum" -Agent DEV -Triggers "rust,axum,backend"
#>

param(
  [Parameter(Mandatory)][string]$Name,
  [Parameter(Mandatory)][string]$Description,
  [string]$Agent = "DEV - Code",
  [string]$Triggers = $Name.Replace("-skill","").Replace("-"," "),
  [switch]$Register,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR }
  else { Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) }
$skillPath = Join-Path $repoRoot "skills" $Name
$skillMdPath = Join-Path $skillPath "SKILL.md"
$autoDelPath = Join-Path $repoRoot "config" "auto-delegation.json"
$registryPath = Join-Path $repoRoot ".atl" "skill-registry.md"

# Validar nombre
if ($Name -notmatch '^[a-z0-9][a-z0-9_-]+$') { Write-Host "[ERROR] Name must be lowercase alphanumeric with hyphens/underscores" -ForegroundColor Red; exit 1 }
if ((Test-Path $skillPath) -and -not $DryRun) { Write-Host "[ERROR] Skill already exists: $skillPath" -ForegroundColor Red; exit 1 }

# Detectar agente corto
$agentShort = $Agent -replace " - .*$", ""
$agentFull = $Agent

Write-Host "[SKILL] Creating skill: $Name" -ForegroundColor Cyan
Write-Host "[SKILL] Agent: $agentFull | Triggers: $Triggers" -ForegroundColor White

if ($DryRun) {
  Write-Host "[DRY-RUN] Would create: $skillMdPath" -ForegroundColor Yellow
  if ($Register) { Write-Host "[DRY-RUN] Would register in: $autoDelPath" -ForegroundColor Yellow }
  return
}

# Crear directorio
$null = New-Item -ItemType Directory -Path $skillPath -Force
$null = New-Item -ItemType Directory -Path (Join-Path $skillPath "references") -Force

# Generar SKILL.md
$skillContent = @"
---
name: $Name
description: >
  $Description
trigger: "$Triggers"
---

# $Name

## When to Use

- $Description

## Guidelines

- Follow project conventions
- Keep instructions clear and concise
- Reference existing patterns in the codebase

## References

- [Detail](references/detail.md)
"@

$skillContent | Out-File $skillMdPath -Encoding utf8
Write-Host "[SKILL] Created: $skillMdPath" -ForegroundColor Green

# Detail
$detailContent = "# $Name -- Detail

## Overview

$Description

## Examples

\`\`\`
# Example usage
\`\`\`

## Edge Cases

- TBD
"
$detailContent | Out-File (Join-Path $skillPath "references" "detail.md") -Encoding utf8
Write-Host "[SKILL] Created: references/detail.md" -ForegroundColor DarkCyan

# Registrar en auto-delegation.json
if ($Register) {
  if (Test-Path $autoDelPath) {
    try {
      $config = Get-Content $autoDelPath -Raw | ConvertFrom-Json
      if ($config.keywordMappings) {
        $existing = $config.keywordMappings.PSObject.Properties | Where-Object { $_.Name -eq $Name }
        if (-not $existing) {
          $newMapping = @{
            agent = $agentShort
            skill = $Name
            triggers = ($Triggers -split ",").Trim()
          }
          $config.keywordMappings | Add-Member -NotePropertyName $Name -NotePropertyValue $newMapping
          $config | ConvertTo-Json -Depth 10 | Out-File $autoDelPath -Encoding utf8
          Write-Host "[SKILL] Registered in auto-delegation.json" -ForegroundColor Green
        } else { Write-Host "[SKILL] Already in auto-delegation.json" -ForegroundColor Yellow }
      }
    } catch { Write-Host "[WARN] Could not update auto-delegation.json: $_" -ForegroundColor Yellow }
  }

  # Append to registry
  $triggerList = ($Triggers -split ",").Trim() -join ", "
  $registryLine = "| $agentFull | $Name | $triggerList |"
  Add-Content -Path $registryPath -Value $registryLine -Encoding utf8
  Write-Host "[SKILL] Appended to skill-registry.md" -ForegroundColor Green
}

# Re-compilar MCP server
Write-Host "[SKILL] Rebuilding MCP server..." -ForegroundColor Cyan
try {
  Push-Location $repoRoot
  & "pnpm" build:mcp 2>&1 | Out-Null
  Pop-Location
  Write-Host "[SKILL] MCP server rebuilt" -ForegroundColor Green
} catch { Write-Host "[WARN] MCP rebuild failed: $_" -ForegroundColor Yellow }

Write-Host "[SKILL] Done! New skill: $Name (agent: $agentFull)" -ForegroundColor Cyan
Write-Host "  Edit: $skillMdPath" -ForegroundColor Gray
