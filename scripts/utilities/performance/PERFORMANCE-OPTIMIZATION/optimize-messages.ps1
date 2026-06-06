<#
.SYNOPSIS
    Optimizes message transmission through compression and batching

.DESCRIPTION
    Applies compression algorithms (GZIP, Deflate) and implements message batching
    to reduce message size by 15-60%

.PARAMETER InputMessage
    Path to input message file

.PARAMETER OutputPath
    Path for optimized output

.PARAMETER CompressionMethod
    Compression method: gzip, deflate (default: gzip)

.PARAMETER EnableBatching
    Enable message batching

.PARAMETER BatchSize
    Number of messages per batch (default: 10)

.PARAMETER Verbose
    Show detailed messages

.EXAMPLE
    .\optimize-messages.ps1 -InputMessage "message.json" -OutputPath "optimized.json" -CompressionMethod gzip -EnableBatching

.NOTES
    Author: Gentle-Vanguard Team
    Version: 1.0.0
    Last Updated: 2026-04-22
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputMessage,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [ValidateSet("gzip", "deflate")]
    [string]$CompressionMethod = "gzip",
    
    [switch]$EnableBatching,
    [int]$BatchSize = 10,
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

class MessageOptimizer {
    [string]$InputPath
    [string]$OutputPath
    [string]$CompressionMethod
    [bool]$BatchingEnabled
    [int]$BatchSize
    [hashtable]$Statistics = @{}
    
    MessageOptimizer([string]$input, [string]$output, [string]$method, [bool]$batch, [int]$size) {
        $this.InputPath = $input
        $this.OutputPath = $output
        $this.CompressionMethod = $method
        $this.BatchingEnabled = $batch
        $this.BatchSize = $size
    }
    
    [byte[]] CompressData([byte[]]$Data) {
        Write-Log "Compressing data using $($this.CompressionMethod)" "DEBUG"
        
        $memStream = New-Object System.IO.MemoryStream
        $compressionType = if ($this.CompressionMethod -eq "gzip") {
            [System.IO.Compression.CompressionMode]::Compress
        } else {
            [System.IO.Compression.CompressionMode]::Compress
        }
        
        try {
            if ($this.CompressionMethod -eq "gzip") {
                $compStream = New-Object System.IO.Compression.GZipStream($memStream, $compressionType)
            } else {
                $compStream = New-Object System.IO.Compression.DeflateStream($memStream, $compressionType)
            }
            
            $compStream.Write($Data, 0, $Data.Length)
            $compStream.Close()
        } finally {
            $memStream.Close()
        }
        
        return $memStream.ToArray()
    }
            else {
                $deflateStream = New-Object System.IO.Compression.DeflateStream($memStream, [System.IO.Compression.CompressionMode]::Compress)
                $deflateStream.Write($Data, 0, $Data.Length)
                $deflateStream.Close()
            }
            
            return $memStream.ToArray()
        }
        finally {
            $memStream.Close()
        }
    }
    
    [object[]] BatchMessages([object[]]$Messages) {
        Write-Log "Batching messages (batch size: $($this.BatchSize))" "DEBUG"
        
        $batches = @()
        
        for ($i = 0; $i -lt $Messages.Count; $i += $this.BatchSize) {
            $batch = $Messages[$i..([Math]::Min($i + $this.BatchSize - 1, $Messages.Count - 1))]
            $batches += @{
                BatchId = [Math]::Floor($i / $this.BatchSize)
                Messages = $batch
                Count = $batch.Count
            }
        }
        
        return $batches
    }
    
    [void] Optimize() {
        Write-Log "Starting message optimization"
        
        try {
            # Create output directory
            if (-not (Test-Path (Split-Path $this.OutputPath))) {
                New-Item -Path (Split-Path $this.OutputPath) -ItemType Directory -Force | Out-Null
            }
            
            # Read input
            $content = Get-Content -Path $this.InputPath -Raw
            $originalSize = $content.Length
            
            Write-Log "Original message size: $originalSize bytes"
            
            # Convert to bytes
            $data = [System.Text.Encoding]::UTF8.GetBytes($content)
            
            # Compress
            $compressed = $this.CompressData($data)
            
            # Prepare output
            $output = @{
                Timestamp = Get-Date -Format "o"
                CompressionMethod = $this.CompressionMethod
                OriginalSize = $originalSize
                CompressedSize = $compressed.Length
                CompressionRatio = [Math]::Round(($compressed.Length / $originalSize) * 100, 2)
                Data = [Convert]::ToBase64String($compressed)
            }
            
            # Add batching info if enabled
            if ($this.BatchingEnabled) {
                try {
                    $messages = $content | ConvertFrom-Json
                    if ($messages -is [array]) {
                        $batches = $this.BatchMessages($messages)
                        $output.Batches = $batches
                        $output.BatchCount = $batches.Count
                    }
                }
                catch {
                    Write-Log "Could not parse messages for batching" "WARN"
                }
            }
            
            # Save optimized content
            $output | ConvertTo-Json | Set-Content -Path $this.OutputPath
            
            $reduction = (($originalSize - $compressed.Length) / $originalSize) * 100
            
            Write-Log "Optimized message size: $($compressed.Length) bytes"
            Write-Log "Message reduction: $([Math]::Round($reduction, 2))%" "SUCCESS"
            
            $this.Statistics = @{
                OriginalSize = $originalSize
                CompressedSize = $compressed.Length
                Reduction = $reduction
                CompressionMethod = $this.CompressionMethod
            }
            
            $this.PrintStatistics()
        }
        catch {
            Write-Log "Error during optimization: $_" "ERROR"
            throw
        }
    }
    
    [void] PrintStatistics() {
        Write-Host "`nMessage Optimization Statistics:" -ForegroundColor Green
        Write-Host "================================"
        Write-Host "Original Size: $($this.Statistics.OriginalSize) bytes"
        Write-Host "Compressed Size: $($this.Statistics.CompressedSize) bytes"
        Write-Host "Reduction: $([Math]::Round($this.Statistics.Reduction, 2))%"
        Write-Host "Method: $($this.Statistics.CompressionMethod)"
    }
}

try {
    Write-Log "Initializing message optimizer"
    
    $optimizer = [MessageOptimizer]::new(
        $InputMessage,
        $OutputPath,
        $CompressionMethod,
        $EnableBatching,
        $BatchSize
    )
    
    $optimizer.Optimize()
    
    Write-Log "Message optimization complete" "SUCCESS"
    exit 0
}
catch {
    Write-Log "Fatal error: $_" "ERROR"
    exit 1
}
