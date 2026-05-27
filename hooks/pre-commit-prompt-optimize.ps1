# Pre-commit hook for prompt optimization
# Automatically compresses system prompts before commit

param([string]$WorkspaceRoot = ".")

Write-Host "[PRE-COMMIT] Optimizing system prompts..." -ForegroundColor Cyan

$claudePath = Join-Path $WorkspaceRoot "CLAUDE.md"
$compressedPath = Join-Path $WorkspaceRoot ".session\CLAUDE.min.md"

if (Test-Path $claudePath) {
    $originalSize = (Get-Item $claudePath).Length
    
    # Compress
    & (Join-Path $WorkspaceRoot "scripts\utilities\semantic-compression.ps1") -InputPath $claudePath -OutputPath $compressedPath | Out-Null
    
    $compressedSize = (Get-Item $compressedPath).Length
    $saved = $originalSize - $compressedSize
    $percent = [Math]::Round(($saved / $originalSize) * 100, 1)
    
    Write-Host "[PRE-COMMIT] Saved $saved bytes ($percent%)" -ForegroundColor Green
    
    # Security scan
    $scanResult = & (Join-Path $WorkspaceRoot "scripts\utilities\prompt-security-scanner.ps1") -PromptContent (Get-Content $claudePath -Raw) 2>&1 | Out-String
    if ($scanResult -match "ISSUES") {
        Write-Host "[PRE-COMMIT] Security issues detected!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "[PRE-COMMIT] Complete" -ForegroundColor Green
