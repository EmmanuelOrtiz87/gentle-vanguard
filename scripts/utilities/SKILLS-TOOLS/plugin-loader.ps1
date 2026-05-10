# plugin-loader.ps1
# Plugin loading and execution engine for Foundation FF-011
# Usage: . .\scripts\utilities\SKILLS-TOOLS\plugin-loader.ps1

$script:PluginRegistry = @{}

function Get-PluginManifest {
    param([string]$PluginPath)

    $manifestFile = Join-Path $PluginPath 'plugin.json'
    if (-not (Test-Path $manifestFile)) { return $null }

    try {
        return Get-Content $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to parse plugin manifest: $manifestFile — $_"
        return $null
    }
}

function Get-PluginMetadata {
    param([PSCustomObject]$Manifest)

    if (-not $Manifest) { return $null }

    return @{
        name                 = $Manifest.name
        version              = $Manifest.version
        author               = $Manifest.author
        description          = $Manifest.description
        minFoundationVersion = if ($Manifest.minFoundationVersion) { $Manifest.minFoundationVersion } else { '2.6.0' }
        provides             = if ($Manifest.provides) { @($Manifest.provides) } else { @() }
        requires             = if ($Manifest.requires) { @($Manifest.requires) } else { @() }
        hooks                = if ($Manifest.hooks) { @($Manifest.hooks) } else { @() }
        commands             = if ($Manifest.commands) { @($Manifest.commands) } else { @() }
    }
}

function Invoke-Plugin {
    param(
        [Parameter(Mandatory)]
        [string]$PluginName,

        [Parameter(Mandatory)]
        [string]$Command,

        [hashtable]$Parameters = @{},

        [switch]$Quiet
    )

    if (-not $script:PluginRegistry.ContainsKey($PluginName)) {
        $err = "Plugin not registered: $PluginName. Run Initialize-Plugins first."
        if (-not $Quiet) { Write-Error $err }
        return @{ success = $false; result = $null; message = $err }
    }

    $entry = $script:PluginRegistry[$PluginName]
    $manifest = $entry.manifest
    $pluginDir = $entry.path

    $cmdEntry = @($manifest.commands | Where-Object {
        if ($_ -is [PSCustomObject]) { $_.name -eq $Command } else { $_ -eq $Command }
    })

    if ($cmdEntry.Count -eq 0) {
        $available = @($manifest.commands | ForEach-Object {
            if ($_ -is [PSCustomObject]) { $_.name } else { $_ }
        }) -join ', '
        $err = "Command '$Command' not found in plugin '$PluginName'. Available: $available"
        if (-not $Quiet) { Write-Error $err }
        return @{ success = $false; result = $null; message = $err }
    }

    $scriptFile = if ($cmdEntry[0] -is [PSCustomObject] -and $cmdEntry[0].script) {
        Join-Path $pluginDir $cmdEntry[0].script
    } elseif ($manifest.main) {
        Join-Path $pluginDir $manifest.main
    } else {
        Join-Path $pluginDir 'plugin.ps1'
    }

    if (-not (Test-Path $scriptFile)) {
        $err = "Plugin script not found: $scriptFile"
        if (-not $Quiet) { Write-Error $err }
        return @{ success = $false; result = $null; message = $err }
    }

    try {
        $result = & $scriptFile @Parameters
        return @{ success = $true; result = $result; message = "OK" }
    } catch {
        $err = "Plugin execution failed: $_"
        if (-not $Quiet) { Write-Error $err }
        return @{ success = $false; result = $null; message = $err }
    }
}

function Register-Plugin {
    param(
        [string]$PluginPath,
        [PSCustomObject]$Manifest,
        [switch]$Quiet
    )

    $name = $Manifest.name

    if ($script:PluginRegistry.ContainsKey($name)) {
        if (-not $Quiet) { Write-Warning "Plugin '$name' already registered, overwriting" }
    }

    $script:PluginRegistry[$name] = @{
        path     = $PluginPath
        manifest = $Manifest
        metadata = Get-PluginMetadata -Manifest $Manifest
        loaded   = Get-Date
    }

    if (-not $Quiet) { Write-Host "[PLUGIN] Registered: $name v$($Manifest.version)" -ForegroundColor Green }
    return $script:PluginRegistry[$name]
}

function Unregister-Plugin {
    param([string]$PluginName)

    if ($script:PluginRegistry.ContainsKey($PluginName)) {
        $script:PluginRegistry.Remove($PluginName)
        Write-Host "[PLUGIN] Unregistered: $PluginName" -ForegroundColor Yellow
    }
}

function Get-RegisteredPlugins {
    return $script:PluginRegistry
}

function Initialize-Plugins {
    param([switch]$Quiet)

    $script:PluginRegistry = @{}
    $loaded = 0
    $failed = 0

    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
    $configPath = Join-Path $repoRoot 'config\plugins.json'

    $searchPaths = @()

    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($p in $config.pluginsPaths) {
                $resolved = if ([System.IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $repoRoot $p }
                $searchPaths += $resolved
            }
        } catch {
            if (-not $Quiet) { Write-Warning "Failed to read plugins.json: $_" }
        }
    }

    $localPath = Join-Path $env:USERPROFILE '.foundation\plugins'
    if (Test-Path $localPath) { $searchPaths += $localPath }

    $searchPaths = $searchPaths | Select-Object -Unique

    foreach ($searchPath in $searchPaths) {
        if (-not (Test-Path $searchPath)) { continue }

        $dirs = Get-ChildItem -Path $searchPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^\.' }

        foreach ($dir in $dirs) {
            $manifest = Get-PluginManifest -PluginPath $dir.FullName
            if (-not $manifest) { $failed++; continue }

            Register-Plugin -PluginPath $dir.FullName -Manifest $manifest -Quiet:$Quiet
            $loaded++
        }
    }

    if (-not $Quiet) {
        Write-Host "[PLUGIN] Initialized: $loaded loaded, $failed failed" -ForegroundColor Cyan
    }

    return @{ loaded = $loaded; failed = $failed; total = $loaded + $failed }
}

try { Export-ModuleMember -Function @(
    'Get-PluginManifest',
    'Get-PluginMetadata',
    'Invoke-Plugin',
    'Register-Plugin',
    'Unregister-Plugin',
    'Get-RegisteredPlugins',
    'Initialize-Plugins'
) } catch { }
