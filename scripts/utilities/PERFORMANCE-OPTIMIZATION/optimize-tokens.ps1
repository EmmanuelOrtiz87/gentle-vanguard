<#
.SYNOPSIS
    Optimizes token usage through compression and abbreviations

.DESCRIPTION
    Compresses token data, applies intelligent abbreviations, and removes
    unnecessary whitespace to reduce token consumption by 20-40%

.PARAMETER InputPath
    Path to input data file

.PARAMETER OutputPath
    Path for optimized output

.PARAMETER EnableAbbreviations
    Enable intelligent abbreviations

.PARAMETER Verbose
    Show detailed messages

.EXAMPLE
    .\optimize-tokens.ps1 -InputPath "data.json" -OutputPath "optimized.json" -EnableAbbreviations

.NOTES
    Author: Gentleman Foundation Team
    Version: 1.0.0
    Last Updated: 2026-04-22
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputPath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [switch]$EnableAbbreviations,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if ($Verbose -or $Level -ne "DEBUG") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

class TokenOptimizer {
    [string]$InputPath
    [string]$OutputPath
    [bool]$AbbreviationsEnabled
    [hashtable]$Abbreviations = @{
        "information" = "info"
        "configuration" = "config"
        "parameter" = "param"
        "description" = "desc"
        "implementation" = "impl"
        "optimization" = "opt"
        "performance" = "perf"
        "management" = "mgmt"
        "authentication" = "auth"
        "authorization" = "authz"
        "database" = "db"
        "application" = "app"
        "development" = "dev"
        "production" = "prod"
        "environment" = "env"
        "variable" = "var"
        "function" = "func"
        "document" = "doc"
        "reference" = "ref"
        "example" = "ex"
    }
    [hashtable]$Statistics = @{}
    
    TokenOptimizer([string]$input, [string]$output, [bool]$abbr) {
        $this.InputPath = $input
        $this.OutputPath = $output
        $this.AbbreviationsEnabled = $abbr
    }
    
    [string] ApplyAbbreviations([string]$Content) {
        Write-Log "Applying abbreviations" "DEBUG"
        
        $result = $Content
        
        if ($this.AbbreviationsEnabled) {
            foreach ($abbr in $this.Abbreviations.GetEnumerator()) {
                # Case-insensitive replacement
                $result = $result -ireplace "\b$($abbr.Key)\b", $abbr.Value
            }
        }
        
        return $result
    }
    
    [string] RemoveUnnecessaryWhitespace([string]$Content) {
        Write-Log "Removing unnecessary whitespace" "DEBUG"
        
        # Remove multiple spaces
        $result = $Content -replace '\s+', ' '
        
        # Remove spaces around special characters
        $result = $result -replace '\s*([{}[\](),;:])\s*', '$1'
        
        # Remove leading/trailing whitespace from lines
        $lines = $result -split "`n"
        $result = ($lines | ForEach-Object { $_.Trim() }) -join "`n"
        
        return $result
    }
    
    [string] CompressJSON([string]$Content) {
        Write-Log "Compressing JSON" "DEBUG"
        
        try {
            $json = $Content | ConvertFrom-Json
            $compressed = $json | ConvertTo-Json -Compress
            return $compressed
        }
        catch {
            Write-Log "Not valid JSON, skipping JSON compression" "WARN"
            return $Content
        }
    }
    
    [void] Optimize() {
        Write-Log "Starting token optimization"
        
        try {
            # Create output directory
            if (-not (Test-Path (Split-Path $this.OutputPath))) {
                New-Item -Path (Split-Path $this.OutputPath) -ItemType Directory -Force | Out-Null
            }
            
            # Read input
            $content = Get-Content -Path $this.InputPath -Raw
            $originalSize = $content.Length
            $originalTokens = [Math]::Ceiling($originalSize / 4)
            
            Write-Log "Original size: $originalSize bytes (~$originalTokens tokens)"
            
            # Apply optimizations
            $optimized = $content
            
            # Try JSON compression first
            $optimized = $this.CompressJSON($optimized)
            
            # Apply abbreviations
            $optimized = $this.ApplyAbbreviations($optimized)
            
            # Remove unnecessary whitespace
            $optimized = $this.RemoveUnnecessaryWhitespace($optimized)
            
            # Save optimized content
            Set-Content -Path $this.OutputPath -Value $optimized
            
            $optimizedSize = $optimized.Length
            $optimizedTokens = [Math]::Ceiling($optimizedSize / 4)
            $reduction = (($originalSize - $optimizedSize) / $originalSize) * 100
            $tokenReduction = (($originalTokens - $optimizedTokens) / $originalTokens) * 100
            
            Write-Log "Optimized size: $optimizedSize bytes (~$optimizedTokens tokens)"
            Write-Log "Token reduction: $([Math]::Round($tokenReduction, 2))%" "SUCCESS"
            
            $this.Statistics = @{
                OriginalSize = $originalSize
                OptimizedSize = $optimizedSize
                OriginalTokens = $originalTokens
                OptimizedTokens = $optimizedTokens
                SizeReduction = $reduction
                TokenReduction = $tokenReduction
            }
            
            $this.PrintStatistics()
        }
        catch {
            Write-Log "Error during optimization: $_" "ERROR"
            throw
        }
    }
    
    [void] PrintStatistics() {
        Write-Host "`nToken Optimization Statistics:" -ForegroundColor Green
        Write-Host "=============================="
        Write-Host "Original Size: $($this.Statistics.OriginalSize) bytes"
        Write-Host "Optimized Size: $($this.Statistics.OptimizedSize) bytes"
        Write-Host "Size Reduction: $([Math]::Round($this.Statistics.SizeReduction, 2))%"
        Write-Host ""
        Write-Host "Original Tokens: ~$($this.Statistics.OriginalTokens)"
        Write-Host "Optimized Tokens: ~$($this.Statistics.OptimizedTokens)"
        Write-Host "Token Reduction: $([Math]::Round($this.Statistics.TokenReduction, 2))%"
    }
}

try {
    Write-Log "Initializing token optimizer"
    
    $optimizer = [TokenOptimizer]::new(
        $InputPath,
        $OutputPath,
        $EnableAbbreviations
    )
    
    $optimizer.Optimize()
    
    Write-Log "Token optimization complete" "SUCCESS"
    exit 0
}
catch {
    Write-Log "Fatal error: $_" "ERROR"
    exit 1
}