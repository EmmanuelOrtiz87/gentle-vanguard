#Requires -Version 7.0

<#
.SYNOPSIS
    Integration tests for Auto-Delegation Router
    
.DESCRIPTION
    Tests keyword extraction, decision trees, confidence scoring,
    and routing functionality
#>

# Import the module
$modulePath = Join-Path $PSScriptRoot "../../skills/auto-delegation-router/auto-delegation-router.ps1"
Import-Module $modulePath -Force

Describe "Auto-Delegation Router" {
    
    Context "Configuration Management" {
        It "Should load default configuration" {
            $config = Get-AutoDelegationConfig
            $config | Should -Not -BeNullOrEmpty
            $config.Enabled | Should -Be $false
            $config.ConfidenceThreshold | Should -Be 60
        }
        
        It "Should enable auto-delegation" {
            $result = Enable-AutoDelegation
            $result.Status | Should -Be "Enabled"
            
            $config = Get-AutoDelegationConfig
            $config.Enabled | Should -Be $true
        }
        
        It "Should disable auto-delegation" {
            $result = Disable-AutoDelegation
            $result.Status | Should -Be "Disabled"
            
            $config = Get-AutoDelegationConfig
            $config.Enabled | Should -Be $false
        }
        
        It "Should set confidence threshold" {
            $result = Set-ConfidenceThreshold -Threshold 75
            $result.Status | Should -Be "Success"
            
            $config = Get-AutoDelegationConfig
            $config.ConfidenceThreshold | Should -Be 75
        }
    }
    
    Context "Keyword Extraction" {
        It "Should extract DEV keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Implement login feature with React components"
            $keywords.Keys | Should -Contain "DEV"
            $keywords["DEV"] | Should -BeGreaterThan 0
        }
        
        It "Should extract QA keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Write unit tests and integration tests"
            $keywords.Keys | Should -Contain "QA"
        }
        
        It "Should extract BA keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Create BDD scenarios for checkout flow"
            $keywords.Keys | Should -Contain "BA"
        }
        
        It "Should extract SAD keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Design API schema and database"
            $keywords.Keys | Should -Contain "SAD"
        }
        
        It "Should extract OPS keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Deploy to Kubernetes and configure Docker"
            $keywords.Keys | Should -Contain "OPS"
        }
        
        It "Should return empty for vague descriptions" {
            $keywords = Extract-TaskKeywords -TaskDescription "Do stuff"
            $keywords.Count | Should -Be 0
        }
    }
    
    Context "Decision Tree Evaluation" {
        It "Should identify primary agent" {
            $keywords = @{ "DEV" = 3; "QA" = 1 }
            $decisions = Evaluate-DecisionTree -TaskDescription "Implement feature" -Keywords $keywords
            
            $primary = $decisions | Where-Object { $_.Level -eq 1 }
            $primary.Agent | Should -Be "DEV"
        }
        
        It "Should identify secondary agent" {
            $keywords = @{ "DEV" = 3; "QA" = 2 }
            $decisions = Evaluate-DecisionTree -TaskDescription "Implement and test feature" -Keywords $keywords
            
            $secondary = $decisions | Where-Object { $_.Level -eq 2 }
            $secondary | Should -Not -BeNullOrEmpty
            $secondary.Agent | Should -Be "QA"
        }
        
        It "Should add QA for high-risk context" {
            $keywords = @{ "DEV" = 2 }
            $context = @{ RiskLevel = "high" }
            $decisions = Evaluate-DecisionTree -TaskDescription "Implement feature" -Keywords $keywords -Context $context
            
            $agents = $decisions | Select-Object -ExpandProperty Agent
            $agents | Should -Contain "QA"
        }
        
        It "Should add OPS for deployment tasks" {
            $keywords = @{ "DEV" = 2 }
            $decisions = Evaluate-DecisionTree -TaskDescription "Deploy to production" -Keywords $keywords
            
            $agents = $decisions | Select-Object -ExpandProperty Agent
            $agents | Should -Contain "OPS"
        }
    }
    
    Context "Confidence Scoring" {
        It "Should calculate high confidence for clear single agent" {
            $keywords = @{ "DEV" = 3 }
            $decisionTree = @(@{ Level = 1; Agent = "DEV" })
            $confidence = Calculate-ConfidenceScore -Keywords $keywords -DecisionTree $decisionTree
            
            $confidence.Score | Should -BeGreaterThan 60
            $confidence.Confidence | Should -Be "High"
        }
        
        It "Should calculate medium confidence for multiple agents" {
            $keywords = @{ "DEV" = 2; "QA" = 2 }
            $decisionTree = @(@{ Level = 1; Agent = "DEV" }, @{ Level = 2; Agent = "QA" })
            $confidence = Calculate-ConfidenceScore -Keywords $keywords -DecisionTree $decisionTree
            
            $confidence.Score | Should -BeGreaterThan 40
        }
        
        It "Should apply adjustments correctly" {
            $keywords = @{ "DEV" = 1 }
            $decisionTree = @(@{ Level = 1; Agent = "DEV" })
            $context = @{ HasClearObjective = $true }
            $confidence = Calculate-ConfidenceScore -Keywords $keywords -DecisionTree $decisionTree -Context $context
            
            $confidence.Adjustments | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Task Routing" {
        BeforeEach {
            Enable-AutoDelegation
            Set-ConfidenceThreshold -Threshold 60
        }
        
        It "Should route development task to DEV" {
            $routing = Route-TaskToAgent -TaskDescription "Implement login feature with React"
            
            $routing.Status | Should -Be "Success"
            $routing.PrimaryAgent | Should -Be "DEV"
            $routing.ConfidenceScore | Should -BeGreaterThan 60
        }
        
        It "Should route testing task to QA" {
            $routing = Route-TaskToAgent -TaskDescription "Write unit tests and E2E tests"
            
            $routing.Status | Should -Be "Success"
            $routing.PrimaryAgent | Should -Be "QA"
        }
        
        It "Should route architecture task to SAD" {
            $routing = Route-TaskToAgent -TaskDescription "Design API schema and database"
            
            $routing.Status | Should -Be "Success"
            $routing.PrimaryAgent | Should -Be "SAD"
        }
        
        It "Should route deployment task to OPS" {
            $routing = Route-TaskToAgent -TaskDescription "Deploy to Kubernetes"
            
            $routing.Status | Should -Be "Success"
            $routing.PrimaryAgent | Should -Be "OPS"
        }
        
        It "Should include secondary agents when applicable" {
            $routing = Route-TaskToAgent -TaskDescription "Implement feature and write tests"
            
            $routing.Status | Should -Be "Success"
            $routing.SecondaryAgents | Should -Not -BeNullOrEmpty
        }
        
        It "Should return LowConfidence for vague tasks" {
            $routing = Route-TaskToAgent -TaskDescription "Fix stuff"
            
            $routing.Status | Should -Be "LowConfidence"
            $routing.RequiresManualDecision | Should -Be $true
        }
        
        It "Should respect disabled auto-delegation" {
            Disable-AutoDelegation
            $routing = Route-TaskToAgent -TaskDescription "Implement feature"
            
            $routing.Status | Should -Be "AutoDelegationDisabled"
            $routing.RequiresManualDecision | Should -Be $true
        }
    }
    
    Context "Metrics and Logging" {
        It "Should get routing metrics" {
            $metrics = Get-RoutingMetrics
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.TotalRoutings | Should -BeGreaterThanOrEqual 0
        }
        
        It "Should log routing decisions" {
            Enable-AutoDelegation
            $routing = Route-TaskToAgent -TaskDescription "Implement feature"
            
            Log-RoutingDecision -RoutingResult $routing
            
            $metrics = Get-RoutingMetrics
            $metrics.TotalRoutings | Should -BeGreaterThan 0
        }
    }
}

# Run tests
Invoke-Pester -Path $PSCommandPath -Verbose