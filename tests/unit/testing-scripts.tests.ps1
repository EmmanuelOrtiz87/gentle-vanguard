# testing-scripts.tests.ps1
# Unit tests for new quality-script tools

Describe 'Testing Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:accessibility = Join-Path $script:root "scripts/testing/check-accessibility.ps1"
        $script:i18n = Join-Path $script:root "scripts/testing/check-i18n.ps1"
    }

    Context 'Accessibility Check Script' {
        It 'check-accessibility.ps1 exists' {
            Test-Path $script:accessibility | Should -Be $true
        }

        It 'check-accessibility.ps1 has parameter block' {
            $content = Get-Content $script:accessibility -Raw
            ($content -match 'param\(') | Should -Be $true
        }

        It 'check-accessibility.ps1 has WCAG rule definitions' {
            $content = Get-Content $script:accessibility -Raw
            ($content -match 'WCAG-1.1.1|WCAG-2.1.1|WCAG-1.4.3') | Should -Be $true
        }

        It 'check-accessibility.ps1 has severity levels' {
            $content = Get-Content $script:accessibility -Raw
            ($content -match 'critical|serious|moderate') | Should -Be $true
        }

        It 'check-accessibility.ps1 returns JSON with -Json flag' {
            $content = Get-Content $script:accessibility -Raw
            ($content -match 'ConvertTo-Json') | Should -Be $true
        }

        It 'check-accessibility.ps1 has try/catch error handling' {
            $content = Get-Content $script:accessibility -Raw
            ($content -match 'try\s*\{') | Should -Be $true
            ($content -match 'catch\s*\{') | Should -Be $true
        }
    }

    Context 'I18n Check Script' {
        It 'check-i18n.ps1 exists' {
            Test-Path $script:i18n | Should -Be $true
        }

        It 'check-i18n.ps1 has parameter block' {
            $content = Get-Content $script:i18n -Raw
            ($content -match 'param\(') | Should -Be $true
        }

        It 'check-i18n.ps1 supports multiple locales' {
            $content = Get-Content $script:i18n -Raw
            ($content -match 'LocalesDir|SourceLocale') | Should -Be $true
        }

        It 'check-i18n.ps1 has key extraction logic' {
            $content = Get-Content $script:i18n -Raw
            ($content -match 'Get-KeysFromJson|ConvertFrom-Json') | Should -Be $true
        }

        It 'check-i18n.ps1 returns JSON with -Json flag' {
            $content = Get-Content $script:i18n -Raw
            ($content -match 'ConvertTo-Json') | Should -Be $true
        }

        It 'check-i18n.ps1 has try/catch error handling' {
            $content = Get-Content $script:i18n -Raw
            ($content -match 'try\s*\{') | Should -Be $true
            ($content -match 'catch\s*\{') | Should -Be $true
        }
    }
}



