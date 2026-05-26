# json-validator.ps1
# Validador de JSON estricto y agnóstico para prevenir errores de sintaxis
# Funciona en Windows (PowerShell), Linux y macOS (bash/zsh)
# Uso: & json-validator.ps1 -JsonString '{"key": "value"}' -Context "mem_context call"

param(
    [Parameter(Mandatory=$true)]
    [string]$JsonString,
    
    [string]$Context = "unspecified",
    [switch]$ThrowOnError,
    [switch]$FixCommonErrors
)

$ErrorActionPreference = "Stop"

# ============================================================================
# STRICT JSON VALIDATION - Agnostic implementation
# ============================================================================

function Test-JsonValidStrict {
    param([string]$Json)
    
    # Check 1: Basic structure
    if ([string]::IsNullOrWhiteSpace($Json)) {
        return @{ Valid = $false; Error = "Empty JSON string"; Position = 0 }
    }
    
    $trimmed = $Json.Trim()
    
    # Check 2: Must start with { or [
    if (-not ($trimmed.StartsWith('{') -or $trimmed.StartsWith('['))) {
        return @{ Valid = $false; Error = "JSON must start with '{' or '['"; Position = 0 }
    }
    
    # Check 3: Must end with } or ]
    if (-not ($trimmed.EndsWith('}') -or $trimmed.EndsWith(']'))) {
        return @{ Valid = $false; Error = "JSON must end with '}' or ']'"; Position = $trimmed.Length - 1 }
    }
    
    # Check 4: Balance of braces, brackets, and quotes
    $inString = $false
    $escapeNext = $false
    $braceCount = 0
    $bracketCount = 0
    $charArray = $trimmed.ToCharArray()
    
    for ($i = 0; $i -lt $charArray.Length; $i++) {
        $char = $charArray[$i]
        
        if ($escapeNext) {
            $escapeNext = $false
            continue
        }
        
        if ($char -eq '\') {
            $escapeNext = $true
            continue
        }
        
        if ($char -eq '"' -and -not $escapeNext) {
            $inString = -not $inString
            continue
        }
        
        if (-not $inString) {
            switch ($char) {
                '{' { $braceCount++ }
                '}' { $braceCount-- }
                '[' { $bracketCount++ }
                ']' { $bracketCount-- }
            }
            
            if ($braceCount -lt 0) {
                return @{ Valid = $false; Error = "Unmatched closing brace '}'"; Position = $i }
            }
            if ($bracketCount -lt 0) {
                return @{ Valid = $false; Error = "Unmatched closing bracket ']'"; Position = $i }
            }
        }
    }
    
    if ($inString) {
        return @{ Valid = $false; Error = "Unterminated string"; Position = $trimmed.Length }
    }
    
    if ($braceCount -gt 0) {
        return @{ Valid = $false; Error = "Missing $braceCount closing brace(s) '}'"; Position = $trimmed.Length }
    }
    
    if ($braceCount -lt 0) {
        return @{ Valid = $false; Error = "Extra closing brace(s)"; Position = $trimmed.Length }
    }
    
    if ($bracketCount -gt 0) {
        return @{ Valid = $false; Error = "Missing $bracketCount closing bracket(s) ']'"; Position = $trimmed.Length }
    }
    
    if ($bracketCount -lt 0) {
        return @{ Valid = $false; Error = "Extra closing bracket(s)"; Position = $trimmed.Length }
    }
    
    # Check 5: Trailing commas (strict JSON doesn't allow)
    $noTrailing = $trimmed -replace ',(\s*[}\]])', '$1'
    if ($noTrailing -ne $trimmed) {
        return @{ Valid = $false; Error = "Trailing comma detected"; Position = ($trimmed.LastIndexOf(',') ) }
    }
    
    # Check 6: Try PowerShell validation as final check
    try {
        $null = $trimmed | ConvertFrom-Json -ErrorAction Stop
        return @{ Valid = $true; Error = $null; Position = 0 }
    } catch {
        return @{ Valid = $false; Error = $_.Exception.Message; Position = 0 }
    }
}

function Repair-CommonJsonErrors {
    param([string]$Json)
    
    $repaired = $Json
    $fixes = @()
    
    # Fix 1: Unterminated string at end - count actual quote characters
    $quoteCount = ($repaired.ToCharArray() | Where-Object { $_ -eq '"' } | Measure-Object).Count
    if ($quoteCount % 2 -ne 0) {
        $repaired = $repaired.TrimEnd() + '"'
        $fixes += "Added missing closing quote"
    }
    
    # Fix 2: Missing closing bracket (do this first for nested structures)
    $openBrackets = ($repaired -split '\[' | Measure-Object).Count - 1
    $closeBrackets = ($repaired -split '\]' | Measure-Object).Count - 1
    if ($openBrackets -gt $closeBrackets) {
        $repaired = $repaired.TrimEnd() + (']' * ($openBrackets - $closeBrackets))
        $fixes += "Added missing closing bracket(s)"
    }
    
    # Fix 3: Missing closing brace (after brackets to handle nested structures)
    $openBraces = ($repaired -split '\{' | Measure-Object).Count - 1
    $closeBraces = ($repaired -split '\}' | Measure-Object).Count - 1
    if ($openBraces -gt $closeBraces) {
        $repaired = $repaired + ('}' * ($openBraces - $closeBraces))
        $fixes += "Added missing closing brace(s)"
    }
    
    # Fix 4: Trailing comma before closing brace/bracket - iterative
    $originalBeforeTrailing = $repaired
    $maxIterations = 10
    $iteration = 0
    while ($iteration -lt $maxIterations) {
        $newRepaired = $repaired -replace ',(\s*[}\]])', '$1'
        if ($newRepaired -eq $repaired) { break }
        $repaired = $newRepaired
        $iteration++
    }
    if ($repaired -ne $originalBeforeTrailing) {
        $fixes += "Removed trailing comma(s)"
    }
    
    return @{ Json = $repaired; Fixes = $fixes }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

$result = Test-JsonValidStrict -Json $JsonString

if ($result.Valid) {
    return @{ 
        Valid = $true
        Original = $JsonString
        Repaired = $JsonString
        Fixes = @()
    } | ConvertTo-Json -Compress
}

# JSON is invalid
if ($FixCommonErrors) {
    $repairResult = Repair-CommonJsonErrors -Json $JsonString
    $revalidated = Test-JsonValidStrict -Json $repairResult.Json
    
    if ($revalidated.Valid) {
        Write-Warning "[JSON-VALIDATOR] Repaired JSON for: $Context"
        foreach ($fix in $repairResult.Fixes) {
            Write-Warning "  - $fix"
        }
        
        return @{
            Valid = $true
            Original = $JsonString
            Repaired = $repairResult.Json
            Fixes = $repairResult.Fixes
        } | ConvertTo-Json -Compress
    }
}

# Cannot repair
$errorMsg = "[JSON-VALIDATOR] Invalid JSON in: $Context`nError: $($result.Error)"

if ($ThrowOnError) {
    throw $errorMsg
}

return @{
    Valid = $false
    Original = $JsonString
    Error = $result.Error
    Fixes = @()
} | ConvertTo-Json -Compress
