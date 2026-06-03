# json-validator.tests.ps1
# Tests for JSON validator

$ErrorActionPreference = "Stop"
$validatorScript = Join-Path $PSScriptRoot ".." "json-validator.ps1"

function Test-Case {
    param(
        [string]$Name,
        [string]$Json,
        [bool]$ExpectedValid,
        [string]$ExpectedRepaired = $null,
        [int]$ExpectedFixes = 0,
        [switch]$FixErrors
    )
    
    Write-Host "Test: $Name" -NoNewline
    
    try {
        $result = & $validatorScript -JsonString $Json -Context "test" -FixCommonErrors:$FixErrors 2>$null | ConvertFrom-Json
        
        if ($result.Valid -ne $ExpectedValid) {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "  Expected Valid=$ExpectedValid, got $($result.Valid)"
            return $false
        }
        
        if ($ExpectedRepaired -and $result.Repaired -ne $ExpectedRepaired) {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "  Expected repaired: $ExpectedRepaired"
            Write-Host "  Got: $($result.Repaired)"
            return $false
        }
        
        if ($result.Fixes.Count -ne $ExpectedFixes) {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "  Expected $ExpectedFixes fixes, got $($result.Fixes.Count)"
            return $false
        }
        
        Write-Host " [PASS]" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  $_"
        return $false
    }
}

Write-Host "=== JSON Validator Tests ===" -ForegroundColor Cyan
$passed = 0
$failed = 0

# Test 1: Valid JSON
if (Test-Case -Name "Valid JSON" -Json '{"key": "value"}' -ExpectedValid $true -ExpectedFixes 0) { $passed++ } else { $failed++ }

# Test 2: Unterminated string (the original bug) - 2 fixes: quote and brace
if (Test-Case -Name "Unterminated string" -Json '{"project": "workspace_gentle_vanguard' -ExpectedValid $true -ExpectedRepaired '{"project": "workspace_gentle_vanguard"}' -ExpectedFixes 2 -FixErrors) { $passed++ } else { $failed++ }

# Test 3: Missing closing brace
if (Test-Case -Name "Missing closing brace" -Json '{"key": "value"' -ExpectedValid $true -ExpectedRepaired '{"key": "value"}' -ExpectedFixes 1 -FixErrors) { $passed++ } else { $failed++ }

# Test 4: Missing closing bracket
if (Test-Case -Name "Missing closing bracket" -Json '["item1", "item2"' -ExpectedValid $true -ExpectedRepaired '["item1", "item2"]' -ExpectedFixes 1 -FixErrors) { $passed++ } else { $failed++ }

# Test 5: Trailing comma
if (Test-Case -Name "Trailing comma" -Json '{"key": "value",}' -ExpectedValid $true -ExpectedRepaired '{"key": "value"}' -ExpectedFixes 1 -FixErrors) { $passed++ } else { $failed++ }

# Test 6: Invalid without fix
if (Test-Case -Name "Invalid without fix" -Json '{"key": "value"' -ExpectedValid $false -ExpectedFixes 0) { $passed++ } else { $failed++ }

# Test 7: Complex nested - 2 fixes: bracket and brace
if (Test-Case -Name "Complex nested" -Json '{"a": {"b": [1, 2' -ExpectedValid $true -ExpectedRepaired '{"a": {"b": [1, 2]}}' -ExpectedFixes 2 -FixErrors) { $passed++ } else { $failed++ }

# Test 8: Empty object
if (Test-Case -Name "Empty object" -Json '{}' -ExpectedValid $true -ExpectedFixes 0) { $passed++ } else { $failed++ }

# Test 9: Empty array
if (Test-Case -Name "Empty array" -Json '[]' -ExpectedValid $true -ExpectedFixes 0) { $passed++ } else { $failed++ }

# Test 10: Multiple trailing commas
if (Test-Case -Name "Multiple trailing commas" -Json '{"a": 1, "b": 2,}' -ExpectedValid $true -ExpectedRepaired '{"a": 1, "b": 2}' -ExpectedFixes 1 -FixErrors) { $passed++ } else { $failed++ }

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if($failed -gt 0){'Red'}else{'Green'})

exit $failed
