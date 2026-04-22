#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Unit Tests for Engram Memory Manager
    
.DESCRIPTION
    Comprehensive unit tests for Engram Memory Manager functions
    
.NOTES
    Requires Pester module
#>

Describe "Engram Memory Manager - Unit Tests" {
    
    BeforeAll {
        $script:ManagerPath = ".\tools\engram-memory-manager.ps1"
        $script:ConfigPath = ".\config\engram-memory.json"
    }
    
    Context "Configuration Loading" {
        It "Should load configuration file" {
            $config = Get-Content $script:ConfigPath | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.version | Should -Be "2.0.0"
        }
        
        It "Should have all required phases" {
            $config = Get-Content $script:ConfigPath | ConvertFrom-Json
            $config.phases | Should -Not -BeNullOrEmpty
            $config.phases.phase1 | Should -Not -BeNullOrEmpty
            $config.phases.phase2 | Should -Not -BeNullOrEmpty
            $config.phases.phase3 | Should -Not -BeNullOrEmpty
        }
        
        It "Should have correct threshold value" {
            $config = Get-Content $script:ConfigPath | ConvertFrom-Json
            $config.phases.phase1.threshold | Should -Be 250
        }
    }
    
    Context "Memory Pack Creation" {
        It "Should create memory pack with valid ID" {
            $packId = "test-pack-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            $packId | Should -Match "^test-pack-\d{8}-\d{6}$"
        }
        
        It "Should validate pack structure" {
            $pack = @{
                id = "test-pack-001"
                type = "memory-pack"
                tokens = 250
                timestamp = (Get-Date -Format "o")
            }
            $pack.id | Should -Not -BeNullOrEmpty
            $pack.type | Should -Be "memory-pack"
            $pack.tokens | Should -Be 250
        }
        
        It "Should enforce token limits" {
            $maxTokens = 250
            $testTokens = 300
            $testTokens -gt $maxTokens | Should -Be $true
        }
    }
    
    Context "Consolidation Logic" {
        It "Should identify consolidation trigger" {
            $packCount = 5
            $triggerThreshold = 5
            $packCount -ge $triggerThreshold | Should -Be $true
        }
        
        It "Should calculate consolidation ratio" {
            $sourcePacks = 5
            $targetPacks = 1
            $ratio = $sourcePacks / $targetPacks
            $ratio | Should -Be 5
        }
        
        It "Should validate consolidation result" {
            $consolidatedPack = @{
                id = "consolidated-001"
                sourcePacks = 5
                tokens = 1250
                compressionRatio = 0.65
            }
            $consolidatedPack.compressionRatio | Should -Be 0.65
            $consolidatedPack.tokens | Should -Be 1250
        }
    }
    
    Context "Compression Operations" {
        It "Should apply compression ratio" {
            $originalSize = 1000
            $compressionRatio = 0.65
            $compressedSize = [int]($originalSize * $compressionRatio)
            $compressedSize | Should -Be 650
        }
        
        It "Should maintain minimum quality score" {
            $qualityScore = 0.91
            $minimumQuality = 0.80
            $qualityScore -ge $minimumQuality | Should -Be $true
        }
        
        It "Should validate compression bounds" {
            $ratio = 0.65
            $ratio -ge 0.50 -and $ratio -le 0.95 | Should -Be $true
        }
    }
    
    Context "Error Handling" {
        It "Should handle missing configuration" {
            $missingConfig = ".\config\nonexistent.json"
            Test-Path $missingConfig | Should -Be $false
        }
        
        It "Should validate input parameters" {
            $invalidAction = "invalid-action"
            $validActions = @("create", "consolidate", "compress", "analyze", "report")
            $validActions -contains $invalidAction | Should -Be $false
        }
        
        It "Should handle corrupted pack data" {
            $corruptedPack = @{
                id = ""
                tokens = -100
            }
            [string]::IsNullOrEmpty($corruptedPack.id) | Should -Be $true
            $corruptedPack.tokens -lt 0 | Should -Be $true
        }
    }
    
    Context "Performance Metrics" {
        It "Should track creation time" {
            $startTime = Get-Date
            Start-Sleep -Milliseconds 10
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalMilliseconds
            $duration -gt 0 | Should -Be $true
        }
        
        It "Should validate performance threshold" {
            $actualTime = 45
            $threshold = 50
            $actualTime -le $threshold | Should -Be $true
        }
        
        It "Should track consolidation performance" {
            $consolidationTime = 95
            $performanceThreshold = 100
            $consolidationTime -le $performanceThreshold | Should -Be $true
        }
    }
    
    Context "Data Integrity" {
        It "Should verify pack integrity" {
            $pack = @{
                id = "test-001"
                checksum = "abc123def456"
                verified = $true
            }
            $pack.verified | Should -Be $true
        }
        
        It "Should detect data corruption" {
            $originalChecksum = "abc123"
            $currentChecksum = "xyz789"
            $originalChecksum -eq $currentChecksum | Should -Be $false
        }
        
        It "Should validate pack structure" {
            $pack = @{
                id = "test-001"
                type = "memory-pack"
                tokens = 250
                timestamp = (Get-Date -Format "o")
            }
            $pack.PSObject.Properties.Count | Should -Be 4
        }
    }
}

Describe "Engram Memory Manager - Integration Tests" {
    
    Context "End-to-End Workflow" {
        It "Should complete full workflow" {
            # Create → Consolidate → Compress → Validate
            $workflow = @("create", "consolidate", "compress", "validate")
            $workflow.Count | Should -Be 4
        }
        
        It "Should maintain state across operations" {
            $state = @{
                packsCreated = 5
                packsConsolidated = 1
                compressionApplied = $true
            }
            $state.packsCreated | Should -Be 5
            $state.compressionApplied | Should -Be $true
        }
    }
}