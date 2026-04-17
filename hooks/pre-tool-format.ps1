# pre-tool-format.ps1
# PreToolUse Hook: Auto-format files before AI agent access
# Runs linter/formatter on saved files to avoid wasting tokens on formatting

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = $PSScriptRoot }

$projectRoot = if (Test-Path ".git") { (Get-Location) } else { $null }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[PreTool-Format] $Message" -ForegroundColor $color
}

function Get-FileFormatter {
    param([string]$Path)
    
    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    $filename = [System.IO.Path]::GetFileName($Path)
    $dir = [System.IO.Path]::GetDirectoryName($Path)
    
    $formatters = @{
        ".ps1" = @{
            name = "PowerShell"
            formats = @(
                @{ cmd = "pwsh"; args = @("-NoProfile", "-Command", "Get-Content '$Path' | Format-Table -AutoSize | Out-String -Width 500 | Set-Content '$Path' -Encoding UTF8"); ext = ".ps1" }
            )
        }
        ".js" = @{
            name = "JavaScript"
            checkFiles = @("package.json", "prettier.config.*", ".prettierrc*")
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".js" }
                @{ cmd = "npx"; args = @("eslint", "--fix", $Path); ext = ".js" }
            )
        }
        ".ts" = @{
            name = "TypeScript"
            checkFiles = @("package.json", "tsconfig.json", "prettier.config.*")
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".ts" }
                @{ cmd = "npx"; args = @("eslint", "--fix", $Path); ext = ".ts" }
            )
        }
        ".tsx" = @{
            name = "React/TSX"
            checkFiles = @("package.json", "tsconfig.json")
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".tsx" }
            )
        }
        ".jsx" = @{
            name = "React/JSX"
            checkFiles = @("package.json")
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".jsx" }
            )
        }
        ".py" = @{
            name = "Python"
            checkFiles = @("setup.py", "pyproject.toml", "requirements.txt", ".python-version")
            formats = @(
                @{ cmd = "python"; args = @("-m", "black", $Path); ext = ".py" }
                @{ cmd = "python"; args = @("-m", "ruff", "--fix", $Path); ext = ".py" }
                @{ cmd = "python"; args = @("-m", "autopep8", "--in-place", "--aggressive", $Path); ext = ".py" }
            )
        }
        ".go" = @{
            name = "Go"
            checkFiles = @("go.mod")
            formats = @(
                @{ cmd = "gofmt"; args = @("-w", $Path); ext = ".go" }
                @{ cmd = "go"; args = @("fmt", $Path); ext = ".go" }
            )
        }
        ".rs" = @{
            name = "Rust"
            checkFiles = @("Cargo.toml")
            formats = @(
                @{ cmd = "rustfmt"; args = @($Path); ext = ".rs" }
            )
        }
        ".java" = @{
            name = "Java"
            checkFiles = @("pom.xml", "build.gradle", "gradlew")
            formats = @(
                @{ cmd = "google-java-format"; args = @("-i", $Path); ext = ".java" }
            )
        }
        ".cs" = @{
            name = "C#"
            checkFiles = @("*.sln", "*.csproj")
            formats = @(
                @{ cmd = "dotnet"; args = @("format", $Path); ext = ".cs" }
            )
        }
        ".json" = @{
            name = "JSON"
            formats = @(
                @{ cmd = "pwsh"; args = @("-NoProfile", "-Command", "Get-Content '$Path' | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Set-Content '$Path' -Encoding UTF8"); ext = ".json" }
            )
        }
        ".md" = @{
            name = "Markdown"
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".md" }
            )
        }
        ".yaml" = @{
            name = "YAML"
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".yaml" }
            )
        }
        ".yml" = @{
            name = "YAML"
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".yml" }
            )
        }
        ".css" = @{
            name = "CSS"
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".css" }
                @{ cmd = "npx"; args = @("stylelint", "--fix", $Path); ext = ".css" }
            )
        }
        ".html" = @{
            name = "HTML"
            formats = @(
                @{ cmd = "npx"; args = @("prettier", "--write", $Path); ext = ".html" }
            )
        }
        ".sql" = @{
            name = "SQL"
            formats = @(
                @{ cmd = "npx"; args = @("sqlformat", "--write", $Path); ext = ".sql" }
            )
        }
        ".sh" = @{
            name = "Shell"
            formats = @(
                @{ cmd = "shfmt"; args = @("-w", $Path); ext = ".sh" }
            )
        }
    }
    
    if ($formatters.ContainsKey($ext)) {
        $formatter = $formatters[$ext]
        
        if ($formatter.checkFiles) {
            $hasConfig = $false
            foreach ($check in $formatter.checkFiles) {
                if ($check -match '\*') {
                    $matches = Get-ChildItem -Path (Split-Path $Path) -Filter $check -ErrorAction SilentlyContinue
                    if ($matches) { $hasConfig = $true; break }
                } elseif (Test-Path $check) {
                    $hasConfig = $true; break
                }
            }
            if (-not $hasConfig) {
                Write-Log "Skipping $Path - no formatter config found" "WARN"
                return $null
            }
        }
        
        return $formatter
    }
    
    return $null
}

function Invoke-Formatter {
    param(
        [string]$Path,
        [hashtable]$Formatter
    )
    
    if ($DryRun) {
        Write-Log "[DRY-RUN] Would format: $Path with $($Formatter.name)" "INFO"
        return $true
    }
    
    $success = $false
    $applied = $false
    
    foreach ($formatCmd in $Formatter.formats) {
        try {
            $cmd = Get-Command $formatCmd.cmd -ErrorAction SilentlyContinue
            if (-not $cmd) {
                continue
            }
            
            Write-Log "Applying $($Formatter.name) with $($formatCmd.cmd)..." "INFO" -ForegroundColor Gray
            
            $cmdArgs = $formatCmd.args
            $output = & $formatCmd.cmd @cmdArgs 2>&1
            
            if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
                $success = $true
                $applied = $true
                Write-Log "Formatted: $([System.IO.Path]::GetFileName($Path))" "SUCCESS"
            }
        }
        catch {
            if ($Detailed) {
                Write-Log "Formatter failed: $_" "WARN"
            }
        }
    }
    
    return $applied
}

if (-not $FilePath) {
    Write-Log "No file path provided" "ERROR"
    exit 1
}

if (-not (Test-Path $FilePath)) {
    Write-Log "File not found: $FilePath" "WARN"
    exit 0
}

$originalContent = Get-Content $FilePath -Raw
$formatter = Get-FileFormatter -Path $FilePath

if (-not $formatter) {
    Write-Log "No formatter for: $FilePath" "INFO"
    exit 0
}

Write-Log "Processing: $FilePath" "INFO"

$wasFormatted = Invoke-Formatter -Path $FilePath -Formatter $formatter

if ($wasFormatted) {
    $newContent = Get-Content $FilePath -Raw
    
    if ($originalContent -ne $newContent) {
        Write-Log "Format applied: $([System.IO.Path]::GetFileName($FilePath))" "SUCCESS"
        
        $originalLines = ($originalContent -split "`n").Count
        $newLines = ($newContent -split "`n").Count
        
        if ($Detailed) {
            Write-Log "Lines: $originalLines -> $newLines" "INFO"
        }
    }
}

exit 0
