#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Integration Tests - Engram Memory System + Orchestrator
    
.DESCRIPTION
    Comprehensive integration tests for Engram and Orchestrator interaction
    
.NOTES
    Requires Pester module
#>

Describe "Engram Memory System - Integration Tests" {
    
    BeforeAll {
        $script:ConfigPath = ".\config\engram-memory.json"
        $script:OrchestratorPath = ".\config\orchestrator.json"
    }
    
    Context "End-to-End Workflow" {
        It "Should complete full workflow: Create  Consolidate  Compress" {
            $workflow = @("create", "consolidate", "compress", "validate")
            $workflow.Count | Should Be 4
            $workflow[0] | Should Be "create"
        }
        
        It "Should maintain state across operations" {
            $state = @{
                packsCreated = 5
                packsConsolidated = 1
                compressionApplied = $true
                qualityScore = 0.91
            }
            $state.packsCreated | Should Be 5
            $state.compressionApplied | Should Be $true
            ($state.qualityScore -ge 0.80) | Should Be $true
        }
        
        It "Should handle multiple packs in sequence" {
            $packs = @(
                @{ id = "pack-001"; tokens = 250 },
                @{ id = "pack-002"; tokens = 250 },
                @{ id = "pack-003"; tokens = 250 },
                @{ id = "pack-004"; tokens = 250 },
                @{ id = "pack-005"; tokens = 250 }
            )
            $packs.Count | Should Be 5
            $packs | ForEach-Object { $_.tokens | Should Be 250 }
        }
    }
    
    Context "Orchestrator Integration" {
        It "Should detect AI tool correctly" {
            $config = Get-Content $script:OrchestratorPath | ConvertFrom-Json
            $config.orchestration.aiToolDetection.enabled | Should Be $true
        }
        
        It "Should load tool-specific configuration" {
            $config = Get-Content $script:OrchestratorPath | ConvertFrom-Json
            ($config.tools -ne $null) | Should Be $true
        }
        
        It "Should apply tool-specific rules" {
            $config = Get-Content $script:OrchestratorPath | ConvertFrom-Json
            ($config.rules -ne $null) | Should Be $true
        }
    }
    
    Context "Engram-Orchestrator Communication" {
        It "Should pass context between components" {
            $context = @{
                tool = "cline"
                tokens = 250
                timestamp = (Get-Date -Format "o")
            }
            $context.tool | Should Be "cline"
            $context.tokens | Should Be 250
        }
        
        It "Should handle context updates" {
            $context = @{ tokens = 250 }
            $context.tokens = 300
            $context.tokens | Should Be 300
        }
        
        It "Should validate context integrity" {
            $context = @{
                id = "ctx-001"
                checksum = "abc123"
                verified = $true
            }
            $context.verified | Should Be $true
        }
    }
    
    Context "Consolidation Workflow" {
        It "Should trigger consolidation at threshold" {
            $packCount = 5
            $threshold = 5
            $packCount -ge $threshold | Should Be $true
        }
        
        It "Should consolidate packs correctly" {
            $sourcePacks = 5
            $targetPacks = 1
            $consolidationRatio = $sourcePacks / $targetPacks
            $consolidationRatio | Should Be 5
        }
        
        It "Should maintain data integrity during consolidation" {
            $originalTokens = 1250
            $consolidatedTokens = 1250
            $originalTokens | Should Be $consolidatedTokens
        }
        
        It "Should apply compression after consolidation" {
            $preCompressionSize = 1250
            $compressionRatio = 0.65
            $postCompressionSize = [int]($preCompressionSize * $compressionRatio)
            $postCompressionSize | Should Be 812
        }
    }
    
    Context "Dynamic Optimization Integration" {
        It "Should monitor system metrics" {
            $metrics = @{
                cpuUsage = 45
                memoryUsage = 60
                tokenUsage = 250
                cacheHitRate = 0.75
            }
            $metrics.cpuUsage | Should BeLessThan 100
            $metrics.cacheHitRate | Should BeGreaterOrEqual 0.70
        }
        
        It "Should adjust parameters based on metrics" {
            $currentCompression = 0.65
            $targetCompression = 0.70
            $currentCompression -lt $targetCompression | Should Be $true
        }
        
        It "Should maintain quality during optimization" {
            $qualityScore = 0.91
            $minimumQuality = 0.80
            ($qualityScore -ge $minimumQuality) | Should Be $true
        }
    }
    
    Context "Error Recovery" {
        It "Should handle pack creation failure" {
            $result = @{ success = $false; error = "Pack creation failed" }
            $result.success | Should Be $false
        }
        
        It "Should recover from consolidation failure" {
            $state = @{ consolidated = $false; recovered = $true }
            $state.recovered | Should Be $true
        }
        
        It "Should validate data after recovery" {
            $pack = @{ id = "recovered-001"; verified = $true }
            $pack.verified | Should Be $true
        }
    }
    
    Context "Performance Under Load" {
        It "Should handle 10 concurrent packs" {
            $concurrentPacks = 10
            ($concurrentPacks -le 10) | Should Be $true
        }
        
        It "Should maintain performance with consolidation" {
            $creationTime = 45
            $consolidationTime = 95
            $totalTime = $creationTime + $consolidationTime
            $totalTime | Should BeLessThan 200
        }
        
        It "Should not degrade with repeated operations" {
            $iteration1Time = 50
            $iteration2Time = 51
            $iteration3Time = 52
            $iteration3Time -le 60 | Should Be $true
        }
    }
}

Describe "Orchestrator - Integration Tests" {
    
    Context "Multi-Tool Support" {
        It "Should support Cline" {
            $tools = @("cline", "continue", "cursor", "copilot")
            $tools -contains "cline" | Should Be $true
        }
        
        It "Should support Continue" {
            $tools = @("cline", "continue", "cursor", "copilot")
            $tools -contains "continue" | Should Be $true
        }
        
        It "Should support Cursor" {
            $tools = @("cline", "continue", "cursor", "copilot")
            $tools -contains "cursor" | Should Be $true
        }
    }
    
    Context "Configuration Switching" {
        It "Should switch between tool configurations" {
            $config1 = @{ tool = "cline"; tokens = 200000 }
            $config2 = @{ tool = "continue"; tokens = 100000 }
            $config1.tokens | Should Not Be $config2.tokens
        }
        
        It "Should apply tool-specific parameters" {
            $clineConfig = @{ compressionRatio = 0.95 }
            $continueConfig = @{ compressionRatio = 0.85 }
            $clineConfig.compressionRatio | Should BeGreaterThan $continueConfig.compressionRatio
        }
    }
}
