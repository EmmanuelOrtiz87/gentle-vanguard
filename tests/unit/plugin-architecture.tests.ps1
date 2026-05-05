# plugin-architecture.tests.ps1
# Unit tests for Plugin Architecture

Describe 'Plugin Architecture Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:configPath = Join-Path $script:root "config"
        $script:docsPath = Join-Path $script:root "docs/reference"
    }

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
}
