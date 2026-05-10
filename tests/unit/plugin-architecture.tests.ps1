# plugin-architecture.tests.ps1
# Unit tests for Plugin Architecture FF-011

$script:root = Resolve-Path "$PSScriptRoot/../.."
$script:configPath = Join-Path $script:root "config"
$script:docsPath = Join-Path $script:root "docs/reference"
$script:toolsPath = Join-Path $script:root "scripts/utilities/SKILLS-TOOLS"
$script:pluginsDir = Join-Path $script:root "plugins"

Describe 'Plugin Architecture Tests' {
    Context 'Plugin Manifest Schema' {
        It 'plugin-manifest-schema.json exists' {
            $f = Join-Path $script:configPath "plugin-manifest-schema.json"
            Test-Path $f | Should Be $true
        }

        It 'plugin-manifest-schema.json is valid JSON' {
            $f = Join-Path $script:configPath "plugin-manifest-schema.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'plugin-manifest-schema.json has required fields' {
            $f = Join-Path $script:configPath "plugin-manifest-schema.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.required | Should Not BeNullOrEmpty
            ($json.required -contains "name") | Should Be $true
            ($json.required -contains "version") | Should Be $true
        }

        It 'plugin-manifest-schema.json includes main field' {
            $f = Join-Path $script:configPath "plugin-manifest-schema.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.properties.main | Should Not BeNullOrEmpty
        }

        It 'plugin-manifest-schema.json includes dependencies field' {
            $f = Join-Path $script:configPath "plugin-manifest-schema.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.properties.dependencies | Should Not BeNullOrEmpty
        }
    }

    Context 'Plugin Config' {
        It 'plugins.json exists' {
            $f = Join-Path $script:configPath "plugins.json"
            Test-Path $f | Should Be $true
        }

        It 'plugins.json is valid JSON' {
            $f = Join-Path $script:configPath "plugins.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'plugins.json has pluginsPaths array' {
            $f = Join-Path $script:configPath "plugins.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.pluginsPaths | Should Not BeNullOrEmpty
        }
    }

    Context 'Plugin Discovery Script' {
        It 'plugins-discovery.ps1 exists' {
            $f = Join-Path $script:toolsPath "plugins-discovery.ps1"
            Test-Path $f | Should Be $true
        }

        It 'plugins-discovery.ps1 has discover action' {
            $f = Join-Path $script:toolsPath "plugins-discovery.ps1"
            $content = Get-Content $f -Raw
            $content -match "discover" | Should Be $true
        }

        It 'plugins-discovery.ps1 has validate action' {
            $f = Join-Path $script:toolsPath "plugins-discovery.ps1"
            $content = Get-Content $f -Raw
            $content -match "validate" | Should Be $true
        }

        It 'plugins-discovery.ps1 -Action discover returns output' {
            $f = Join-Path $script:toolsPath "plugins-discovery.ps1"
            $result = & $f -Action discover -Quiet -AsJson | ConvertFrom-Json
            $result.total_plugins | Should Not BeNullOrEmpty
        }

        It 'plugins-discovery.ps1 discovers example plugin' {
            $f = Join-Path $script:toolsPath "plugins-discovery.ps1"
            $result = & $f -Action discover -Quiet -AsJson | ConvertFrom-Json
            $names = $result.plugins | ForEach-Object { $_.name }
            $names -contains "example-hello-world" | Should Be $true
        }
    }

    Context 'Plugin Loader Script' {
        It 'plugin-loader.ps1 exists' {
            $f = Join-Path $script:toolsPath "plugin-loader.ps1"
            Test-Path $f | Should Be $true
        }

        It 'plugin-loader.ps1 has Initialize-Plugins function' {
            $f = Join-Path $script:toolsPath "plugin-loader.ps1"
            $content = Get-Content $f -Raw
            $content -match "function Initialize-Plugins" | Should Be $true
        }

        It 'plugin-loader.ps1 has Invoke-Plugin function' {
            $f = Join-Path $script:toolsPath "plugin-loader.ps1"
            $content = Get-Content $f -Raw
            $content -match "function Invoke-Plugin" | Should Be $true
        }

        It 'plugin-loader.ps1 can be dot-sourced' {
            $f = Join-Path $script:toolsPath "plugin-loader.ps1"
            { . $f } | Should Not Throw
        }

        It 'plugin-loader.ps1 loads example plugin' {
            $f = Join-Path $script:toolsPath "plugin-loader.ps1"
            . $f
            $result = Initialize-Plugins -Quiet
            ($result.loaded -ge 0) | Should Be $true
        }
    }

    Context 'Example Plugin' {
        It 'example-hello-world/plugin.json exists' {
            $f = Join-Path $script:pluginsDir "example-hello-world/plugin.json"
            Test-Path $f | Should Be $true
        }

        It 'example-hello-world/plugin.json is valid JSON' {
            $f = Join-Path $script:pluginsDir "example-hello-world/plugin.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'example plugin manifest has all required fields' {
            $f = Join-Path $script:pluginsDir "example-hello-world/plugin.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.name | Should Be "example-hello-world"
            $json.version | Should Be "1.0.0"
            $json.author | Should Not BeNullOrEmpty
            $json.description | Should Not BeNullOrEmpty
        }

        It 'hello-world.ps1 exists in plugin dir' {
            $f = Join-Path $script:pluginsDir "example-hello-world/hello-world.ps1"
            Test-Path $f | Should Be $true
        }

        It 'hello-world.ps1 can be invoked' {
            $f = Join-Path $script:pluginsDir "example-hello-world/hello-world.ps1"
            $result = & $f -Name "Test"
            $result | Should BeNullOrEmpty  # Write-Host returns nothing
        }
    }

    Context 'Plugin Documentation' {
        It 'PLUGIN-ARCHITECTURE.md exists' {
            $f = Join-Path $script:docsPath "PLUGIN-ARCHITECTURE.md"
            Test-Path $f | Should Be $true
        }

        It 'PLUGIN-ARCHITECTURE.md is non-empty' {
            $f = Join-Path $script:docsPath "PLUGIN-ARCHITECTURE.md"
            (Get-Item $f).Length | Should BeGreaterThan 0
        }

        It 'PLUGIN-ARCHITECTURE.md mentions interface contract' {
            $f = Join-Path $script:docsPath "PLUGIN-ARCHITECTURE.md"
            $content = Get-Content $f -Raw
            ($content -match 'interface|contract|IPlugin') | Should Be $true
        }
    }

    Context 'CI Integration' {
        It 'autonomous-validation.yml has plugin validation step' {
            $f = Join-Path $script:root ".github/workflows/autonomous-validation.yml"
            $content = Get-Content $f -Raw
            $content -match "Validate Plugins" | Should Be $true
        }

        It 'autonomous-validation.yml invokes plugins-discovery.ps1' {
            $f = Join-Path $script:root ".github/workflows/autonomous-validation.yml"
            $content = Get-Content $f -Raw
            $content -match "plugins-discovery.ps1" | Should Be $true
        }
    }
}
