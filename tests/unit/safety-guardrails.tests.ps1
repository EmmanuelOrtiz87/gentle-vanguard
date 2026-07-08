BeforeAll {
  $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
  $script:guardrailsPath = Join-Path $script:root "scripts/utilities/SAFETY/safety-guardrails.ps1"
  $script:injectionPath = Join-Path $script:root "scripts/utilities/SAFETY/prompt-injection-guard.ps1"
  $script:scorerPath = Join-Path $script:root "scripts/utilities/SAFETY/mutation-safety-scorer.ps1"
  $script:safetyConfigPath = Join-Path $script:root "config/safety-layer.json"
}

Describe "safety-guardrails.ps1" {
  Context "Script exists and is loadable" {
    It "safety-guardrails.ps1 exists" {
      Test-Path $script:guardrailsPath | Should -Be $true
    }
    It "prompt-injection-guard.ps1 exists" {
      Test-Path $script:injectionPath | Should -Be $true
    }
    It "mutation-safety-scorer.ps1 exists" {
      Test-Path $script:scorerPath | Should -Be $true
    }
    It "safety-layer.json exists" {
      Test-Path $script:safetyConfigPath | Should -Be $true
    }
    It "safety-guardrails has 3 valid actions" {
      $content = Get-Content $script:guardrailsPath -Raw
      $actions = @('validate', 'status', 'rules')
      foreach ($a in $actions) {
        $content | Should -Match "'$a'"
      }
    }
    It "prompt-injection-guard has 3 valid actions" {
      $content = Get-Content $script:injectionPath -Raw
      $actions = @('scan', 'sanitize', 'patterns')
      foreach ($a in $actions) {
        $content | Should -Match "'$a'"
      }
    }
    It "mutation-safety-scorer has 2 valid actions" {
      $content = Get-Content $script:scorerPath -Raw
      $actions = @('score', 'config')
      foreach ($a in $actions) {
        $content | Should -Match "'$a'"
      }
    }
  }

  Context "Safety config validation" {
    It "safety-layer.json is valid JSON" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      $cfg.version | Should -Not -BeNullOrEmpty
    }
    It "has at least 3 constitutional rules" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      @($cfg.guardrails.constitutional).Count | Should -BeGreaterOrEqual 3
    }
    It "has at least 3 blocked patterns" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      @($cfg.guardrails.blockedPatterns).Count | Should -BeGreaterOrEqual 3
    }
    It "has resource limits configured" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      $cfg.guardrails.resourceLimits.maxFilesPerMutation | Should -BeGreaterThan 0
    }
    It "has injection protection enabled" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      $cfg.injectionProtection.enabled | Should -Be $true
    }
    It "has at least 5 injection patterns" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      @($cfg.injectionProtection.knownPatterns).Count | Should -BeGreaterOrEqual 5
    }
    It "has scoring signals configured" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      $cfg.scoring.signals.scopeImpactWeight | Should -BeGreaterThan 0
    }
    It "has dashboard endpoint configured" {
      $cfg = Get-Content $script:safetyConfigPath -Raw | ConvertFrom-Json
      $cfg.dashboard.endpoint | Should -Be '/api/safety'
    }
  }
}
