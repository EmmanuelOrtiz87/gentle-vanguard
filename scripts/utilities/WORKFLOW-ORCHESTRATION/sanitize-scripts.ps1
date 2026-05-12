<#
.SYNOPSIS
Sanitize PowerShell scripts by removing emojis and special characters

.DESCRIPTION
Removes problematic characters from scripts:
- Emojis ([OK] [FAIL] [WARN] [AUTO])
- Special Unicode characters
- Replaces with safe ASCII equivalents

.PARAMETER ScriptPath
Path to script to sanitize

.PARAMETER Recursive
Sanitize all scripts in directory

.EXAMPLE
.\sanitize-scripts.ps1 -Recursive
#>

param(
    [string]$ScriptPath,
    [switch]$Recursive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Mapping of emojis to safe text
$replacements = @{
    '[OK]' = '[OK]'
    '[FAIL]' = '[FAIL]'
    '[WARN]' = '[WARN]'
    '[AUTO]' = '[AUTO]'
    '=' = '='
    '|' = '|'
    '+' = '+'
    '+' = '+'
    '+' = '+'
    '+' = '+'
    '+' = '+'
    '+' = '+'
    '+' = '+'
    '+' = '+'
    '+' = '+'
}

function Sanitize-File {
    param([string]$FilePath)
    
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $originalContent = $content
        
        foreach ($emoji in $replacements.Keys) {
            $content = $content -replace [regex]::Escape($emoji), $replacements[$emoji]
        }
        
        if ($content -ne $originalContent) {
            Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
            Write-Host "[OK] Sanitized: $FilePath"
            return $true
        }
        else {
            Write-Host "[SKIP] No changes needed: $FilePath"
            return $false
        }
    }
    catch {
        Write-Host "[FAIL] Error sanitizing $FilePath : $_"
        return $false
    }
}

# Main logic
if ($Recursive) {
    $scripts = Get-ChildItem -Path "foundation\\scripts\utilities" -Filter "*.ps1" -Recurse
    $sanitized = 0
    
    foreach ($script in $scripts) {
        if (Sanitize-File -FilePath $script.FullName) {
            $sanitized++
        }
    }
    
    Write-Host ""
    Write-Host "Sanitization complete: $sanitized files modified"
}
elseif ($ScriptPath) {
    Sanitize-File -FilePath $ScriptPath
}
else {
    Write-Host "Usage: .\sanitize-scripts.ps1 -Recursive"
}