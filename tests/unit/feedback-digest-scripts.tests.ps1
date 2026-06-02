# feedback-digest-scripts.tests.ps1
# Unit tests for FEEDBACK and DIGEST utility scripts

Describe 'FEEDBACK Scripts' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:feedbackDir = Join-Path $script:root "scripts/utilities/FEEDBACK"
    }

    Context 'feedback-collector.ps1' {
        It 'exists and is non-empty' {
            $f = Join-Path $script:feedbackDir "feedback-collector.ps1"
            Test-Path $f | Should -Be $true
            (Get-Item $f).Length | Should -BeGreaterThan 0
        }

        It 'has valid PowerShell syntax' {
            $f = Join-Path $script:feedbackDir "feedback-collector.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0
        }

        It 'defines Rate parameter with ValidateRange 1-5' {
            $f = Join-Path $script:feedbackDir "feedback-collector.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'ValidateRange\(1,5\)') | Should -Be $true
        }

        It 'defines Action parameter with ValidateSet' {
            $f = Join-Path $script:feedbackDir "feedback-collector.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'ValidateSet\(''healing''') | Should -Be $true
        }

        It 'has Status switch parameter' {
            $f = Join-Path $script:feedbackDir "feedback-collector.ps1"
            $content = Get-Content $f -Raw
            ($content -match '\[switch\]\$Status') | Should -Be $true
        }
    }

    Context 'feedback-analyzer.ps1' {
        It 'exists and is non-empty' {
            $f = Join-Path $script:feedbackDir "feedback-analyzer.ps1"
            Test-Path $f | Should -Be $true
            (Get-Item $f).Length | Should -BeGreaterThan 0
        }

        It 'has valid PowerShell syntax' {
            $f = Join-Path $script:feedbackDir "feedback-analyzer.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0
        }

        It 'defines AutoPropose switch parameter' {
            $f = Join-Path $script:feedbackDir "feedback-analyzer.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'AutoPropose') | Should -Be $true
        }
    }
}

Describe 'DIGEST Scripts' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:digestDir = Join-Path $script:root "scripts/utilities/DIGEST"
    }

    Context 'digest-generator.ps1' {
        It 'exists and is non-empty' {
            $f = Join-Path $script:digestDir "digest-generator.ps1"
            Test-Path $f | Should -Be $true
            (Get-Item $f).Length | Should -BeGreaterThan 0
        }

        It 'has valid PowerShell syntax' {
            $f = Join-Path $script:digestDir "digest-generator.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0
        }

        It 'defines Mode parameter with ValidateSet daily|status|weekly' {
            $f = Join-Path $script:digestDir "digest-generator.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'ValidateSet\(''daily''') | Should -Be $true
        }

        It 'calculates health, feedback and proposals' {
            $f = Join-Path $script:digestDir "digest-generator.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'healthStatus') | Should -Be $true
            ($content -match 'feedbackEntries') | Should -Be $true
            ($content -match 'pendingProposals') | Should -Be $true
        }
    }
}
