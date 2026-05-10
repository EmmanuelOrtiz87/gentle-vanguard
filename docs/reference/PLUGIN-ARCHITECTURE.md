# Plugin Architecture Specification

# FF-011: Extensibility contract for third-party plugins

## Overview

Standardized interface for third-party plugins with clear contract.

## Plugin Interface

### Required Methods

```powershell
function Invoke-Plugin {
    param(
        [string]$Command,
        [hashtable]$Parameters
    )

    # Plugin implementation
    return @{
        success = $true
        result = $null
        message = ""
    }
}

function Get-PluginMetadata {
    return @{
        name = "plugin-name"
        version = "1.0.0"
        author = "Author"
        description = "Plugin description"
        minFoundationVersion = "2.6.0"
        provides = @("capability1", "capability2")
    }
}
```

## Plugin Discovery

Plugins discovered from:

1. `plugins/` directory (built-in)
2. `C:\Users\$env:USERNAME\.foundation\plugins\` (user)
3. Configured paths in `config/plugins.json`

## Plugin Loading

```powershell
function Load-Plugin {
    param([string]$PluginPath)

    $pluginFile = Join-Path $PluginPath "plugin.ps1"
    if (-not (Test-Path $pluginFile)) { return $null }

    $plugin = . $pluginFile
    $metadata = Get-PluginMetadata

    return @{
        path = $PluginPath
        metadata = $metadata
        instance = $plugin
    }
}
```

## Security

- Plugins run in sandbox (restricted PSSession)
- Require signature validation
- Manifest whitelist approach

## Example Plugin Structure

```
plugins/
  example-plugin/
    plugin.ps1          # Main plugin code
    plugin.json         # Metadata manifest
    README.md           # Documentation
```

## Integration Points

- Hooks: Plugins can register git hooks
- Skills: Plugins can provide custom skills
- Commands: Plugins can add wf.ps1 subcommands
- Tools: Plugins can provide new tool integrations

## Lifecycle

1. Discover → 2. Validate → 3. Load → 4. Initialize → 5. Execute → 6. Cleanup
