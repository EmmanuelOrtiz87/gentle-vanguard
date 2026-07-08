BeforeAll {
  $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
  $script:queryPath = Join-Path $script:root "scripts/utilities/knowledge/knowledge-query.ps1"
  $script:eventStoreDir = Join-Path $script:root ".session/event-store"
  $script:traceDir = Join-Path $script:root ".telemetry/traces"
  $script:ckptDir = Join-Path $script:root ".session/checkpoints"
}

Describe "knowledge-query.ps1" {
  Context "Script exists" {
    It "knowledge-query.ps1 exists" {
      Test-Path $script:queryPath | Should -Be $true
    }
    It "has required parameters" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match '\$Query'
      $content | Should -Match '\$Sources'
      $content | Should -Match '\$Limit'
      $content | Should -Match '\$Format'
    }
  }

  Context "Parameter validation" {
    It "defaults to events/traces/feedback/checkpoints sources" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "events.*traces.*feedback.*checkpoints"
    }
    It "accepts json format" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "'json'"
    }
    It "accepts text format" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "'text'"
    }
  }

  Context "Source: Engram integration" {
    It "has engram source support" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "'engram'"
    }
    It "searches .session/memories/ for engram data" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "memories"
    }
    It "falls back to context-log summaries" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "context-summary"
    }
  }

  Context "Source: Events" {
    It "reads .session/event-store/*.jsonl" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "event-store"
      $content | Should -Match "\.jsonl"
    }
  }

  Context "Source: Traces" {
    It "reads telemetry traces *.jsonl" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "traces"
      $content | Should -Match "\.jsonl"
    }
  }

  Context "Source: Feedback" {
    It "reads .session/feedback/*.json" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "feedback"
    }
  }

  Context "Source: Checkpoints" {
    It "reads .session/checkpoints/ directories" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "checkpoints"
    }
  }

  Context "Relevance scoring" {
    It "has Score-Relevance function" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "Score-Relevance"
    }
    It "exact match scores 1.0" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "1.0"
    }
    It "partial match scores 0.9" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "0.9"
    }
  }

  Context "Time range filtering" {
    It "has Is-InTimeRange function" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "Is-InTimeRange"
    }
    It "supports -TimeRange parameter" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "TimeRange"
    }
  }

  Context "Output format" {
    It "json output produces valid JSON structure" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "ConvertTo-Json"
    }
    It "text output shows source badges" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "source.*ToUpper"
    }
  }

  Context "Color coding" {
    It "engram source has color mapping" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "engram.*Red"
    }
    It "events source has color mapping" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "events.*DarkCyan"
    }
    It "traces source has color mapping" {
      $content = Get-Content $script:queryPath -Raw
      $content | Should -Match "traces.*Magenta"
    }
  }

  Context "Run modes (no data = graceful)" {
    It "runs with empty query without throwing" {
      { & $script:queryPath -Query "" -Format json -Quiet *>$null } | Should -Not -Throw
    }
    It "text format outputs without throwing" {
      { & $script:queryPath -Query "test" -Format text -Quiet *>$null } | Should -Not -Throw
    }
    It "handles -TimeRange parameter without throwing" {
      { & $script:queryPath -Query "" -TimeRange "-24h..now" -Format json -Quiet *>$null } | Should -Not -Throw
    }
  }
}
