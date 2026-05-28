# encryption-manager.tests.ps1
# Tests for AES-256 encryption/decryption, key generation, and validation

Describe "Encryption Manager (encryption-manager.ps1)" {
    BeforeAll {
        $script:scriptPath = Join-Path $PSScriptRoot "..\..\scripts\security\encryption-manager.ps1"
        $script:testKeyPath = Join-Path $ENV:TEMP "gv-test-key-$(Get-Random).key"
    }

    AfterAll {
        if (Test-Path $script:testKeyPath) { Remove-Item $script:testKeyPath -Force }
    }

    Context "Key Generation" {
        It "Should generate a valid AES-256 key" {
            $result = & $script:scriptPath -Action generate-key -KeyPath $script:testKeyPath 2>&1
            $LASTEXITCODE | Should -Be 0
            Test-Path $script:testKeyPath | Should -Be $true
        }

        It "Should generate a 32-byte (256-bit) key" {
            $keyBase64 = Get-Content $script:testKeyPath -Raw
            $key = [Convert]::FromBase64String($keyBase64.Trim())
            $key.Length | Should -Be 32
        }

        It "Should not overwrite existing key without warning" {
            $keyBefore = Get-Content $script:testKeyPath -Raw
            & $script:scriptPath -Action generate-key -KeyPath $script:testKeyPath 2>$null
            $keyAfter = Get-Content $script:testKeyPath -Raw
            $keyAfter | Should -Be $keyBefore
        }
    }

    Context "Encryption / Decryption" {
        It "Should encrypt and decrypt data correctly" {
            $original = "Sensitive test data: api_key=sk-test-12345"
            $encrypted = & $script:scriptPath -Action encrypt -Data $original -KeyPath $script:testKeyPath 2>&1 | Select-Object -Last 1
            $decrypted = & $script:scriptPath -Action decrypt -Data $encrypted -KeyPath $script:testKeyPath 2>&1 | Select-Object -Last 1
            $decrypted.Trim() | Should -Be $original
        }

        It "Should produce different ciphertext for same plaintext (random IV)" {
            $data = "hello world"
            $enc1 = & $script:scriptPath -Action encrypt -Data $data -KeyPath $script:testKeyPath 2>&1 | Select-Object -Last 1
            $enc2 = & $script:scriptPath -Action encrypt -Data $data -KeyPath $script:testKeyPath 2>&1 | Select-Object -Last 1
            $enc1 | Should -Not -Be $enc2
        }

        It "Should reject empty data" {
            $result = & $script:scriptPath -Action encrypt -Data "" -KeyPath $script:testKeyPath 2>&1
            $LASTEXITCODE | Should -Not -Be 0
        }
    }

    Context "Validation" {
        It "Should validate encryption setup" {
            $result = & $script:scriptPath -Action validate -KeyPath $script:testKeyPath 2>&1
            $LASTEXITCODE | Should -Be 0
        }
    }
}



