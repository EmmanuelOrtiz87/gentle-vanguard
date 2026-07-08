<#
.SYNOPSIS
  Org Registry — manage known organizations and their trust status.
.DESCRIPTION
  Stores org identity, trust anchors, approved capabilities, and last handshake.
  Provides discovery via seed file and status reporting.
.PARAMETER Action
  register  — add/update an org in the local registry (default)
  discover  — find orgs via seed or broadcast
  status    — show all known orgs and their health
  untrust   — remove an org and invalidate its trust
.PARAMETER OrgId
  Org ID to register/untrust.
.PARAMETER PublicKey
  Org's public key (PEM format) for verification.
.PARAMETER ApprovedCapabilities
  Comma-separated list of capabilities to approve for this org.
.PARAMETER SeedPath
  Path to seed file for discovery.
.EXAMPLE
  .\org-registry.ps1 -Action register -OrgId "acme-corp" -PublicKey "-----BEGIN..."
  .\org-registry.ps1 -Action discover
  .\org-registry.ps1 -Action untrust -OrgId "acme-corp"
#>

param(
  [ValidateSet("register", "discover", "status", "untrust")]
  [string]$Action = "status",
  [string]$OrgId = "",
  [string]$PublicKey = "",
  [string]$ApprovedCapabilities = "",
  [string]$SeedPath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$configPath = Join-Path $repoRoot "config\federation-config.json"
$config = if (Test-Path $configPath) { Get-Content $configPath -Raw | ConvertFrom-Json } else { $null }

$federationDir = Join-Path $repoRoot ".session\federation"
$null = New-Item -ItemType Directory -Path $federationDir -Force

$registryPath = Join-Path $federationDir "org-registry.json"

function Get-Registry {
  if (Test-Path $registryPath) {
    try { return Get-Content $registryPath -Raw | ConvertFrom-Json } catch {}
  }
  return @{ localOrg = if ($config) { @{ id = $config.localOrg.id; displayName = $config.localOrg.displayName } } else { @{ id = "unknown" } }; knownOrgs = @() }
}

function Save-Registry {
  param($Registry)
  $Registry | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding utf8
}

switch ($Action) {
  "register" {
    if (-not $OrgId) { Write-Error "Provide -OrgId"; exit 1 }

    $registry = Get-Registry
    $caps = if ($ApprovedCapabilities) { $ApprovedCapabilities -split ',' | ForEach-Object { $_.Trim() } } else { @() }

    $existing = $registry.knownOrgs | Where-Object { $_.id -eq $OrgId }
    if ($existing) {
      $existing.publicKey = if ($PublicKey) { $PublicKey } else { $existing.publicKey }
      $existing.lastUpdated = Get-Date -Format "o"
      $existing.approvedCapabilities = $caps
      Write-Host "[ORG-REG] Updated org: $OrgId" -ForegroundColor Yellow
    } else {
      $newOrg = @{
        id = $OrgId
        trusted = $false
        publicKey = $PublicKey
        approvedCapabilities = $caps
        firstSeen = Get-Date -Format "o"
        lastHandshake = $null
        workspaces = @()
      }
      $registry.knownOrgs += $newOrg
      Write-Host "[ORG-REG] Registered new org: $OrgId" -ForegroundColor Green
    }

    Save-Registry -Registry $registry
    return $registry
  }

  "discover" {
    $seedFile = if ($SeedPath) { $SeedPath } elseif ($config) { Join-Path $repoRoot $config.discovery.seedFile } else { Join-Path $federationDir "seeds.json" }

    if (-not (Test-Path $seedFile)) {
      $null = New-Item -ItemType Directory -Path (Split-Path -Parent $seedFile) -Force
      Set-Content $seedFile '{"seeds":[]}' -Encoding utf8
    }

    $seeds = Get-Content $seedFile -Raw | ConvertFrom-Json
    $discovered = @()
    $registry = Get-Registry

    foreach ($seed in $seeds.seeds) {
      if (-not ($registry.knownOrgs | Where-Object { $_.id -eq $seed.orgId })) {
        $discoveredOrg = @{
          id = $seed.orgId
          fromSeed = $seedFile
          discoveryTime = Get-Date -Format "o"
        }
        $discovered += $discoveredOrg
        Write-Host "[ORG-REG] Discovered: $($seed.orgId) from seed" -ForegroundColor Cyan
      }
    }

    $knownCount = $registry.knownOrgs.Count
    Write-Host "[ORG-REG] Discovery complete — $($discovered.Count) new, $knownCount known" -ForegroundColor Green
    return @{ discovered = $discovered; knownOrgs = $registry.knownOrgs }
  }

  "status" {
    $registry = Get-Registry
    Write-Host "[ORG-REG] Federation status:" -ForegroundColor Cyan
    Write-Host "  Local org: $($registry.localOrg.id)" -ForegroundColor White
    Write-Host "  Known orgs: $($registry.knownOrgs.Count)" -ForegroundColor Gray

    foreach ($org in $registry.knownOrgs) {
      $trustColor = if ($org.trusted) { "Green" } else { "Yellow" }
      $handshakeStr = if ($org.lastHandshake) { $org.lastHandshake } else { "never" }
      Write-Host "  [$($org.id)] trusted=$($org.trusted) last=$handshakeStr caps=$($org.approvedCapabilities.Count)" -ForegroundColor $trustColor
    }
    return $registry
  }

  "untrust" {
    if (-not $OrgId) { Write-Error "Provide -OrgId"; exit 1 }
    $registry = Get-Registry
    $registry.knownOrgs = $registry.knownOrgs | Where-Object { $_.id -ne $OrgId }
    Save-Registry -Registry $registry
    Write-Host "[ORG-REG] Removed org: $OrgId" -ForegroundColor Red
    return $registry
  }
}
