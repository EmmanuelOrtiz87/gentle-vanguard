<#
.SYNOPSIS
  Tenant context resolution and routing for multi-tenant Gentle-Vanguard.

.DESCRIPTION
  Resolves the current tenant ID from environment variable, workspace path, or
  tenant-config.json. Provides path mapping so all .session/, .codegraph/, .telemetry/
  directories are automatically scoped per tenant.

  Single-tenant mode (default): no GENTLE_TENANT_ID set → backward compatible.
  Multi-tenant mode: GENTLE_TENANT_ID or detected from workspace → all paths scoped.

.PARAMETER Action
  get    — returns current tenant context (default)
  set    — sets GENTLE_TENANT_ID for current session
  list   — lists all known tenants from tenant-registry.json
  validate — checks tenant isolation boundaries

.PARAMETER TenantId
  Tenant ID to set (used with -Action set).

.EXAMPLE
  .\tenant-context.ps1 -Action get
  Returns: @{ TenantId = "my-project"; RootDir = "..."; IsMultiTenant = $true }

.EXAMPLE
  .\tenant-context.ps1 -Action set -TenantId "project-alpha"

.NOTES
  Part of Gentle-Vanguard v5.1 multi-tenant isolation.
#>

param(
  [ValidateSet("get", "set", "list", "validate")]
  [string]$Action = "get",
  [string]$TenantId = ""
)

$ErrorActionPreference = "Stop"

# Resolve repo root (same pattern as session-start-optimized.ps1)
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) {
  $env:GENTLE_VANGUARD_BASE_DIR
} else {
  $root = Split-Path -Parent $PSScriptRoot
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) {
    $root = Split-Path -Parent $root
  }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$tenantRegistryPath = Join-Path $repoRoot "config\tenant-registry.json"
$sessionRoot = Join-Path $repoRoot ".session"
$codegraphRoot = Join-Path $repoRoot ".codegraph"
$telemetryRoot = Join-Path $repoRoot ".telemetry"
$runtimeRoot = Join-Path $repoRoot ".runtime"

function Get-TenantId {
  <#
  .SYNOPSIS
    Resolve tenant ID from environment variable, workspace folder, or registry.
    Returns empty string for single-tenant mode.
  #>
  # 1. Env var takes precedence
  if ($env:GENTLE_TENANT_ID) {
    return $env:GENTLE_TENANT_ID
  }
  # 2. Check for tenant-config.json in repo root
  $tenantConfigPath = Join-Path $repoRoot "tenant-config.json"
  if (Test-Path $tenantConfigPath) {
    try {
      $config = Get-Content $tenantConfigPath -Raw | ConvertFrom-Json
      if ($config.tenantId) {
        return $config.tenantId
      }
    } catch {
      # ignore invalid config
    }
  }
  # 3. Detect from workspace folder name (if not the default repo name)
  $workspaceName = Split-Path -Leaf $repoRoot
  if ($workspaceName -and $workspaceName -ne "gentle-vanguard") {
    return $workspaceName
  }
  # 4. Single-tenant mode
  return ""
}

function Get-TenantContext {
  <#
  .SYNOPSIS
    Returns structured tenant context with mapped paths.
  #>
  $tenantId = Get-TenantId
  $isMultiTenant = [string]::IsNullOrEmpty($tenantId) -eq $false

  $context = @{
    TenantId = $tenantId
    IsMultiTenant = $isMultiTenant
    RepoRoot = $repoRoot
  }

  if ($isMultiTenant) {
    $context.SessionDir = Join-Path $sessionRoot $tenantId
    $context.CodeGraphDir = Join-Path $codegraphRoot $tenantId
    $context.TelemetryDir = Join-Path $telemetryRoot $tenantId
    $context.RuntimeDir = Join-Path $runtimeRoot $tenantId
    $context.AuditDir = Join-Path (Join-Path $sessionRoot $tenantId) "audit"
    $context.EvalDir = Join-Path (Join-Path $sessionRoot $tenantId) "eval"
  } else {
    $context.SessionDir = $sessionRoot
    $context.CodeGraphDir = $codegraphRoot
    $context.TelemetryDir = $telemetryRoot
    $context.RuntimeDir = $runtimeRoot
    $context.AuditDir = Join-Path $sessionRoot "audit"
    $context.EvalDir = Join-Path $sessionRoot "eval"
  }

  # Ensure directories exist
  $dirsToCreate = @($context.SessionDir, $context.AuditDir)
  if ($isMultiTenant) {
    $dirsToCreate += $context.CodeGraphDir
    $dirsToCreate += $context.EvalDir
  }
  foreach ($dir in $dirsToCreate) {
    if (-not (Test-Path $dir)) {
      $null = New-Item -ItemType Directory -Path $dir -Force
    }
  }

  return $context
}

function Set-TenantContext {
  param([string]$TenantId)
  if ([string]::IsNullOrEmpty($TenantId)) {
    Write-Warn "Tenant ID cannot be empty"
    return
  }
  $env:GENTLE_TENANT_ID = $TenantId
  Write-Host "[TENANT] Tenant set to: $TenantId" -ForegroundColor Green
}

function Get-TenantRegistry {
  if (Test-Path $tenantRegistryPath) {
    return Get-Content $tenantRegistryPath -Raw | ConvertFrom-Json
  }
  return @{ tenants = @() }
}

function Invoke-TenantIsolationValidation {
  <#
  .SYNOPSIS
    Validates that tenant directories are properly isolated.
  #>
  $errors = @()
  $ctx = Get-TenantContext

  # Check that session dir exists
  if (-not (Test-Path $ctx.SessionDir)) {
    $errors += "Session dir missing: $($ctx.SessionDir)"
  }

  # In multi-tenant mode, verify we don't have cross-tenant data
  if ($ctx.IsMultiTenant) {
    $parentSession = Split-Path -Parent $ctx.SessionDir
    if (Test-Path $parentSession) {
      $otherTenants = Get-ChildItem -Directory $parentSession | Where-Object {
        $_.Name -ne $ctx.TenantId
      }
      foreach ($other in $otherTenants) {
        Write-Warn "[TENANT] Cross-tenant data detected: $($other.FullName)"
      }
    }
  }

  if ($errors.Count -eq 0) {
    Write-Host "[TENANT] Isolation validation PASS" -ForegroundColor Green
  } else {
    Write-Host "[TENANT] Isolation validation FAIL" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host "  - $e" -ForegroundColor Red }
  }

  return @{ pass = ($errors.Count -eq 0); errors = $errors; context = $ctx }
}

# ---- Main dispatch ----

switch ($Action) {
  "get" {
    $ctx = Get-TenantContext
    if ($ctx.IsMultiTenant) {
      Write-Host "[TENANT] Current tenant: $($ctx.TenantId)" -ForegroundColor Cyan
    } else {
      Write-Host "[TENANT] Single-tenant mode" -ForegroundColor Gray
    }
    return $ctx | ConvertTo-Json -Compress
  }
  "set" {
    if ([string]::IsNullOrEmpty($TenantId)) {
      Write-Error "TenantId required for set action"
      exit 1
    }
    Set-TenantContext -TenantId $TenantId
  }
  "list" {
    $reg = Get-TenantRegistry
    Write-Host "[TENANT] Known tenants:" -ForegroundColor Cyan
    foreach ($t in $reg.tenants) {
      Write-Host "  - $($t.id) (last active: $($t.lastActive))" -ForegroundColor Gray
    }
  }
  "validate" {
    $null = Invoke-TenantIsolationValidation
  }
}
