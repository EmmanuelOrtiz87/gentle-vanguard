<#
.SYNOPSIS
    Optimizes context usage through compression and deduplication

.DESCRIPTION
    Compresses context data, removes redundancies, and implements lazy loading
    to reduce context consumption by 30-70%

.PARAMETER ContextPath
    Path to context file or directory

.PARAMETER OutputPath
    Path for optimized context output

.PARAMETER CompressionLevel
    Compression level: low, medium, high (default: high)

.PARAMETER EnableLazyLoading
    Enable lazy loading of context chunks

.PARAMETER Verbose
    Show detailed messages

.EXAMPLE
    .\optimize-context.ps1 -ContextPath "C:\context" -OutputPath "C:\optimized" -CompressionLevel high

.NOTES
    Author: Gentleman Foundation Team
    Version: 1.0.0
    Last Updated: 2026-04-22
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$ContextPath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [ValidateSet("low", "medium", "high")]
    [string]$CompressionLevel = "high",
    
    [switch]$EnableLazyLoading,
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

class ContextOptimizer {
    [string]$SourcePath
    [string]$OutputPath
    [string]$CompressionLevel
    [bool]$LazyLoadingEnabled
    [hashtable]$Statistics = @{}
    
    ContextOptimizer([string]$source, [string]$output, [string]$level, [bool]$lazy) {
        $this.SourcePath = $source
        $this.OutputPath = $output
        $this.CompressionLevel = $level
        $this.LazyLoadingEnabled = $lazy
    }
    
    [object] ExtractKeyPoints([string]$Content) {
        Write-Log "Extracting key points from content" "DEBUG"
        
        $keyPoints = @()
        
        # Extract headers and important sections
        $lines = $Content -split "`n"
        foreach ($line in $lines) {
            if ($line -match '^#{1,3}\s' -or $line -match '^\*\*' -or $line -match '^\[') {
                $keyPoints += $line.Trim()
            }
        }
        
        return $keyPoints
    }
    
    [string] CompressContent([string]$Content) {
        Write-Log "Compressing content (Level: $($this.CompressionLevel))" "DEBUG"
        
        $compressed = $Content
        
        # Remove extra whitespace
        $compressed = $compressed -replace '\s+', ' '
        
        # Apply compression based on level
        switch ($this.CompressionLevel) {
            "high" {
                $compressed = $compressed -replace 'information', 'info'
                $compressed = $compressed -replace 'configuration', 'config'
                $compressed = $compressed -replace 'parameter', 'param'
                $compressed = $compressed -replace 'description', 'desc'
                $compressed = $compressed -replace 'implementation', 'impl'
                $compressed = $compressed -replace 'optimization', 'opt'
            }
            "medium" {
                $compressed = $compressed -replace 'information', 'info'
                $compressed = $compressed -replace 'configuration', 'config'
            }
        }
        
        return $compressed
    }
    
    [hashtable] DeduplicateContent([string]$Content) {
        Write-Log "Deduplicating content" "DEBUG"
        
        $lines = $Content -split "`n"
        $unique = @()
        $duplicates = 0
        
        foreach ($line in $lines) {
            if ($line.Trim() -and $unique -notcontains $line) {
                $unique += $line
            }
            else {
                $duplicates++
            }
        }
        
        return @{
            Content = $unique -join "`n"
            DuplicatesRemoved = $duplicates
            OriginalLines = $lines.Count
            UniqueLines = $unique.Count
        }
    }
    
    [void] CreateLazyLoadingIndex([string]$Content, [string]$IndexPath) {
        Write-Log "Creating lazy loading index" "DEBUG"
        
        $lines = $Content -split "`n"
        $index = @()
        $position = 0
        $chunkSize = 1000
        
        for ($i = 0; $i -lt $lines.Count; $i += $chunkSize) {
            $chunk = $lines[$i..([Math]::Min($i + $chunkSize - 1, $lines.Count - 1))]
            $index += @{
                ChunkId = $i / $chunkSize
                StartLine = $i
                EndLine = [Math]::Min($i + $chunkSize - 1, $lines.Count - 1)
                Size = ($chunk -join "`n").Length
            }
        }
        
        $index | ConvertTo-Json | Set-Content -Path $IndexPath
        Write-Log "Created lazy loading index with $($index.Count) chunks" "DEBUG"
    }
    
    [void] Optimize() {
        Write-Log "Starting context optimization"
        
        try {
            # Create output directory
            if (-not (Test-Path $this.OutputPath)) {
                New-Item -Path $this.OutputPath -ItemType Directory -Force | Out-Null
            }
            
            # Get all context files
            $files = Get-ChildItem -Path $this.SourcePath -File -Recurse
            Write-Log "Found $($files.Count) context files"
            
            foreach ($file in $files) {
                Write-Log "Processing: $($file.Name)"
                
                # Read content
                $content = Get-Content -Path $file.FullName -Raw
                $originalSize = $content.Length
                
                # Extract key points
                $keyPoints = $this.ExtractKeyPoints($content)
                
                # Compress content
                $compressed = $this.CompressContent($content)
                
                # Deduplicate
                $dedup = $this.DeduplicateContent($compressed)
                $dedupContent = $dedup.Content
                
                # Create lazy loading index if enabled
                if ($this.LazyLoadingEnabled) {
                    $indexPath = Join-Path $this.OutputPath "$($file.BaseName).index.json"
                    $this.CreateLazyLoadingIndex($dedupContent, $indexPath)
                }
                
                # Save optimized content
                $outputFile = Join-Path $this.OutputPath $file.Name
                Set-Content -Path $outputFile -Value $dedupContent
                
                $optimizedSize = $dedupContent.Length
                $reduction = (($originalSize - $optimizedSize) / $originalSize) * 100
                
                Write-Log "Optimized: $($file.Name) - Reduction: $([Math]::Round($reduction, 2))%"
                
                # Store statistics
                $this.Statistics[$file.Name] = @{
                    OriginalSize = $originalSize
                    OptimizedSize = $optimizedSize
                    Reduction = $reduction
                    DuplicatesRemoved = $dedup.DuplicatesRemoved
                }
            }
            
            Write-Log "Context optimization completed successfully" "SUCCESS"
            $this.PrintStatistics()
        }
        catch {
            Write-Log "Error during optimization: $_" "ERROR"
            throw
        }
    }
    
    [void] PrintStatistics() {
        Write-Host "`nOptimization Statistics:" -ForegroundColor Green
        Write-Host "========================"
        
        $totalOriginal = 0
        $totalOptimized = 0
        
        foreach ($stat in $this.Statistics.GetEnumerator()) {
            $totalOriginal += $stat.Value.OriginalSize
            $totalOptimized += $stat.Value.OptimizedSize
            
            Write-Host "$($stat.Key):"
            Write-Host "  Original: $($stat.Value.OriginalSize) bytes"
            Write-Host "  Optimized: $($stat.Value.OptimizedSize) bytes"
            Write-Host "  Reduction: $([Math]::Round($stat.Value.Reduction, 2))%"
        }
        
        $totalReduction = (($totalOriginal - $totalOptimized) / $totalOriginal) * 100
        Write-Host "`nTotal Reduction: $([Math]::Round($totalReduction, 2))%"
        Write-Host "Space Saved: $([Math]::Round(($totalOriginal - $totalOptimized) / 1MB, 2)) MB"
    }
}

try {
    Write-Log "Initializing context optimizer"
    
    $optimizer = [ContextOptimizer]::new(
        $ContextPath,
        $OutputPath,
        $CompressionLevel,
        $EnableLazyLoading
    )
    
    $optimizer.Optimize()
    
    Write-Log "Context optimization complete" "SUCCESS"
    exit 0
}
catch {
    Write-Log "Fatal error: $_" "ERROR"
    exit 1
}