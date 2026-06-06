<#
.SYNOPSIS
    Pester tests for multi-repo-engine.ps1
.DESCRIPTION
    Unit tests for the Multi-Repository Orchestration Engine
#>

BeforeAll {
    $script:TestRoot = Join-Path $PSScriptRoot "..\..\..\tests\multi-repo"
    $script:EnginePath = Join-Path $PSScriptRoot "multi-repo-engine.ps1"
    $script:TestConfig = Join-Path $TestRoot "test-config.json"
    
    # Create test directory structure
    if (-not (Test-Path $TestRoot)) {
        New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
    }
    
    # Create mock config
    $mockConfig = @{
        version = "2.0.0"
        enabled = $true
        repos = @(
            @{ name = "test-repo-1"; path = "$TestRoot\repo1"; remote = "origin"; defaultBranch = "main"; roles = @("core") }
            @{ name = "test-repo-2"; path = "$TestRoot\repo2"; remote = "origin"; defaultBranch = "main"; roles = @("community") }
        )
        coordination = @{
            autoDetectDependencies = $true
            validateVersionAlignment = $true
            maxParallelPRs = 3
            retryAttempts = 3
        }
    }
    $mockConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $TestConfig -Encoding UTF8
    
    # Create mock repos
    foreach ($repo in $mockConfig.repos) {
        $repoPath = $repo.path
        if (-not (Test-Path $repoPath)) {
            New-Item -ItemType Directory -Path $repoPath -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $repoPath ".git") -Force | Out-Null
            "1.0.0" | Set-Content -Path (Join-Path $repoPath "VERSION") -Encoding UTF8
        }
    }
}

AfterAll {
    # Cleanup test directory
    if (Test-Path $script:TestRoot) {
        Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Multi-Repo Engine" {
    Context "Configuration" {
        It "Should load configuration from JSON file" {
            $config = & $script:EnginePath -Action status -ConfigPath $script:TestConfig -Raw 2>$null | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.version | Should -Be "2.0.0"
            $config.enabled | Should -Be $true
        }
        
        It "Should detect correct number of repos" {
            $config = & $script:EnginePath -Action status -ConfigPath $script:TestConfig -Raw 2>$null | ConvertFrom-Json
            $config.repoCount | Should -Be 2
        }
        
        It "Should identify existing repos" {
            $config = & $script:EnginePath -Action status -ConfigPath $script:TestConfig -Raw 2>$null | ConvertFrom-Json
            $config.repos[0].exists | Should -Be $true
            $config.repos[0].hasGit | Should -Be $true
        }
    }
    
    Context "Version Alignment" {
        It "Should validate version alignment" {
            $result = & $script:EnginePath -Action validate -ConfigPath $script:TestConfig -Raw 2>$null | ConvertFrom-Json
            $result.versionAligned | Should -Be $true
        }
        
        It "Should detect version mismatch" {
            # Modify one repo version
            "2.0.0" | Set-Content -Path (Join-Path $script:TestRoot "repo2\VERSION") -Encoding UTF8
            $result = & $script:EnginePath -Action validate -ConfigPath $script:TestConfig -Raw 2>$null | ConvertFrom-Json
            $result.versionAligned | Should -Be $false
            # Reset
            "1.0.0" | Set-Content -Path (Join-Path $script:TestRoot "repo2\VERSION") -Encoding UTF8
        }
    }
    
    Context "Discovery" {
        It "Should discover sibling repos" {
            $result = & $script:EnginePath -Action discover -ConfigPath $script:TestConfig -Raw 2>$null | ConvertFrom-Json
            $result.discovered | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Dependency Check" {
        It "Should check for internal dependencies" {
            # Create package.json with internal deps
            $pkg = @{
                name = "test-repo-1"
                dependencies = @{
                    "@gentle-vanguard/core" = "^1.0.0"
                    "react" = "^18.0.0"
                }
                devDependencies = @{}
            }
            $pkg | ConvertTo-Json | Set-Content -Path (Join-Path $script:TestRoot "repo1\package.json") -Encoding UTF8
            
            $result = & $script:EnginePath -Action dependency-check -ConfigPath $script:TestConfig -Raw 2>$null | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            $result[0].hasInternalDeps | Should -Be $true
            $result[0].internalDeps | Should -Contain "@gentle-vanguard/core"
        }
    }
    
    Context "Dry Run Mode" {
        It "Should simulate coordinated PRs without executing" {
            $result = & $script:EnginePath -Action coordinated-pr -ConfigPath $script:TestConfig -Title "Test PR" -DryRun -Raw 2>$null | ConvertFrom-Json
            $result.dryRun | Should -Be $true
        }
    }
    
    Context "Error Handling" {
        It "Should handle missing config gracefully" {
            $missingConfig = Join-Path $script:TestRoot "missing.json"
            { & $script:EnginePath -Action status -ConfigPath $missingConfig -Raw 2>$null } | Should -Not -Throw
        }
        
        It "Should require Title for coordinated-pr" {
            { & $script:EnginePath -Action coordinated-pr -ConfigPath $script:TestConfig 2>$null } | Should -Throw
        }
        
        It "Should require Command for bulk-command" {
            { & $script:EnginePath -Action bulk-command -ConfigPath $script:TestConfig 2>$null } | Should -Throw
        }
    }
}

Describe "Logging Functions" {
    It "Should output formatted log messages" {
        $output = & { Write-Log "INFO" "Test message" } 2>&1
        $output | Should -Match "\[INFO\] Test message"
    }
    
    It "Should support different log levels" {
        $levels = @("INFO", "WARN", "ERROR", "SUCCESS")
        foreach ($level in $levels) {
            $output = & { Write-Log $level "Test" } 2>&1
            $output | Should -Match "\[$level\]"
        }
    }
}

Describe "Retry Logic" {
    It "Should succeed on first attempt" {
        $attempts = 0
        $result = Invoke-WithRetry -ScriptBlock { $script:attempts++; return "success" } -MaxRetries 3
        $result | Should -Be "success"
        $attempts | Should -Be 1
    }
    
    It "Should retry on failure" {
        $attempts = 0
        { Invoke-WithRetry -ScriptBlock { $script:attempts++; throw "error" } -MaxRetries 3 -DelaySeconds 0 } | Should -Throw
        $attempts | Should -Be 3
    }
}
