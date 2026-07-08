BeforeAll {
  $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
  $script:managerPath = Join-Path $script:root "scripts/utilities/MCP/mcp-manager.ps1"
  $script:registryPath = Join-Path $script:root "config/mcp-registry.json"
  $script:templatesPath = Join-Path $script:root "config/mcp-templates.json"
  $script:tempDir = Join-Path $script:root ".runtime/test-mcp"
}

Describe "mcp-manager.ps1" {
  Context "Script exists and is loadable" {
    It "mcp-manager.ps1 exists" {
      Test-Path $script:managerPath | Should -Be $true
    }
    It "mcp-registry.json exists" {
      Test-Path $script:registryPath | Should -Be $true
    }
    It "mcp-templates.json exists" {
      Test-Path $script:templatesPath | Should -Be $true
    }
    It "has 11 valid actions" {
      $content = Get-Content $script:managerPath -Raw
      $matches = [regex]::Matches($content, "'(\w+)'")
      $actions = $matches.Value | Where-Object { $_ -match 'register|unregister|list|start|stop|restart|health|reload|quickstart|list-templates|create' }
      @($actions).Count | Should -BeGreaterOrEqual 11
    }
  }

  Context "Registry config" {
    It "mcp-registry.json is valid JSON" {
      $reg = Get-Content $script:registryPath -Raw | ConvertFrom-Json
      $reg.version | Should -Not -BeNullOrEmpty
    }
    It "mcp-registry.json has servers array" {
      $reg = Get-Content $script:registryPath -Raw | ConvertFrom-Json
      $reg.servers | Should -Not -Be $null
    }
  }

  Context "Templates config" {
    It "mcp-templates.json is valid JSON" {
      $tpl = Get-Content $script:templatesPath -Raw | ConvertFrom-Json
      $tpl.version | Should -Not -BeNullOrEmpty
    }
    It "has at least 5 templates" {
      $tpl = Get-Content $script:templatesPath -Raw | ConvertFrom-Json
      @($tpl.templates).Count | Should -BeGreaterOrEqual 5
    }
    It "every template has required fields" {
      $tpl = Get-Content $script:templatesPath -Raw | ConvertFrom-Json
      foreach ($t in $tpl.templates) {
        $t.name | Should -Not -BeNullOrEmpty
        $t.description | Should -Not -BeNullOrEmpty
        $t.command | Should -Not -BeNullOrEmpty
        $t.args | Should -Not -Be $null
      }
    }
    It "includes sqlite template" {
      $tpl = Get-Content $script:templatesPath -Raw | ConvertFrom-Json
      $tpl.templates.name -contains 'sqlite' | Should -Be $true
    }
    It "includes postgres template" {
      $tpl = Get-Content $script:templatesPath -Raw | ConvertFrom-Json
      $tpl.templates.name -contains 'postgres' | Should -Be $true
    }
    It "includes redis template" {
      $tpl = Get-Content $script:templatesPath -Raw | ConvertFrom-Json
      $tpl.templates.name -contains 'redis' | Should -Be $true
    }
    It "includes puppeteer template" {
      $tpl = Get-Content $script:templatesPath -Raw | ConvertFrom-Json
      $tpl.templates.name -contains 'puppeteer' | Should -Be $true
    }
  }

  Context "Action: list (read-only)" {
    It "-Action list runs without throwing" {
      { & $script:managerPath -Action list -Quiet *>$null } | Should -Not -Throw
    }
  }

  Context "Action: list-templates (read-only)" {
    It "-Action list-templates runs without throwing" {
      { & $script:managerPath -Action list-templates -Quiet *>$null } | Should -Not -Throw
    }
  }

  Context "Action: health (read-only)" {
    It "-Action health runs without throwing" {
      { & $script:managerPath -Action health -Quiet *>$null } | Should -Not -Throw
    }
  }

  Context "Scaffolder: create action" {
    It "-Action create validates -Name in script code" {
      $content = Get-Content $script:managerPath -Raw
      $content | Should -Match "-Name.*required"
    }
    It "-Action register -Quiet runs without throwing" {
      { & $script:managerPath -Action register -Name test123 -Command node -Quiet *>$null } | Should -Not -Throw
      & $script:managerPath -Action unregister -Name test123 -Quiet *>$null
    }
    It "-Lang accepts ts, js, py, go, rs" {
      $content = Get-Content $script:managerPath -Raw
      $content | Should -Match "ValidateSet\('ts', 'js', 'py', 'go', 'rs'\)"
    }
    It "has -Build switch parameter" {
      $content = Get-Content $script:managerPath -Raw
      $content | Should -Match '\$Build'
    }
    It "has -Register switch parameter" {
      $content = Get-Content $script:managerPath -Raw
      $content | Should -Match '\$Register'
    }
  }
}
