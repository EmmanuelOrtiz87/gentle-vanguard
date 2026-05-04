# Pre-commit hook to validate opencode.json
# Validates centralized configuration against JSON Schema
# Consult NORMATIVAS-ORQUESTADOR.md before allowing changes
#
# Reference: docs/reference/NORMATIVAS-ORQUESTADOR.md

param([switch]$Verbose = $false)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $colors = @{ Success = "Green"; Error = "Red"; Warning = "Yellow"; Info = "Cyan" }
    $color = if ($colors.ContainsKey($Level)) { $colors[$Level] } else { "White" }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-JsonSchema {
    param([string]$JsonPath, [string]$SchemaPath)
    
    if (-not (Test-Path $JsonPath)) {
        Write-Log "File not found: $JsonPath" "Error"
        return $false
    }
    
    if (-not (Test-Path $SchemaPath)) {
        Write-Log "Schema not found: $SchemaPath" "Error"
        return $false
    }
    
    try {
        $json = Get-Content $JsonPath -Raw | ConvertFrom-Json
        $schema = Get-Content $SchemaPath -Raw | ConvertFrom-Json
        
        # Validate required fields
        $requiredFields = $schema.required
        foreach ($field in $requiredFields) {
            if (-not ($json.PSObject.Properties.Name -contains $field)) {
                Write-Log "Required field missing: $field" "Error"
                return $false
            }
        }
        
        # Validate provider.anthropic
        if (-not $json.provider.anthropic) {
            Write-Log "provider.anthropic is required" "Error"
            return $false
        }
        
        if (-not $json.provider.anthropic.enabled -or -not $json.provider.anthropic.model) {
            Write-Log "provider.anthropic.enabled and model are required" "Error"
            return $false
        }
        
        Write-Log "JSON schema validation passed" "Success"
        return $true
    }
    catch {
        Write-Log "Invalid JSON: $_" "Error"
        return $false
    }
}

function Test-Normativas {
    param([string]$JsonPath)
    
    $normativasPath = Join-Path $GitRoot "docs/reference/NORMATIVAS-ORQUESTADOR.md"
    if (-not (Test-Path $normativasPath)) {
        Write-Log "NORMATIVAS-ORQUESTADOR.md not found, skipping" "Warning"
        return $true
    }
    
    try {
        $json = Get-Content $JsonPath -Raw | ConvertFrom-Json
        $normativas = Get-Content $normativasPath -Raw
        
        # Check required sections
        $requiredSections = @("Identity", "Purpose", "Scope", "Decisions")
        foreach ($section in $requiredSections) {
            if ($normativas -notmatch "##\s*$section") {
                Write-Log "Missing section in NORMATIVAS: $section" "Warning"
            }
        }
        
        Write-Log "Normativas check completed" "Success"
        return $true
    }
    catch {
        Write-Log "Error checking normativas: $_" "Warning"
        return $true
    }
}

# Main
$GitRoot = git rev-parse --show-toplevel 2>$null
if (-not $GitRoot) {
    Write-Log "Not in a git repository" "Warning"
    exit 0
}

$StagedFiles = git diff --cached --name-only --diff-filter=ACM 2>$null
$configFiles = $StagedFiles | Where-Object { $_ -match '\.json$' -and $_ -match '(config|opencode)' }

if ($configFiles.Count -eq 0) {
    Write-Log "No configuration changes" "Success"
    exit 0
}

Write-Log "Configuration files to validate: $($configFiles.Count)" "Info"

$hasErrors = $false

foreach ($file in $configFiles) {
    Write-Log "Validating: $file" "Info"
    
    # Validate JSON
    try {
        $content = Get-Content $file -Raw
        $json = $content | ConvertFrom-Json
        Write-Log "  Valid JSON" "Success"
    }
    catch {
        Write-Log "  Invalid JSON: $_" "Error"
        $hasErrors = $true
        continue
    }
    
    # Validate against schema
    $schemaFile = $file -replace '\.json$', '.schema.json'
    if (Test-Path $schemaFile) {
        Write-Log "  Validating against schema..." "Info"
        if (-not (Test-JsonSchema -JsonPath $file -SchemaPath $schemaFile)) {
            $hasErrors = $true
        }
    }
    
    # Validate against normativas
    if ($file -match 'opencode|config') {
        Write-Log "  Checking normativas..." "Info"
        if (-not (Test-Normativas -JsonPath $file)) {
            $hasErrors = $true
        }
    }
}

if ($hasErrors) {
    Write-Log "Configuration validation failed" "Error"
    exit 1
}

Write-Log "All configuration validations passed" "Success"
exit 0