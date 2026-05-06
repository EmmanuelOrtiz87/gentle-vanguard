#Requires -Version 7.0

<#
.SYNOPSIS
    Integration tests for Auto-Delegation Router
#>

# Import the module by dot-sourcing
$modulePath = Join-Path $PSScriptRoot "../../skills/auto-delegation-router/auto-delegation-router.ps1"
. $modulePath

Describe "Auto-Delegation Router" {
    
    Context "Configuration Management" {
        It "Should load default configuration" {
            $config = Get-AutoDelegationConfig
            $config | Should Not BeNullOrEmpty
            $config.Enabled | Should Be $true
            $config.ConfidenceThreshold | Should Be 60
        }
        
        It "Should enable auto-delegation" {
            $result = Enable-AutoDelegation
            $result | Should Not BeNullOrEmpty
            $result.Status | Should Be "Enabled"
            
            $config = Get-AutoDelegationConfig
            $config.Enabled | Should Be $true
        }
        
        It "Should disable auto-delegation" {
            $result = Disable-AutoDelegation
            $result | Should Not BeNullOrEmpty
            $result.Status | Should Be "Disabled"
            
            $config = Get-AutoDelegationConfig
            $config.Enabled | Should Be $false
        }
        
        It "Should set confidence threshold" {
            Enable-AutoDelegation | Out-Null
            $result = Set-ConfidenceThreshold -Threshold 75
            $result | Should Not BeNullOrEmpty
            $result.Status | Should Be "Success"
            
            $config = Get-AutoDelegationConfig
            $config.ConfidenceThreshold | Should Be 75
        }
    }
    
    Context "Keyword Extraction" {
        It "Should extract DEV keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Implement login feature with React components"
            $keywords | Should Not BeNullOrEmpty
            $keywords.ContainsKey("DEV") | Should Be $true
        }
        
        It "Should extract QA keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Write test cases and verify QA"
            $keywords | Should Not BeNullOrEmpty
            $keywords.ContainsKey("QA") | Should Be $true
        }
        
        It "Should extract SAD keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Design API schema and database"
            $keywords | Should Not BeNullOrEmpty
            $keywords.ContainsKey("SAD") | Should Be $true
        }
        
        It "Should extract OPS keywords" {
            $keywords = Extract-TaskKeywords -TaskDescription "Deploy to Kubernetes and configure Docker"
            $keywords | Should Not BeNullOrEmpty
            $keywords.ContainsKey("OPS") | Should Be $true
        }
    }
    
    Context "Decision Tree Evaluation" {
        It "Should identify primary agent" {
            $keywords = @{ "DEV" = 3; "QA" = 1 }
            $decisions = Evaluate-DecisionTree -TaskDescription "Implement feature" -Keywords $keywords
            
            $primary = $decisions | Where-Object { $_.Level -eq 1 }
            $primary.Agent | Should Be "DEV"
        }
        
        It "Should identify secondary agent" {
            $keywords = @{ "DEV" = 3; "QA" = 2 }
            $decisions = Evaluate-DecisionTree -TaskDescription "Implement and test feature" -Keywords $keywords
            
            $secondary = $decisions | Where-Object { $_.Level -eq 2 }
            $secondary.Agent | Should Be "QA"
        }
    }
    
    Context "Confidence Scoring" {
        It "Should calculate medium confidence for single agent" {
            $keywords = @{ "DEV" = 3 }
            $decisionTree = @(@{ Level = 1; Agent = "DEV" })
            $confidence = Calculate-ConfidenceScore -Keywords $keywords -DecisionTree $decisionTree
            
            $confidence.Confidence | Should Be "Medium"
        }
    }
    
    Context "Task Routing" {
        BeforeEach {
            Enable-AutoDelegation | Out-Null
            Set-ConfidenceThreshold -Threshold 60 | Out-Null
        }
        
        It "Should route development task to DEV" {
            $routing = Route-TaskToAgent -TaskDescription "Implement login feature with React"
            $routing.PrimaryAgent | Should Be "DEV"
        }
        
        It "Should route testing task to QA" {
            $routing = Route-TaskToAgent -TaskDescription "Write unit tests and E2E tests"
            $routing.PrimaryAgent | Should Be "QA"
        }
        
        It "Should return NoKeywordsFound for vague tasks" {
            $routing = Route-TaskToAgent -TaskDescription "Fix stuff"
            $routing.Status | Should Be "NoKeywordsFound"
        }
    }
}
