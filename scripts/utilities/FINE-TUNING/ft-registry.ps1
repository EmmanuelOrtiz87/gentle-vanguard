param(
    [ValidateSet("list","get","register","unregister","status")]
    [string]$Action = "list",
    [string]$Domain = "",
    [string]$AdapterPath = "",
    [string]$ModelName = "",
    [string]$Description = "",
    [string]$Version = "1.0.0",
    [string]$RegistryPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot
if (-not $RegistryPath) { $RegistryPath = Join-Path $ProjectRoot ".ft" "registry.json" }

function Get-Registry {
    if (Test-Path $RegistryPath) {
        try { return Get-Content $RegistryPath -Raw | ConvertFrom-Json }
        catch { return @{ adapters = @(); updated = "" } }
    }
    return @{ adapters = @(); updated = "" }
}

function Save-Registry {
    param($Registry)
    $Registry.updated = (Get-Date -Format "o")
    $Registry | ConvertTo-Json -Depth 3 | Out-File $RegistryPath -Encoding utf8
}

switch ($Action) {
    "list" {
        $reg = Get-Registry
        if ($reg.adapters.Count -eq 0) {
            Write-Host "[FT-REG] No adapters registered" -ForegroundColor Yellow
            return
        }
        Write-Host "=== FT Adapter Registry ===" -ForegroundColor Cyan
        Write-Host "Updated: $($reg.updated)" -ForegroundColor Gray
        $reg.adapters | ForEach-Object {
            $status = if ($_.active -eq $true) { "ACTIVE" } else { "INACTIVE" }
            Write-Host "  $($_.domain): $($_.model) v$($_.version) [$status]" -ForegroundColor $(if($_.active){'Green'}else{'Gray'})
            Write-Host "      Path: $($_.path)"
            Write-Host "      Trained: $($_.trainedAt)"
            Write-Host "      Metrics: acc=$($_.metrics.accuracy)% loss=$($_.metrics.loss)"
            Write-Host ""
        }
    }

    "get" {
        if (-not $Domain) { Write-Error "Domain required for get action"; return }
        $reg = Get-Registry
        $adapter = $reg.adapters | Where-Object { $_.domain -eq $Domain } | Select-Object -First 1
        if (-not $adapter) { Write-Host "[FT-REG] No adapter for domain '$Domain'" -ForegroundColor Yellow; return }
        $adapter | ConvertTo-Json -Depth 3
    }

    "register" {
        if (-not $Domain -or -not $AdapterPath) { Write-Error "Domain and AdapterPath required"; return }
        if (-not $ModelName) { $ModelName = "mistral-7b-lora" }
        $reg = Get-Registry
        $existing = $reg.adapters | Where-Object { $_.domain -eq $Domain } | Select-Object -First 1
        $entry = @{
            domain = $Domain
            model = $ModelName
            version = $Version
            path = $AdapterPath
            description = $Description
            active = $true
            trainedAt = (Get-Date -Format "o")
            metrics = @{ accuracy = 0; loss = 1.0; evalDate = "" }
        }
        if ($existing) {
            $reg.adapters = @($reg.adapters | Where-Object { $_.domain -ne $Domain }) + $entry
            Write-Host "[FT-REG] Updated adapter for $Domain" -ForegroundColor Green
        } else {
            $reg.adapters += $entry
            Write-Host "[FT-REG] Registered new adapter for $Domain" -ForegroundColor Green
        }
        Save-Registry $reg
    }

    "unregister" {
        if (-not $Domain) { Write-Error "Domain required"; return }
        $reg = Get-Registry
        $before = $reg.adapters.Count
        $reg.adapters = @($reg.adapters | Where-Object { $_.domain -ne $Domain })
        if ($reg.adapters.Count -lt $before) {
            Save-Registry $reg
            Write-Host "[FT-REG] Removed adapter for $Domain" -ForegroundColor Yellow
        } else {
            Write-Host "[FT-REG] No adapter found for $Domain" -ForegroundColor Yellow
        }
    }

    "status" {
        $reg = Get-Registry
        $total = $reg.adapters.Count
        $active = @($reg.adapters | Where-Object { $_.active }).Count
        Write-Host "=== FT Registry Status ===" -ForegroundColor Cyan
        Write-Host "  Total adapters: $total"
        Write-Host "  Active: $active"
        Write-Host "  Inactive: $($total - $active)"
        Write-Host "  Registry file: $RegistryPath"
        if ($total -gt 0) {
            Write-Host "  Domains:" -ForegroundColor Gray
            $reg.adapters | ForEach-Object { Write-Host "    $($_.domain): $($_.model) $(if($_.active){'[ACTIVE]'}else{'[INACTIVE]'})" }
        }
    }
}
