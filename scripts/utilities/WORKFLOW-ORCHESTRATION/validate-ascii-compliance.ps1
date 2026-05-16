<#
.SYNOPSIS
Validate that all scripts contain only ASCII-safe characters

.DESCRIPTION
Ensures complete compatibility across all environments:
- No emojis
- No Unicode characters
- No special box-drawing characters
- Only ASCII 0-127 allowed

.PARAMETER Recursive
Validate all scripts in directory

.EXAMPLE
.\validate-ascii-compliance.ps1 -Recursive
#>

param(
    [switch]$Recursive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Test-ASCIICompliance {
    param([string]$FilePath)
    
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $nonASCII = @()
        
        for ($i = 0; $i -lt $content.Length; $i++) {
            $char = $content[$i]
            $code = [int][char]$char
            
            if ($code -gt 127) {
                $nonASCII += @{
                    char = $char
                    code = $code
                    position = $i
                }
            }
        }
        
        if ($nonASCII.Count -gt 0) {
            Write-Host "[FAIL] Non-ASCII characters found in: $FilePath"
            foreach ($item in $nonASCII | Select-Object -First 5) {
                Write-Host "  - Character code $($item.code) at position $($item.position)"
            }
            return $false
        }
        else {
            Write-Host "[OK] ASCII compliant: $FilePath"
            return $true
        }
    }
    catch {
        Write-Host "[ERROR] Error validating $FilePath : $_"
        return $false
    }
}

# Main logic
if ($Recursive) {
    $scripts = Get-ChildItem -Path "gentle-vanguard\\scripts\utilities" -Filter "*.ps1" -Recurse
    $compliant = 0
    $nonCompliant = 0
    
    foreach ($script in $scripts) {
        if (Test-ASCIICompliance -FilePath $script.FullName) {
            $compliant++
        }
        else {
            $nonCompliant++
        }
    }
    
    Write-Host ""
    Write-Host "ASCII Compliance Report:"
    Write-Host "  Compliant: $compliant"
    Write-Host "  Non-Compliant: $nonCompliant"
    
    if ($nonCompliant -eq 0) {
        Write-Host "[OK] All scripts are ASCII compliant"
        exit 0
    }
    else {
        Write-Host "[FAIL] Some scripts contain non-ASCII characters"
        exit 1
    }
}
