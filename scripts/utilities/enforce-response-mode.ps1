<#
.SYNOPSIS
    Enforce Response Mode - Forces summarized responses to reduce token usage
    
.DESCRIPTION
    Enforces token-efficient response patterns:
    - Limits response verbosity
    - Removes redundant explanations
    - Enforces concise output format
    - Validates response compression
    
.PARAMETER Mode
    Enforcement mode: check, enforce, fix
    
.PARAMETER MaxResponseLines
    Maximum lines per response (default: 10)
    
.EXAMPLE
    .\tools\enforce-response-mode.ps1 -Mode check
    Checks if responses are within limits
    
.EXAMPLE
    .\tools\enforce-response-mode.ps1 -Mode enforce -MaxResponseLines 5
    Enforces maximum 5 lines per response
    
.NOTES
    Author: gentle-vanguard
    Version: 1.0
#>

param(
    [ValidateSet('check', 'enforce', 'fix')]
    [string]$Mode = 'check',
    
    [int]$MaxResponseLines = 10,
    
    [int]$MaxResponseChars = 500,
    
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message)
    Write-Host "[RESPONSE-MODE] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check current AGENTS.md for response instructions
function Test-ResponseInstructions {
    $agentsMdPath = ".\AGENTS.md"
    
    if (-not (Test-Path $agentsMdPath)) {
        Write-WarningMsg "AGENTS.md not found"
        return $false
    }
    
    $content = Get-Content $agentsMdPath -Raw
    
    $checks = @{
        hasConciseRule = ($content -match "concise|breve|summarized|resum")
        hasNoPreamble = ($content -match "no preamble|without preamble|avoid.*introduction")
        hasNoPostamble = ($content -match "no postamble|without.*conclusion|avoid.*conclusion")
        hasLineLimit = ($content -match "lines|lneas")
        hasTokenEfficiency = ($content -match "token.*efficien|context.*optim")
    }
    
    Write-Status "Checking AGENTS.md response instructions..."
    
    $allPass = $true
    foreach ($check in $checks.GetEnumerator()) {
        $status = if ($check.Value) { "[PASS]" } else { "[FAIL]" }
        $color = if ($check.Value) { "Green" } else { "Yellow" }
        Write-Host "  $status $($check.Key)" -ForegroundColor $color
        
        if (-not $check.Value) { $allPass = $false }
    }
    
    return $allPass
}

# Add response mode rules to AGENTS.md
function Add-ResponseModeRules {
    $agentsMdPath = ".\AGENTS.md"
    
    if (-not (Test-Path $agentsMdPath)) {
        Write-ErrorMsg "AGENTS.md not found"
        return $false
    }
    
    $responseRules = @"

## Response Mode (Token Efficiency)

### Concise Output Rule
You MUST answer concisely with fewer than $MaxResponseLines lines (not including tool use or code generation), unless user asks for detail.
Answer the user's question directly, without elaboration, explanation, or details.
One word answers are best. Avoid introductions, conclusions, and explanations.
You MUST avoid text before/after your response, such as "The answer is...", "Here is...", "Based on...".

### Prohibited Patterns (Automatic Token Waste)
- NO introductions: "I'll help you...", "Let me...", "Sure, I can..."
- NO conclusions: "I hope this helps...", "Let me know if...", "Feel free to..."
- NO explanations unless explicitly asked
- NO repeated context from user's question
- NO redundant confirmations: "Yes, I understand...", "The file is..."

### Output Format Rules
1. Direct answers only
2. Code blocks when needed (no surrounding text)
3. Bullet points for lists (no preamble)
4. Error messages: state the error only

### Enforcement
Response mode is MANDATORY. Violations detected by token-guard will trigger auto-compact.
"@
    
    $content = Get-Content $agentsMdPath -Raw
    
    if ($content -match "## Response Mode") {
        Write-WarningMsg "Response mode rules already present"
        return $true
    }
    
    # Add rules before the first ## section or at the end
    if ($content -match "(?m)^## ") {
        $insertPoint = $Matches[0].Index
        $newContent = $content.Insert($insertPoint, $responseRules + "`n")
    } else {
        $newContent = $content + $responseRules
    }
    
    $newContent | Set-Content $agentsMdPath -Encoding UTF8
    Write-Success "Response mode rules added to AGENTS.md"
    return $true
}

# Validate configuration files for errors/redundancy
function Test-ConfigurationValidity {
    Write-Status "Validating configuration files..."
    
        $configFiles = @(
            ".\tools\session-autostart.config.json",
            ".\tools\context-efficiency-config.json",
            ".\tools\token-guard-config.json"
        )
    
    $allValid = $true
    
    foreach ($configFile in $configFiles) {
        if (-not (Test-Path $configFile)) {
            Write-WarningMsg "Missing: $configFile"
            continue
        }
        
        try {
            $content = Get-Content $configFile | ConvertFrom-Json
            Write-Host "  [PASS] $configFile - Valid JSON" -ForegroundColor Green
            
            # Simple check: parse JSON and look for duplicate top-level keys
            $jsonText = Get-Content $configFile -Raw
            $topLevelKeys = @{}
            $hasDuplicates = $false
            
            # Match top-level keys (lines starting with "key": at low indent)
            $lines = $jsonText -split "`n"
            foreach ($line in $lines) {
                if ($line -match '^\s*"([^"]+)"\s*:') {
                    $key = $Matches[1]
                    $indent = ($line -replace '^(\s*).*', '$1').Length
                    
                    # Only check top-level (indent 0-2)
                    if ($indent -le 2) {
                        if ($topLevelKeys.ContainsKey($key)) {
                            $hasDuplicates = $true
                            break
                        }
                        $topLevelKeys[$key] = $true
                    }
                }
            }
            
            if ($hasDuplicates) {
                Write-Host "    [WARN] Potential duplicate top-level keys" -ForegroundColor Yellow
                $allValid = $false
            }
        }
        catch {
            Write-Host "  [FAIL] $configFile - Invalid JSON: $_" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    return $allValid
}

# Main execution
switch ($Mode) {
    'check' {
        Write-Status "Running response mode checks..."
        $responseOk = Test-ResponseInstructions
        $configOk = Test-ConfigurationValidity
        
        Write-Host ""
        Write-Host ("=" * 50) -ForegroundColor Cyan
        
        if ($responseOk -and $configOk) {
            Write-Success "All checks passed - Response mode properly configured"
            exit 0
        } else {
            Write-WarningMsg "Some checks failed - run with -Mode fix to auto-fix"
            exit 1
        }
    }
    
    'enforce' {
        Write-Status "Enforcing response mode..."
        Add-ResponseModeRules
        Write-Success "Response mode enforced"
        exit 0
    }
    
    'fix' {
        Write-Status "Fixing configuration issues..."
        
        Add-ResponseModeRules
        
        Write-Success "Configuration fixed"
        exit 0
    }
}

